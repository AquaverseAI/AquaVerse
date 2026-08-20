"""Integration tests — real data quality signals (P3.3).

`GET /v1/data-quality` used to return hardcoded numbers
(`total_logs_last_7d: 142`, fixed `missing_parameter_rates`, etc.)
regardless of what was actually in the database. This exercises the
real path: real counts/ratios over real seeded `Log` rows, and real
sensor-offline detection based on each pond's real most-recent log.
"""

from __future__ import annotations

from datetime import UTC, datetime, timedelta
from typing import TYPE_CHECKING
from uuid import uuid4

import pytest

from app.core.security import create_access_token
from app.db.models.log import Log
from app.db.models.pond import Pond

if TYPE_CHECKING:
    from httpx import AsyncClient
    from sqlalchemy.ext.asyncio import AsyncSession


def _staff_headers(district: str | None = "Nagapattinam") -> dict[str, str]:
    token = create_access_token(sub=str(uuid4()), role="staff", district=district)
    return {"Authorization": f"Bearer {token}"}


def _admin_headers() -> dict[str, str]:
    token = create_access_token(sub=str(uuid4()), role="admin")
    return {"Authorization": f"Bearer {token}"}


@pytest.mark.integration
@pytest.mark.asyncio(loop_scope="session")
async def test_data_quality_computes_real_counts_and_missing_rates(
    db_session: AsyncSession, db_client: AsyncClient
) -> None:
    district = f"DQTest-{uuid4()}"
    pond = Pond(id=uuid4(), owner_user_id=uuid4(), name="DQ Pond", district=district)
    db_session.add(pond)
    await db_session.flush()

    now = datetime.now(UTC)
    # 4 recent logs: 1 missing dissolved_oxygen_mgl, 1 missing ph, 2 complete.
    db_session.add(
        Log(
            pond_id=pond.id,
            recorded_at=now - timedelta(hours=1),
            recorded_by=uuid4(),
            dissolved_oxygen_mgl=None,
            ph=7.5,
            temperature_c=29.0,
            salinity_ppt=15.0,
            ammonia_nh3_mgl=0.1,
        )
    )
    db_session.add(
        Log(
            pond_id=pond.id,
            recorded_at=now - timedelta(hours=2),
            recorded_by=uuid4(),
            dissolved_oxygen_mgl=5.0,
            ph=None,
            temperature_c=29.0,
            salinity_ppt=15.0,
            ammonia_nh3_mgl=0.1,
        )
    )
    for i in range(2):
        db_session.add(
            Log(
                pond_id=pond.id,
                recorded_at=now - timedelta(hours=3 + i),
                recorded_by=uuid4(),
                dissolved_oxygen_mgl=5.0,
                ph=7.5,
                temperature_c=29.0,
                salinity_ppt=15.0,
                ammonia_nh3_mgl=0.1,
            )
        )
    await db_session.commit()

    resp = await db_client.get(
        "/v1/data-quality", params={"pond_id": str(pond.id)}, headers=_staff_headers(district)
    )
    assert resp.status_code == 200, resp.text
    body = resp.json()
    assert body["total_logs_last_7d"] == 4
    assert body["missing_parameter_rates"]["dissolved_oxygen_mgl"] == 0.25
    assert body["missing_parameter_rates"]["ph"] == 0.25
    assert body["missing_parameter_rates"]["temperature_c"] == 0.0
    # Most recent log is 1h old, well inside the default 4h threshold.
    assert body["sensor_offline_ponds"] == 0
    assert body["stale_threshold_hours"] == 4


@pytest.mark.integration
@pytest.mark.asyncio(loop_scope="session")
async def test_data_quality_flags_pond_with_only_stale_logs_as_offline(
    db_session: AsyncSession, db_client: AsyncClient
) -> None:
    district = f"DQTest-{uuid4()}"
    pond = Pond(id=uuid4(), owner_user_id=uuid4(), name="Stale Pond", district=district)
    db_session.add(pond)
    await db_session.flush()

    now = datetime.now(UTC)
    db_session.add(
        Log(
            pond_id=pond.id,
            recorded_at=now - timedelta(days=10),
            recorded_by=uuid4(),
            dissolved_oxygen_mgl=5.0,
        )
    )
    await db_session.commit()

    resp = await db_client.get(
        "/v1/data-quality", params={"pond_id": str(pond.id)}, headers=_staff_headers(district)
    )
    assert resp.status_code == 200, resp.text
    body = resp.json()
    # The one log is 10 days old — outside the 7-day completeness window.
    assert body["total_logs_last_7d"] == 0
    assert body["sensor_offline_ponds"] == 1


@pytest.mark.integration
@pytest.mark.asyncio(loop_scope="session")
async def test_data_quality_pond_with_zero_logs_is_offline_with_zero_rates(
    db_session: AsyncSession, db_client: AsyncClient
) -> None:
    district = f"DQTest-{uuid4()}"
    pond = Pond(id=uuid4(), owner_user_id=uuid4(), name="Empty Pond", district=district)
    db_session.add(pond)
    await db_session.commit()

    resp = await db_client.get(
        "/v1/data-quality", params={"pond_id": str(pond.id)}, headers=_staff_headers(district)
    )
    assert resp.status_code == 200, resp.text
    body = resp.json()
    assert body["total_logs_last_7d"] == 0
    assert body["sensor_offline_ponds"] == 1
    # No logs at all -> an honest 0.0, never a divide-by-zero crash or a
    # fabricated non-zero rate.
    assert all(rate == 0.0 for rate in body["missing_parameter_rates"].values())


@pytest.mark.integration
@pytest.mark.asyncio(loop_scope="session")
async def test_data_quality_unknown_pond_returns_404(db_client: AsyncClient) -> None:
    resp = await db_client.get(
        "/v1/data-quality", params={"pond_id": str(uuid4())}, headers=_staff_headers()
    )
    assert resp.status_code == 404


@pytest.mark.integration
@pytest.mark.asyncio(loop_scope="session")
async def test_data_quality_staff_without_district_or_pond_id_fails_closed(
    db_client: AsyncClient,
) -> None:
    """No pond_id and no district claim -> nothing to honestly scope to;
    must return real zeros, not an unscoped global read."""
    resp = await db_client.get("/v1/data-quality", headers=_staff_headers(district=None))
    assert resp.status_code == 200, resp.text
    body = resp.json()
    assert body["total_logs_last_7d"] == 0
    assert body["sensor_offline_ponds"] == 0


@pytest.mark.integration
@pytest.mark.asyncio(loop_scope="session")
async def test_data_quality_admin_sees_ponds_outside_their_own_district(
    db_session: AsyncSession, db_client: AsyncClient
) -> None:
    district = f"DQTest-{uuid4()}"
    pond = Pond(id=uuid4(), owner_user_id=uuid4(), name="Admin-visible Pond", district=district)
    db_session.add(pond)
    db_session.add(
        Log(
            pond_id=pond.id,
            recorded_at=datetime.now(UTC),
            recorded_by=uuid4(),
            dissolved_oxygen_mgl=5.0,
        )
    )
    await db_session.commit()

    resp = await db_client.get(
        "/v1/data-quality", params={"pond_id": str(pond.id)}, headers=_admin_headers()
    )
    assert resp.status_code == 200, resp.text
    assert resp.json()["total_logs_last_7d"] == 1
