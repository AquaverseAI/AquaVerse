"""FCM + SMS alert fan-out.

HONESTY NOTE (same convention as `do_forecast.py`'s empirical baseline):
no FCM service account or SMS provider credentials exist in this repo's
`.env.example` beyond placeholders (`Settings.fcm_service_account_path`,
`Settings.sms_provider` defaulting to `"mock"`). Rather than pretend to
send a push notification, this module honestly reports "not configured"
and returns `(False, False)` — `Alert.fcm_sent`/`sms_sent` stay accurate
instead of silently lying. Once real credentials are provisioned, swap the
bodies of `_send_fcm`/`_send_sms` below for real client calls; the
`dispatch()` call site (`app/ingest/router.py`) does not need to change.
"""

from __future__ import annotations

from dataclasses import dataclass

import structlog

from app.config import get_settings
from app.db.models.alert import Alert

log = structlog.get_logger(__name__)


@dataclass(frozen=True)
class FanoutResult:
    fcm_sent: bool
    sms_sent: bool


def _send_fcm(alert: Alert) -> bool:
    settings = get_settings()
    if not settings.fcm_service_account_path or settings.fcm_service_account_path.startswith(
        "./certs/"
    ):
        # Default placeholder path — treat as "not configured" rather than
        # attempt (and fail) a real Firebase Admin SDK call.
        log.info(
            "alerts.fanout.fcm_skipped",
            alert_id=str(alert.id),
            reason="fcm_service_account_path not configured",
        )
        return False
    log.info("alerts.fanout.fcm_not_implemented", alert_id=str(alert.id))
    return False


def _send_sms(alert: Alert) -> bool:
    settings = get_settings()
    if settings.sms_provider == "mock" or not settings.sms_api_key:
        log.info(
            "alerts.fanout.sms_skipped",
            alert_id=str(alert.id),
            reason=f"sms_provider={settings.sms_provider!r}, api key configured={bool(settings.sms_api_key)}",
        )
        return False
    log.info("alerts.fanout.sms_not_implemented", alert_id=str(alert.id))
    return False


def dispatch(alert: Alert) -> FanoutResult:
    """Attempt to fan out `alert` via push + SMS.

    Suppressed alerts should not be dispatched — callers (see
    `app/ingest/router.py`) are expected to check `alert.suppressed` before
    calling this, per the blind-state-is-visible-but-not-actionable rule.
    """
    if alert.suppressed:
        log.info("alerts.fanout.suppressed_not_dispatched", alert_id=str(alert.id))
        return FanoutResult(fcm_sent=False, sms_sent=False)
    return FanoutResult(fcm_sent=_send_fcm(alert), sms_sent=_send_sms(alert))
