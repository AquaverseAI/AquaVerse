"""Redis translation cache — hash-keyed, ~90% hit rate target (P3.1).

`POST /v1/translate` used to always report `cached=False` because nothing
was ever actually cached. This stores/looks up translated text in Redis,
keyed by a hash of `(source_lang, target_lang, text)` so identical repeat
requests (a common pattern for farmer-facing UI strings and advisory
templates) are served without a second Bhashini call.
"""

from __future__ import annotations

import hashlib
from typing import TYPE_CHECKING

import structlog

from app.config import get_settings

if TYPE_CHECKING:
    from redis.asyncio import Redis

log = structlog.get_logger(__name__)


def _cache_key(source_lang: str, target_lang: str, text: str) -> str:
    digest = hashlib.sha256(f"{source_lang}:{target_lang}:{text}".encode()).hexdigest()
    return f"translate:{digest}"


async def get_cached_translation(
    redis: Redis,  # type: ignore[type-arg]
    source_lang: str,
    target_lang: str,
    text: str,
) -> str | None:
    """Return the cached translated text, or None on a cache miss."""
    raw = await redis.get(_cache_key(source_lang, target_lang, text))
    if raw is None:
        return None
    log.info("i18n.cache_hit", source_lang=source_lang, target_lang=target_lang)
    return raw.decode("utf-8") if isinstance(raw, bytes) else str(raw)


async def store_translation(
    redis: Redis,  # type: ignore[type-arg]
    source_lang: str,
    target_lang: str,
    text: str,
    translated_text: str,
) -> None:
    """Cache a fresh translation for `Settings.redis_cache_ttl_seconds`."""
    settings = get_settings()
    await redis.setex(
        _cache_key(source_lang, target_lang, text),
        settings.redis_cache_ttl_seconds,
        translated_text,
    )
    log.info("i18n.cache_store", source_lang=source_lang, target_lang=target_lang)
