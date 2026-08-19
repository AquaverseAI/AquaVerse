"""Alerts — router for /v1/alerts."""

from __future__ import annotations

from datetime import datetime
from uuid import UUID

from fastapi import APIRouter, HTTPException, Query, status
from sqlalchemy import and_, or_, select

from app.alerts.schemas import (
    AlertAckIn,
    AlertAckOut,
    AlertFeedbackIn,
    AlertFeedbackOut,
    AlertOut,
)
from app.core import rbac
from app.core.pagination import CursorPage, clamp_limit, decode_keyset_cursor, encode_keyset_cursor
from app.core.timezones import utcnow
from app.db.models.alert import Alert
from app.db.models.pond import Pond
from app.deps import CurrentUser, DbSession

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
    session: DbSession,
    pond_id: UUID | None = Query(default=None),
    severity: str | None = Query(default=None),
    acked: bool | None = Query(default=None),
    cursor: str | None = Query(default=None),
    limit: int | None = Query(default=None),
) -> CursorPage[AlertOut]:
    effective_limit = clamp_limit(limit)
    stmt = select(Alert, Pond.name).join(Pond, Pond.id == Alert.pond_id)

    if pond_id is not None:
        if user.role not in ("staff", "admin"):
            rbac.require_pond_scope(user.pond_ids, pond_id)
        stmt = stmt.where(Alert.pond_id == pond_id)
    elif user.role == "farmer":
        if not user.pond_ids:
            return CursorPage[AlertOut](items=[], next_cursor=None)
        stmt = stmt.where(Alert.pond_id.in_(user.pond_ids))
    elif user.role == "staff":
        if user.district is None:
            # No district claim and no explicit pond_id — fail closed.
            return CursorPage[AlertOut](items=[], next_cursor=None)
        stmt = stmt.where(Pond.district == user.district)
    # admin with no pond_id filter: unrestricted.

    if severity is not None:
        stmt = stmt.where(Alert.severity == severity)
    if acked is not None:
        stmt = stmt.where(Alert.acked == acked)

    decoded = decode_keyset_cursor(cursor)
    if decoded is not None:
        last_created_at_raw, last_id_raw = decoded
        try:
            last_created_at = datetime.fromisoformat(last_created_at_raw)
            last_id = UUID(last_id_raw)
        except ValueError:
            last_created_at = None
            last_id = None

        if last_created_at is not None and last_id is not None:
            stmt = stmt.where(
                or_(
                    Alert.created_at < last_created_at,
                    and_(Alert.created_at == last_created_at, Alert.id < last_id),
                )
            )

    stmt = stmt.order_by(Alert.created_at.desc(), Alert.id.desc())
    stmt = stmt.limit(effective_limit + 1)

    rows = (await session.execute(stmt)).all()

    has_next = len(rows) > effective_limit
    rows = rows[:effective_limit]

    next_cursor: str | None = None
    if has_next and rows:
        last_alert = rows[-1][0]
        next_cursor = encode_keyset_cursor(last_alert.created_at.isoformat(), last_alert.id)

    items = [
        AlertOut(
            id=alert.id,
            pond_id=alert.pond_id,
            pond_name=pond_name,
            alert_type=alert.alert_type,
            severity=alert.severity,
            title=alert.title,
            message=alert.message,
            parameter=alert.parameter,
            measured_value=alert.measured_value,
            threshold_value=alert.threshold_value,
            suppressed=alert.suppressed,
            suppression_reason=alert.suppression_reason,
            acked=alert.acked,
            acked_at=alert.acked_at,
            risk_score=alert.risk_score,
            created_at=alert.created_at,
        )
        for alert, pond_name in rows
    ]
    return CursorPage[AlertOut](items=items, next_cursor=next_cursor)


async def _get_scoped_alert(session: DbSession, user: CurrentUser, alert_id: UUID) -> Alert:
    stmt = select(Alert).where(Alert.id == alert_id)
    alert = (await session.execute(stmt)).scalar_one_or_none()
    if alert is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Alert not found")
    if user.role not in ("staff", "admin"):
        rbac.require_pond_scope(user.pond_ids, alert.pond_id)
    return alert


@router.post(
    "/{alert_id}/ack",
    response_model=AlertAckOut,
    summary="Acknowledge an alert",
)
async def ack_alert(
    alert_id: UUID, body: AlertAckIn, user: CurrentUser, session: DbSession
) -> AlertAckOut:
    alert = await _get_scoped_alert(session, user, alert_id)
    now = utcnow()
    alert.acked = True
    alert.acked_by = UUID(user.sub) if _is_uuid(user.sub) else None
    alert.acked_at = now
    alert.ack_note = body.note
    await session.commit()
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
    alert_id: UUID, body: AlertFeedbackIn, user: CurrentUser, session: DbSession
) -> AlertFeedbackOut:
    alert = await _get_scoped_alert(session, user, alert_id)
    alert.feedback_useful = body.useful
    alert.feedback_comment = body.comment
    alert.feedback_false_positive = body.false_positive
    alert.feedback_at = utcnow()
    await session.commit()
    return AlertFeedbackOut(
        alert_id=alert_id,
        feedback_recorded=True,
        message="Thank you for your feedback.",
    )


def _is_uuid(value: str) -> bool:
    try:
        UUID(value)
    except ValueError:
        return False
    return True
