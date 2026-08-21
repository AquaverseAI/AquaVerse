"""Integration tests — real Geo domain (P2.3).

`GET /v1/geo/ponds` and `GET /v1/geo/clusters` used to return one fixed
GeoJSON fixture regardless of input. This exercises the real path: real
PostGIS ST_DWithin spatial filtering over real Pond.geom, and real DBSCAN
spatial clustering (app/geo/clustering.py) over ponds with a recent Alert.
"""

from __future__ import annotations

from datetime import UTC, datetime, timedelta
from typing import TYPE_CHECKING
from uuid import uuid4

import pytest
from geoalchemy2.elements import WKTElement

from app.core.security import create_access_token
from app.db.models.alert import Alert
from app.db.models.pond import Pond

if TYPE_CHECKING:
    from httpx import AsyncClient
    from sqlalchemy.ext.asyncio import AsyncSession

# Real Nagapattinam-district coordinates, close enough together (~1.2km)
# to fall inside DEFAULT_EPS_KM / a small within_km filter.
POND_A_LATLON = (10.7905, 79.8306)
POND_B_LATLON = (10.8000, 79.8306)
# Far away — different district's worth of distance, should never cluster
# or match a tight within_km filter with A/B.
POND_FAR_LATLON = (12.0, 80.5)


def _admin_headers() -> dict[str, str]:
    token = create_access_token(sub=str(uuid4()), role="admin")
    return {"Authorization": f"Bearer {token}"}


async def _seed_pond(
    db_session: AsyncSession,
    *,
    lat: float | None,
    lon: float | None,
    district: str = "Nagapattinam",
    name: str = "Geo Test Pond",
) -> Pond:
    pond = Pond(
        id=uuid4(),
        owner_user_id=uuid4(),
        name=name,
        district=district,
        species="Litopenaeus vannamei",
        geom=WKTElement(f"POINT({lon} {lat})", srid=4326) if lat is not None else None,
    )
    db_session.add(pond)
    await db_session.commit()
    return pond


async def _seed_alert(
    db_session: AsyncSession, pond: Pond, *, alert_type: str = "low_dissolved_oxygen"
) -> Alert:
    alert = Alert(
        pond_id=pond.id,
        alert_type=alert_type,
        severity="high",
        title="test alert",
        message="test alert message",
        suppressed=False,
    )
    db_session.add(alert)
    await db_session.commit()
    return alert


@pytest.mark.integration
@pytest.mark.asyncio(loop_scope="session")
async def test_geo_ponds_omits_ponds_with_no_geom(
    db_session: AsyncSession, db_client: AsyncClient
) -> None:
    lat, lon = POND_A_LATLON
    located = await _seed_pond(db_session, lat=lat, lon=lon, name="Located Pond")
    unlocated = await _seed_pond(db_session, lat=None, lon=None, name="Unlocated Pond")

    resp = await db_client.get("/v1/geo/ponds", headers=_admin_headers())
    assert resp.status_code == 200, resp.text
    ids = {f["id"] for f in resp.json()["features"]}
    assert str(located.id) in ids
    assert str(unlocated.id) not in ids


@pytest.mark.integration
@pytest.mark.asyncio(loop_scope="session")
async def test_geo_ponds_geometry_and_risk_properties_are_real(
    db_session: AsyncSession, db_client: AsyncClient
) -> None:
    lat, lon = POND_A_LATLON
    pond = await _seed_pond(db_session, lat=lat, lon=lon)

    resp = await db_client.get("/v1/geo/ponds", headers=_admin_headers())
    assert resp.status_code == 200, resp.text
    feature = next(f for f in resp.json()["features"] if f["id"] == str(pond.id))
    assert feature["geometry"]["type"] == "Point"
    got_lon, got_lat = feature["geometry"]["coordinates"]
    assert got_lon == pytest.approx(lon, abs=1e-4)
    assert got_lat == pytest.approx(lat, abs=1e-4)
    # No logs seeded -> real risk computation should report blind-state.
    assert feature["properties"]["suppressed"] is True
    assert feature["properties"]["risk_score"] is not None


@pytest.mark.integration
@pytest.mark.asyncio(loop_scope="session")
async def test_geo_ponds_within_km_filters_by_real_distance(
    db_session: AsyncSession, db_client: AsyncClient
) -> None:
    near = await _seed_pond(db_session, lat=POND_A_LATLON[0], lon=POND_A_LATLON[1])
    far = await _seed_pond(db_session, lat=POND_FAR_LATLON[0], lon=POND_FAR_LATLON[1])

    resp = await db_client.get(
        f"/v1/geo/ponds?within_km=5&lat={POND_A_LATLON[0]}&lon={POND_A_LATLON[1]}",
        headers=_admin_headers(),
    )
    assert resp.status_code == 200, resp.text
    ids = {f["id"] for f in resp.json()["features"]}
    assert str(near.id) in ids
    assert str(far.id) not in ids


@pytest.mark.integration
@pytest.mark.asyncio(loop_scope="session")
async def test_geo_ponds_within_km_without_latlon_rejected(db_client: AsyncClient) -> None:
    resp = await db_client.get("/v1/geo/ponds?within_km=5", headers=_admin_headers())
    assert resp.status_code == 422


@pytest.mark.integration
@pytest.mark.asyncio(loop_scope="session")
async def test_geo_clusters_groups_nearby_alerting_ponds(
    db_session: AsyncSession, db_client: AsyncClient
) -> None:
    # Integration tests share one real Postgres for the whole run and app
    # writes commit for real (no per-test rollback) — a unique district
    # scopes this test's admin query to only its own ponds, regardless of
    # what other tests left behind at the same/nearby coordinates.
    district = f"GeoClusterTest-{uuid4()}"
    pond_a = await _seed_pond(
        db_session, lat=POND_A_LATLON[0], lon=POND_A_LATLON[1], district=district
    )
    pond_b = await _seed_pond(
        db_session, lat=POND_B_LATLON[0], lon=POND_B_LATLON[1], district=district
    )
    pond_far = await _seed_pond(
        db_session, lat=POND_FAR_LATLON[0], lon=POND_FAR_LATLON[1], district=district
    )

    await _seed_alert(db_session, pond_a)
    await _seed_alert(db_session, pond_b)
    await _seed_alert(db_session, pond_far)

    resp = await db_client.get(f"/v1/geo/clusters?district={district}", headers=_admin_headers())
    assert resp.status_code == 200, resp.text
    features = resp.json()["features"]
    assert len(features) == 1
    cluster = features[0]["properties"]
    assert cluster["pond_count"] == 2
    assert set(cluster["pond_ids"]) == {str(pond_a.id), str(pond_b.id)}
    assert str(pond_far.id) not in cluster["pond_ids"]
    assert cluster["dominant_risk"] == "low_dissolved_oxygen"
    assert features[0]["geometry"]["type"] == "Polygon"


@pytest.mark.integration
@pytest.mark.asyncio(loop_scope="session")
async def test_geo_clusters_single_pond_alert_is_not_a_cluster(
    db_session: AsyncSession, db_client: AsyncClient
) -> None:
    district = f"GeoClusterTest-{uuid4()}"
    pond = await _seed_pond(
        db_session, lat=POND_A_LATLON[0], lon=POND_A_LATLON[1], district=district
    )
    await _seed_alert(db_session, pond)

    resp = await db_client.get(f"/v1/geo/clusters?district={district}", headers=_admin_headers())
    assert resp.status_code == 200, resp.text
    assert resp.json()["features"] == []


@pytest.mark.integration
@pytest.mark.asyncio(loop_scope="session")
async def test_geo_clusters_respects_days_back_window(
    db_session: AsyncSession, db_client: AsyncClient
) -> None:
    district = f"GeoClusterTest-{uuid4()}"
    pond_a = await _seed_pond(
        db_session, lat=POND_A_LATLON[0], lon=POND_A_LATLON[1], district=district
    )
    pond_b = await _seed_pond(
        db_session, lat=POND_B_LATLON[0], lon=POND_B_LATLON[1], district=district
    )

    old_alert = Alert(
        pond_id=pond_a.id,
        alert_type="low_dissolved_oxygen",
        severity="high",
        title="old",
        message="old alert message",
        suppressed=False,
    )
    db_session.add(old_alert)
    await db_session.commit()
    # Backdate outside the default 30-day window directly via SQL update
    # (Alert.created_at has a server_default; ORM assignment before flush
    # would be overwritten).
    from sqlalchemy import update

    await db_session.execute(
        update(Alert)
        .where(Alert.id == old_alert.id)
        .values(created_at=datetime.now(UTC) - timedelta(days=60))
    )
    await db_session.commit()

    await _seed_alert(db_session, pond_b)

    resp = await db_client.get(
        f"/v1/geo/clusters?days_back=30&district={district}", headers=_admin_headers()
    )
    assert resp.status_code == 200, resp.text
    # Only pond_b's alert is within the window -> below MIN_POND_COUNT, no cluster.
    assert resp.json()["features"] == []


@pytest.mark.integration
@pytest.mark.asyncio(loop_scope="session")
async def test_farmer_only_sees_own_ponds_in_geo_ponds(
    db_session: AsyncSession, db_client: AsyncClient
) -> None:
    owner_id = uuid4()
    own_pond = Pond(
        id=uuid4(),
        owner_user_id=owner_id,
        name="Farmer's Own Pond",
        district="Nagapattinam",
        species="Litopenaeus vannamei",
        geom=WKTElement(f"POINT({POND_A_LATLON[1]} {POND_A_LATLON[0]})", srid=4326),
    )
    other_pond = Pond(
        id=uuid4(),
        owner_user_id=uuid4(),
        name="Someone Else's Pond",
        district="Nagapattinam",
        species="Litopenaeus vannamei",
        geom=WKTElement(f"POINT({POND_B_LATLON[1]} {POND_B_LATLON[0]})", srid=4326),
    )
    db_session.add_all([own_pond, other_pond])
    await db_session.commit()

    farmer_token = create_access_token(
        sub=str(owner_id), role="farmer", pond_ids=[str(own_pond.id)]
    )
    resp = await db_client.get("/v1/geo/ponds", headers={"Authorization": f"Bearer {farmer_token}"})
    assert resp.status_code == 200, resp.text
    ids = {f["id"] for f in resp.json()["features"]}
    assert ids == {str(own_pond.id)}
