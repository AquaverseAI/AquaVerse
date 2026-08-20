"""Unit tests — Bhashini client honesty (P3.1), no network/containers."""

from __future__ import annotations

import os

import pytest

os.environ.setdefault("DATABASE_URL", "postgresql+asyncpg://x:x@localhost/x")
os.environ.setdefault("APP_SECRET_KEY", "test_secret_key_minimum_32_chars_here")
os.environ.setdefault("INTERNAL_API_TOKEN", "test_internal_token_minimum_32_chars")

from app.i18n.translate import TranslationNotConfigured, translate_text


@pytest.mark.asyncio
async def test_translate_text_raises_when_unconfigured() -> None:
    """Default test settings carry empty bhashini_* fields — the client
    must raise, never fabricate a translation string."""
    with pytest.raises(TranslationNotConfigured):
        await translate_text("hello", "en", "ta")
