"""Reporting — router for /v1/reports."""

from __future__ import annotations

from typing import TYPE_CHECKING
from uuid import UUID

from fastapi import APIRouter, Query
from fastapi.responses import JSONResponse

from app.core.timezones import utcnow

if TYPE_CHECKING:
    pass


router = APIRouter(prefix="/reports", tags=["Reports"])


@router.get(
    "/export",
    summary="Export pond data as PDF or XLSX",
    description=(
        "Triggers an async export job. Returns a job_id and a download_url "
        "once the export is ready (polled by the client or delivered via SSE)."
    ),
)
async def export_report(
    pond_id: UUID | None = Query(default=None),
    format: str = Query(default="pdf", description="pdf | xlsx"),
    from_date: str | None = Query(default=None, description="YYYY-MM-DD"),
    to_date: str | None = Query(default=None, description="YYYY-MM-DD"),
) -> JSONResponse:
    """Phase 1: return fixture. Phase 5: enqueue ARQ job, return job_id."""
    now = utcnow()
    return JSONResponse(
        content={
            "job_id": "job_00000000-stub-0000-0000-000000000001",
            "status": "queued",
            "format": format,
            "download_url": None,
            "estimated_ready_at": (now.isoformat()),
            "message": "Export job queued. Poll job_id or subscribe to SSE stream for completion.",
        }
    )
