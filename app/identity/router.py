"""Identity — auth routers: OTP, token."""

from __future__ import annotations

from fastapi import APIRouter, status

from app.identity.schemas import (
    OtpRequestIn,
    OtpRequestOut,
    OtpVerifyIn,
    OtpVerifyOut,
    TokenIn,
    TokenOut,
)

router = APIRouter(prefix="/auth", tags=["Auth"])


@router.post(
    "/otp/request",
    response_model=OtpRequestOut,
    status_code=status.HTTP_200_OK,
    summary="Request an OTP for farmer login/registration",
    description=(
        "Sends a 6-digit OTP to the farmer's registered phone number via SMS. "
        "Rate-limited to 5 requests/minute per phone number."
    ),
)
async def otp_request(body: OtpRequestIn) -> OtpRequestOut:
    """
    Phase 1: return fixture.
    Phase 3: generate OTP, store HMAC hash in Redis with TTL, send via SMS gateway.
    """
    return OtpRequestOut(
        message="OTP sent successfully",
        expires_in_seconds=300,
        request_id="req_00000000-stub-0000-0000-000000000001",
    )


@router.post(
    "/otp/verify",
    response_model=OtpVerifyOut,
    status_code=status.HTTP_200_OK,
    summary="Verify OTP and receive a JWT",
)
async def otp_verify(body: OtpVerifyIn) -> OtpVerifyOut:
    """
    Phase 1: return fixture JWT.
    Phase 3: verify HMAC hash from Redis, issue pond-scoped JWT.
    """
    return OtpVerifyOut(
        access_token="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.stub",
        token_type="bearer",
        expires_in=3600,
        role="farmer",
        is_new_user=False,
    )


@router.post(
    "/token",
    response_model=TokenOut,
    status_code=status.HTTP_200_OK,
    summary="Staff/admin token via Keycloak credentials or code exchange",
)
async def token(body: TokenIn) -> TokenOut:
    """
    Phase 1: return fixture token.
    Phase 3: verify against Keycloak, embed district claims.
    """
    return TokenOut(
        access_token="eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.stub",
        refresh_token="refresh.stub",
        token_type="bearer",
        expires_in=3600,
        role="district_officer",
        district="Nagapattinam",
    )
