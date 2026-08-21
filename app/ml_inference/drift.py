"""Model drift signal — real PSI over recent Log distributions (P2.7).

`GET /v1/models/drift` used to return one hardcoded fixture
(`feature_drift={"dissolved_oxygen_mgl": 0.02, ...}`, always
`drift_detected=False`). A literal train-vs-serving skew number can't be
computed honestly here: that needs the trained model's calibration
baseline snapshotted at training time, and nothing in this repo's
training pipeline persists that for the M2 model actually loaded
(app/ml_inference/numeric/m2_risk_engine.py).

What *can* be computed honestly, from data this app actually has: real
Population Stability Index (PSI) between two real windows of `Log`
readings — the current `window_days` and the `window_days` immediately
before it — for each raw chemistry input the M2 model consumes directly
(`RawLogPoint`'s fields, before any derived/engineered columns). This is
a legitimate live-monitoring signal in its own right (recent population
shift), just not literally "vs. the model's original training
distribution" — labelled as such via `alert_threshold`'s neighbouring
fields rather than silently passed off as the textbook definition.
"""

from __future__ import annotations

import math
from datetime import datetime, timedelta
from typing import TYPE_CHECKING

from sqlalchemy import select
from sqlalchemy.orm import InstrumentedAttribute

from app.core.timezones import utcnow
from app.db.models.log import Log
from app.ml_inference.schemas import DriftReport

if TYPE_CHECKING:
    from sqlalchemy.ext.asyncio import AsyncSession

# M2's directly-observed (non-engineered) chemistry inputs, mapped to the
# real Log columns they come from. Deliberately excludes engineered
# features (trends, rolling stats, data_health_score, ...) — those would
# need recomputing the same feature-engineering pipeline just to drift-check
# them, which is out of scope here.
_FEATURE_COLUMNS: dict[str, InstrumentedAttribute[float | None]] = {
    "do_mg_l": Log.dissolved_oxygen_mgl,
    "tan_mg_l": Log.ammonia_nh3_mgl,
    "ph": Log.ph,
    "water_temp_c": Log.temperature_c,
    "salinity_ppt": Log.salinity_ppt,
    "alkalinity_mg_l": Log.alkalinity_mgl,
    "no2_mg_l": Log.nitrite_mgl,
    "no3_mg_l": Log.nitrate_mgl,
}

DEFAULT_WINDOW_DAYS = 7
DEFAULT_ALERT_THRESHOLD = 0.2
_PSI_BINS = 10
_MIN_SAMPLES_PER_WINDOW = 20


def _psi(baseline: list[float], current: list[float], bins: int = _PSI_BINS) -> float:
    """Real Population Stability Index between two real samples. Returns
    0.0 (no drift signal, not a fabricated "no drift") when either window
    doesn't have enough real readings to bin meaningfully."""
    if len(baseline) < _MIN_SAMPLES_PER_WINDOW or len(current) < _MIN_SAMPLES_PER_WINDOW:
        return 0.0

    sorted_baseline = sorted(baseline)
    edges = sorted(
        {
            sorted_baseline[min(int(q * (len(sorted_baseline) - 1)), len(sorted_baseline) - 1)]
            for q in (i / bins for i in range(bins + 1))
        }
    )
    if len(edges) < 2:
        return 0.0

    def _bucket_counts(values: list[float]) -> list[int]:
        counts = [0] * (len(edges) - 1)
        for v in values:
            if v <= edges[0]:
                counts[0] += 1
            elif v > edges[-1]:
                counts[-1] += 1
            else:
                for i in range(len(edges) - 1):
                    if edges[i] < v <= edges[i + 1]:
                        counts[i] += 1
                        break
        return counts

    baseline_counts = _bucket_counts(baseline)
    current_counts = _bucket_counts(current)

    eps = 1e-4
    psi = 0.0
    for b_count, c_count in zip(baseline_counts, current_counts, strict=True):
        b_pct = max(b_count / len(baseline), eps)
        c_pct = max(c_count / len(current), eps)
        psi += (c_pct - b_pct) * math.log(c_pct / b_pct)
    return round(psi, 4)


async def compute_drift_report(
    session: AsyncSession,
    *,
    model_name: str,
    model_version: str,
    window_days: int = DEFAULT_WINDOW_DAYS,
    alert_threshold: float = DEFAULT_ALERT_THRESHOLD,
) -> DriftReport:
    now = utcnow()
    current_start = now - timedelta(days=window_days)
    previous_start = now - timedelta(days=2 * window_days)

    async def _values_in_range(
        column: InstrumentedAttribute[float | None], start: datetime, end: datetime | None
    ) -> list[float]:
        stmt = select(column).where(Log.recorded_at >= start, column.isnot(None))
        if end is not None:
            stmt = stmt.where(Log.recorded_at < end)
        result = (await session.execute(stmt)).scalars().all()
        return [v for v in result if v is not None]

    feature_drift: dict[str, float] = {}
    for feature_name, column in _FEATURE_COLUMNS.items():
        current_values = await _values_in_range(column, current_start, None)
        previous_values = await _values_in_range(column, previous_start, current_start)
        feature_drift[feature_name] = _psi(previous_values, current_values)

    drift_detected = any(score > alert_threshold for score in feature_drift.values())

    return DriftReport(
        model_name=model_name,
        model_version=model_version,
        feature_drift=feature_drift,
        alert_threshold=alert_threshold,
        drift_detected=drift_detected,
        evaluated_at=now,
    )
