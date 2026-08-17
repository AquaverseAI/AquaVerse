"""OTP generation, storage, and verification — Redis-backed with HMAC security."""

from __future__ import annotations

import uuid
from typing import TYPE_CHECKING

import structlog

from app.config import get_settings
from app.core.security import generate_otp, hash_otp, verify_otp_hash

if TYPE_CHECKING:
    import redis.asyncio as aioredis

log = structlog.get_logger(__name__)

# Redis key patterns
_OTP_KEY = "otp:{request_id}"   # value = "phone:hmac_hash"
_RATE_KEY = "otp_rate:{phone}"  # value = request count


async def create_otp(
    phone: str,
    redis: aioredis.Redis,  # type: ignore[type-arg]
) -> tuple[str, str]:
    """
    Generate an OTP, store its HMAC hash in Redis, return (request_id, raw_otp).

    The raw_otp is ONLY used in dev-mode logging — never stored.
    The returned request_id must be sent by the client on /otp/verify.
    """
    settings = get_settings()

    # Rate-limit check
    rate_key = _RATE_KEY.format(phone=phone)
    count = await redis.incr(rate_key)
    if count == 1:
        await redis.expire(rate_key, 60)  # 1 minute window
    if count > settings.rate_limit_otp_per_minute:
        raise RateLimitExceeded(f"Too many OTP requests for {phone}. Try again in 1 minute.")

    # Generate OTP + request correlation ID
    otp = generate_otp(settings.otp_length)
    request_id = f"req_{uuid.uuid4().hex}"
    otp_hash = hash_otp(otp, phone)

    # Store: "<phone>:<hmac_hash>" under the request_id key
    key = _OTP_KEY.format(request_id=request_id)
    await redis.setex(key, settings.otp_expiry_seconds, f"{phone}:{otp_hash}")

    log.info(
        "otp.created",
        phone_suffix=phone[-4:],
        request_id=request_id,
        ttl=settings.otp_expiry_seconds,
    )

    # Dev-mode: log the raw OTP so testers can use it without SMS
    if settings.is_development:
        log.warning(
            "otp.dev_mode_plaintext",
            otp=otp,
            phone=phone,
            note="NEVER log OTP in production",
        )

    return request_id, otp


async def verify_otp(
    request_id: str,
    phone: str,
    otp: str,
    redis: aioredis.Redis,  # type: ignore[type-arg]
) -> bool:
    """
    Verify an OTP against the stored HMAC hash.

    Returns True on success. Raises OtpInvalid on failure.
    Always deletes the key after one attempt (one-time use).
    """
    key = _OTP_KEY.format(request_id=request_id)
    stored = await redis.get(key)

    if stored is None:
        raise OtpExpiredOrNotFound("OTP has expired or request_id is invalid.")

    # Decode stored value
    stored_str = stored.decode() if isinstance(stored, bytes) else stored
    parts = stored_str.split(":", 1)
    if len(parts) != 2:
        await redis.delete(key)
        raise OtpInvalid("Malformed OTP record.")

    stored_phone, stored_hash = parts

    # One-time use: delete before verifying (prevents timing oracle)
    await redis.delete(key)

    if stored_phone != phone:
        raise OtpInvalid("Phone number does not match OTP request.")

    if not verify_otp_hash(otp, phone, stored_hash):
        raise OtpInvalid("OTP is incorrect.")

    log.info("otp.verified", phone_suffix=phone[-4:], request_id=request_id)
    return True


# ---------------------------------------------------------------------------
# Exceptions
# ---------------------------------------------------------------------------
class OtpInvalid(Exception):
    """OTP value is wrong."""


class OtpExpiredOrNotFound(Exception):
    """OTP has expired or request_id doesn't exist in Redis."""


class RateLimitExceeded(Exception):
    """Too many OTP requests."""
