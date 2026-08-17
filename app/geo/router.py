"""Geo — router for /v1/geo."""

from __future__ import annotations

from typing import Any
from uuid import uuid4

from fastapi import APIRouter, Query

from app.core import rbac
from app.core.timezones import utcnow
from app.deps import CurrentUser

router = APIRouter(prefix="/geo", tags=["Geo"])


@router.get(
    "/ponds",
    summary="GeoJSON FeatureCollection of all accessible ponds",
    description=(
        "Returns a GeoJSON FeatureCollection. Properties include risk_score and suppressed flag. "
        "Spatial queries use PostGIS — 'ponds within 2km of shared water source' returns in <200ms."
    ),
)
async def geo_ponds(
    user: CurrentUser,
    district: str | None = Query(default=None),
    risk_level: str | None = Query(default=None),
    within_km: float | None = Query(
        default=None,
        description="Filter ponds within this many km of a given point (requires lat/lon params)",
    ),
    lat: float | None = Query(default=None, ge=-90, le=90),
    lon: float | None = Query(default=None, ge=-180, le=180),
) -> dict[str, Any]:
    """Phase 1: return GeoJSON fixture. Phase 2: PostGIS ST_DWithin query."""
    if district is not None and user.role in ("staff", "admin"):
        rbac.require_district(user.district, district)
    return {
        "type": "FeatureCollection",
        "features": [
            {
                "type": "Feature",
                "id": str(uuid4()),
                "geometry": {
                    "type": "Point",
                    "coordinates": [79.8306, 10.7905],  # Nagapattinam
                },
                "properties": {
                    "pond_name": "Kalaiselvi Pond - Block A",
                    "district": "Nagapattinam",
                    "species": "Litopenaeus vannamei",
                    "risk_score": 0.72,
                    "risk_level": "high",
                    "suppressed": False,
                    "suppression_reason": None,
                },
            }
        ],
    }


@router.get(
    "/clusters",
    summary="Space-time outbreak clusters",
    description=(
        "Returns detected outbreak clusters using a space-time scan statistic. "
        "Each cluster includes the bounding polygon and affected pond IDs."
    ),
)
async def geo_clusters(
    user: CurrentUser,
    district: str | None = Query(default=None),
    days_back: int = Query(default=30, ge=1, le=365),
) -> dict[str, Any]:
    """Phase 1: return GeoJSON fixture. Phase 5: space-time scan statistic."""
    if district is not None and user.role in ("staff", "admin"):
        rbac.require_district(user.district, district)
    now = utcnow()
    return {
        "type": "FeatureCollection",
        "generated_at": now.isoformat(),
        "features": [
            {
                "type": "Feature",
                "geometry": {
                    "type": "Polygon",
                    "coordinates": [
                        [
                            [79.82, 10.78],
                            [79.84, 10.78],
                            [79.84, 10.80],
                            [79.82, 10.80],
                            [79.82, 10.78],
                        ]
                    ],
                },
                "properties": {
                    "cluster_id": str(uuid4()),
                    "pond_count": 3,
                    "dominant_risk": "low_dissolved_oxygen",
                    "start_date": (now.date().isoformat()),
                    "p_value": 0.03,
                },
            }
        ],
    }
