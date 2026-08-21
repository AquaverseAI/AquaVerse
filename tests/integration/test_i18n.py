"""Integration tests — real i18n translation cache/router (P3.1).

`POST /v1/translate` used to always return a hardcoded
`[STUB TRANSLATION to {lang}] {text}` string. This exercises the real
Redis-backed cache (`i18n_client` fixture, tests/conftest.py — a real
Redis container) plus the honest "not configured" path
(`app/i18n/translate.py` raises `TranslationNotConfigured` when no
Bhashini credentials are set, which the router turns into a 503 rather
than fabricating a translation).

The genuinely-configured Bhashini call path is covered separately by
monkeypatching `app.i18n.router.translate_text`, since no real Bhashini
credentials exist in CI — this still exercises the real cache read/write
around it.
"""

from __future__ import annotations

from typing import TYPE_CHECKING
from uuid import uuid4

import pytest

from app.core.security import create_access_token

if TYPE_CHECKING:
    from httpx import AsyncClient


def _headers() -> dict[str, str]:
    token = create_access_token(sub=str(uuid4()), role="staff", district="Nagapattinam")
    return {"Authorization": f"Bearer {token}"}


@pytest.mark.integration
async def test_same_source_and_target_lang_is_a_passthrough(i18n_client: AsyncClient) -> None:
    resp = await i18n_client.post(
        "/v1/translate",
        json={"text": "hello pond", "source_lang": "en", "target_lang": "en"},
        headers=_headers(),
    )
    assert resp.status_code == 200, resp.text
    body = resp.json()
    assert body["translated_text"] == "hello pond"
    assert body["cached"] is False


@pytest.mark.integration
async def test_translate_without_bhashini_credentials_returns_503(i18n_client: AsyncClient) -> None:
    """No bhashini_api_key/user_id/pipeline_id is set in the test env, so
    this must honestly report unavailable rather than fabricate a string
    like the old `[STUB TRANSLATION ...]` fixture did."""
    resp = await i18n_client.post(
        "/v1/translate",
        json={"text": "water quality is low", "source_lang": "en", "target_lang": "ta"},
        headers=_headers(),
    )
    assert resp.status_code == 503, resp.text


@pytest.mark.integration
async def test_translate_caches_result_and_second_call_hits_cache(
    i18n_client: AsyncClient, monkeypatch: pytest.MonkeyPatch
) -> None:
    calls = 0

    async def _fake_translate_text(text: str, source_lang: str, target_lang: str) -> str:
        nonlocal calls
        calls += 1
        return f"{text}::{target_lang}"

    monkeypatch.setattr("app.i18n.router.translate_text", _fake_translate_text)

    payload = {"text": "check the DO levels", "source_lang": "en", "target_lang": "ta"}

    first = await i18n_client.post("/v1/translate", json=payload, headers=_headers())
    assert first.status_code == 200, first.text
    first_body = first.json()
    assert first_body["cached"] is False
    assert first_body["translated_text"] == "check the DO levels::ta"
    assert calls == 1

    second = await i18n_client.post("/v1/translate", json=payload, headers=_headers())
    assert second.status_code == 200, second.text
    second_body = second.json()
    assert second_body["cached"] is True
    assert second_body["translated_text"] == "check the DO levels::ta"
    # Real cache hit — the fake translator was not called again.
    assert calls == 1


@pytest.mark.integration
async def test_translate_requires_auth(i18n_client: AsyncClient) -> None:
    resp = await i18n_client.post(
        "/v1/translate",
        json={"text": "hi", "source_lang": "en", "target_lang": "ta"},
    )
    assert resp.status_code in (401, 403)
