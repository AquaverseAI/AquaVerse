"""
Feature store interface — point-in-time-correct reads.

Provides helpers to perform point-in-time-correct features lookup
to prevent data leakage during ML model training.
"""

from __future__ import annotations

import json
from datetime import datetime
from typing import TYPE_CHECKING, Any
from uuid import UUID

import structlog
from sqlalchemy import text

if TYPE_CHECKING:
    from sqlalchemy.ext.asyncio import AsyncSession

log = structlog.get_logger(__name__)


async def get_historical_features(
    db: AsyncSession,
    entities: list[dict[str, Any]],
) -> list[dict[str, Any]]:
    """
    Perform a point-in-time correct join for a batch of entities.

    Args:
        db: The async database session.
        entities: A list of dicts, each containing:
            - 'pond_id': UUID or str
            - 'timestamp': datetime (timezone-aware)

    Returns:
        A list of dicts containing the entity keys plus the closest historical features
        that were recorded at or before the given 'timestamp'.
    """
    if not entities:
        return []

    # Normalize UUIDs and datetime objects to ISO strings for JSON serialization
    serialized_entities = []
    for ent in entities:
        pond_id = ent["pond_id"]
        ts = ent["timestamp"]

        pond_id_str = str(pond_id) if isinstance(pond_id, UUID) else pond_id

        ts_str = ts.isoformat() if isinstance(ts, datetime) else ts

        serialized_entities.append({"pond_id": pond_id_str, "timestamp": ts_str})

    # NB: use CAST(... AS jsonb), not `:entities_json::jsonb` — SQLAlchemy's
    # text() bind-param regex requires a non-colon character immediately
    # after the param name, so a trailing `::cast` makes it backtrack and
    # swallow the name's last character into the (then-literal) SQL text,
    # silently registering a bind param one character short of the one
    # passed to execute() below and producing a Postgres syntax error.
    query = text("""
        SELECT
            e.pond_id,
            e.timestamp AS event_time,
            l.temperature_c,
            l.dissolved_oxygen_mgl,
            l.ph,
            l.salinity_ppt,
            l.ammonia_nh3_mgl,
            l.turbidity_ntu,
            l.recorded_at AS feature_time
        FROM jsonb_to_recordset(CAST(:entities_json AS jsonb)) AS e(pond_id uuid, timestamp timestamptz)
        LEFT JOIN LATERAL (
            SELECT
                temperature_c,
                dissolved_oxygen_mgl,
                ph,
                salinity_ppt,
                ammonia_nh3_mgl,
                turbidity_ntu,
                recorded_at
            FROM logs
            WHERE pond_id = e.pond_id
              AND recorded_at <= e.timestamp
            ORDER BY recorded_at DESC
            LIMIT 1
        ) l ON TRUE;
    """)

    log.debug("features.get_historical_features.executing", batch_size=len(entities))

    result = await db.execute(query, {"entities_json": json.dumps(serialized_entities)})
    rows = result.fetchall()

    return [
        {
            "pond_id": row.pond_id,
            "event_time": row.event_time,
            "temperature_c": row.temperature_c,
            "dissolved_oxygen_mgl": row.dissolved_oxygen_mgl,
            "ph": row.ph,
            "salinity_ppt": row.salinity_ppt,
            "ammonia_nh3_mgl": row.ammonia_nh3_mgl,
            "turbidity_ntu": row.turbidity_ntu,
            "feature_time": row.feature_time,
        }
        for row in rows
    ]
