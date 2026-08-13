"""
Point-in-time-correct materialised views under the features schema.
No Feast — these are PostgreSQL materialised views with TimescaleDB continuous aggregates.
"""

from __future__ import annotations

from typing import TYPE_CHECKING

import structlog
from sqlalchemy import text

if TYPE_CHECKING:
    from sqlalchemy.ext.asyncio import AsyncSession

log = structlog.get_logger(__name__)

CREATE_DAILY_FEATURES_MV_SQL = """
CREATE MATERIALIZED VIEW IF NOT EXISTS features.daily_features_mv AS
SELECT
    dwq.pond_id,
    dwq.bucket AS day,
    p.district,
    p.species,
    dwq.avg_temp,
    dwq.min_temp,
    dwq.max_temp,
    dwq.avg_do,
    dwq.min_do,
    dwq.max_do,
    dwq.avg_ph,
    dwq.avg_salinity,
    dwq.avg_ammonia,
    dwq.avg_turbidity
FROM daily_water_quality dwq
JOIN ponds p ON p.id = dwq.pond_id;
"""

CREATE_DAILY_FEATURES_MV_INDEX_SQL = """
CREATE UNIQUE INDEX IF NOT EXISTS idx_daily_features_mv_pond_day
ON features.daily_features_mv (pond_id, day);
"""


async def refresh_features_views(db: AsyncSession) -> None:
    """
    Refresh the features.daily_features_mv materialized view.
    Usually called by an ARQ background cron job or upon new log ingestion batch.
    """
    log.info("features.refresh_views.started")
    try:
        await db.execute(text("REFRESH MATERIALIZED VIEW CONCURRENTLY features.daily_features_mv"))
        await db.commit()
        log.info("features.refresh_views.completed")
    except Exception as e:
        log.error("features.refresh_views.failed", error=str(e))
        await db.rollback()
        raise
