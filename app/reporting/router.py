"""Reporting — router for /v1/reports."""

from __future__ import annotations

from datetime import date
from typing import TYPE_CHECKING, Any
from uuid import UUID

import structlog
from fastapi import APIRouter, HTTPException, Query, status

from app.core.s3 import generate_presigned_get_url
from app.db.models.pond import Pond
from app.db.models.report_job import ReportJob
from app.deps import CurrentStaff, DbSession

if TYPE_CHECKING:
    from arq import ArqRedis

log = structlog.get_logger(__name__)

router = APIRouter(prefix="/reports", tags=["Reports"])

_VALID_FORMATS = {"pdf", "xlsx"}

# Lazy singleton ARQ connection pool — same pattern as the lazy Redis
# client in app/identity/router.py / app/i18n/router.py.
_arq_pool: ArqRedis | None = None


async def _get_arq_pool() -> ArqRedis:
    global _arq_pool
    if _arq_pool is None:
        from arq import create_pool
        from arq.connections import RedisSettings

        from app.config import get_settings

        settings = get_settings()
        _arq_pool = await create_pool(RedisSettings.from_dsn(settings.redis_url))
    return _arq_pool


def _parse_date(raw: str | None, field_name: str) -> date | None:
    if raw is None:
        return None
    try:
        return date.fromisoformat(raw)
    except ValueError as exc:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Invalid {field_name}: expected YYYY-MM-DD",
        ) from exc


@router.get(
    "/export",
    summary="Export pond data as PDF or XLSX",
    description=(
        "Enqueues a real async export job on the ARQ worker "
        "(app/reporting/jobs.py). Poll GET /v1/reports/export/{job_id} "
        "for status and a download URL once it's ready."
    ),
)
async def export_report(
    user: CurrentStaff,
    session: DbSession,
    pond_id: UUID | None = Query(default=None),
    format: str = Query(default="pdf", description="pdf | xlsx"),
    from_date: str | None = Query(default=None, description="YYYY-MM-DD"),
    to_date: str | None = Query(default=None, description="YYYY-MM-DD"),
) -> dict[str, Any]:
    if format not in _VALID_FORMATS:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"format must be one of {sorted(_VALID_FORMATS)}",
        )

    parsed_from = _parse_date(from_date, "from_date")
    parsed_to = _parse_date(to_date, "to_date")
    if parsed_from is not None and parsed_to is not None and parsed_from > parsed_to:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, detail="from_date must not be after to_date"
        )

    district: str | None = None
    if pond_id is not None:
        pond = await session.get(Pond, pond_id)
        if pond is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Pond not found")
    else:
        # No specific pond -> a district-wide export. Staff are scoped to
        # their own district; an admin token with no district claim gets
        # an unrestricted, all-ponds export — same precedent as
        # app/geo/router.py's _scope_pond_query for the admin role.
        if user.role == "staff":
            if user.district is None:
                raise HTTPException(
                    status_code=status.HTTP_403_FORBIDDEN,
                    detail="Your token has no district claim; specify pond_id instead.",
                )
            district = user.district

    try:
        requester = UUID(user.sub)
    except ValueError as exc:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, detail="Token 'sub' claim is not a valid UUID."
        ) from exc

    job = ReportJob(
        requested_by=requester,
        pond_id=pond_id,
        district=district,
        format=format,
        status="queued",
        from_date=parsed_from,
        to_date=parsed_to,
    )
    session.add(job)
    await session.commit()

    pool = await _get_arq_pool()
    await pool.enqueue_job("generate_report_job", str(job.id), _job_id=str(job.id))
    log.info("reporting.job_enqueued", job_id=str(job.id), format=format)

    return {
        "job_id": str(job.id),
        "status": job.status,
        "format": job.format,
        "download_url": None,
        "estimated_ready_at": None,
        "message": "Export job queued. Poll GET /v1/reports/export/{job_id} for completion.",
    }


@router.get(
    "/export/{job_id}",
    summary="Poll a report export job",
    description=(
        "Real status of a previously queued export job, with a presigned "
        "download URL once it has completed."
    ),
)
async def get_export_status(job_id: UUID, user: CurrentStaff, session: DbSession) -> dict[str, Any]:
    job = await session.get(ReportJob, job_id)
    if job is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Report job not found")

    if user.role != "admin" and job.requested_by != UUID(user.sub):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="This report job belongs to a different user.",
        )

    download_url: str | None = None
    if job.status == "completed" and job.s3_key is not None:
        download_url = generate_presigned_get_url(job.s3_key)

    return {
        "job_id": str(job.id),
        "status": job.status,
        "format": job.format,
        "download_url": download_url,
        "error": job.error_message,
    }
