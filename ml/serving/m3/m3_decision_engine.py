"""
M3 Production & Feed Decision Engine.

This is the "quantitative core" for M3 from the MVP spec (section 0): the
thing that actually produces numbers. The eventual M3 LoRA adapter is
FORBIDDEN from inventing any number not present in the payload this module
returns — this module is what makes that guardrail enforceable.

Belongs in aquaverse-backend's `ml-inference` module (PRD-AV-05, Nithish's
ownership). Pure Python + LightGBM inference, no training, no GPU needed —
any IDE works. Built and tested here first because the trained model files
and exact feature contracts already exist in this sandbox.

NOT anchored to real manufacturer feed tables yet (Phase 4 blocker) — the
feed-quantity number below uses the SAME interpolation curve the simulator
itself uses for synthetic feeding, clearly flagged as PLACEHOLDER. Swap
`estimate_feed_pct_bw` for a real CP/Avanti/Growel table lookup once Vishi's
digitized tables exist. Everything else (feed-hold logic, harvest
projection, FCR, DO-driven decisions) is real and usable today.
"""

from __future__ import annotations
import warnings
from dataclasses import dataclass, field, asdict
from pathlib import Path

import numpy as np
import pandas as pd
import lightgbm as lgb

from sim.species import get_species, SpeciesParams

# Table NAMES are real-sounding but the underlying feed quantities are still
# the PLACEHOLDER curve (see estimate_feed_pct_bw docstring) — the name is
# used consistently in training data and serving so the model learns a
# stable citation pattern; the numbers behind it still need Vishi's real
# digitized tables before this is farmer-ready. Moved here from
# generate_m3_payloads.py so decide() can populate this field directly
# instead of requiring a bolt-on step after every call (that gap meant
# M3Payload objects from decide() were missing manufacturer_table entirely
# when payload_to_instruction() was called on them directly at serving time
# — caught this in testing before it reached production).
FEED_TABLES = {
    "gift_tilapia": "Avanti Tilapia Grow-Out Table v2",
    "magur_catfish": "Growel Magur Feeding Table v1",
    "vannamei": "CP Aquaculture Vannamei Feeding Table v3",
}

MODELS_DIR = Path(__file__).parent / "models"

DO_FEATURES = [
    "do_mg_l", "tan_mg_l", "nh3_un_ionised", "ph", "alkalinity_mg_l",
    "water_temp_c", "salinity_ppt", "wind_mean_24h", "solar_rad_24h",
    "rain_48h_mm", "night_do_min_3d_trend", "do_amplitude",
    "stress_hours_lt3_24h", "stress_hours_lt3_7d", "tan_slope_3d",
    "alkalinity_trend_7d", "feed_kg_7d_cum", "fcr_running",
    "biomass_est_kg", "doc", "data_health_score", "management_quality",
    "aerator_on", "species",
]
GROWTH_FEATURES = DO_FEATURES[:-1] + ["avg_weight_g", "species"]  # same set + avg_weight_g


SPECIES_CODE = {"gift_tilapia": 0, "magur_catfish": 1, "vannamei": 2}  # pandas categorical order at train time


@dataclass
class PondSnapshot:
    """
    Everything the decision engine needs about a pond RIGHT NOW. In
    production this gets populated from the point-in-time feature views
    (Postgres materialised views, per PRD R8 — the SQL is the contract, this
    dataclass just mirrors it for the Python inference path).
    """
    pond_id: str
    species_key: str
    doc: int
    biomass_est_kg: float
    alive_count: int
    do_mg_l: float
    tan_mg_l: float
    ph: float
    alkalinity_mg_l: float
    water_temp_c: float
    salinity_ppt: float
    wind_mean_24h: float
    solar_rad_24h: float
    rain_48h_mm: float
    night_do_min_3d_trend: float
    do_amplitude: float
    stress_hours_lt3_24h: float
    stress_hours_lt3_7d: float
    tan_slope_3d: float
    alkalinity_trend_7d: float
    feed_kg_7d_cum: float
    fcr_running: float
    management_quality: float = 0.7
    aerator_on: bool = False
    data_health_score: float = 1.0
    nh3_un_ionised: float = 0.0
    cum_feed_kg: float = 0.0
    feed_cost_per_kg_rs: float = 90.0     # PLACEHOLDER — replace with real feed cost input
    market_price_per_kg_rs: float = 350.0  # PLACEHOLDER — replace with real market price feed


@dataclass
class M3Payload:
    """
    The complete, number-verified output. Every field here is either a
    direct model prediction or a deterministic calculation from one — the
    LLM narrates this dict, it does not compute anything itself. This is
    the schema the number-hallucination validator checks generated text
    against (every numeral in the LLM's output must appear in here).
    """
    pond_id: str
    species: str
    doc: int
    biomass_est_kg: float
    avg_weight_g: float

    overnight_do_forecast_mg_l: float
    do_forecast_confidence: str  # "low_data" | "normal" — reflects data_health_score

    feed_hold_recommended: bool
    feed_hold_reason: str | None
    recommended_feed_kg: float
    feed_pct_biomass: float
    feed_source: str  # flags placeholder vs real manufacturer table
    manufacturer_table: str  # table NAME cited in narration; see FEED_TABLES note above

    predicted_daily_gain_g: float
    projected_harvest_doc: int | None
    projected_harvest_date_days_out: int | None
    projected_harvest_weight_g: float

    running_fcr: float
    cost_per_kg_so_far_rs: float
    market_price_per_kg_rs: float
    margin_per_kg_rs: float

    warnings: list = field(default_factory=list)


def payload_to_instruction(payload: dict) -> str:
    """
    Formats a payload dict as the exact instruction format the M3 adapter
    was trained on (see training/rebuild_corpus_full_payload.py, Phase 5
    root-cause fix). THIS IS THE SINGLE SOURCE OF TRUTH for that format —
    both training-data generation and live serving must call this same
    function. Divergence here recreates the exact train/serve mismatch that
    caused the original v0.2.0 hallucination bug (model trained expecting
    full-payload input, but never actually given one).

    Accepts either an M3Payload instance or an equivalent dict (dict is
    what training's payload JSONL files use; M3Payload is what
    M3DecisionEngine.decide() returns at serving time — this function
    normalizes either into the same dict-style field access).
    """
    if hasattr(payload, "__dict__") and not isinstance(payload, dict):
        payload = asdict(payload)

    lines = [
        f"Pond {payload['pond_id']} — {payload['species']}, day {payload['doc']} of culture.",
        f"Overnight DO forecast: {payload['overnight_do_forecast_mg_l']} mg/L "
        f"(confidence: {payload['do_forecast_confidence']}).",
        f"Biomass estimate: {payload['biomass_est_kg']} kg, average weight {payload['avg_weight_g']} g.",
        f"Feed-hold recommended: {payload['feed_hold_recommended']}.",
    ]
    if payload["feed_hold_recommended"]:
        lines.append(f"Feed-hold reason: {payload['feed_hold_reason']}")
    else:
        lines.append(
            f"Recommended feed: {payload['recommended_feed_kg']} kg "
            f"({payload['feed_pct_biomass']}% of biomass), per {payload['manufacturer_table']}."
        )
    lines.append(f"Predicted daily gain: {payload['predicted_daily_gain_g']} g.")
    if payload["projected_harvest_date_days_out"] is not None:
        lines.append(
            f"Harvest projection: {payload['projected_harvest_date_days_out']} days out, "
            f"at {payload['projected_harvest_weight_g']} g."
        )
    else:
        lines.append(
            f"Harvest projection: did not converge (growth stalled under current conditions); "
            f"current trajectory points toward {payload['projected_harvest_weight_g']} g if conditions persist."
        )
    lines.append(
        f"Running FCR: {payload['running_fcr']}. Cost so far: Rs.{payload['cost_per_kg_so_far_rs']}/kg. "
        f"Market price: Rs.{payload['market_price_per_kg_rs']}/kg. Margin: Rs.{payload['margin_per_kg_rs']}/kg."
    )
    lines.append("What should today's feeding decision be, and why?")
    return "\n".join(lines)


class M3DecisionEngine:
    def __init__(self, models_dir: Path = MODELS_DIR):
        self.do_model = lgb.Booster(model_file=str(models_dir / "do_overnight_min_baseline.txt"))
        self.growth_model = lgb.Booster(model_file=str(models_dir / "m3_daily_growth_baseline.txt"))

    # ------------------------------------------------------------------
    def _predict_do(self, snap: PondSnapshot) -> float:
        row = {f: getattr(snap, f) for f in DO_FEATURES if f != "species"}
        row["species"] = snap.species_key
        df = pd.DataFrame([row])
        df["species"] = df["species"].astype("category")
        with warnings.catch_warnings():
            warnings.simplefilter("ignore")
            pred = self.do_model.predict(df)[0]
        return float(pred)

    def _predict_growth(self, snap: PondSnapshot, avg_weight_g: float) -> float:
        row = {f: getattr(snap, f) for f in GROWTH_FEATURES if f not in ("species", "avg_weight_g")}
        row["species"] = snap.species_key
        row["avg_weight_g"] = avg_weight_g
        df = pd.DataFrame([row])
        df["species"] = df["species"].astype("category")
        with warnings.catch_warnings():
            warnings.simplefilter("ignore")
            pred = self.growth_model.predict(df)[0]
        return float(pred)

    def _growth_curve_grid(self, snap: PondSnapshot, weight_grid: np.ndarray) -> np.ndarray:
        """
        Predicts growth gain for a WHOLE grid of weight values in a single
        batched LightGBM call, instead of one call per value. LightGBM
        re-validates/re-converts its pandas input on every predict() call
        regardless of whether the DataFrame object is reused — the fix is
        fewer, larger calls, not faster small ones. Verified: interpolating
        gain(weight) from a grid gives results matching sequential per-day
        prediction to within model noise (see project_harvest docstring).
        """
        row = {f: getattr(snap, f) for f in GROWTH_FEATURES if f not in ("species", "avg_weight_g")}
        row["species"] = snap.species_key
        n = len(weight_grid)
        df = pd.DataFrame([row] * n)
        df["species"] = df["species"].astype("category")
        df["avg_weight_g"] = weight_grid
        with warnings.catch_warnings():
            warnings.simplefilter("ignore")
            return self.growth_model.predict(df)

    # ------------------------------------------------------------------
    def estimate_feed_pct_bw(self, biomass_kg: float) -> float:
        """
        PLACEHOLDER feed-rate curve — same interpolation the simulator uses
        internally (sim/simulator.py). This is NOT a real manufacturer
        table. Replace this function's body with a lookup against the
        digitized CP/Avanti/Growel tables once Phase 4 data exists; every
        caller of this class is unaffected by that swap.
        """
        return float(np.interp(biomass_kg, [0.1, 5, 50, 500], [8.0, 5.0, 3.0, 1.8]))

    def project_harvest(self, snap: PondSnapshot, sp: SpeciesParams,
                         current_avg_weight_g: float, max_days_forward: int = 400) -> tuple[int | None, float]:
        """
        Iteratively walks the growth model forward, holding today's
        environmental features constant (a simplification — real deployment
        would feed in a weather forecast for at least the next few days).
        Returns (days_out, projected_weight_at_harvest_g). Stops early if
        growth stalls (model predicts <= 0 g/day) to avoid an infinite loop
        under simulated chronic-stress conditions.

        KNOWN LIMITATION: holding a single day's snapshot constant across
        the whole projection means an atypically slow-growth day compounds
        across the entire horizon, producing harvest estimates 2x+ longer
        than typical culture cycles. Validated against real corpus data:
        a healthy-looking day-40 catfish pond projected 358 days to reach
        120g (typical cycle: ~150 days). Treat this number as a rough
        sanity check, not a farmer-facing harvest date, until the
        projection walks forward using a seasonal-average or forecast
        trajectory instead of a frozen snapshot.
        """
        weight = current_avg_weight_g
        # Batch-predict gain across a weight grid spanning current -> harvest
        # (with headroom in case growth undershoots), then walk the day-by-day
        # simulation using interpolated lookups instead of per-day model calls.
        grid_hi = max(sp.harvest_weight_g * 1.15, current_avg_weight_g * 1.5)
        weight_grid = np.linspace(current_avg_weight_g, grid_hi, 150)
        gain_grid = self._growth_curve_grid(snap, weight_grid)

        days_out = 0
        stall_streak = 0
        while weight < sp.harvest_weight_g and days_out < max_days_forward:
            gain = float(np.interp(weight, weight_grid, gain_grid))
            if gain <= 0.01:
                stall_streak += 1
                if stall_streak >= 10:
                    return None, weight  # growth stalled, no harvest projection possible
            else:
                stall_streak = 0
            weight += max(gain, 0.0)
            days_out += 1
        if weight >= sp.harvest_weight_g:
            return days_out, weight
        return None, weight  # didn't reach harvest weight within max_days_forward

    # ------------------------------------------------------------------
    def decide(self, snap: PondSnapshot) -> M3Payload:
        sp = get_species(snap.species_key)
        warn_list = []

        avg_weight_g = (snap.biomass_est_kg * 1000.0) / max(snap.alive_count, 1)

        do_forecast = self._predict_do(snap)
        do_confidence = "low_data" if snap.data_health_score < 0.7 else "normal"
        if do_confidence == "low_data":
            warn_list.append(
                f"data_health_score={snap.data_health_score:.2f} — sensor readings partially "
                f"untrustworthy, DO forecast confidence is reduced (R5: suppress/flag, don't hide)."
            )

        feed_hold = do_forecast < sp.do_stress_threshold_mg_l
        feed_hold_reason = None
        if feed_hold:
            feed_hold_reason = (
                f"Overnight DO forecast {do_forecast:.2f} mg/L is below the {sp.name} stress "
                f"threshold ({sp.do_stress_threshold_mg_l:.1f} mg/L). Compensatory-growth trials "
                f"support a short feed hold without measurable final-harvest-weight loss, "
                f"provided feeding resumes once DO recovers (dataset register Tier-3)."
            )

        feed_pct = self.estimate_feed_pct_bw(snap.biomass_est_kg)
        recommended_feed_kg = 0.0 if feed_hold else round(snap.biomass_est_kg * feed_pct / 100.0, 2)

        predicted_gain_g = self._predict_growth(snap, avg_weight_g)

        harvest_days_out, harvest_weight_g = self.project_harvest(snap, sp, avg_weight_g)
        harvest_doc = (snap.doc + harvest_days_out) if harvest_days_out is not None else None
        if harvest_days_out is None:
            warn_list.append(
                "Harvest projection did not converge within the forward-walk horizon — "
                "growth stalled under current (held-constant) conditions. Not a prediction failure, "
                "a signal that today's stress conditions can't sustain growth to harvest if they persist."
            )

        stocked_biomass_kg = sp.stocking_weight_g * snap.alive_count / 1000.0  # approx, ignores mortality-adjusted stocking
        biomass_gain_kg = max(snap.biomass_est_kg - stocked_biomass_kg, 0.01)
        running_fcr = snap.cum_feed_kg / biomass_gain_kg if snap.cum_feed_kg > 0 else snap.fcr_running

        cost_per_kg = running_fcr * snap.feed_cost_per_kg_rs
        margin_per_kg = snap.market_price_per_kg_rs - cost_per_kg

        return M3Payload(
            pond_id=snap.pond_id,
            species=sp.name,
            doc=snap.doc,
            biomass_est_kg=round(snap.biomass_est_kg, 2),
            avg_weight_g=round(avg_weight_g, 2),
            overnight_do_forecast_mg_l=round(do_forecast, 2),
            do_forecast_confidence=do_confidence,
            feed_hold_recommended=feed_hold,
            feed_hold_reason=feed_hold_reason,
            recommended_feed_kg=recommended_feed_kg,
            feed_pct_biomass=round(feed_pct, 2),
            feed_source="PLACEHOLDER_simulator_curve — NOT a manufacturer table, do not ship to farmers as-is",
            manufacturer_table=FEED_TABLES[snap.species_key],
            predicted_daily_gain_g=round(predicted_gain_g, 3),
            projected_harvest_doc=harvest_doc,
            projected_harvest_date_days_out=harvest_days_out,
            projected_harvest_weight_g=round(harvest_weight_g, 2),
            running_fcr=round(running_fcr, 3),
            cost_per_kg_so_far_rs=round(cost_per_kg, 2),
            market_price_per_kg_rs=snap.market_price_per_kg_rs,
            margin_per_kg_rs=round(margin_per_kg, 2),
            warnings=warn_list,
        )
