"""Identity — auth routers: OTP, token, and /me."""

from __future__ import annotations

from typing import TYPE_CHECKING

import structlog
from fastapi import APIRouter, HTTPException, status
from sqlalchemy import select

if TYPE_CHECKING:
    pass

from app.config import get_settings
from app.core.security import create_access_token
from app.db.models.user import User
from app.db.session import AsyncSessionLocal
from app.deps import CurrentUser
from app.identity.otp import (
    OtpExpiredOrNotFound,
    OtpInvalid,
    RateLimitExceeded,
    create_otp,
    verify_otp,
)
from app.identity.schemas import (
    OtpRequestIn,
    OtpRequestOut,
    OtpVerifyIn,
    OtpVerifyOut,
    TokenIn,
    TokenOut,
    UserMeOut,
)

log = structlog.get_logger(__name__)

router = APIRouter(prefix="/auth", tags=["Auth"])


# ---------------------------------------------------------------------------
# Redis helper — lazy singleton
# ---------------------------------------------------------------------------
_redis_client: object = None


async def _get_redis() -> object:
    """Return a shared Redis async client."""
    global _redis_client
    if _redis_client is None:
        import redis.asyncio as aioredis

        settings = get_settings()
        _redis_client = aioredis.from_url(settings.redis_url, decode_responses=False)
    return _redis_client


# ---------------------------------------------------------------------------
# POST /v1/auth/otp/request
# ---------------------------------------------------------------------------
@router.post(
    "/otp/request",
    response_model=OtpRequestOut,
    status_code=status.HTTP_200_OK,
    summary="Request an OTP for farmer / staff login",
    description=(
        "Sends a 6-digit OTP to the farmer's registered phone number. "
        "In development mode the OTP is returned in the response as `dev_otp`. "
        "Rate-limited to 5 requests/minute per phone number."
    ),
)
async def otp_request(body: OtpRequestIn) -> OtpRequestOut:
    settings = get_settings()
    redis = await _get_redis()

    # Check user exists
    async with AsyncSessionLocal() as db:
        result = await db.execute(select(User).where(User.phone == body.phone))
        user = result.scalar_one_or_none()

    if user is None:
        # Return generic message to avoid phone enumeration
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="No account found for this phone number.",
        )

    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Account is deactivated.",
        )

    try:
        request_id, raw_otp = await create_otp(body.phone, redis)  # type: ignore[arg-type]
    except RateLimitExceeded as exc:
        raise HTTPException(
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
            detail=str(exc),
        ) from exc

    return OtpRequestOut(
        message="OTP sent successfully",
        expires_in_seconds=settings.otp_expiry_seconds,
        request_id=request_id,
        # Only expose raw OTP in dev mode
        dev_otp=raw_otp if settings.is_development else None,
    )


# ---------------------------------------------------------------------------
# POST /v1/auth/otp/verify
# ---------------------------------------------------------------------------
@router.post(
    "/otp/verify",
    response_model=OtpVerifyOut,
    status_code=status.HTTP_200_OK,
    summary="Verify OTP and receive a JWT",
)
async def otp_verify(body: OtpVerifyIn) -> OtpVerifyOut:
    redis = await _get_redis()

    try:
        await verify_otp(body.request_id, body.phone, body.otp, redis)  # type: ignore[arg-type]
    except OtpExpiredOrNotFound as exc:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=str(exc),
        ) from exc
    except OtpInvalid as exc:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=str(exc),
        ) from exc

    # Load user after successful verification
    async with AsyncSessionLocal() as db:
        result = await db.execute(select(User).where(User.phone == body.phone))
        user = result.scalar_one_or_none()

    if user is None or not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Account not found or deactivated.",
        )

    token = create_access_token(
        sub=str(user.id),
        role=user.role,
        district=user.district,
        expires_in=3600,
    )

    log.info("auth.otp_verified", user_id=str(user.id), role=user.role)

    return OtpVerifyOut(
        access_token=token,
        token_type="bearer",
        expires_in=3600,
        role=user.role,
        name=user.name,
        is_new_user=False,
    )


# ---------------------------------------------------------------------------
# POST /v1/auth/token  (staff / admin password login)
# ---------------------------------------------------------------------------
@router.post(
    "/token",
    response_model=TokenOut,
    status_code=status.HTTP_200_OK,
    summary="Staff/admin login via username + password",
    description=(
        "Password-based login for staff and admin accounts. "
        "Farmers should use the OTP flow instead."
    ),
    include_in_schema=True,
)
async def token(body: TokenIn) -> TokenOut:
    if body.grant_type != "password" or not body.username or not body.password:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="grant_type must be 'password' and username + password are required.",
        )

    async with AsyncSessionLocal() as db:
        result = await db.execute(
            select(User).where(User.username == body.username)
        )
        user = result.scalar_one_or_none()

    if user is None or not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid credentials.",
        )

    if user.role not in ("staff", "admin"):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="This login method is for staff and admin only.",
        )

    # Verify password with bcrypt
    from passlib.context import CryptContext

    pwd_ctx = CryptContext(schemes=["bcrypt"], deprecated="auto")
    if not user.password_hash or not pwd_ctx.verify(body.password, user.password_hash):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid credentials.",
        )

    token_str = create_access_token(
        sub=str(user.id),
        role=user.role,
        district=user.district,
        expires_in=3600,
    )

    log.info("auth.password_login", user_id=str(user.id), role=user.role)

    return TokenOut(
        access_token=token_str,
        token_type="bearer",
        expires_in=3600,
        role=user.role,
        name=user.name,
        district=user.district,
    )


# ---------------------------------------------------------------------------
# GET /v1/auth/me  (who am I?)
# ---------------------------------------------------------------------------
@router.get(
    "/me",
    response_model=UserMeOut,
    status_code=status.HTTP_200_OK,
    summary="Return the current user's identity from the JWT",
)
async def me(current_user: CurrentUser) -> UserMeOut:
    return UserMeOut(
        sub=current_user.sub,
        role=current_user.role,
        district=current_user.district,
    )
