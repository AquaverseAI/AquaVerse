"""i18n — router for /v1/translate."""

from __future__ import annotations

import structlog
from fastapi import APIRouter, HTTPException, status

from app.core.timezones import utcnow
from app.deps import CurrentUser
from app.i18n.cache import get_cached_translation, store_translation
from app.i18n.schemas import TranslateIn, TranslateOut
from app.i18n.translate import TranslationFailed, TranslationNotConfigured, translate_text

log = structlog.get_logger(__name__)

router = APIRouter(prefix="/translate", tags=["i18n"])


# ---------------------------------------------------------------------------
# Redis helper — lazy singleton (same pattern as app/identity/router.py)
# ---------------------------------------------------------------------------
_redis_client: object = None


async def _get_redis() -> object:
    """Return a shared Redis async client."""
    global _redis_client
    if _redis_client is None:
        import redis.asyncio as aioredis

        from app.config import get_settings

        settings = get_settings()
        _redis_client = aioredis.from_url(settings.redis_url, decode_responses=False)
    return _redis_client


@router.post(
    "",
    response_model=TranslateOut,
    status_code=status.HTTP_200_OK,
    summary="Translate text using IndicTrans2 / Bhashini",
    description=(
        "Translate text between Indian languages via the real Bhashini ULCA "
        "pipeline. Results are cached in Redis by hash of "
        "(source_lang, target_lang, text)."
    ),
)
async def translate(body: TranslateIn, user: CurrentUser) -> TranslateOut:
    now = utcnow()

    if body.source_lang == body.target_lang:
        return TranslateOut(
            source_lang=body.source_lang,
            target_lang=body.target_lang,
            source_text=body.text,
            translated_text=body.text,
            cached=False,
            tts_url=None,
            translated_at=now,
        )

    redis = await _get_redis()

    cached = await get_cached_translation(
        redis,  # type: ignore[arg-type]
        body.source_lang,
        body.target_lang,
        body.text,
    )
    if cached is not None:
        return TranslateOut(
            source_lang=body.source_lang,
            target_lang=body.target_lang,
            source_text=body.text,
            translated_text=cached,
            cached=True,
            tts_url=None,
            translated_at=now,
        )

    try:
        translated_text = await translate_text(body.text, body.source_lang, body.target_lang)
    except TranslationNotConfigured as exc:
        log.info("i18n.translate_not_configured")
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Translation service is not configured for this deployment",
        ) from exc
    except TranslationFailed as exc:
        log.warning("i18n.translate_failed", error=str(exc))
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail="Translation service call failed",
        ) from exc

    await store_translation(
        redis,  # type: ignore[arg-type]
        body.source_lang,
        body.target_lang,
        body.text,
        translated_text,
    )

    return TranslateOut(
        source_lang=body.source_lang,
        target_lang=body.target_lang,
        source_text=body.text,
        translated_text=translated_text,
        cached=False,
        tts_url=None,
        translated_at=now,
    )
