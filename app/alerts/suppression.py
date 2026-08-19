"""
Blind-state suppression logic.

RULE: Suppression is ALWAYS visible on the response payload — never silent.
`AlertOut.suppressed`/`suppression_reason` must be populated from this
module's output, not defaulted to `False`/`None`.

A pond is "blind" when its most recent `Log` row is older than
`Settings.alert_stale_threshold_hours` (or it has no logs at all). In that
state we cannot tell a genuinely recovered pond from one whose sensor has
simply stopped reporting, so any alert raised against stale data is marked
suppressed rather than presented as a confident signal — but it is still
returned to the client with the reason attached, per the rule above.
"""

from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime
from typing import TYPE_CHECKING
from uuid import UUID

from sqlalchemy import select

from app.config import get_settings
from app.db.models.log import Log

if TYPE_CHECKING:
    from sqlalchemy.ext.asyncio import AsyncSession


@dataclass(frozen=True)
class BlindStateResult:
    suppressed: bool
    suppression_reason: str | None
    last_log_at: datetime | None


async def check_blind_state(
    session: AsyncSession,
    pond_id: UUID,
    now: datetime,
    stale_threshold_hours: int | None = None,
) -> BlindStateResult:
    """Return whether `pond_id` is currently in a blind (sensor-stale) state."""
    threshold_hours = (
        stale_threshold_hours
        if stale_threshold_hours is not None
        else get_settings().alert_stale_threshold_hours
    )

    stmt = select(Log.recorded_at).where(Log.pond_id == pond_id).order_by(Log.recorded_at.desc())
    result = await session.execute(stmt.limit(1))
    last_log_at = result.scalar_one_or_none()

    if last_log_at is None:
        return BlindStateResult(
            suppressed=True,
            suppression_reason="No sensor or manual readings recorded for this pond yet.",
            last_log_at=None,
        )

    age_hours = (now - last_log_at).total_seconds() / 3600.0
    if age_hours > threshold_hours:
        return BlindStateResult(
            suppressed=True,
            suppression_reason=(
                f"Sensor offline > {threshold_hours}h "
                f"(last reading {age_hours:.1f}h ago); readings are blind-state."
            ),
            last_log_at=last_log_at,
        )

    return BlindStateResult(suppressed=False, suppression_reason=None, last_log_at=last_log_at)
