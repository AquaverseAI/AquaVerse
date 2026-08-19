"""Integration tests — real DB-backed Ponds domain (P1.2).

Covers GET /v1/ponds, GET /v1/ponds/{id}, GET /v1/ponds/{id}/timeseries, and
GET /v1/ponds/{id}/events against real Postgres via the `db_session` +
`db_client` fixtures (same pattern as test_logs_pagination.py — real keyset
pagination, real lifespan, no fixture data).
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

NUM_LOGS = 7


async def _seed_pond_and_logs(db_session: AsyncSession) -> tuple[Pond, list[Log]]:
    """Mirrors test_logs_pagination.py's helper — one pond, NUM_LOGS logs with
    a tied-timestamp pair (i=0, i=1) to exercise the id tie-breaker."""
    pond_id = uuid4()
    owner_id = uuid4()
    pond = Pond(
        id=pond_id,
        owner_user_id=owner_id,
        name="Ponds Domain Test Pond",
        district="Nagapattinam",
        species="Litopenaeus vannamei",
    )
    db_session.add(pond)

    t_base = datetime.now(UTC).replace(microsecond=0)
    logs = []
    for i in range(NUM_LOGS):
        log = Log(
            id=uuid4(),
            pond_id=pond_id,
            recorded_by=owner_id,
            recorded_at=t_base - timedelta(hours=(i // 2)),
            temperature_c=25.0 + i,
            dissolved_oxygen_mgl=6.0 + (i * 0.1),
            ph=7.5,
            salinity_ppt=15.0,
            ammonia_nh3_mgl=0.1 * i,
            source="sensor",
        )
        logs.append(log)
    db_session.add_all(logs)
    await db_session.commit()
    return pond, logs


def _staff_token(district: str = "Nagapattinam") -> str:
    return create_access_token(sub=str(uuid4()), role="staff", district=district)


# ---------------------------------------------------------------------------
# (a) Farmer scoping — list_ponds only shows the caller's own pond(s)
# ---------------------------------------------------------------------------
@pytest.mark.integration
@pytest.mark.asyncio(loop_scope="session")
async def test_farmer_list_ponds_only_sees_own_pond(
    db_session: AsyncSession, db_client: AsyncClient
) -> None:
    farmer_a_id = uuid4()
    farmer_b_id = uuid4()
    pond_a = Pond(
        id=uuid4(),
        owner_user_id=farmer_a_id,
        name="Farmer A Pond",
        district="Nagapattinam",
    )
    pond_b = Pond(
        id=uuid4(),
        owner_user_id=farmer_b_id,
        name="Farmer B Pond",
        district="Nagapattinam",
    )
    db_session.add_all([pond_a, pond_b])
    await db_session.commit()

    token = create_access_token(
        sub=str(farmer_a_id),
        role="farmer",
        pond_ids=[str(pond_a.id)],
        district="Nagapattinam",
    )
    headers = {"Authorization": f"Bearer {token}"}

    response = await db_client.get("/v1/ponds", headers=headers)
    assert response.status_code == 200, response.text
    body = response.json()

    ids = {item["id"] for item in body["items"]}
    assert str(pond_a.id) in ids
    assert str(pond_b.id) not in ids
    # Every returned pond must actually be owned by farmer A.
    assert all(item["owner_user_id"] == str(farmer_a_id) for item in body["items"])


# ---------------------------------------------------------------------------
# (a2) Staff / admin district scoping — list_ponds branch coverage
# ---------------------------------------------------------------------------
@pytest.mark.integration
@pytest.mark.asyncio(loop_scope="session")
async def test_staff_list_ponds_defaults_to_own_district(
    db_session: AsyncSession, db_client: AsyncClient
) -> None:
    pond, _logs = await _seed_pond_and_logs(db_session)  # district=Nagapattinam
    other = Pond(
        id=uuid4(), owner_user_id=uuid4(), name="Other District Pond", district="Thanjavur"
    )
    db_session.add(other)
    await db_session.commit()

    headers = {"Authorization": f"Bearer {_staff_token(district='Nagapattinam')}"}
    response = await db_client.get("/v1/ponds", headers=headers)
    assert response.status_code == 200, response.text
    ids = {item["id"] for item in response.json()["items"]}
    assert str(pond.id) in ids
    assert str(other.id) not in ids


@pytest.mark.integration
@pytest.mark.asyncio(loop_scope="session")
async def test_staff_list_ponds_district_param_mismatch_403(db_client: AsyncClient) -> None:
    headers = {"Authorization": f"Bearer {_staff_token(district='Nagapattinam')}"}
    response = await db_client.get("/v1/ponds", params={"district": "Thanjavur"}, headers=headers)
    assert response.status_code == 403, response.text


@pytest.mark.integration
@pytest.mark.asyncio(loop_scope="session")
async def test_staff_list_ponds_no_district_claim_fails_closed_empty(
    db_session: AsyncSession, db_client: AsyncClient
) -> None:
    await _seed_pond_and_logs(db_session)
    token = create_access_token(sub=str(uuid4()), role="staff", district=None)
    headers = {"Authorization": f"Bearer {token}"}
    response = await db_client.get("/v1/ponds", headers=headers)
    assert response.status_code == 200, response.text
    assert response.json()["items"] == []


@pytest.mark.integration
@pytest.mark.asyncio(loop_scope="session")
async def test_admin_list_ponds_unrestricted_across_districts(
    db_session: AsyncSession, db_client: AsyncClient
) -> None:
    pond, _logs = await _seed_pond_and_logs(db_session)  # district=Nagapattinam
    other = Pond(
        id=uuid4(), owner_user_id=uuid4(), name="Other District Pond", district="Thanjavur"
    )
    db_session.add(other)
    await db_session.commit()

    token = create_access_token(sub=str(uuid4()), role="admin", district=None)
    headers = {"Authorization": f"Bearer {token}"}
    response = await db_client.get("/v1/ponds", headers=headers)
    assert response.status_code == 200, response.text
    ids = {item["id"] for item in response.json()["items"]}
    assert str(pond.id) in ids
    assert str(other.id) in ids

    # Admin can also explicitly filter by district without a require_district check.
    response = await db_client.get("/v1/ponds", params={"district": "Thanjavur"}, headers=headers)
    assert response.status_code == 200, response.text
    ids = {item["id"] for item in response.json()["items"]}
    assert str(other.id) in ids
    assert str(pond.id) not in ids


# ---------------------------------------------------------------------------
# (b) GET /v1/ponds/{id} 404s for a nonexistent pond id
# ---------------------------------------------------------------------------
@pytest.mark.integration
@pytest.mark.asyncio(loop_scope="session")
async def test_get_pond_404_for_nonexistent_pond(db_client: AsyncClient) -> None:
    token = _staff_token()
    headers = {"Authorization": f"Bearer {token}"}

    response = await db_client.get(f"/v1/ponds/{uuid4()}", headers=headers)
    assert response.status_code == 404, response.text


@pytest.mark.integration
@pytest.mark.asyncio(loop_scope="session")
async def test_get_pond_returns_real_seeded_pond(
    db_session: AsyncSession, db_client: AsyncClient
) -> None:
    pond, _logs = await _seed_pond_and_logs(db_session)
    token = _staff_token()
    headers = {"Authorization": f"Bearer {token}"}

    response = await db_client.get(f"/v1/ponds/{pond.id}", headers=headers)
    assert response.status_code == 200, response.text
    body = response.json()
    assert body["id"] == str(pond.id)
    assert body["name"] == "Ponds Domain Test Pond"
    assert body["district"] == "Nagapattinam"
    assert body["species"] == "Litopenaeus vannamei"
    # Not the old hardcoded fixture string.
    assert body["name"] != "Kalaiselvi Pond - Block A"


# ---------------------------------------------------------------------------
# (c) GET /v1/ponds/{id}/timeseries — real seeded Log values, paginated
# ---------------------------------------------------------------------------
@pytest.mark.integration
@pytest.mark.asyncio(loop_scope="session")
async def test_pond_timeseries_returns_real_values_and_paginates(
    db_session: AsyncSession, db_client: AsyncClient
) -> None:
    pond, logs = await _seed_pond_and_logs(db_session)
    token = _staff_token()
    headers = {"Authorization": f"Bearer {token}"}

    # Points carry no id in the schema, so track (recorded_at, temperature_c)
    # pairs — temperature_c is distinct per seeded log (25.0 + i), including
    # within the tied-timestamp pairs, so this uniquely identifies each row.
    seen_points: list[tuple[datetime, float]] = []
    cursor: str | None = None
    pages_fetched = 0

    while True:
        params: dict[str, object] = {"limit": 3}
        if cursor:
            params["cursor"] = cursor
        response = await db_client.get(
            f"/v1/ponds/{pond.id}/timeseries", params=params, headers=headers
        )
        assert response.status_code == 200, response.text
        body = response.json()
        assert body["pond_id"] == str(pond.id)

        for point in body["points"]:
            seen_points.append(
                (datetime.fromisoformat(point["recorded_at"]), point["temperature_c"])
            )

        cursor = body["next_cursor"]
        pages_fetched += 1
        assert pages_fetched <= NUM_LOGS + 1, "pagination did not terminate"
        if cursor is None:
            break

    assert len(seen_points) == NUM_LOGS
    assert len(set(seen_points)) == NUM_LOGS, "duplicate rows across pages"

    expected_points = {(log.recorded_at, log.temperature_c) for log in logs}
    assert set(seen_points) == expected_points

    # recorded_at is non-increasing across the full page walk (DESC order);
    # the id tie-breaker within a shared timestamp isn't independently
    # observable from this schema, but full DESC ordering on the primary
    # sort key is.
    recorded_ats = [p[0] for p in seen_points]
    assert recorded_ats == sorted(recorded_ats, reverse=True)


@pytest.mark.integration
@pytest.mark.asyncio(loop_scope="session")
async def test_pond_timeseries_404_for_nonexistent_pond(db_client: AsyncClient) -> None:
    token = _staff_token()
    headers = {"Authorization": f"Bearer {token}"}
    response = await db_client.get(f"/v1/ponds/{uuid4()}/timeseries", headers=headers)
    assert response.status_code == 404, response.text


# ---------------------------------------------------------------------------
# (d) GET /v1/ponds/{id}/events — synthesized log-sourced events
# ---------------------------------------------------------------------------
@pytest.mark.integration
@pytest.mark.asyncio(loop_scope="session")
async def test_pond_events_synthesized_from_real_logs(
    db_session: AsyncSession, db_client: AsyncClient
) -> None:
    pond, logs = await _seed_pond_and_logs(db_session)
    token = _staff_token()
    headers = {"Authorization": f"Bearer {token}"}

    response = await db_client.get(f"/v1/ponds/{pond.id}/events", headers=headers)
    assert response.status_code == 200, response.text
    body = response.json()

    assert len(body["items"]) > 0
    logs_by_id = {str(log.id): log for log in logs}

    for item in body["items"]:
        assert item["event_type"] == "log"
        assert item["id"] in logs_by_id
        log = logs_by_id[item["id"]]
        assert item["title"] == f"Water quality log recorded ({log.source})"
        assert item["metadata"]["temperature_c"] == log.temperature_c
        assert item["metadata"]["dissolved_oxygen_mgl"] == log.dissolved_oxygen_mgl


@pytest.mark.integration
@pytest.mark.asyncio(loop_scope="session")
async def test_pond_events_404_for_nonexistent_pond(db_client: AsyncClient) -> None:
    token = _staff_token()
    headers = {"Authorization": f"Bearer {token}"}
    response = await db_client.get(f"/v1/ponds/{uuid4()}/events", headers=headers)
    assert response.status_code == 404, response.text
