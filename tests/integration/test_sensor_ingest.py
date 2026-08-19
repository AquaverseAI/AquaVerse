"""Integration tests — POST /v1/ingest/sensor/{pond_id} (IoT device webhook).

Exercises the exact payload shape a field sensor unit sends (raw `ph`,
`air_temperature`, `humidity`, `water_temperature`, `turbidity` keys — no
farmer/staff JWT, no pond_id in the body), and confirms the resulting row is
immediately visible through both GET /v1/logs and
GET /v1/ponds/{pond_id}/timeseries.
"""

from __future__ import annotations

from typing import TYPE_CHECKING
from uuid import uuid4

import pytest
from sqlalchemy import select

from app.core.security import create_access_token
from app.db.models.log import Log
from app.db.models.pond import Pond

if TYPE_CHECKING:
    from httpx import AsyncClient
    from sqlalchemy.ext.asyncio import AsyncSession

# The exact payload a real device sends — see the bug report this fixes.
DEVICE_PAYLOAD = {
    "ph": 14.00,
    "air_temperature": 0.00,
    "humidity": 0.00,
    "water_temperature": 0.00,
    "turbidity": 7.8,
}


async def _seed_pond(db_session: AsyncSession) -> Pond:
    pond = Pond(
        id=uuid4(),
        owner_user_id=uuid4(),
        name="Sensor Ingest Test Pond",
        district="Nagapattinam",
    )
    db_session.add(pond)
    await db_session.commit()
    return pond


@pytest.mark.integration
@pytest.mark.asyncio(loop_scope="session")
async def test_sensor_ingest_accepts_exact_device_payload_and_persists(
    db_session: AsyncSession, db_client: AsyncClient
) -> None:
    pond = await _seed_pond(db_session)

    resp = await db_client.post(f"/v1/ingest/sensor/{pond.id}", json=DEVICE_PAYLOAD)

    assert resp.status_code == 201, resp.text
    body = resp.json()
    assert body["pond_id"] == str(pond.id)
    assert body["ph"] == 14.0
    assert body["air_temperature_c"] == 0.0
    assert body["humidity_pct"] == 0.0
    assert body["water_temperature_c"] == 0.0
    assert body["turbidity_ntu"] == 7.8
    assert body["source"] == "sensor"

    # Real DB row, not just an echoed response.
    row = (await db_session.execute(select(Log).where(Log.id == body["id"]))).scalar_one()
    assert row.pond_id == pond.id
    assert row.ph == 14.0
    assert row.air_temperature_c == 0.0
    assert row.humidity_pct == 0.0
    assert row.temperature_c == 0.0
    assert row.turbidity_ntu == 7.8
    assert row.source == "sensor"


@pytest.mark.integration
@pytest.mark.asyncio(loop_scope="session")
async def test_sensor_ingest_unknown_pond_returns_404(db_client: AsyncClient) -> None:
    resp = await db_client.post(f"/v1/ingest/sensor/{uuid4()}", json=DEVICE_PAYLOAD)
    assert resp.status_code == 404


@pytest.mark.integration
@pytest.mark.asyncio(loop_scope="session")
async def test_sensor_ingest_rejects_out_of_range_ph(
    db_session: AsyncSession, db_client: AsyncClient
) -> None:
    pond = await _seed_pond(db_session)
    bad_payload = {**DEVICE_PAYLOAD, "ph": 15.0}
    resp = await db_client.post(f"/v1/ingest/sensor/{pond.id}", json=bad_payload)
    assert resp.status_code == 422


@pytest.mark.integration
@pytest.mark.asyncio(loop_scope="session")
async def test_sensor_ingest_reading_visible_via_logs_and_timeseries(
    db_session: AsyncSession, db_client: AsyncClient
) -> None:
    pond = await _seed_pond(db_session)

    ingest_resp = await db_client.post(f"/v1/ingest/sensor/{pond.id}", json=DEVICE_PAYLOAD)
    assert ingest_resp.status_code == 201
    reading_id = ingest_resp.json()["id"]

    token = create_access_token(sub=str(uuid4()), role="admin")
    headers = {"Authorization": f"Bearer {token}"}

    logs_resp = await db_client.get(f"/v1/logs?pond_id={pond.id}", headers=headers)
    assert logs_resp.status_code == 200
    log_ids = [item["id"] for item in logs_resp.json()["items"]]
    assert reading_id in log_ids

    ts_resp = await db_client.get(f"/v1/ponds/{pond.id}/timeseries?parameter=ph", headers=headers)
    assert ts_resp.status_code == 200
    points = ts_resp.json()["points"]
    assert any(
        p["air_temperature_c"] == 0.0 and p["humidity_pct"] == 0.0 and p["turbidity_ntu"] == 7.8
        for p in points
    )
