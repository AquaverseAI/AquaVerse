"""Report export job — the real ARQ task body (P3.2).

`GET /v1/reports/export` used to return a fixture `job_id` that never
progressed. `POST /v1/reports/export`'s router now creates a real
`ReportJob` row and enqueues this task on the ARQ queue (`app/worker.py`);
this is what actually builds the file and uploads it to S3.
"""

from __future__ import annotations

from datetime import date, datetime, time, timedelta
from typing import Any
from uuid import UUID

import structlog
from sqlalchemy import select

from app.core.s3 import put_object
from app.core.timezones import UTC_TZ, utcnow
from app.db.models.log import Log
from app.db.models.pond import Pond
from app.db.models.report_job import ReportJob
from app.db.session import get_async_session
from app.reporting.pdf import render_pond_report_pdf
from app.reporting.xlsx import render_pond_report_xlsx

log = structlog.get_logger(__name__)


def _start_of_day_utc(d: date) -> datetime:
    return datetime.combine(d, time.min, tzinfo=UTC_TZ)


def _end_of_day_utc(d: date) -> datetime:
    """Exclusive upper bound — midnight of the day *after* `d`."""
    return _start_of_day_utc(d) + timedelta(days=1)


async def generate_report_job(ctx: dict[str, Any], report_job_id: str) -> None:
    """ARQ task body — real DB query, real PDF/XLSX render, real S3 upload.

    `ctx` is ARQ's per-job context dict (unused here — no shared
    connections are stashed on it; each task opens its own DB session via
    `app.db.session`, whose engine `app/worker.py`'s startup hook
    initializes once for the whole worker process).
    """
    session = get_async_session()
    job: ReportJob | None = None
    try:
        job = await session.get(ReportJob, UUID(report_job_id))
        if job is None:
            log.warning("reporting.job_not_found", report_job_id=report_job_id)
            return

        job.status = "running"
        await session.commit()

        pond_stmt = select(Pond)
        if job.pond_id is not None:
            pond_stmt = pond_stmt.where(Pond.id == job.pond_id)
        elif job.district is not None:
            pond_stmt = pond_stmt.where(Pond.district == job.district)
        ponds = list((await session.execute(pond_stmt)).scalars().all())

        logs_by_pond: dict[UUID, list[Log]] = {}
        for pond in ponds:
            log_stmt = select(Log).where(Log.pond_id == pond.id).order_by(Log.recorded_at)
            if job.from_date is not None:
                log_stmt = log_stmt.where(Log.recorded_at >= _start_of_day_utc(job.from_date))
            if job.to_date is not None:
                log_stmt = log_stmt.where(Log.recorded_at < _end_of_day_utc(job.to_date))
            logs_by_pond[pond.id] = list((await session.execute(log_stmt)).scalars().all())

        scope_label = job.district or (ponds[0].name if ponds else "export")
        title = f"AquaVerse Pond Water Quality Report — {scope_label}"

        if job.format == "xlsx":
            body = render_pond_report_xlsx(ponds=ponds, logs_by_pond=logs_by_pond)
            content_type = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
            ext = "xlsx"
        else:
            body = render_pond_report_pdf(
                title=title,
                generated_at_iso=utcnow().isoformat(),
                ponds=ponds,
                logs_by_pond=logs_by_pond,
            )
            content_type = "application/pdf"
            ext = "pdf"

        s3_key = f"reports/{job.id}.{ext}"
        put_object(s3_key, body, content_type)

        job.status = "completed"
        job.s3_key = s3_key
        await session.commit()
        log.info("reporting.job_completed", report_job_id=report_job_id, pond_count=len(ponds))
    except Exception as exc:
        await session.rollback()
        if job is not None:
            refreshed = await session.get(ReportJob, UUID(report_job_id))
            if refreshed is not None:
                refreshed.status = "failed"
                refreshed.error_message = str(exc)[:2000]
                await session.commit()
        log.warning("reporting.job_failed", report_job_id=report_job_id, error=str(exc))
        raise
    finally:
        await session.close()
