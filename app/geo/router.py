"""Geo — router for /v1/geo (P2.3)."""

from __future__ import annotations

import json
import math
from datetime import timedelta
from typing import Any
from uuid import UUID

from fastapi import APIRouter, HTTPException, Query, status
from geoalchemy2 import Geography
from geoalchemy2.functions import ST_X, ST_Y, ST_AsGeoJSON, ST_DWithin, ST_MakePoint, ST_SetSRID
from sqlalchemy import Select, cast, select

from app.core import rbac
from app.core.timezones import utcnow
from app.db.models.alert import Alert
from app.db.models.pond import Pond
from app.deps import CurrentUser, DbSession
from app.geo import clustering
from app.ml_inference.router import _compute_pond_risk

router = APIRouter(prefix="/geo", tags=["Geo"])

# GET /v1/geo/ponds computes a fresh risk score per pond in-process (same
# "does not scale to a large ward/district" caveat as GET /v1/risk/worklist
# in ml_inference/router.py). Hard-capped rather than left unbounded.
MAX_GEO_PONDS = 200


def _scope_pond_query(user: CurrentUser, district: str | None) -> Select[tuple[Pond]] | None:
    """Same scoping rule as GET /v1/ponds (ml_inference/router.py):
    farmer -> own ponds; staff -> own district (or an explicit district,
    validated); admin -> unrestricted, or filtered to `district`.
    Returns None for "no rows" (fail closed) rather than an unscoped query.
    """
    stmt = select(Pond).where(Pond.geom.isnot(None))

    if user.role == "admin":
        if district is not None:
            stmt = stmt.where(Pond.district == district)
        return stmt
    if user.role == "staff":
        if district is not None:
            rbac.require_district(user.district, district, user.role)
            return stmt.where(Pond.district == district)
        if user.district is None:
            return None
        return stmt.where(Pond.district == user.district)
    # farmer
    try:
        owner_id = UUID(user.sub)
    except ValueError as exc:
        raise HTTPException(
            status_code=400, detail="Token 'sub' claim is not a valid UUID."
        ) from exc
    return stmt.where(Pond.owner_user_id == owner_id)


@router.get(
    "/ponds",
    summary="GeoJSON FeatureCollection of all accessible ponds",
    description=(
        "Returns a GeoJSON FeatureCollection. Properties include risk_score and suppressed flag. "
        "Ponds with no recorded location (Pond.geom) are omitted — never plotted with a fabricated "
        "coordinate. Spatial queries use real PostGIS ST_DWithin (geography cast, so within_km is "
        "an accurate great-circle distance, not a planar approximation)."
    ),
)
async def geo_ponds(
    user: CurrentUser,
    session: DbSession,
    district: str | None = Query(default=None),
    risk_level: str | None = Query(default=None),
    within_km: float | None = Query(
        default=None,
        description="Filter ponds within this many km of a given point (requires lat/lon params)",
    ),
    lat: float | None = Query(default=None, ge=-90, le=90),
    lon: float | None = Query(default=None, ge=-180, le=180),
) -> dict[str, Any]:
    if within_km is not None and (lat is None or lon is None):
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="within_km requires both lat and lon.",
        )

    stmt = _scope_pond_query(user, district)
    if stmt is None:
        return {"type": "FeatureCollection", "features": []}

    if within_km is not None and lat is not None and lon is not None:
        point = ST_SetSRID(ST_MakePoint(lon, lat), 4326)
        stmt = stmt.where(
            ST_DWithin(cast(Pond.geom, Geography), cast(point, Geography), within_km * 1000)
        )

    stmt = stmt.add_columns(ST_AsGeoJSON(Pond.geom).label("geom_json")).limit(MAX_GEO_PONDS)
    rows = (await session.execute(stmt)).all()

    now = utcnow()
    features: list[dict[str, Any]] = []
    for pond, geom_json in rows:
        computation = await _compute_pond_risk(session, pond, now)
        risk = computation.risk_out
        if risk_level is not None and risk.risk_level != risk_level:
            continue
        features.append(
            {
                "type": "Feature",
                "id": str(pond.id),
                "geometry": json.loads(geom_json),
                "properties": {
                    "pond_name": pond.name,
                    "district": pond.district,
                    "species": pond.species,
                    "risk_score": risk.risk_score,
                    "risk_level": risk.risk_level,
                    "suppressed": risk.suppressed,
                    "suppression_reason": risk.suppression_reason,
                },
            }
        )

    return {"type": "FeatureCollection", "features": features}


def _circle_polygon_geojson(
    centroid_lat: float, centroid_lon: float, radius_km: float, n_vertices: int = 24
) -> dict[str, Any]:
    """Approximate circular buffer around a cluster centroid, for display.

    A real bounding shape would be the alert points' convex hull, but two
    or three points produce a degenerate hull (a line or a sliver
    triangle) that renders misleadingly on a map. A circle sized to the
    cluster's own real radius_km (the max real distance from centroid to
    a member pond, computed in clustering.py) is a documented, honest
    approximation of cluster extent — not a fabricated exact boundary.
    Guarantees a real Polygon even for a 2-pond cluster.
    """
    # Small radius floor so a near-zero-distance cluster (ponds almost on
    # top of each other) still renders a visible polygon, not a point.
    radius_km = max(radius_km, 0.2)
    lat_rad = math.radians(centroid_lat)
    km_per_deg_lat = 110.574
    km_per_deg_lon = 111.320 * math.cos(lat_rad)

    coords = []
    for i in range(n_vertices + 1):  # +1 to close the ring
        angle = 2 * math.pi * i / n_vertices
        dlat = (radius_km / km_per_deg_lat) * math.sin(angle)
        dlon = (radius_km / km_per_deg_lon) * math.cos(angle) if km_per_deg_lon else 0.0
        coords.append([round(centroid_lon + dlon, 6), round(centroid_lat + dlat, 6)])

    return {"type": "Polygon", "coordinates": [coords]}


@router.get(
    "/clusters",
    summary="Spatial outbreak clusters",
    description=(
        "Detects spatial clusters of ponds with a recent alert using DBSCAN (real, standard "
        "density-based clustering — see app/geo/clustering.py's module docstring for why this is "
        "not literally the space-time scan statistic (SaTScan) the original spec named, and why no "
        "p_value is returned). Each cluster includes an approximate circular bounding polygon and "
        "the affected pond IDs."
    ),
)
async def geo_clusters(
    user: CurrentUser,
    session: DbSession,
    district: str | None = Query(default=None),
    days_back: int = Query(default=30, ge=1, le=365),
) -> dict[str, Any]:
    pond_stmt = _scope_pond_query(user, district)
    if pond_stmt is None:
        return {"type": "FeatureCollection", "generated_at": utcnow().isoformat(), "features": []}

    now = utcnow()
    since = now - timedelta(days=days_back)

    pond_subq = pond_stmt.subquery()
    scoped_pond_ids = select(pond_subq.c.id)

    # One row per pond: its single most recent alert in the window. A
    # spatial cluster is about *which ponds* are affected, not how many
    # times each one alerted.
    latest_alert_stmt = (
        select(
            Alert.pond_id,
            Alert.alert_type,
            Alert.created_at,
            ST_Y(Pond.geom).label("lat"),
            ST_X(Pond.geom).label("lon"),
        )
        .join(Pond, Pond.id == Alert.pond_id)
        .where(Alert.pond_id.in_(scoped_pond_ids), Alert.created_at >= since)
        .distinct(Alert.pond_id)
        .order_by(Alert.pond_id, Alert.created_at.desc())
    )
    rows = (await session.execute(latest_alert_stmt)).all()

    points = [
        clustering.AlertPoint(
            pond_id=pond_id,
            lat=float(lat),
            lon=float(lon),
            alert_type=alert_type,
            created_at=created_at,
        )
        for pond_id, alert_type, created_at, lat, lon in rows
    ]
    clusters = clustering.detect_clusters(points)

    features = [
        {
            "type": "Feature",
            "geometry": _circle_polygon_geojson(c.centroid_lat, c.centroid_lon, c.radius_km),
            "properties": {
                "cluster_id": str(c.cluster_id),
                "pond_count": c.pond_count,
                "pond_ids": [str(pid) for pid in c.pond_ids],
                "dominant_risk": c.dominant_risk,
                "start_date": c.start_date.isoformat(),
                "radius_km": c.radius_km,
            },
        }
        for c in clusters
    ]

    return {"type": "FeatureCollection", "generated_at": now.isoformat(), "features": features}
