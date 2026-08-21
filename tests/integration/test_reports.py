"""Integration tests — real Reporting export domain (P3.2).

`GET /v1/reports/export` used to return a fixture `job_id` that never
progressed, and `reporting/pdf.py`/`xlsx.py` were unused. This exercises
the real path: a real `ReportJob` row, a real ARQ enqueue onto a real
Redis container (`reports_client` fixture, tests/conftest.py), and —
since no ARQ worker process runs in CI — a direct call into the same
task function (`app.reporting.jobs.generate_report_job`) the worker would
run, against real Postgres data and a real MinIO container, to prove the
whole pipeline (query -> render -> upload -> presigned download) works.
"""

from __future__ import annotations

from datetime import UTC, datetime
from typing import TYPE_CHECKING
from uuid import uuid4

import httpx
import pytest

from app.core.security import create_access_token
from app.db.models.log import Log
from app.db.models.pond import Pond
from app.reporting.jobs import generate_report_job

if TYPE_CHECKING:
    from httpx import AsyncClient
    from sqlalchemy.ext.asyncio import AsyncSession


def _staff_headers(district: str = "Nagapattinam") -> dict[str, str]:
    token = create_access_token(sub=str(uuid4()), role="staff", district=district)
    return {"Authorization": f"Bearer {token}"}


async def _seed_pond_with_logs(db_session: AsyncSession, district: str) -> Pond:
    pond = Pond(id=uuid4(), owner_user_id=uuid4(), name="Reports Test Pond", district=district)
    db_session.add(pond)
    await db_session.flush()
    for i in range(3):
        db_session.add(
            Log(
                pond_id=pond.id,
                recorded_at=datetime.now(UTC),
                recorded_by=uuid4(),
                temperature_c=28.0 + i,
                dissolved_oxygen_mgl=5.0,
                ph=7.9,
            )
        )
    await db_session.commit()
    return pond


@pytest.mark.integration
@pytest.mark.asyncio(loop_scope="session")
async def test_export_report_creates_real_queued_job(
    db_session: AsyncSession, reports_client: AsyncClient
) -> None:
    district = f"ReportsTest-{uuid4()}"
    pond = await _seed_pond_with_logs(db_session, district)

    resp = await reports_client.get(
        "/v1/reports/export",
        params={"pond_id": str(pond.id), "format": "pdf"},
        headers=_staff_headers(district),
    )
    assert resp.status_code == 200, resp.text
    body = resp.json()
    assert body["status"] == "queued"
    assert body["job_id"]
    assert body["download_url"] is None


@pytest.mark.integration
@pytest.mark.asyncio(loop_scope="session")
async def test_export_report_invalid_format_returns_400(
    db_session: AsyncSession, reports_client: AsyncClient
) -> None:
    district = f"ReportsTest-{uuid4()}"
    resp = await reports_client.get(
        "/v1/reports/export", params={"format": "docx"}, headers=_staff_headers(district)
    )
    assert resp.status_code == 400


@pytest.mark.integration
@pytest.mark.asyncio(loop_scope="session")
async def test_export_report_unknown_pond_returns_404(
    reports_client: AsyncClient,
) -> None:
    resp = await reports_client.get(
        "/v1/reports/export",
        params={"pond_id": str(uuid4())},
        headers=_staff_headers("Nagapattinam"),
    )
    assert resp.status_code == 404


@pytest.mark.integration
@pytest.mark.asyncio(loop_scope="session")
async def test_full_pipeline_produces_downloadable_pdf(
    db_session: AsyncSession, reports_client: AsyncClient
) -> None:
    """End-to-end: create job -> run the real worker task body -> poll
    status -> GET the real presigned URL and confirm real PDF bytes."""
    district = f"ReportsTest-{uuid4()}"
    pond = await _seed_pond_with_logs(db_session, district)
    headers = _staff_headers(district)

    create_resp = await reports_client.get(
        "/v1/reports/export",
        params={"pond_id": str(pond.id), "format": "pdf"},
        headers=headers,
    )
    assert create_resp.status_code == 200, create_resp.text
    job_id = create_resp.json()["job_id"]

    # No ARQ worker process runs in this test suite — call the real task
    # body directly, exactly as the worker would.
    await generate_report_job({}, job_id)

    status_resp = await reports_client.get(f"/v1/reports/export/{job_id}", headers=headers)
    assert status_resp.status_code == 200, status_resp.text
    status_body = status_resp.json()
    assert status_body["status"] == "completed"
    assert status_body["download_url"] is not None

    async with httpx.AsyncClient() as raw_client:
        download_resp = await raw_client.get(status_body["download_url"])
    assert download_resp.status_code == 200
    assert download_resp.content.startswith(b"%PDF-")


@pytest.mark.integration
@pytest.mark.asyncio(loop_scope="session")
async def test_full_pipeline_xlsx_format(
    db_session: AsyncSession, reports_client: AsyncClient
) -> None:
    district = f"ReportsTest-{uuid4()}"
    pond = await _seed_pond_with_logs(db_session, district)
    headers = _staff_headers(district)

    create_resp = await reports_client.get(
        "/v1/reports/export",
        params={"pond_id": str(pond.id), "format": "xlsx"},
        headers=headers,
    )
    job_id = create_resp.json()["job_id"]

    await generate_report_job({}, job_id)

    status_resp = await reports_client.get(f"/v1/reports/export/{job_id}", headers=headers)
    status_body = status_resp.json()
    assert status_body["status"] == "completed"

    async with httpx.AsyncClient() as raw_client:
        download_resp = await raw_client.get(status_body["download_url"])
    assert download_resp.status_code == 200
    assert download_resp.content[:2] == b"PK"


@pytest.mark.integration
@pytest.mark.asyncio(loop_scope="session")
async def test_get_export_status_unknown_job_returns_404(reports_client: AsyncClient) -> None:
    resp = await reports_client.get(
        f"/v1/reports/export/{uuid4()}", headers=_staff_headers("Nagapattinam")
    )
    assert resp.status_code == 404


@pytest.mark.integration
@pytest.mark.asyncio(loop_scope="session")
async def test_get_export_status_rejects_other_requesters_job(
    db_session: AsyncSession, reports_client: AsyncClient
) -> None:
    district = f"ReportsTest-{uuid4()}"
    pond = await _seed_pond_with_logs(db_session, district)

    create_resp = await reports_client.get(
        "/v1/reports/export",
        params={"pond_id": str(pond.id)},
        headers=_staff_headers(district),
    )
    job_id = create_resp.json()["job_id"]

    other_staff_headers = _staff_headers(district)  # different random sub
    resp = await reports_client.get(f"/v1/reports/export/{job_id}", headers=other_staff_headers)
    assert resp.status_code == 403


@pytest.mark.integration
@pytest.mark.asyncio(loop_scope="session")
async def test_district_wide_export_requires_district_claim(reports_client: AsyncClient) -> None:
    """Staff token with no district claim and no pond_id can't be scoped
    to anything — must fail closed, not silently export everything."""
    token = create_access_token(sub=str(uuid4()), role="staff", district=None)
    resp = await reports_client.get(
        "/v1/reports/export", headers={"Authorization": f"Bearer {token}"}
    )
    assert resp.status_code == 403
