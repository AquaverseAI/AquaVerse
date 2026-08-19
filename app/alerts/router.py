"""Alerts — router for /v1/alerts."""

from __future__ import annotations

from uuid import UUID, uuid4

from fastapi import APIRouter, Query

from app.alerts.schemas import (
    AlertAckIn,
    AlertAckOut,
    AlertFeedbackIn,
    AlertFeedbackOut,
    AlertOut,
)
from app.core import rbac
from app.core.pagination import CursorPage
from app.core.timezones import utcnow
from app.deps import CurrentUser

router = APIRouter(prefix="/alerts", tags=["Alerts"])


@router.get(
    "",
    response_model=CursorPage[AlertOut],
    summary="List alerts",
    description=(
        "Returns alerts with their suppression state always visible. "
        "If suppressed=True, suppression_reason explains why (e.g. 'Sensor offline > 4h')."
    ),
)
async def list_alerts(
    user: CurrentUser,
    pond_id: UUID | None = Query(default=None),
    severity: str | None = Query(default=None),
    acked: bool | None = Query(default=None),
    cursor: str | None = Query(default=None),
    limit: int = Query(default=50, ge=1, le=200),
) -> CursorPage[AlertOut]:
    if pond_id is not None and user.role not in ("staff", "admin"):
        rbac.require_pond_scope(user.pond_ids, pond_id)
    now = utcnow()
    stub = AlertOut(
        id=uuid4(),
        pond_id=pond_id or uuid4(),
        pond_name="Kalaiselvi Pond - Block A",
        alert_type="low_dissolved_oxygen",
        severity="high",
        title="Dissolved oxygen critically low",
        message="Dissolved oxygen has dropped to 4.2 mg/L — below the safety threshold of 5.0 mg/L.",
        parameter="dissolved_oxygen_mgl",
        measured_value=4.2,
        threshold_value=5.0,
        suppressed=False,
        acked=False,
        risk_score=0.72,
        created_at=now,
    )
    return CursorPage[AlertOut](items=[stub], next_cursor=None)


@router.post(
    "/{alert_id}/ack",
    response_model=AlertAckOut,
    summary="Acknowledge an alert",
)
async def ack_alert(alert_id: UUID, body: AlertAckIn, user: CurrentUser) -> AlertAckOut:
    now = utcnow()
    return AlertAckOut(
        alert_id=alert_id,
        acked=True,
        acked_at=now,
        message="Alert acknowledged.",
    )


@router.post(
    "/{alert_id}/feedback",
    response_model=AlertFeedbackOut,
    summary="Submit feedback on an alert",
)
async def alert_feedback(
    alert_id: UUID, body: AlertFeedbackIn, user: CurrentUser
) -> AlertFeedbackOut:
    return AlertFeedbackOut(
        alert_id=alert_id,
        feedback_recorded=True,
        message="Thank you for your feedback.",
    )
