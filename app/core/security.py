"""JWT verification, OTP flow, Keycloak client stubs."""

from __future__ import annotations

import hashlib
import hmac
import secrets
from datetime import UTC, datetime, timedelta

import structlog
from jose import JWTError, jwt

from app.config import get_settings

log = structlog.get_logger(__name__)


# ---------------------------------------------------------------------------
# OTP
# ---------------------------------------------------------------------------
def generate_otp(length: int = 6) -> str:
    """Generate a cryptographically secure numeric OTP."""
    return "".join([str(secrets.randbelow(10)) for _ in range(length)])


def hash_otp(otp: str, phone: str) -> str:
    """HMAC-SHA256 of otp+phone using the app secret key."""
    settings = get_settings()
    key = settings.app_secret_key.encode()
    msg = f"{phone}:{otp}".encode()
    return hmac.new(key, msg, hashlib.sha256).hexdigest()


def verify_otp_hash(otp: str, phone: str, stored_hash: str) -> bool:
    """Constant-time comparison of OTP hash."""
    expected = hash_otp(otp, phone)
    return hmac.compare_digest(expected, stored_hash)


# ---------------------------------------------------------------------------
# JWT  (Phase 3: load RS256 public key from file; Phase 1: HS256 stub)
# ---------------------------------------------------------------------------
ALGORITHM_STUB = "HS256"  # replaced by RS256 in Phase 3


def create_access_token(
    sub: str,
    role: str,
    pond_ids: list[str] | None = None,
    district: str | None = None,
    expires_in: int = 3600,
) -> str:
    """Create a signed JWT. Phase 1 uses HS256 with app_secret_key."""
    settings = get_settings()
    now = datetime.now(UTC)
    payload: dict[str, object] = {
        "sub": sub,
        "role": role,
        "pond_ids": pond_ids or [],
        "district": district,
        "iat": now,
        "exp": now + timedelta(seconds=expires_in),
        "iss": "aquaverse-backend",
    }
    return jwt.encode(payload, settings.app_secret_key, algorithm=ALGORITHM_STUB)


def verify_token(token: str) -> dict[str, object]:
    """
    Decode and verify a JWT.
    Phase 1: HS256 with app_secret_key.
    Phase 3: RS256 with public key loaded from settings.jwt_public_key_path.
    """
    settings = get_settings()
    try:
        decoded = jwt.decode(token, settings.app_secret_key, algorithms=[ALGORITHM_STUB])
        return decoded
    except JWTError as exc:
        log.warning("jwt.verification_failed", error=str(exc))
        raise


# ---------------------------------------------------------------------------
# Keycloak client  (Phase 3: full implementation)
# ---------------------------------------------------------------------------
class KeycloakClient:
    """
    Thin async wrapper around the Keycloak admin REST API.
    Phase 1: stub that logs and returns empty data structures.
    Phase 3: implement introspect, user-info, token-exchange calls.
    """

    async def introspect(self, token: str) -> dict[str, object]:
        log.warning("keycloak.introspect.stub_called", token_prefix=token[:8])
        return {"active": True, "sub": "stub-user"}

    async def get_user_info(self, token: str) -> dict[str, object]:
        log.warning("keycloak.get_user_info.stub_called")
        return {"sub": "stub-user", "email": "stub@example.com"}


keycloak_client = KeycloakClient()
