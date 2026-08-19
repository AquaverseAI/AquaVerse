"""Integration tests — real M2-model-backed risk scoring (P1.3).

Covers GET /v1/ponds/{id}/risk and GET /v1/risk/worklist against real
Postgres via the `db_session` + `db_client` fixtures (same pattern as
test_ponds.py / test_logs_pagination.py): real seeded Pond/Log rows, real
lifespan, real in-process LightGBM inference + SHAP — no fixture data, no
mocked model.
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
    from collections.abc import Callable

    from httpx import AsyncClient
    from sqlalchemy.ext.asyncio import AsyncSession

# The exact 27 real feature names the M2 booster was trained on (verified
# empirically against booster.feature_name() while building
# app/ml_inference/numeric/m2_risk_engine.py) — used below to prove SHAP
# contributions reference real model features, not the old stub's made-up
# "dissolved_oxygen_mgl" / "ammonia_nh3_mgl" names.
KNOWN_M2_FEATURES = {
    "species",
    "salinity_ppt",
    "management_quality",
    "do_mg_l",
    "tan_mg_l",
    "no2_mg_l",
    "no3_mg_l",
    "ph",
    "alkalinity_mg_l",
    "water_temp_c",
    "secchi_cm",
    "night_do_min",
    "night_do_min_3d_trend",
    "do_amplitude",
    "stress_hours_lt3_24h",
    "stress_hours_lt3_7d",
    "tan_slope_3d",
    "alkalinity_trend_7d",
    "nh3_un_ionised",
    "rain_48h_mm",
    "wind_mean_24h",
    "solar_rad_24h",
    "feed_kg_7d_cum",
    "fcr_running",
    "biomass_est_kg",
    "doc",
    "data_health_score",
}

# The old hardcoded stub's exact (feature, value, shap_value) pairs — real
# SHAP output must never coincide with these.
OLD_STUB_SHAP_SIGNATURES = {
    ("dissolved_oxygen_mgl", 4.2, 0.18),
    ("ammonia_nh3_mgl", 0.8, 0.12),
}


def _staff_token(district: str = "Nagapattinam") -> str:
    return create_access_token(sub=str(uuid4()), role="staff", district=district)


def _headers(token: str) -> dict[str, str]:
    return {"Authorization": f"Bearer {token}"}


async def _seed_pond_with_hourly_logs(
    db_session: AsyncSession,
    *,
    district: str = "Nagapattinam",
    hours: int = 96,
    do_fn: Callable[[datetime], float],
    ph: float = 7.6,
    tan: float = 0.1,
    alkalinity: float = 140.0,
    temp: float = 29.0,
    salinity: float = 15.0,
    latest_offset: timedelta = timedelta(hours=0),
    name: str = "Risk Test Pond",
) -> tuple[Pond, list[Log]]:
    """Seed one pond with `hours` real hourly Log rows, ending `latest_offset`
    before now. `do_fn(timestamp) -> mg/L` lets each test drive a distinct,
    realistic DO trajectory (e.g. chronic night-time stress) rather than a
    flat constant, exercising the real rolling-window feature engineering
    (night_do_min, stress_hours_lt3_*, etc.) in sim/features.py.
    """
    pond_id = uuid4()
    owner_id = uuid4()
    pond = Pond(
        id=pond_id,
        owner_user_id=owner_id,
        name=name,
        district=district,
        species="Litopenaeus vannamei",
    )
    db_session.add(pond)

    t_end = datetime.now(UTC).replace(microsecond=0) - latest_offset
    logs = [
        Log(
            id=uuid4(),
            pond_id=pond_id,
            recorded_by=owner_id,
            recorded_at=(t := t_end - timedelta(hours=h)),
            temperature_c=temp,
            dissolved_oxygen_mgl=do_fn(t),
            ph=ph,
            salinity_ppt=salinity,
            ammonia_nh3_mgl=tan,
            alkalinity_mgl=alkalinity,
            nitrite_mgl=0.05,
            nitrate_mgl=1.0,
            source="sensor",
        )
        for h in range(hours, 0, -1)
    ]
    db_session.add_all(logs)
    await db_session.commit()
    return pond, logs


def _healthy_do(_t: datetime) -> float:
    return 6.0


def _stressed_do(t: datetime) -> float:
    # Chronic night-time DO crash (22:00-06:00), still low-ish by day.
    return 1.2 if (t.hour >= 22 or t.hour < 6) else 3.0


# ---------------------------------------------------------------------------
# (a) Risk score genuinely varies based on real seeded Log values
# ---------------------------------------------------------------------------
@pytest.mark.integration
@pytest.mark.asyncio(loop_scope="session")
async def test_risk_score_varies_with_real_log_values(
    db_session: AsyncSession, db_client: AsyncClient
) -> None:
    healthy_pond, _ = await _seed_pond_with_hourly_logs(
        db_session, do_fn=_healthy_do, ph=7.6, tan=0.1, alkalinity=140.0, name="Healthy Pond"
    )
    stressed_pond, _ = await _seed_pond_with_hourly_logs(
        db_session, do_fn=_stressed_do, ph=9.3, tan=1.5, alkalinity=40.0, name="Stressed Pond"
    )
    headers = _headers(_staff_token())

    healthy_resp = await db_client.get(f"/v1/ponds/{healthy_pond.id}/risk", headers=headers)
    stressed_resp = await db_client.get(f"/v1/ponds/{stressed_pond.id}/risk", headers=headers)
    assert healthy_resp.status_code == 200, healthy_resp.text
    assert stressed_resp.status_code == 200, stressed_resp.text

    healthy_body = healthy_resp.json()
    stressed_body = stressed_resp.json()

    # Not the old hardcoded fixture value, and the two real ponds score
    # differently from each other.
    assert healthy_body["risk_score"] != 0.72
    assert stressed_body["risk_score"] != 0.72
    assert healthy_body["risk_score"] != stressed_body["risk_score"]
    assert stressed_body["risk_score"] > healthy_body["risk_score"]

    # Neither pond's data is stale/missing -> neither should be suppressed.
    assert healthy_body["suppressed"] is False
    assert stressed_body["suppressed"] is False

    # health component is a legitimate 1:1 mapping of the real M2 score.
    assert healthy_body["components"]["health"] == healthy_body["risk_score"]
    assert stressed_body["components"]["health"] == stressed_body["risk_score"]

    # chemistry proxy must also reflect the real chemistry difference.
    assert stressed_body["components"]["chemistry"] > healthy_body["components"]["chemistry"]

    assert healthy_body["model_version"] != "lightgbm-v1.2.0"
    assert healthy_body["model_version"].startswith("m2-mortality-risk-baseline-lgbm")


# ---------------------------------------------------------------------------
# (b) Suppression — no logs at all, and stale-but-present logs
# ---------------------------------------------------------------------------
@pytest.mark.integration
@pytest.mark.asyncio(loop_scope="session")
async def test_risk_suppressed_for_pond_with_no_logs(
    db_session: AsyncSession, db_client: AsyncClient
) -> None:
    pond = Pond(id=uuid4(), owner_user_id=uuid4(), name="No Data Pond", district="Nagapattinam")
    db_session.add(pond)
    await db_session.commit()

    response = await db_client.get(f"/v1/ponds/{pond.id}/risk", headers=_headers(_staff_token()))
    assert response.status_code == 200, response.text
    body = response.json()

    assert body["suppressed"] is True
    assert body["suppression_reason"] == "No sensor data recorded for this pond."
    # R5: suppress/flag, don't hide — a real score is still returned.
    assert isinstance(body["risk_score"], float)
    assert 0.0 <= body["risk_score"] <= 1.0


@pytest.mark.integration
@pytest.mark.asyncio(loop_scope="session")
async def test_risk_suppressed_for_stale_logs(
    db_session: AsyncSession, db_client: AsyncClient
) -> None:
    pond, _logs = await _seed_pond_with_hourly_logs(
        db_session,
        do_fn=_healthy_do,
        hours=48,
        latest_offset=timedelta(hours=10),  # most recent reading is 10h old
        name="Stale Data Pond",
    )
    response = await db_client.get(f"/v1/ponds/{pond.id}/risk", headers=_headers(_staff_token()))
    assert response.status_code == 200, response.text
    body = response.json()

    assert body["suppressed"] is True
    assert body["suppression_reason"] is not None
    assert "stale" in body["suppression_reason"].lower()
    assert isinstance(body["risk_score"], float)


@pytest.mark.integration
@pytest.mark.asyncio(loop_scope="session")
async def test_risk_not_suppressed_for_fresh_logs(
    db_session: AsyncSession, db_client: AsyncClient
) -> None:
    pond, _ = await _seed_pond_with_hourly_logs(
        db_session, do_fn=_healthy_do, hours=48, latest_offset=timedelta(hours=0), name="Fresh Pond"
    )
    response = await db_client.get(f"/v1/ponds/{pond.id}/risk", headers=_headers(_staff_token()))
    assert response.status_code == 200, response.text
    body = response.json()
    assert body["suppressed"] is False
    assert body["suppression_reason"] is None


# ---------------------------------------------------------------------------
# (c) SHAP contributions are real, not fixture
# ---------------------------------------------------------------------------
@pytest.mark.integration
@pytest.mark.asyncio(loop_scope="session")
async def test_shap_contributions_reference_real_features(
    db_session: AsyncSession, db_client: AsyncClient
) -> None:
    pond, _ = await _seed_pond_with_hourly_logs(
        db_session, do_fn=_stressed_do, ph=9.3, tan=1.5, alkalinity=40.0, name="SHAP Test Pond"
    )
    response = await db_client.get(f"/v1/ponds/{pond.id}/risk", headers=_headers(_staff_token()))
    assert response.status_code == 200, response.text
    body = response.json()

    contributions = body["shap_contributions"]
    assert len(contributions) > 0

    for c in contributions:
        assert c["feature"] in KNOWN_M2_FEATURES
        assert c["direction"] in ("increases_risk", "decreases_risk", "neutral")
        assert isinstance(c["value"], float)
        assert isinstance(c["shap_value"], float)

    # Never the old stub's hardcoded (feature, value, shap_value) triples.
    actual_signatures = {(c["feature"], c["value"], c["shap_value"]) for c in contributions}
    assert actual_signatures.isdisjoint(OLD_STUB_SHAP_SIGNATURES)

    # At least one contribution carries a real (non-zero) SHAP signal.
    assert any(abs(c["shap_value"]) > 1e-9 for c in contributions)

    # do_mg_l (the real driver of this stressed scenario) should show up
    # among the explained features at all, given how extreme the DO
    # trajectory is.
    assert any(
        c["feature"] in ("do_mg_l", "night_do_min", "stress_hours_lt3_24h", "stress_hours_lt3_7d")
        for c in contributions
    )


# ---------------------------------------------------------------------------
# (d) Worklist ranks by risk_score descending and paginates without dupes
# ---------------------------------------------------------------------------
@pytest.mark.integration
@pytest.mark.asyncio(loop_scope="session")
async def test_worklist_ranks_by_risk_descending_and_paginates(
    db_session: AsyncSession, db_client: AsyncClient
) -> None:
    # A unique per-run district, not the shared "Nagapattinam" used by other
    # tests in this module: db_session.commit() really commits to the
    # session-scoped testcontainers Postgres (its rollback-after-yield only
    # undoes uncommitted work), so other tests' Nagapattinam ponds are still
    # present when this one queries by district. A district-listing
    # assertion like "exactly these N ponds, this order" needs isolation a
    # shared district name can't give it — same reason test_ponds.py's own
    # district-scoping tests key off specific pond ids rather than exact
    # counts wherever they share "Nagapattinam" with other tests.
    district = f"WorklistTestDistrict-{uuid4().hex[:10]}"
    ponds: list[Pond] = []
    for level in range(5):
        do_value = 6.0 - level * 1.1  # progressively worse DO per pond

        def _do_fn(_t: datetime, v: float = do_value) -> float:
            return v

        pond, _ = await _seed_pond_with_hourly_logs(
            db_session,
            district=district,
            hours=60,
            do_fn=_do_fn,
            name=f"Worklist Pond {level}",
        )
        ponds.append(pond)

    headers = _headers(_staff_token(district=district))

    seen_ids: list[str] = []
    seen_scores: list[float] = []
    cursor: str | None = None
    pages_fetched = 0

    while True:
        params: dict[str, object] = {"limit": 2}
        if cursor:
            params["cursor"] = cursor
        response = await db_client.get("/v1/risk/worklist", params=params, headers=headers)
        assert response.status_code == 200, response.text
        body = response.json()

        for item in body["items"]:
            seen_ids.append(item["pond_id"])
            seen_scores.append(item["risk_score"])

        cursor = body["next_cursor"]
        pages_fetched += 1
        assert pages_fetched <= len(ponds) + 2, "pagination did not terminate"
        if cursor is None:
            break

    # Every seeded pond appears exactly once — no duplicates, no drops.
    assert len(seen_ids) == len(ponds)
    assert len(set(seen_ids)) == len(ponds)
    assert set(seen_ids) == {str(p.id) for p in ponds}

    # Descending risk_score order, preserved across page boundaries.
    assert seen_scores == sorted(seen_scores, reverse=True)
