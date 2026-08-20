"""Advisory ORM model (P2.4).

A staff-broadcast advisory to farmers. `GET /v1/advisories` used to
return one hardcoded fixture and `POST /v1/advisories/broadcast` echoed
its input without persisting or fanning out to anyone — there was no
table for either to read from or write to.
"""

from __future__ import annotations

import uuid
from datetime import datetime
from typing import TYPE_CHECKING

from sqlalchemy import Boolean, DateTime, String, Text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base, TimestampMixin, UUIDPrimaryKeyMixin

if TYPE_CHECKING:
    pass


class Advisory(Base, UUIDPrimaryKeyMixin, TimestampMixin):
    """A published advisory. `created_at` (via TimestampMixin) doubles as
    `issued_at` — an advisory is never edited after broadcast, so the two
    are always the same instant; no separate column needed.
    """

    __tablename__ = "advisories"

    title: Mapped[str] = mapped_column(String(500), nullable=False)
    body: Mapped[str] = mapped_column(Text, nullable=False)
    language: Mapped[str] = mapped_column(String(10), nullable=False, default="ta")
    target_district: Mapped[str | None] = mapped_column(String(100), index=True)
    target_species: Mapped[str | None] = mapped_column(String(100))
    severity: Mapped[str | None] = mapped_column(String(20))  # info | warning | critical
    expires_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))

    # No FK constraint to users.id — same convention as Log.recorded_by
    # (app/db/models/log.py): JWT identity in this system is not
    # guaranteed to correspond to a seeded `users` row (self-signed
    # tokens carry an arbitrary `sub` claim), so a strict FK would reject
    # real, legitimately-authenticated writes.
    issued_by: Mapped[uuid.UUID | None] = mapped_column(UUID(as_uuid=True), nullable=True)

    # Fan-out status — same honest convention as Alert.fcm_sent/sms_sent
    # (app/alerts/fanout.py): real attempt outcome, never a fabricated
    # "sent" claim.
    fcm_sent: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
    sms_sent: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
