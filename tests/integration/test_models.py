"""Integration tests — real model registry / metrics / drift (P2.7).

`GET /v1/models` and `GET /v1/models/drift` used to return one hardcoded
fixture each; `GET /v1/models/metrics` hardcoded every field except
`rejected_attempts`. This exercises the real path: a real `ModelRegistry`
row synced from the actually-loaded M2 bundle
(app/ml_inference/model_registry_sync.py), real Prometheus counters read
back through `app.core.metrics.snapshot()`, and a real PSI drift
computation over real seeded `Log` rows (app/ml_inference/drift.py).
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


def _staff_headers() -> dict[str, str]:
    token = create_access_token(sub=str(uuid4()), role="staff", district="Nagapattinam")
    return {"Authorization": f"Bearer {token}"}


@pytest.mark.integration
@pytest.mark.asyncio(loop_scope="session")
async def test_list_models_returns_real_registered_bundle(db_client: AsyncClient) -> None:
    resp = await db_client.get("/v1/models", headers=_staff_headers())
    assert resp.status_code == 200, resp.text
    body = resp.json()
    assert len(body["items"]) >= 1
    model = body["items"][0]
    assert model["name"] == "risk_lightgbm"
    assert model["model_type"] == "lightgbm"
    # Real model_version derived from the actually-loaded booster, not a
    # hardcoded "1.2.0".
    assert model["version"].startswith("m2-mortality-risk-baseline-lgbm-trees")
    assert len(model["dataset_hash"]) == 64
    # Real eval metrics from the trained artifact's results.json.
    assert "auc_roc" in model["metrics"]


@pytest.mark.integration
@pytest.mark.asyncio(loop_scope="session")
async def test_list_models_is_idempotent(db_client: AsyncClient) -> None:
    """Calling it twice must not insert a second row for the same
    (already-loaded, unchanged) model version."""
    first = await db_client.get("/v1/models", headers=_staff_headers())
    second = await db_client.get("/v1/models", headers=_staff_headers())
    first_ids = {item["id"] for item in first.json()["items"]}
    second_ids = {item["id"] for item in second.json()["items"]}
    assert first_ids == second_ids


@pytest.mark.integration
@pytest.mark.asyncio(loop_scope="session")
async def test_model_metrics_reflects_real_traffic(db_client: AsyncClient) -> None:
    # Generate at least one real request before reading metrics.
    await db_client.get("/v1/models", headers=_staff_headers())

    resp = await db_client.get("/v1/models/metrics", headers=_staff_headers())
    assert resp.status_code == 200, resp.text
    body = resp.json()
    assert body["rejected_attempts"] == 0
    assert body["total_requests"] >= 1
    assert body["avg_latency_ms"] >= 0.0
    assert body["p95_latency_ms"] >= 0.0
    assert body["p99_latency_ms"] >= 0.0
    # No serving-layer response cache exists — honestly 0.0.
    assert body["cache_hit_rate"] == 0.0


@pytest.mark.integration
@pytest.mark.asyncio(loop_scope="session")
async def test_model_drift_response_shape(db_client: AsyncClient) -> None:
    """The full test suite shares one real, non-rolled-back Postgres
    across many test files, and this endpoint's drift computation is
    deliberately global (unscoped by pond/district, matching the
    original stub's shape — see app/ml_inference/drift.py) — so this
    asserts real response *shape*, not specific PSI values, which other
    tests' seeded Log rows could otherwise make flaky."""
    resp = await db_client.get("/v1/models/drift", headers=_staff_headers())
    assert resp.status_code == 200, resp.text
    body = resp.json()
    assert len(body["items"]) == 1
    report = body["items"][0]
    assert report["model_name"] == "risk_lightgbm"
    assert report["alert_threshold"] == 0.2
    assert set(report["feature_drift"]) == {
        "do_mg_l",
        "tan_mg_l",
        "ph",
        "water_temp_c",
        "salinity_ppt",
        "alkalinity_mg_l",
        "no2_mg_l",
        "no3_mg_l",
    }
    assert all(score >= 0.0 for score in report["feature_drift"].values())
    assert report["drift_detected"] == any(
        score > report["alert_threshold"] for score in report["feature_drift"].values()
    )


@pytest.mark.integration
@pytest.mark.asyncio(loop_scope="session")
async def test_model_drift_detects_real_distribution_shift(
    db_session: AsyncSession, db_client: AsyncClient
) -> None:
    """Seed 25 previous-window logs with a real (jittered, not
    perfectly constant — see app/ml_inference/drift.py's docstring on
    degenerate/zero-variance baselines) DO distribution, and 25
    current-window logs at a sharply different level -> real PSI must
    flag it, even diluted by whatever other tests' "now"-ish Log rows
    already sit in the current window (the previous window, 8-14 days
    back, is not a range any other test's fixtures use)."""
    pond = Pond(id=uuid4(), owner_user_id=uuid4(), name="Drift Test Pond", district="Nagapattinam")
    db_session.add(pond)
    await db_session.flush()

    now = datetime.now(UTC)
    previous_window_at = now - timedelta(days=10)
    current_window_at = now - timedelta(days=1)

    for i in range(25):
        db_session.add(
            Log(
                pond_id=pond.id,
                recorded_at=previous_window_at + timedelta(minutes=i),
                recorded_by=uuid4(),
                dissolved_oxygen_mgl=5.0 + (i % 5) * 0.05,
            )
        )
    for i in range(25):
        db_session.add(
            Log(
                pond_id=pond.id,
                recorded_at=current_window_at + timedelta(minutes=i),
                recorded_by=uuid4(),
                dissolved_oxygen_mgl=1.0 + (i % 5) * 0.05,
            )
        )
    await db_session.commit()

    resp = await db_client.get("/v1/models/drift", headers=_staff_headers())
    assert resp.status_code == 200, resp.text
    report = resp.json()["items"][0]
    assert report["feature_drift"]["do_mg_l"] > 0.2
    assert report["drift_detected"] is True
