"""i18n — Pydantic v2 schemas for /v1/translate."""

from __future__ import annotations

from datetime import datetime
from typing import TYPE_CHECKING

from pydantic import BaseModel, Field

if TYPE_CHECKING:
    pass


class TranslateIn(BaseModel):
    text: str = Field(..., max_length=5000)
    source_lang: str = Field(default="en", description="BCP-47 language code, e.g. 'en', 'ta'")
    target_lang: str = Field(..., description="BCP-47 language code, e.g. 'ta', 'te', 'ml'")
    include_tts: bool = Field(default=False, description="Return TTS audio URL for translated text")


class TranslateOut(BaseModel):
    source_lang: str
    target_lang: str
    source_text: str
    translated_text: str
    cached: bool = Field(..., description="True if served from Redis translation cache")
    tts_url: str | None = Field(default=None, description="URL to TTS audio file (if requested)")
    translated_at: datetime
