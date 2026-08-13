"""Shared FastAPI dependency providers."""

from __future__ import annotations

from typing import TYPE_CHECKING, Annotated

from fastapi import Depends, Header, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import Settings, get_settings
from app.db.session import AsyncSessionLocal

if TYPE_CHECKING:
    from collections.abc import AsyncGenerator
    from uuid import UUID


# ---------------------------------------------------------------------------
# Database session
# ---------------------------------------------------------------------------
async def get_db() -> AsyncGenerator[AsyncSession, None]:
    """Yield an async DB session and close it when the request finishes."""
    async with AsyncSessionLocal() as session:
        try:
            yield session
            await session.commit()
        except Exception:
            await session.rollback()
            raise


DbSession = Annotated[AsyncSession, Depends(get_db)]
AppSettings = Annotated[Settings, Depends(get_settings)]


# ---------------------------------------------------------------------------
# Auth token parsing  (Phase 3 will wire Keycloak / JWT verify fully)
# ---------------------------------------------------------------------------
class TokenPayload:
    """Parsed JWT claims. Populated by verify_token in core/security.py."""

    def __init__(
        self,
        sub: str,
        role: str,
        pond_ids: list[UUID] | None = None,
        district: str | None = None,
    ) -> None:
        self.sub = sub
        self.role = role
        self.pond_ids = pond_ids or []
        self.district = district


async def _parse_bearer(authorization: str = Header(default="")) -> str:
    if not authorization.startswith("Bearer "):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Missing or malformed Bearer token",
            headers={"WWW-Authenticate": "Bearer"},
        )
    return authorization.removeprefix("Bearer ").strip()


async def get_current_user(
    token: Annotated[str, Depends(_parse_bearer)],
) -> TokenPayload:
    """
    Verify JWT and return parsed claims.
    Phase 1: stub returns a mock farmer token so endpoints can be exercised.
    Phase 3: replace stub body with real JWT verification.
    """
    # TODO (Phase 3): call core/security.py verify_token(token)
    from uuid import uuid4

    _ = token  # suppress unused warning
    return TokenPayload(
        sub=str(uuid4()),
        role="farmer",
        pond_ids=[uuid4()],
        district=None,
    )


CurrentUser = Annotated[TokenPayload, Depends(get_current_user)]


async def get_current_farmer(user: CurrentUser) -> TokenPayload:
    """Require farmer role."""
    if user.role not in ("farmer", "staff", "admin"):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Farmer role required")
    return user


async def get_current_staff(user: CurrentUser) -> TokenPayload:
    """Require staff or admin role."""
    if user.role not in ("staff", "admin"):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Staff role required")
    return user


CurrentFarmer = Annotated[TokenPayload, Depends(get_current_farmer)]
CurrentStaff = Annotated[TokenPayload, Depends(get_current_staff)]


# ---------------------------------------------------------------------------
# Internal API guard (POST /v1/reason)
# ---------------------------------------------------------------------------
async def require_internal_token(
    x_internal_token: str = Header(default="", alias="X-Internal-Token"),
) -> None:
    """Gate keeper for internal-only endpoints."""
    settings = get_settings()
    if x_internal_token != settings.internal_api_token:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="This endpoint is restricted to internal callers.",
        )


InternalOnly = Annotated[None, Depends(require_internal_token)]


# ---------------------------------------------------------------------------
# District claim check
# ---------------------------------------------------------------------------
async def require_district_claim(
    district: str,
    user: CurrentStaff,
) -> None:
    """Verify a staff user has a claim for the requested district."""
    if user.district and user.district != district:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=f"Access to district '{district}' denied for your token.",
        )
