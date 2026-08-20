"""FCM + SMS fan-out — shared by Alerts (P2.1) and Advisories (P2.4).

HONESTY NOTE (same convention as `do_forecast.py`'s empirical baseline):
no FCM service account or SMS provider credentials exist in this repo's
`.env.example` beyond placeholders (`Settings.fcm_service_account_path`,
`Settings.sms_provider` defaulting to `"mock"`). Rather than pretend to
send a push notification, this module honestly reports "not configured"
and returns `(False, False)` — callers' `fcm_sent`/`sms_sent` columns stay
accurate instead of silently lying. Once real credentials are
provisioned, swap the bodies of `_send_fcm`/`_send_sms` below for real
client calls; call sites (`app/ingest/router.py`, `app/advisory/router.py`)
do not need to change.

Originally alert-only (hence living under `app/alerts/`); generalized to
`dispatch(entity_id, suppressed=...)` once `POST /v1/advisories/broadcast`
needed the exact same "not configured" fan-out logic rather than a second
copy of it.
"""

from __future__ import annotations

from dataclasses import dataclass
from uuid import UUID

import structlog

from app.config import get_settings

log = structlog.get_logger(__name__)


@dataclass(frozen=True)
class FanoutResult:
    fcm_sent: bool
    sms_sent: bool


def _send_fcm(entity_id: UUID) -> bool:
    settings = get_settings()
    if not settings.fcm_service_account_path or settings.fcm_service_account_path.startswith(
        "./certs/"
    ):
        # Default placeholder path — treat as "not configured" rather than
        # attempt (and fail) a real Firebase Admin SDK call.
        log.info(
            "fanout.fcm_skipped",
            entity_id=str(entity_id),
            reason="fcm_service_account_path not configured",
        )
        return False
    log.info("fanout.fcm_not_implemented", entity_id=str(entity_id))
    return False


def _send_sms(entity_id: UUID) -> bool:
    settings = get_settings()
    if settings.sms_provider == "mock" or not settings.sms_api_key:
        log.info(
            "fanout.sms_skipped",
            entity_id=str(entity_id),
            reason=f"sms_provider={settings.sms_provider!r}, api key configured={bool(settings.sms_api_key)}",
        )
        return False
    log.info("fanout.sms_not_implemented", entity_id=str(entity_id))
    return False


def dispatch(entity_id: UUID, *, suppressed: bool = False) -> FanoutResult:
    """Attempt to fan out `entity_id` (an Alert or Advisory id) via push + SMS.

    Suppressed entities should not be dispatched — callers are expected to
    pass `suppressed=True` for e.g. a blind-state alert, per the
    blind-state-is-visible-but-not-actionable rule. Advisories have no
    suppression concept, so callers there simply omit it (default False).
    """
    if suppressed:
        log.info("fanout.suppressed_not_dispatched", entity_id=str(entity_id))
        return FanoutResult(fcm_sent=False, sms_sent=False)
    return FanoutResult(fcm_sent=_send_fcm(entity_id), sms_sent=_send_sms(entity_id))
