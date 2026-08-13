"""
Integration tests for the point-in-time-correct features store.

Requires a running database (run via testcontainers).
"""

from __future__ import annotations

from datetime import UTC, datetime, timedelta
from typing import TYPE_CHECKING
from uuid import uuid4

import pytest

from app.db.models.log import Log
from app.db.models.pond import Pond
from app.features.store import get_historical_features

if TYPE_CHECKING:
    from sqlalchemy.ext.asyncio import AsyncSession


@pytest.mark.integration
@pytest.mark.asyncio
async def test_get_historical_features_point_in_time(db_session: AsyncSession) -> None:
    # 1. Create a pond
    pond_id = uuid4()
    owner_id = uuid4()

    pond = Pond(
        id=pond_id,
        owner_user_id=owner_id,
        name="Test Feature Pond",
        district="Nagapattinam",
    )
    db_session.add(pond)
    await db_session.commit()

    # 2. Add logs at different timestamps
    # Log 1: T-2 hours (temp=25.0)
    # Log 2: T-1 hour (temp=27.5)
    # Log 3: T+1 hour (temp=30.0) -> future log relative to event
    t_base = datetime.now(UTC).replace(microsecond=0)

    log1 = Log(
        id=uuid4(),
        pond_id=pond_id,
        recorded_by=owner_id,
        recorded_at=t_base - timedelta(hours=2),
        temperature_c=25.0,
        source="sensor",
    )
    log2 = Log(
        id=uuid4(),
        pond_id=pond_id,
        recorded_by=owner_id,
        recorded_at=t_base - timedelta(hours=1),
        temperature_c=27.5,
        source="sensor",
    )
    log3 = Log(
        id=uuid4(),
        pond_id=pond_id,
        recorded_by=owner_id,
        recorded_at=t_base + timedelta(hours=1),
        temperature_c=30.0,
        source="sensor",
    )

    db_session.add_all([log1, log2, log3])
    await db_session.commit()

    # 3. Query historical features at t_base (T-0)
    # The expected result is Log 2 (temp=27.5) because it is the latest log before/at t_base.
    # Log 3 is in the future, Log 1 is older.
    entities = [{"pond_id": pond_id, "timestamp": t_base}]

    features = await get_historical_features(db_session, entities)

    assert len(features) == 1
    feat = features[0]
    assert feat["pond_id"] == pond_id
    assert feat["temperature_c"] == 27.5
    assert feat["feature_time"] == t_base - timedelta(hours=1)
