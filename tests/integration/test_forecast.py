"""Integration tests — real empirical DO-quantile forecast baseline (P1.4).

Covers GET /v1/ponds/{id}/forecast/do against real Postgres via the
`db_session` + `db_client` fixtures (same pattern as test_risk.py /
test_ponds.py): real seeded Pond/Log rows, real lifespan, real in-process
hour-of-day empirical-quantile computation — no fixture data, no mocked
"model" (there is no trained model here; see
app/ml_inference/numeric/do_forecast.py).
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


def _staff_token(district: str = "Nagapattinam") -> str:
    return create_access_token(sub=str(uuid4()), role="staff", district=district)


def _headers(token: str) -> dict[str, str]:
    return {"Authorization": f"Bearer {token}"}


def _diurnal_do(t: datetime) -> float:
    """Clear, deliberately-separated diurnal DO pattern: low overnight
    (respiration-dominated), high during the day (photosynthesis-dominated),
    with a small deterministic per-timestamp jitter so each hour-of-day
    bucket isn't a single repeated value (real percentile computation over
    a real, if synthetic, spread) while keeping day/night bands far enough
    apart (~4 mg/L) that no jitter can blur the day-vs-night comparison the
    tests below rely on.
    """
    night = t.hour >= 22 or t.hour < 6
    base = 3.0 if night else 7.0
    jitter = ((t.timetuple().tm_yday * 31 + t.hour * 7) % 10) / 100.0  # 0.00-0.09
    return base + jitter


async def _seed_pond_with_hourly_logs(
    db_session: AsyncSession,
    *,
    days: int = 14,
    do_fn=_diurnal_do,
    district: str = "Nagapattinam",
    name: str = "Forecast Test Pond",
    species: str | None = "Litopenaeus vannamei",
) -> Pond:
    pond_id = uuid4()
    owner_id = uuid4()
    pond = Pond(
        id=pond_id,
        owner_user_id=owner_id,
        name=name,
        district=district,
        species=species,
    )
    db_session.add(pond)

    t_end = datetime.now(UTC).replace(minute=0, second=0, microsecond=0)
    hours = days * 24
    logs = [
        Log(
            id=uuid4(),
            pond_id=pond_id,
            recorded_by=owner_id,
            recorded_at=(t := t_end - timedelta(hours=h)),
            temperature_c=28.0,
            dissolved_oxygen_mgl=do_fn(t),
            ph=7.6,
            salinity_ppt=15.0,
            ammonia_nh3_mgl=0.1,
            source="sensor",
        )
        for h in range(hours, 0, -1)
    ]
    db_session.add_all(logs)
    await db_session.commit()
    return pond


# ---------------------------------------------------------------------------
# (a) Forecast bands genuinely reflect the pond's real seeded diurnal pattern
# ---------------------------------------------------------------------------
@pytest.mark.integration
@pytest.mark.asyncio(loop_scope="session")
async def test_forecast_reflects_real_diurnal_do_pattern(
    db_session: AsyncSession, db_client: AsyncClient
) -> None:
    pond = await _seed_pond_with_hourly_logs(db_session)
    headers = _headers(_staff_token())

    response = await db_client.get(
        f"/v1/ponds/{pond.id}/forecast/do", params={"horizon_hours": 24}, headers=headers
    )
    assert response.status_code == 200, response.text
    body = response.json()

    assert body["parameter"] == "dissolved_oxygen_mgl"
    assert len(body["points"]) == 24

    # horizon_hours=24 covers every hour-of-day at least once — pull out the
    # forecasted points landing on a clear night hour (3am) and a clear day
    # hour (3pm) and confirm the real seeded separation survives into the
    # forecast: this is the assertion that proves it's not flat/fake output.
    night_points = [
        p for p in body["points"] if datetime.fromisoformat(p["forecasted_at"]).hour == 3
    ]
    day_points = [
        p for p in body["points"] if datetime.fromisoformat(p["forecasted_at"]).hour == 15
    ]
    assert night_points, "expected a forecasted point at hour-of-day 3"
    assert day_points, "expected a forecasted point at hour-of-day 15"

    night_p50 = night_points[0]["p50"]
    day_p50 = day_points[0]["p50"]
    assert night_p50 < day_p50
    # Seeded bands are ~3.0-3.09 (night) vs ~7.0-7.09 (day) — a real
    # multi-mg/L gap, not noise.
    assert day_p50 - night_p50 > 2.0
    assert 2.5 <= night_p50 <= 3.5
    assert 6.5 <= day_p50 <= 7.5

    # Not the old fake linear-decay fixture / fictional model string.
    assert body["model_version"] != "patchtst-v0.3.1"
    assert body["model_version"] == "empirical-do-quantile-baseline-v1"
    assert "trained temporal model" in body["uncertainty_note"]
    assert "TCN" in body["uncertainty_note"] or "PatchTST" in body["uncertainty_note"]


# ---------------------------------------------------------------------------
# (b) p10 <= p50 <= p90 holds for every point
# ---------------------------------------------------------------------------
@pytest.mark.integration
@pytest.mark.asyncio(loop_scope="session")
async def test_forecast_bands_are_always_ordered(
    db_session: AsyncSession, db_client: AsyncClient
) -> None:
    pond = await _seed_pond_with_hourly_logs(db_session)
    headers = _headers(_staff_token())

    response = await db_client.get(
        f"/v1/ponds/{pond.id}/forecast/do", params={"horizon_hours": 48}, headers=headers
    )
    assert response.status_code == 200, response.text
    body = response.json()

    assert len(body["points"]) == 48
    for point in body["points"]:
        assert point["p10"] <= point["p50"] <= point["p90"]


# ---------------------------------------------------------------------------
# (c) horizon_hours is respected, and the existing Query bound is untouched
# ---------------------------------------------------------------------------
@pytest.mark.integration
@pytest.mark.asyncio(loop_scope="session")
async def test_horizon_hours_respected_and_bound_unchanged(
    db_session: AsyncSession, db_client: AsyncClient
) -> None:
    pond = await _seed_pond_with_hourly_logs(db_session)
    headers = _headers(_staff_token())

    response = await db_client.get(
        f"/v1/ponds/{pond.id}/forecast/do", params={"horizon_hours": 5}, headers=headers
    )
    assert response.status_code == 200, response.text
    assert len(response.json()["points"]) == 5

    # Default (no horizon_hours passed) is still 24.
    default_response = await db_client.get(f"/v1/ponds/{pond.id}/forecast/do", headers=headers)
    assert default_response.status_code == 200, default_response.text
    assert len(default_response.json()["points"]) == 24
    assert default_response.json()["horizon_hours"] == 24

    # The existing le=168 bound is untouched — over it is a 422, not a
    # silent clamp.
    too_far_response = await db_client.get(
        f"/v1/ponds/{pond.id}/forecast/do", params={"horizon_hours": 169}, headers=headers
    )
    assert too_far_response.status_code == 422

    # Exactly at the bound still works.
    at_bound_response = await db_client.get(
        f"/v1/ponds/{pond.id}/forecast/do", params={"horizon_hours": 168}, headers=headers
    )
    assert at_bound_response.status_code == 200, at_bound_response.text
    assert len(at_bound_response.json()["points"]) == 168


# ---------------------------------------------------------------------------
# (d) Zero DO history — honest species-default fallback, no crash
# ---------------------------------------------------------------------------
@pytest.mark.integration
@pytest.mark.asyncio(loop_scope="session")
async def test_forecast_falls_back_honestly_with_no_do_history(
    db_session: AsyncSession, db_client: AsyncClient
) -> None:
    pond = Pond(
        id=uuid4(),
        owner_user_id=uuid4(),
        name="No DO History Pond",
        district="Nagapattinam",
        species="Litopenaeus vannamei",
    )
    db_session.add(pond)
    await db_session.commit()

    response = await db_client.get(
        f"/v1/ponds/{pond.id}/forecast/do",
        params={"horizon_hours": 12},
        headers=_headers(_staff_token()),
    )
    assert response.status_code == 200, response.text
    body = response.json()

    assert len(body["points"]) == 12
    for point in body["points"]:
        assert point["p10"] <= point["p50"] <= point["p90"]

    # Still the honest baseline model_version either way...
    assert body["model_version"] == "empirical-do-quantile-baseline-v1"
    # ...but the note must explicitly call out the no-real-data fallback,
    # not bury it.
    assert "no usable historical DO data" in body["uncertainty_note"]
    assert "species-default" in body["uncertainty_note"]


# ---------------------------------------------------------------------------
# (e) 404 for a nonexistent pond
# ---------------------------------------------------------------------------
@pytest.mark.integration
@pytest.mark.asyncio(loop_scope="session")
async def test_forecast_404_for_nonexistent_pond(db_client: AsyncClient) -> None:
    response = await db_client.get(
        f"/v1/ponds/{uuid4()}/forecast/do", headers=_headers(_staff_token())
    )
    assert response.status_code == 404
