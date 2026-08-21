"""Alerts — Pydantic v2 schemas."""

from __future__ import annotations

from datetime import datetime
from typing import TYPE_CHECKING
from uuid import UUID

from pydantic import BaseModel, Field

if TYPE_CHECKING:
    pass


class AlertOut(BaseModel):
    id: UUID
    pond_id: UUID
    pond_name: str | None = None
    alert_type: str
    severity: str  # critical | high | medium | low
    title: str
    message: str
    parameter: str | None = None
    measured_value: float | None = None
    threshold_value: float | None = None

    # RULE: blind-state suppression ALWAYS visible — never silent
    suppressed: bool = Field(
        ...,
        description=(
            "True if this alert is suppressed due to blind state (e.g. sensor offline). "
            "Always surfaced — never hidden from the client."
        ),
    )
    suppression_reason: str | None = Field(
        default=None,
        description="Why the alert is suppressed. Always provided when suppressed=True.",
    )

    acked: bool
    acked_at: datetime | None = None
    risk_score: float | None = None
    created_at: datetime


class AlertAckIn(BaseModel):
    note: str | None = Field(default=None, max_length=500)
    client_log_id: str | None = Field(default=None, max_length=200)


class AlertAckOut(BaseModel):
    alert_id: UUID
    acked: bool
    acked_at: datetime
    message: str


class AlertFeedbackIn(BaseModel):
    useful: bool
    comment: str | None = Field(default=None, max_length=500)
    false_positive: bool = False


class AlertFeedbackOut(BaseModel):
    alert_id: UUID
    feedback_recorded: bool
    message: str
