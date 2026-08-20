"""Report export job ORM model (P3.2).

`GET /v1/reports/export` used to return a hardcoded `job_id` that never
progressed — there was no table backing it and no worker consuming it.
This is that table: one row per export request, updated in place by the
real ARQ worker task (`app/reporting/jobs.py`) as it moves through
queued -> running -> completed|failed.
"""

from __future__ import annotations

import uuid
from datetime import date

from sqlalchemy import Date, ForeignKey, String, Text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base, TimestampMixin, UUIDPrimaryKeyMixin


class ReportJob(Base, UUIDPrimaryKeyMixin, TimestampMixin):
    __tablename__ = "report_jobs"

    # No FK to users.id — same convention as Log.recorded_by /
    # Advisory.issued_by: JWT identity here is self-signed, not
    # guaranteed to correspond to a seeded `users` row.
    requested_by: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), nullable=False, index=True)

    pond_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("ponds.id", ondelete="SET NULL"), nullable=True
    )
    # Persisted district scope for a pond_id=None ("all my district's
    # ponds") export — recorded at request time so the worker's later
    # query uses the exact scope that was authorized, not whatever the
    # requester's token claims by the time the job actually runs.
    district: Mapped[str | None] = mapped_column(String(100), nullable=True)

    format: Mapped[str] = mapped_column(String(10), nullable=False)  # pdf | xlsx
    status: Mapped[str] = mapped_column(
        String(20), nullable=False, default="queued"
    )  # queued | running | completed | failed
    from_date: Mapped[date | None] = mapped_column(Date, nullable=True)
    to_date: Mapped[date | None] = mapped_column(Date, nullable=True)

    s3_key: Mapped[str | None] = mapped_column(String(500), nullable=True)
    error_message: Mapped[str | None] = mapped_column(Text, nullable=True)
