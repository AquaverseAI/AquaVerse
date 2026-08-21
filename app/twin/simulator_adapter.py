"""Digital Twin simulator adapter (P2.2).

`GET /v1/twin/{id}/state` promises a schema that is "identical whether
backed by real sensors or the simulator" — the whole point of a digital
twin is that a caller gets *something* usable even when the pond is
blind-state (see `app/alerts/suppression.py`). This module wraps the
repo's own real hourly pond simulator (`ml/serving/m3/sim/simulator.py`'s
`PondSimulator`) as that fallback — the same engine the project's ML
training data was generated from (DO mass balance, N-cycle, species-
parameterized growth/mortality), not a made-up formula.

Determinism: `PondSimulator` takes an RNG seed. We derive one from the
pond's UUID via SHA-256 (not Python's built-in `hash()`, which is
per-process randomized for `str`) so the same pond always simulates the
same trajectory across requests and process restarts.

Honesty notes (same PLACEHOLDER convention used throughout
`m2_risk_engine.py`/`do_forecast.py`):
1. `biomass_kg_estimated`/`fcr_estimated` always come from this simulated
   run, real sensor data or not — there is no real biomass-telemetry or
   feed-log ingestion pipeline anywhere in this repo to measure either.
2. `turbidity_ntu` is a documented flat placeholder, NOT derived from the
   simulator's `secchi_cm` output — `do_forecast.py` already establishes
   the rule that Secchi depth and NTU turbidity are different instruments/
   units and must not be silently converted between (would be fabricating
   a formula). `ammonia_nh3_mgl` here is the simulator's `tan_mg_l` (total
   ammonia nitrogen), matching how `Log.ammonia_nh3_mgl` / the alert
   threshold in `app/alerts/rules.py` already use that field name.
3. Running a full multi-day hourly simulation per call is real work
   (~0.1s for a 50-day cycle in local testing), fine at demo scale but not
   something to call in a hot loop; days are capped at `MAX_SIMULATED_DAYS`
   for the same "does not scale to production traffic" reason already
   called out on `GET /v1/risk/worklist`.
"""

from __future__ import annotations

import hashlib
import math
from dataclasses import dataclass
from uuid import UUID

from app.ml_inference.numeric.m3_engine import _ensure_engine_dir_on_path

# Generic pond-aquaculture pH band (matches app/alerts/rules.py's
# PH_SAFE_LOW/HIGH) — only used if a run somehow yields no rows at all
# (should not happen; defensive fallback, see simulate_state below).
PH_BASELINE_LOW = 6.5
PH_BASELINE_HIGH = 9.0

# Documented placeholder — see honesty note #2. No turbidity-baseline data
# source exists; a plausible "moderately clear pond" default, not a
# measurement or a converted quantity.
TURBIDITY_BASELINE_NTU = 15.0

# See honesty note #3.
MAX_SIMULATED_DAYS = 250


def _seed_for_pond(pond_id: UUID) -> int:
    digest = hashlib.sha256(str(pond_id).encode("utf-8")).digest()
    return int.from_bytes(digest[:4], "big")


@dataclass(frozen=True)
class SimulatedState:
    temperature_c: float
    dissolved_oxygen_mgl: float
    ph: float
    salinity_ppt: float
    ammonia_nh3_mgl: float
    turbidity_ntu: float
    biomass_kg_estimated: float
    fcr_estimated: float


def simulate_state(
    pond_id: UUID,
    species_key: str,
    day_of_culture: int,
    stocking_count: int,
) -> SimulatedState:
    """Run the real `PondSimulator` from stocking through `day_of_culture`
    and return its last hour's state, deterministic per `pond_id`.
    """
    _ensure_engine_dir_on_path()
    from sim.simulator import PondSimulator, compute_running_fcr  # type: ignore[import-not-found]
    from sim.species import get_species  # type: ignore[import-not-found]

    sp = get_species(species_key)
    days = max(min(day_of_culture, MAX_SIMULATED_DAYS), 1)
    salinity_mid = float(sum(sp.salinity_range_ppt) / 2)

    sim = PondSimulator(
        species_key,
        stocking_count=max(stocking_count, 1),
        salinity_ppt=salinity_mid,
        seed=_seed_for_pond(pond_id),
    )
    df = sim.run(days=days)
    if df.empty:
        # Defensive only — PondSimulator.run() always returns >= 24 rows
        # for days >= 1; this branch should be unreachable.
        return SimulatedState(
            temperature_c=float(sum(sp.temp_optimum_c) / 2),
            dissolved_oxygen_mgl=sp.do_stress_threshold_mg_l + 1.5,
            ph=(PH_BASELINE_LOW + PH_BASELINE_HIGH) / 2,
            salinity_ppt=salinity_mid,
            ammonia_nh3_mgl=0.1,
            turbidity_ntu=TURBIDITY_BASELINE_NTU,
            biomass_kg_estimated=round(sp.stocking_weight_g * stocking_count / 1000.0, 2),
            fcr_estimated=float(sp.fcr_target),
        )

    last = df.iloc[-1]
    fcr_series = compute_running_fcr(df, sp.stocking_weight_g, max(stocking_count, 1))
    fcr_last = float(fcr_series.iloc[-1])
    if math.isnan(fcr_last) or fcr_last <= 0:  # non-finite guard
        fcr_last = float(sp.fcr_target)

    return SimulatedState(
        temperature_c=round(float(last["water_temp_c"]), 2),
        dissolved_oxygen_mgl=round(float(last["do_mg_l"]), 2),
        ph=round(float(last["ph"]), 2),
        salinity_ppt=round(float(last["salinity_ppt"]), 2),
        ammonia_nh3_mgl=round(float(last["tan_mg_l"]), 3),
        turbidity_ntu=TURBIDITY_BASELINE_NTU,
        biomass_kg_estimated=round(float(last["biomass_kg"]), 3),
        fcr_estimated=round(fcr_last, 3),
    )


def apply_scenario_deltas(
    base: SimulatedState,
    *,
    delta_temperature_c: float | None,
    delta_dissolved_oxygen_mgl: float | None,
    delta_salinity_ppt: float | None,
) -> SimulatedState:
    """Apply what-if deltas to a baseline state, clamped to physically
    sane bounds. `delta_feed_rate_pct` (on `WhatIfScenario`) deliberately
    has no effect here — there is no feed-log ingestion pipeline to
    translate a feed-rate change into a chemistry effect; that gap is
    surfaced by the caller (`app/twin/router.py`), not silently absorbed.
    Biomass/FCR are carried over unchanged — a temperature/DO/salinity
    what-if does not re-run growth; it answers "what would the chemistry
    (and downstream risk score) look like", not "how would this change
    the harvest".
    """
    return SimulatedState(
        temperature_c=round(base.temperature_c + (delta_temperature_c or 0.0), 2),
        dissolved_oxygen_mgl=round(
            max(base.dissolved_oxygen_mgl + (delta_dissolved_oxygen_mgl or 0.0), 0.0), 2
        ),
        ph=base.ph,
        salinity_ppt=round(max(base.salinity_ppt + (delta_salinity_ppt or 0.0), 0.0), 2),
        ammonia_nh3_mgl=base.ammonia_nh3_mgl,
        turbidity_ntu=base.turbidity_ntu,
        biomass_kg_estimated=base.biomass_kg_estimated,
        fcr_estimated=base.fcr_estimated,
    )
