"""Alert ORM model.

RULE: Blind-state suppression must always be visible on the payload — never silent.
The `suppressed` flag and `suppression_reason` are ALWAYS returned to the client.
"""

from __future__ import annotations

import uuid
from datetime import datetime
from typing import TYPE_CHECKING

from sqlalchemy import Boolean, DateTime, Float, ForeignKey, Integer, String, Text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base, TimestampMixin, UUIDPrimaryKeyMixin

if TYPE_CHECKING:
    from app.db.models.pond import Pond


class Alert(Base, UUIDPrimaryKeyMixin, TimestampMixin):
    """
    A generated alert for a pond.

    Suppression is ALWAYS visible. The `suppressed` field is exposed on every
    API response that includes alerts. If suppressed=True, `suppression_reason`
    explains why — e.g. "Sensor offline > 4 hours; readings are blind-state."
    This is non-negotiable per the architecture spec.
    """

    __tablename__ = "alerts"

    pond_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("ponds.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    alert_type: Mapped[str] = mapped_column(String(100), nullable=False, index=True)
    severity: Mapped[str] = mapped_column(
        String(20), nullable=False
    )  # critical | high | medium | low
    title: Mapped[str] = mapped_column(String(500), nullable=False)
    message: Mapped[str] = mapped_column(Text, nullable=False)
    parameter: Mapped[str | None] = mapped_column(String(100))  # e.g. "dissolved_oxygen"
    measured_value: Mapped[float | None] = mapped_column(Float)
    threshold_value: Mapped[float | None] = mapped_column(Float)

    # Suppression — ALWAYS visible, NEVER silent
    suppressed: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
    suppression_reason: Mapped[str | None] = mapped_column(Text)

    # Acknowledgement
    acked: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
    acked_by: Mapped[uuid.UUID | None] = mapped_column(UUID(as_uuid=True))
    acked_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    ack_note: Mapped[str | None] = mapped_column(Text)

    # Feedback (POST /v1/alerts/{id}/feedback) — added in
    # e4f5a6b7c8d9_add_alert_feedback_columns.
    feedback_useful: Mapped[bool | None] = mapped_column(Boolean)
    feedback_comment: Mapped[str | None] = mapped_column(Text)
    feedback_false_positive: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
    feedback_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))

    # Fan-out status
    fcm_sent: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
    sms_sent: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
    retry_count: Mapped[int] = mapped_column(Integer, nullable=False, default=0)

    # Risk score that triggered this alert (from quantitative layer)
    risk_score: Mapped[float | None] = mapped_column(Float)

    # Relationships
    pond: Mapped[Pond] = relationship("Pond", back_populates="alerts")
