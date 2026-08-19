"""
Dissolved-oxygen forecast — real empirical baseline (P1.4).

`GET /v1/ponds/{id}/forecast/do` used to return `p10=5.2-i*0.05,
p50=6.0-i*0.04, p90=6.8-i*0.03` — pure linear-decay arithmetic wearing a
fictional `model_version="patchtst-v0.3.1"` label. There is no trained
temporal model (TCN/TFT/PatchTST or otherwise) anywhere in this repo for DO
forecasting — unlike M2 risk scoring (`m2_risk_engine.py`), there is no
`.txt` booster to load here. Full model training is out of scope for this
change.

What this module does instead, honestly: a **seasonal-naive / empirical-
quantile baseline**, a standard forecasting technique, not a placeholder
pretending to be a trained model. DO in aquaculture ponds has a strong
diurnal cycle (photosynthesis raises it by day, respiration drops it
overnight), so "what has this pond's DO actually looked like at 3am
historically" is a real, meaningful predictor of "what will it look like at
3am tomorrow" — much more so than a flat/global average, and certainly more
than the old linear-decay fixture.

Algorithm
---------
1. Bucket the pond's real historical (non-null) `dissolved_oxygen_mgl`
   readings by hour-of-day (`recorded_at.hour`, 0-23).
2. For each requested future timestamp, use its hour-of-day bucket's real
   p10/p50/p90 (`numpy.percentile`) if that bucket has >= `MIN_BUCKET_SAMPLES`
   readings.
3. If the specific hour-of-day bucket is too small, fall back to the pooled
   all-hours empirical distribution for this pond (still real data, just
   less time-specific).
4. If the pond has fewer than `MIN_BUCKET_SAMPLES` DO readings in total
   (including zero), fall back to a documented default band centered on
   `sim.species.get_species(key).do_stress_threshold_mg_l` plus a fixed
   healthy margin (see `_species_default_band` below) — the same "reuse a
   real cited constant, document the gap honestly" convention used
   throughout `m2_risk_engine.py`. This is tracked and surfaced via
   `ForecastResult.used_species_default_fallback` so the caller can put it
   in `ForecastOut.uncertainty_note` rather than burying it.
5. p10 <= p50 <= p90 is enforced by construction (`numpy.percentile` on a
   sorted-by-value array cannot produce an out-of-order triple by itself,
   but a bucket with very few samples plus floating point could in
   principle tie/round oddly at the boundary — sorted() defensively here
   documents the invariant rather than trusting percentile silently).
"""

from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime

import numpy as np

from app.ml_inference.numeric.m3_engine import _ensure_engine_dir_on_path

MODEL_VERSION = "empirical-do-quantile-baseline-v1"

# Minimum samples in a bucket before its own empirical quantiles are
# trusted. Below this, numpy.percentile on 1-2 points is not a meaningful
# distribution — fall back to a broader (but still real) pool.
MIN_BUCKET_SAMPLES = 3

# Documented healthy margin above a species' DO stress threshold, used only
# for the final species-default fallback (zero/near-zero real DO history
# for this pond). Not a cited literature value like
# `do_stress_threshold_mg_l` itself — a simple, documented band width
# (+/- this many mg/L) wide enough to signal "we genuinely don't know",
# not a tight, false-precision range.
SPECIES_DEFAULT_MARGIN_MG_L = 1.5
SPECIES_DEFAULT_HALF_SPREAD_MG_L = 1.0

UNCERTAINTY_NOTE_BASELINE = (
    "Baseline forecast — p10/p50/p90 are this pond's own historical DO readings "
    "at each target hour-of-day, not a trained temporal model (no TCN/TFT/PatchTST "
    "exists in this repo). Treat as a naive seasonal reference, not a validated "
    "prediction."
)
UNCERTAINTY_NOTE_SPECIES_DEFAULT_SUFFIX = (
    " This pond has no usable historical DO data, so at least one point below falls "
    "back to a species-default band (do_stress_threshold_mg_l + a documented margin, "
    "see app/ml_inference/numeric/do_forecast.py) rather than real readings — treat "
    "those points as even less certain than the baseline note above already implies."
)


@dataclass(frozen=True)
class DoBand:
    p10: float
    p50: float
    p90: float


@dataclass(frozen=True)
class ForecastResult:
    bands_by_timestamp: list[tuple[datetime, DoBand]]
    used_species_default_fallback: bool
    model_version: str
    uncertainty_note: str


def _sorted_band(p10: float, p50: float, p90: float) -> DoBand:
    """Enforce p10 <= p50 <= p90 by construction. `numpy.percentile` on a
    real array cannot itself produce an out-of-order triple, but this is
    cheap insurance against a pathological few-sample bucket and documents
    the invariant explicitly rather than trusting it silently.
    """
    lo, mid, hi = sorted((p10, p50, p90))
    return DoBand(p10=lo, p50=mid, p90=hi)


def _species_default_band(species_key: str) -> DoBand:
    """Documented fallback when a pond has no usable real DO history at
    all. Centered `SPECIES_DEFAULT_MARGIN_MG_L` above the species' real,
    literature-sourced `do_stress_threshold_mg_l` (ml/serving/m3/sim/species.py)
    — i.e. a "healthy, comfortably above stress" reference point, not a
    fabricated number. The +/- spread around that center is an authored,
    documented band width (not a cited constant) sized to signal genuine
    uncertainty rather than false precision.
    """
    _ensure_engine_dir_on_path()
    from sim.species import get_species  # type: ignore[import-not-found]

    sp = get_species(species_key)
    center = sp.do_stress_threshold_mg_l + SPECIES_DEFAULT_MARGIN_MG_L
    return _sorted_band(
        center - SPECIES_DEFAULT_HALF_SPREAD_MG_L,
        center,
        center + SPECIES_DEFAULT_HALF_SPREAD_MG_L,
    )


def _quantile_band(values: list[float]) -> DoBand:
    arr = np.asarray(values, dtype=float)
    p10, p50, p90 = np.percentile(arr, [10, 50, 90])
    return _sorted_band(float(p10), float(p50), float(p90))


def build_do_forecast(
    historical_readings: list[tuple[datetime, float]],
    target_timestamps: list[datetime],
    species_key: str,
) -> ForecastResult:
    """Build an empirical-quantile DO forecast for one pond.

    `historical_readings`: real `(recorded_at, dissolved_oxygen_mgl)` pairs
    for the pond, non-null values only, any lookback window (the caller —
    `router.py` — decides how far back to query).
    `target_timestamps`: the future timestamps to forecast for
    (`now + 1h ... now + horizon_hours`).
    `species_key`: resolved via the same `m2_risk_engine.resolve_species_key`
    mapping the caller already uses for risk scoring, so this module stays
    in sync with that convention rather than inventing a second one.
    """
    by_hour: dict[int, list[float]] = {h: [] for h in range(24)}
    pooled: list[float] = []
    for recorded_at, value in historical_readings:
        by_hour[recorded_at.hour].append(value)
        pooled.append(value)

    used_species_default = len(pooled) < MIN_BUCKET_SAMPLES
    species_default_band = _species_default_band(species_key) if used_species_default else None
    pooled_band = _quantile_band(pooled) if not used_species_default else None

    bands_by_timestamp: list[tuple[datetime, DoBand]] = []
    for ts in target_timestamps:
        if used_species_default:
            band = species_default_band
        else:
            bucket = by_hour[ts.hour]
            band = _quantile_band(bucket) if len(bucket) >= MIN_BUCKET_SAMPLES else pooled_band
        assert band is not None
        bands_by_timestamp.append((ts, band))

    note = UNCERTAINTY_NOTE_BASELINE
    if used_species_default:
        note += UNCERTAINTY_NOTE_SPECIES_DEFAULT_SUFFIX

    return ForecastResult(
        bands_by_timestamp=bands_by_timestamp,
        used_species_default_fallback=used_species_default,
        model_version=MODEL_VERSION,
        uncertainty_note=note,
    )
