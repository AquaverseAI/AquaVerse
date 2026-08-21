"""Integration tests — real Digital Twin domain (P2.2).

`GET /v1/twin/{id}/state`, `/view`, `POST /{id}/whatif` used to return
fixed numbers regardless of pond_id or real data. This exercises the real
path: a pond with recent real Log data gets its state from that data; a
blind-state pond (no recent logs) falls back to the repo's real
`PondSimulator` (app/twin/simulator_adapter.py) — deterministic per pond,
suppression always visible. `whatif` re-scores risk through the real M2
engine rather than returning a hardcoded delta.
"""

from __future__ import annotations

from datetime import UTC, datetime
from typing import TYPE_CHECKING
from uuid import uuid4

import pytest

from app.core.security import create_access_token
from app.db.models.log import Log
from app.db.models.pond import Pond

if TYPE_CHECKING:
    from httpx import AsyncClient
    from sqlalchemy.ext.asyncio import AsyncSession


def _admin_headers() -> dict[str, str]:
    token = create_access_token(sub=str(uuid4()), role="admin")
    return {"Authorization": f"Bearer {token}"}


async def _seed_pond(db_session: AsyncSession, *, species: str = "Litopenaeus vannamei") -> Pond:
    pond = Pond(
        id=uuid4(),
        owner_user_id=uuid4(),
        name="Twin Test Pond",
        district="Nagapattinam",
        species=species,
    )
    db_session.add(pond)
    await db_session.commit()
    return pond


async def _seed_recent_log(db_session: AsyncSession, pond: Pond) -> Log:
    log = Log(
        pond_id=pond.id,
        recorded_at=datetime.now(UTC),
        recorded_by=uuid4(),
        temperature_c=29.0,
        dissolved_oxygen_mgl=6.1,
        ph=7.9,
        salinity_ppt=16.0,
        ammonia_nh3_mgl=0.2,
        turbidity_ntu=10.0,
        source="manual",
    )
    db_session.add(log)
    await db_session.commit()
    return log


@pytest.mark.integration
@pytest.mark.asyncio(loop_scope="session")
async def test_twin_state_unknown_pond_returns_404(db_client: AsyncClient) -> None:
    resp = await db_client.get(f"/v1/twin/{uuid4()}/state", headers=_admin_headers())
    assert resp.status_code == 404


@pytest.mark.integration
@pytest.mark.asyncio(loop_scope="session")
async def test_twin_state_uses_real_log_when_not_blind(
    db_session: AsyncSession, db_client: AsyncClient
) -> None:
    pond = await _seed_pond(db_session)
    await _seed_recent_log(db_session, pond)

    resp = await db_client.get(f"/v1/twin/{pond.id}/state", headers=_admin_headers())
    assert resp.status_code == 200, resp.text
    body = resp.json()
    assert body["pond_id"] == str(pond.id)
    assert body["suppressed"] is False
    assert body["temperature_c"] == 29.0
    assert body["dissolved_oxygen_mgl"] == 6.1
    assert body["ph"] == 7.9
    # Biomass/FCR are always simulator-estimated — real data or not.
    assert body["biomass_kg_estimated"] is not None
    assert body["fcr_estimated"] is not None


@pytest.mark.integration
@pytest.mark.asyncio(loop_scope="session")
async def test_twin_state_falls_back_to_simulator_when_blind(
    db_session: AsyncSession, db_client: AsyncClient
) -> None:
    pond = await _seed_pond(db_session)
    # No logs at all -> blind state.
    resp = await db_client.get(f"/v1/twin/{pond.id}/state", headers=_admin_headers())
    assert resp.status_code == 200, resp.text
    body = resp.json()
    assert body["suppressed"] is True
    assert body["suppression_reason"] is not None
    # Simulator fallback still produces a full, usable state vector.
    assert body["temperature_c"] is not None
    assert body["dissolved_oxygen_mgl"] is not None
    assert body["biomass_kg_estimated"] is not None


@pytest.mark.integration
@pytest.mark.asyncio(loop_scope="session")
async def test_twin_state_is_deterministic_per_pond(
    db_session: AsyncSession, db_client: AsyncClient
) -> None:
    pond = await _seed_pond(db_session)
    headers = _admin_headers()

    resp1 = await db_client.get(f"/v1/twin/{pond.id}/state", headers=headers)
    resp2 = await db_client.get(f"/v1/twin/{pond.id}/state", headers=headers)
    assert resp1.json()["dissolved_oxygen_mgl"] == resp2.json()["dissolved_oxygen_mgl"]
    assert resp1.json()["biomass_kg_estimated"] == resp2.json()["biomass_kg_estimated"]


@pytest.mark.integration
@pytest.mark.asyncio(loop_scope="session")
async def test_twin_view_renders_html_with_suppression_badge(
    db_session: AsyncSession, db_client: AsyncClient
) -> None:
    pond = await _seed_pond(db_session)
    resp = await db_client.get(f"/v1/twin/{pond.id}/view", headers=_admin_headers())
    assert resp.status_code == 200, resp.text
    assert "text/html" in resp.headers["content-type"]
    assert str(pond.id) in resp.text
    assert "Blind state" in resp.text  # no logs seeded -> blind


@pytest.mark.integration
@pytest.mark.asyncio(loop_scope="session")
async def test_whatif_lower_do_increases_risk_delta(
    db_session: AsyncSession, db_client: AsyncClient
) -> None:
    pond = await _seed_pond(db_session)
    await _seed_recent_log(db_session, pond)
    headers = _admin_headers()

    resp = await db_client.post(
        f"/v1/twin/{pond.id}/whatif",
        json={"delta_dissolved_oxygen_mgl": -5.0},
        headers=headers,
    )
    assert resp.status_code == 200, resp.text
    body = resp.json()
    assert body["pond_id"] == str(pond.id)
    assert body["simulated_state"]["dissolved_oxygen_mgl"] == pytest.approx(1.1, abs=0.01)
    # A large DO drop should never look safer than the baseline.
    assert body["risk_delta"] >= 0


@pytest.mark.integration
@pytest.mark.asyncio(loop_scope="session")
async def test_whatif_no_scenario_deltas_yields_zero_risk_delta(
    db_session: AsyncSession, db_client: AsyncClient
) -> None:
    pond = await _seed_pond(db_session)
    await _seed_recent_log(db_session, pond)
    headers = _admin_headers()

    resp = await db_client.post(f"/v1/twin/{pond.id}/whatif", json={}, headers=headers)
    assert resp.status_code == 200, resp.text
    assert resp.json()["risk_delta"] == 0.0


@pytest.mark.integration
@pytest.mark.asyncio(loop_scope="session")
async def test_whatif_unknown_pond_returns_404(db_client: AsyncClient) -> None:
    resp = await db_client.post(f"/v1/twin/{uuid4()}/whatif", json={}, headers=_admin_headers())
    assert resp.status_code == 404


@pytest.mark.integration
@pytest.mark.asyncio(loop_scope="session")
async def test_farmer_cannot_view_twin_outside_pond_scope(
    db_session: AsyncSession, db_client: AsyncClient
) -> None:
    pond = await _seed_pond(db_session)
    farmer_token = create_access_token(sub=str(uuid4()), role="farmer", pond_ids=[])
    resp = await db_client.get(
        f"/v1/twin/{pond.id}/state", headers={"Authorization": f"Bearer {farmer_token}"}
    )
    assert resp.status_code == 403


@pytest.mark.integration
@pytest.mark.asyncio(loop_scope="session")
async def test_whatif_delta_out_of_bounds_rejected(
    db_session: AsyncSession, db_client: AsyncClient
) -> None:
    pond = await _seed_pond(db_session)
    resp = await db_client.post(
        f"/v1/twin/{pond.id}/whatif",
        json={"delta_dissolved_oxygen_mgl": -999.0},
        headers=_admin_headers(),
    )
    assert resp.status_code == 422
