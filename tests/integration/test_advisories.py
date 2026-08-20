"""Integration tests — real Advisories domain (P2.4).

`GET /v1/advisories` used to return one hardcoded fixture and
`POST /v1/advisories/broadcast` echoed its input without persisting or
fanning out to anyone — there was no table for either to read from or
write to. This exercises the real path: broadcast persists a real
`Advisory` row and attempts real (honestly "not configured") fan-out;
list reads real rows with real district/expiry filtering.

Each test uses a unique `target_district` (or the always-visible
district-agnostic NULL) so results stay isolated from whatever other
tests have already committed to the shared test database — see
test_geo.py's CI failure for why this matters here.
"""

from __future__ import annotations

from datetime import UTC, datetime, timedelta
from typing import TYPE_CHECKING
from uuid import uuid4

import pytest

from app.core.security import create_access_token
from app.db.models.advisory import Advisory

if TYPE_CHECKING:
    from httpx import AsyncClient
    from sqlalchemy.ext.asyncio import AsyncSession


def _staff_headers(district: str = "Nagapattinam") -> dict[str, str]:
    token = create_access_token(sub=str(uuid4()), role="staff", district=district)
    return {"Authorization": f"Bearer {token}"}


def _admin_headers() -> dict[str, str]:
    token = create_access_token(sub=str(uuid4()), role="admin")
    return {"Authorization": f"Bearer {token}"}


@pytest.mark.integration
@pytest.mark.asyncio(loop_scope="session")
async def test_broadcast_persists_a_real_advisory(db_client: AsyncClient) -> None:
    district = f"AdvisoryTest-{uuid4()}"
    resp = await db_client.post(
        "/v1/advisories/broadcast",
        json={
            "title": "Algal bloom risk this week",
            "body": "Monitor dissolved oxygen closely; expect afternoon crashes.",
            "language": "ta",
            "target_district": district,
            "severity": "warning",
        },
        headers=_staff_headers(district=district),
    )
    assert resp.status_code == 201, resp.text
    body = resp.json()
    assert body["title"] == "Algal bloom risk this week"
    assert body["target_district"] == district
    assert body["severity"] == "warning"
    assert body["issued_at"] is not None

    # Real DB row, not just an echoed response.
    list_resp = await db_client.get(f"/v1/advisories?district={district}", headers=_admin_headers())
    assert list_resp.status_code == 200, list_resp.text
    ids = {item["id"] for item in list_resp.json()["items"]}
    assert body["id"] in ids


@pytest.mark.integration
@pytest.mark.asyncio(loop_scope="session")
async def test_broadcast_staff_cannot_target_other_district(db_client: AsyncClient) -> None:
    resp = await db_client.post(
        "/v1/advisories/broadcast",
        json={
            "title": "test",
            "body": "test body",
            "target_district": "SomeOtherDistrict",
        },
        headers=_staff_headers(district="Nagapattinam"),
    )
    assert resp.status_code == 403


@pytest.mark.integration
@pytest.mark.asyncio(loop_scope="session")
async def test_list_advisories_excludes_expired(
    db_session: AsyncSession, db_client: AsyncClient
) -> None:
    district = f"AdvisoryTest-{uuid4()}"
    now = datetime.now(UTC)

    live = Advisory(
        title="Live advisory",
        body="still valid",
        language="ta",
        target_district=district,
        expires_at=now + timedelta(days=7),
    )
    expired = Advisory(
        title="Expired advisory",
        body="no longer valid",
        language="ta",
        target_district=district,
        expires_at=now - timedelta(days=1),
    )
    db_session.add_all([live, expired])
    await db_session.commit()

    resp = await db_client.get(f"/v1/advisories?district={district}", headers=_admin_headers())
    assert resp.status_code == 200, resp.text
    titles = {item["title"] for item in resp.json()["items"]}
    assert "Live advisory" in titles
    assert "Expired advisory" not in titles


@pytest.mark.integration
@pytest.mark.asyncio(loop_scope="session")
async def test_list_advisories_district_filter_includes_all_district_advisories(
    db_session: AsyncSession, db_client: AsyncClient
) -> None:
    district = f"AdvisoryTest-{uuid4()}"
    scoped = Advisory(
        title="District-specific advisory",
        body="body",
        language="ta",
        target_district=district,
    )
    all_district = Advisory(
        title=f"State-wide advisory {uuid4()}",
        body="body",
        language="ta",
        target_district=None,
    )
    other_district = Advisory(
        title="Different district advisory",
        body="body",
        language="ta",
        target_district=f"AdvisoryTest-{uuid4()}",
    )
    db_session.add_all([scoped, all_district, other_district])
    await db_session.commit()

    resp = await db_client.get(f"/v1/advisories?district={district}", headers=_admin_headers())
    assert resp.status_code == 200, resp.text
    titles = {item["title"] for item in resp.json()["items"]}
    assert scoped.title in titles
    assert all_district.title in titles
    assert other_district.title not in titles


@pytest.mark.integration
@pytest.mark.asyncio(loop_scope="session")
async def test_broadcast_reports_real_unconfigured_fanout(
    db_session: AsyncSession, db_client: AsyncClient
) -> None:
    district = f"AdvisoryTest-{uuid4()}"
    resp = await db_client.post(
        "/v1/advisories/broadcast",
        json={"title": "test", "body": "test body", "target_district": district},
        headers=_staff_headers(district=district),
    )
    assert resp.status_code == 201, resp.text
    advisory_id = resp.json()["id"]

    from sqlalchemy import select

    row = (
        await db_session.execute(select(Advisory).where(Advisory.id == advisory_id))
    ).scalar_one()
    # No FCM/SMS credentials are configured in the test environment — the
    # honest outcome is False, never a fabricated "sent" claim.
    assert row.fcm_sent is False
    assert row.sms_sent is False


@pytest.mark.integration
@pytest.mark.asyncio(loop_scope="session")
async def test_farmer_cannot_broadcast(db_client: AsyncClient) -> None:
    farmer_token = create_access_token(sub=str(uuid4()), role="farmer", pond_ids=[])
    resp = await db_client.post(
        "/v1/advisories/broadcast",
        json={"title": "test", "body": "test body"},
        headers={"Authorization": f"Bearer {farmer_token}"},
    )
    assert resp.status_code == 403
