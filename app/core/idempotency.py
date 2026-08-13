"""Idempotency — client_log_id replay handling via Redis."""

from __future__ import annotations

import json
from datetime import UTC, datetime
from typing import TYPE_CHECKING, Any

import structlog

if TYPE_CHECKING:
    from redis.asyncio import Redis

log = structlog.get_logger(__name__)

# Keys expire after 48 hours — mobile clients should not replay after that
_TTL_SECONDS = 172_800


def _key(client_log_id: str) -> str:
    return f"idempotency:{client_log_id}"


async def check_idempotency(
    redis: Redis,  # type: ignore[type-arg]
    client_log_id: str,
) -> dict[str, Any] | None:
    """
    Return the cached response if this client_log_id has been seen before,
    or None if this is a new request.
    """
    raw = await redis.get(_key(client_log_id))
    if raw is None:
        return None
    log.info("idempotency.cache_hit", client_log_id=client_log_id)
    res = json.loads(raw)
    if isinstance(res, dict):
        return res
    return None


async def store_idempotency(
    redis: Redis,  # type: ignore[type-arg]
    client_log_id: str,
    response_body: dict[str, Any],
) -> None:
    """
    Store the response for future replays.
    The payload is tagged with the original timestamp so callers can tell
    it is a replay.
    """
    payload = {
        **response_body,
        "_idempotency": {
            "client_log_id": client_log_id,
            "stored_at": datetime.now(UTC).isoformat(),
        },
    }
    await redis.setex(_key(client_log_id), _TTL_SECONDS, json.dumps(payload))
    log.info("idempotency.stored", client_log_id=client_log_id)
