"""Bhashini ULCA translation client (P3.1).

`POST /v1/translate` used to return a hardcoded `[STUB TRANSLATION ...]`
string for every request, regardless of configuration. This module calls
the real Bhashini ULCA pipeline API (https://bhashini.gov.in) when
credentials are configured (`Settings.bhashini_api_key` /
`bhashini_user_id` / `bhashini_pipeline_id`), and raises
`TranslationNotConfigured` — never a fabricated string — when they are
not. This mirrors `app/alerts/fanout.py`'s "report, don't fake" convention
for integrations this deployment may not have credentials for.

The Bhashini pipeline is a two-step call:
1. `getModelsPipeline` resolves, for a given source/target language pair,
   the actual inference endpoint (`callbackUrl`) plus a short-lived
   per-call API key.
2. That `callbackUrl` is then called with the text to translate,
   authenticated with the per-call key from step 1.
"""

from __future__ import annotations

from typing import Any

import httpx
import structlog

from app.config import Settings, get_settings

log = structlog.get_logger(__name__)

_PIPELINE_CONFIG_URL = "https://meity-auth.ulcacontrib.org/ulca/apis/v0/model/getModelsPipeline"
_TRANSLATION_TASK_TYPE = "translation"


class TranslationNotConfigured(Exception):
    """Raised when Bhashini credentials are not configured for this deployment."""


class TranslationFailed(Exception):
    """Raised when Bhashini is configured but the API call itself failed."""


async def translate_text(text: str, source_lang: str, target_lang: str) -> str:
    """Translate `text` from `source_lang` to `target_lang` via Bhashini.

    Raises `TranslationNotConfigured` if no credentials are set, or
    `TranslationFailed` if the (real) API call fails or returns an
    unexpected shape.
    """
    settings = get_settings()
    if not (
        settings.bhashini_api_key and settings.bhashini_user_id and settings.bhashini_pipeline_id
    ):
        raise TranslationNotConfigured(
            "Bhashini credentials are not configured "
            "(bhashini_api_key / bhashini_user_id / bhashini_pipeline_id)"
        )

    async with httpx.AsyncClient(timeout=15.0) as client:
        pipeline = await _resolve_pipeline(client, settings, source_lang, target_lang)
        return await _run_translation(client, pipeline, text)


async def _resolve_pipeline(
    client: httpx.AsyncClient, settings: Settings, source_lang: str, target_lang: str
) -> dict[str, str]:
    headers = {
        "userID": settings.bhashini_user_id,
        "ulcaApiKey": settings.bhashini_api_key,
        "Content-Type": "application/json",
    }
    payload = {
        "pipelineTasks": [
            {
                "taskType": _TRANSLATION_TASK_TYPE,
                "config": {
                    "language": {"sourceLanguage": source_lang, "targetLanguage": target_lang}
                },
            }
        ],
        "pipelineRequestConfig": {"pipelineId": settings.bhashini_pipeline_id},
    }
    try:
        resp = await client.post(_PIPELINE_CONFIG_URL, json=payload, headers=headers)
        resp.raise_for_status()
    except httpx.HTTPError as exc:
        log.warning("i18n.pipeline_config_failed", error=str(exc))
        raise TranslationFailed(f"Bhashini pipeline config call failed: {exc}") from exc

    data: dict[str, Any] = resp.json()
    try:
        endpoint = data["pipelineInferenceAPIEndPoint"]
        callback_url: str = endpoint["callbackUrl"]
        inference_key = endpoint["inferenceApiKey"]
        service_id: str = data["pipelineResponseConfig"][0]["config"][0]["serviceId"]
    except (KeyError, IndexError) as exc:
        raise TranslationFailed(f"Unexpected Bhashini pipeline response shape: {exc}") from exc

    return {
        "callback_url": callback_url,
        "inference_key_name": inference_key["name"],
        "inference_key_value": inference_key["value"],
        "service_id": service_id,
    }


async def _run_translation(client: httpx.AsyncClient, pipeline: dict[str, str], text: str) -> str:
    headers = {
        pipeline["inference_key_name"]: pipeline["inference_key_value"],
        "Content-Type": "application/json",
    }
    payload = {
        "pipelineTasks": [
            {"taskType": _TRANSLATION_TASK_TYPE, "config": {"serviceId": pipeline["service_id"]}}
        ],
        "inputData": {"input": [{"source": text}]},
    }
    try:
        resp = await client.post(pipeline["callback_url"], json=payload, headers=headers)
        resp.raise_for_status()
    except httpx.HTTPError as exc:
        log.warning("i18n.translation_call_failed", error=str(exc))
        raise TranslationFailed(f"Bhashini translation call failed: {exc}") from exc

    data: dict[str, Any] = resp.json()
    try:
        target_text: str = data["pipelineResponse"][0]["output"][0]["target"]
    except (KeyError, IndexError) as exc:
        raise TranslationFailed(f"Unexpected Bhashini translation response shape: {exc}") from exc
    return target_text
