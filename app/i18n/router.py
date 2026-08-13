"""i18n — router for /v1/translate."""

from __future__ import annotations

from fastapi import APIRouter, status

from app.core.timezones import utcnow
from app.i18n.schemas import TranslateIn, TranslateOut

router = APIRouter(prefix="/translate", tags=["i18n"])


@router.post(
    "",
    response_model=TranslateOut,
    status_code=status.HTTP_200_OK,
    summary="Translate text using IndicTrans2 / Bhashini",
    description=(
        "Translate text between Indian languages using IndicTrans2 (via Bhashini API). "
        "Results are cached in Redis by hash of (source_lang, target_lang, text) with ~90% hit rate target."
    ),
)
async def translate(body: TranslateIn) -> TranslateOut:
    """Phase 1: return echo fixture. Phase 5: call Bhashini / AI4Bharat with Redis cache."""
    now = utcnow()
    return TranslateOut(
        source_lang=body.source_lang,
        target_lang=body.target_lang,
        source_text=body.text,
        translated_text=f"[STUB TRANSLATION to {body.target_lang}] {body.text}",
        cached=False,
        tts_url=None,
        translated_at=now,
    )
