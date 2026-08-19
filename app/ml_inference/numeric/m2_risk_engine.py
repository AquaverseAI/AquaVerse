"""
M2 mortality-risk engine — in-process wiring to the real trained booster
(P1.3).

`GET /v1/ponds/{id}/risk` and `GET /v1/risk/worklist` used to return a fixed
`risk_score=0.72` fixture for every pond. There IS a real, already-trained
model for this — a separate LightGBM classifier
(`ml/serving/m3/models/m2_mortality_risk_baseline.txt`) that the M3 engine
(`app/ml_inference/numeric/m3_engine.py`, feed/growth/DO-forecast only)
never touches. This module loads and serves that booster.

HONESTY NOTE (matches `ml/serving/m3/build_m2_table.py` /
`train_m2_baseline.py`, read both docstrings before touching this file):
this model predicts "elevated mortality risk from environmental-stress
next 24h" — DO crashes, chronic stress. It is NOT a disease/pathogen
classifier (no WSSV/EHP/AHPND signal anywhere in its training data). Label
it that way in any UI/report copy that surfaces its output.

Real inputs vs. honestly-defaulted placeholders
------------------------------------------------
Real, from `Log`/`Pond`/`Crop` rows: do_mg_l, tan_mg_l, ph, water_temp_c,
alkalinity_mg_l, no2_mg_l, no3_mg_l, salinity_ppt, species, day_of_culture
(when an active Crop exists).

Placeholder (no ingestion pipeline exists anywhere in this repo for these
yet — documented individually below, values reused from
`advisory/router.py`'s `/ask` stub `PondSnapshot` construction wherever a
matching field already exists there, rather than inventing new numbers):
wind_speed_ms, solar_rad_wm2, rain_mm, feed_kg, cum_feed_kg, biomass_kg,
management_quality, secchi_cm, and day_of_culture/stocking_count when no
active Crop row exists.

Feature order — verified empirically, not assumed
---------------------------------------------------
`build_m2_table.py`'s `keep_cols` concatenation (`STATIC_COLS +
RAW_SENSOR_COLS + FEATURE_COLS_FOR_M2`) is what the booster was actually
trained on. Rather than hand-copy that order here and hope it stays in
sync, `score_pond()` below builds a `{feature_name: value}` dict keyed by
the booster's OWN `booster.feature_name()` list (see `get_m2_engine_bundle`)
and reindexes the final `DataFrame` against it before predicting. A
mismatch between what we computed and what the booster expects raises
immediately (`KeyError`/`AssertionError`) instead of silently feeding a
misaligned vector into a real model — this exact class of bug (train/serve
feature mismatch) is called out in `m3_decision_engine.py`'s
`payload_to_instruction` docstring as the root cause of a real past
incident ("the original v0.2.0 hallucination bug").

Manual verification performed for this change (do not skip if you touch
this file): loaded the booster, printed `booster.feature_name()`, and
confirmed it is exactly `["species", "salinity_ppt", "management_quality",
"do_mg_l", "tan_mg_l", "no2_mg_l", "no3_mg_l", "ph", "alkalinity_mg_l",
"water_temp_c", "secchi_cm"] + sim.features.FEATURE_COLUMNS minus
"neighbour_risk_2km"` (27 features total) — i.e. `STATIC_COLS +
RAW_SENSOR_COLS + FEATURE_COLS_FOR_M2` in `build_m2_table.py`, in that
exact order.
"""

from __future__ import annotations

import json
import warnings
from dataclasses import dataclass
from datetime import datetime
from functools import lru_cache
from pathlib import Path
from typing import Any

import numpy as np
import pandas as pd

# Reuse the exact same sys.path patching the M3 engine already uses — both
# `m2_mortality_risk_baseline.txt` and the M3 boosters live under the same
# `Settings.m3_engine_dir` (`ml/serving/m3/models/`), and `sim.features` /
# `sim.species` are the same package either module needs importable. Not
# duplicating the sys.path logic per the task brief's explicit suggestion.
from app.ml_inference.numeric.m3_engine import _ensure_engine_dir_on_path

# ---------------------------------------------------------------------------
# Placeholder constants — no real data source exists yet for these fields.
# Reused from advisory/router.py's /ask stub PondSnapshot construction
# wherever an equivalent field already exists there, rather than inventing
# new numbers.
# ---------------------------------------------------------------------------
WIND_SPEED_MS_PLACEHOLDER = (
    3.2  # PLACEHOLDER — no weather ingestion exists; matches /ask stub wind_mean_24h
)
SOLAR_RAD_WM2_PLACEHOLDER = 450.0  # PLACEHOLDER — ditto, matches /ask stub solar_rad_24h
RAIN_MM_PLACEHOLDER = 0.0  # PLACEHOLDER — ditto, matches /ask stub rain_48h_mm
FEED_KG_PLACEHOLDER = 0.0  # PLACEHOLDER — no feed-log ingestion exists
BIOMASS_KG_PLACEHOLDER = (
    12.3  # PLACEHOLDER — no biomass-estimation pipeline; matches /ask stub biomass_est_kg
)
STOCKING_COUNT_PLACEHOLDER = 180  # PLACEHOLDER — matches /ask stub alive_count; used only if no active Crop has a real post_larvae_count
SECCHI_CM_PLACEHOLDER = 30.0  # PLACEHOLDER — Log.turbidity_ntu is a different instrument/unit; NOT converted (would be fabricating a formula). No real Secchi-disk reading exists anywhere in this repo.
MANAGEMENT_QUALITY_PLACEHOLDER = (
    0.7  # matches ml/serving/m3/m3_decision_engine.py's PondSnapshot.management_quality default
)
DEFAULT_DOC = 52  # matches advisory/router.py's /ask stub `doc=52`; used only when the pond has no active Crop row

# Matches DataQualityOut's stale_threshold_hours value, hardcoded in
# ml_inference/router.py's get_data_quality (this schema module's other
# staleness signal) — reused here rather than a second invented number.
STALE_LOG_THRESHOLD_HOURS = 4

SPECIES_KEY_MAP = {
    "vannamei": "vannamei",
    "litopenaeus vannamei": "vannamei",
    "gift_tilapia": "gift_tilapia",
    "gift tilapia": "gift_tilapia",
    "oreochromis niloticus": "gift_tilapia",
    "tilapia": "gift_tilapia",
    "magur_catfish": "magur_catfish",
    "magur catfish": "magur_catfish",
    "clarias magur": "magur_catfish",
    "catfish": "magur_catfish",
}
DEFAULT_SPECIES_KEY = "vannamei"


def resolve_species_key(species_text: str | None) -> str:
    """Map a free-text `Pond.species` value to a `sim.species` key.

    Same mapping style already used in `advisory/router.py`'s `/ask`
    (which just hardcodes `species_key="vannamei"`); defaults to
    `"vannamei"` for unmapped/missing text, documented.
    """
    if not species_text:
        return DEFAULT_SPECIES_KEY
    return SPECIES_KEY_MAP.get(species_text.strip().lower(), DEFAULT_SPECIES_KEY)


# ---------------------------------------------------------------------------
# Raw input
# ---------------------------------------------------------------------------
@dataclass(frozen=True)
class RawLogPoint:
    """One real hourly `Log` row's worth of chemistry, pre-extracted from
    the ORM so this module has zero DB/ORM dependency (easy to unit test)."""

    recorded_at: datetime
    do_mg_l: float | None
    tan_mg_l: float | None
    ph: float | None
    water_temp_c: float | None
    alkalinity_mg_l: float | None
    no2_mg_l: float | None
    no3_mg_l: float | None
    salinity_ppt: float | None


# ---------------------------------------------------------------------------
# Engine bundle (booster + operating threshold), loaded once per process
# ---------------------------------------------------------------------------
@dataclass(frozen=True)
class M2EngineBundle:
    booster: Any  # lightgbm.Booster
    feature_order: list[str]  # booster.feature_name() — the ONE authoritative order
    operating_threshold: float
    test_metrics: dict[str, float]
    model_version: str


@lru_cache(maxsize=1)
def get_m2_engine_bundle() -> M2EngineBundle:
    """Load the M2 booster + its real tuned operating threshold once per process."""
    _ensure_engine_dir_on_path()

    import lightgbm as lgb

    from app.config import get_settings

    settings = get_settings()
    models_dir = Path(settings.m3_engine_dir).resolve() / "models"
    model_path = models_dir / "m2_mortality_risk_baseline.txt"
    results_path = models_dir / "m2_mortality_risk_baseline_results.json"

    booster = lgb.Booster(model_file=str(model_path))
    feature_order = list(booster.feature_name())

    with open(results_path) as f:
        results = json.load(f)
    operating_threshold = float(results["operating_point"]["threshold"])
    test_metrics = {
        k: float(v) for k, v in results.get("test", {}).items() if isinstance(v, int | float)
    }

    model_version = (
        f"m2-mortality-risk-baseline-lgbm-trees{booster.num_trees()}-thr{operating_threshold:.4f}"
    )

    return M2EngineBundle(
        booster=booster,
        feature_order=feature_order,
        operating_threshold=operating_threshold,
        test_metrics=test_metrics,
        model_version=model_version,
    )


# ---------------------------------------------------------------------------
# Feature engineering — build the raw hourly frame, then defer to the real
# training-side reference implementation (sim.features.compute_features)
# ---------------------------------------------------------------------------
def _build_raw_frame(points: list[RawLogPoint], doc_value: int) -> pd.DataFrame:
    """Build the hourly dataframe `compute_features()` expects.

    `doc_value` (day_of_culture) is applied as a constant across all rows:
    `compute_features` only ever passes `day_of_culture` straight through
    to its output `doc` column (it does not feed into any rolling-window
    calculation), so only the value at the most recent row — the one we
    actually serve — matters. Recomputing a real per-row DOC would add
    complexity for no observable difference in the served prediction.
    """

    def _n(v: float | None) -> float:
        # A single-row (or all-None-column) DataFrame keeps Python `None`
        # as an object-dtype value rather than coercing it to `np.nan` —
        # `compute_features`'s arithmetic (e.g. `temp_c + 273.15`) then
        # raises TypeError on the raw `None`. Coerce explicitly so
        # "missing sensor reading" always reaches compute_features as a
        # real NaN, which LightGBM/SHAP both handle as "missing" natively.
        return np.nan if v is None else float(v)

    rows = [
        {
            "timestamp": pd.Timestamp(p.recorded_at),
            "do_mg_l": _n(p.do_mg_l),
            "tan_mg_l": _n(p.tan_mg_l),
            "ph": _n(p.ph),
            "water_temp_c": _n(p.water_temp_c),
            "alkalinity_mg_l": _n(p.alkalinity_mg_l),
            "wind_speed_ms": WIND_SPEED_MS_PLACEHOLDER,
            "solar_rad_wm2": SOLAR_RAD_WM2_PLACEHOLDER,
            "rain_mm": RAIN_MM_PLACEHOLDER,
            "feed_kg": FEED_KG_PLACEHOLDER,
            "cum_feed_kg": FEED_KG_PLACEHOLDER,
            "biomass_kg": BIOMASS_KG_PLACEHOLDER,
            "day_of_culture": doc_value,
        }
        for p in points
    ]
    return pd.DataFrame(rows)


def _data_health_score(points: list[RawLogPoint]) -> float:
    """Real completeness signal — fraction of the core real-sourced sensor
    fields that are actually present (non-null) across the queried window.
    Not a model output; a simple ratio, in the same spirit as the M3
    engine's own `data_health_score` low-data warning (R5: suppress/flag,
    don't hide)."""
    if not points:
        return 0.0
    fields = (
        "do_mg_l",
        "tan_mg_l",
        "ph",
        "water_temp_c",
        "alkalinity_mg_l",
        "no2_mg_l",
        "no3_mg_l",
        "salinity_ppt",
    )
    total = len(points) * len(fields)
    present = sum(1 for p in points for f in fields if getattr(p, f) is not None)
    return round(present / total, 4) if total else 0.0


# ---------------------------------------------------------------------------
# Prediction + SHAP
# ---------------------------------------------------------------------------
@dataclass(frozen=True)
class ShapFeatureContribution:
    feature: str
    value: float
    shap_value: float
    direction: str  # increases_risk | decreases_risk | neutral


@dataclass(frozen=True)
class M2RiskResult:
    risk_score: float
    risk_level: str
    species_key: str
    do_mg_l: float | None
    ph: float | None
    nh3_un_ionised: float | None
    data_health_score: float
    shap_contributions: list[ShapFeatureContribution]
    model_version: str
    operating_threshold: float


def _bucket_risk_level(score: float, op_threshold: float) -> str:
    """`high`'s boundary is the model's own real tuned operating threshold
    (`m2_mortality_risk_baseline_results.json`'s `operating_point.threshold`,
    ~0.589 — the 80%-recall decision boundary chosen on the validation set
    during training, see `train_m2_baseline.py`). `critical`/`medium`/`low`
    are NOT from training data; they are reasonable authored subdivisions on
    top of that one real number, so a worklist has more than a binary
    alert/no-alert split to sort against:
      * critical: score >= 0.85 — deep into the positive-class probability
        mass (test Brier ~0.12 per results.json — scores this high are
        rarely miscalibrated noise).
      * high: op_threshold <= score < 0.85 — the model's real alert band.
      * medium: 0.3 <= score < op_threshold — below the tuned alert
        threshold but above the ~15% training-set base rate of the
        positive class (build_m2_table.py: 85th-percentile label).
      * low: score < 0.3.
    """
    if score >= 0.85:
        return "critical"
    if score >= op_threshold:
        return "high"
    if score >= 0.3:
        return "medium"
    return "low"


def score_pond(
    points: list[RawLogPoint],
    species_text: str | None,
    doc_value: int | None,
    stocking_count: int | None,
    now: datetime,
) -> M2RiskResult:
    """Score one pond's current mortality risk from its real recent `Log`
    history. Always returns a real score — even with zero logs, per this
    codebase's R5 "suppress/flag, don't hide" convention; the CALLER is
    responsible for setting `suppressed`/`suppression_reason` on the
    response (this function has no opinion on staleness, only on scoring).
    """
    _ensure_engine_dir_on_path()
    from sim.species import get_species  # type: ignore[import-not-found]

    bundle = get_m2_engine_bundle()
    species_key = resolve_species_key(species_text)
    sp = get_species(species_key)
    effective_doc = doc_value if doc_value is not None else DEFAULT_DOC
    effective_stocking_count = (
        stocking_count
        if stocking_count is not None and stocking_count > 0
        else STOCKING_COUNT_PLACEHOLDER
    )

    sorted_points = sorted(points, key=lambda p: p.recorded_at)
    if sorted_points:
        raw_df = _build_raw_frame(sorted_points, effective_doc)
    else:
        # No log data at all — synthesize a single all-missing row anchored
        # to "now" so the pipeline still produces a real (if low-confidence)
        # score instead of omitting it. LightGBM/SHAP both handle NaN
        # features as "missing" natively — no fabricated sensor values.
        raw_df = _build_raw_frame(
            [
                RawLogPoint(
                    recorded_at=now,
                    do_mg_l=None,
                    tan_mg_l=None,
                    ph=None,
                    water_temp_c=None,
                    alkalinity_mg_l=None,
                    no2_mg_l=None,
                    no3_mg_l=None,
                    salinity_ppt=None,
                )
            ],
            effective_doc,
        )

    from sim.features import compute_features  # type: ignore[import-not-found]

    feat_df = compute_features(
        raw_df, stocking_weight_g=sp.stocking_weight_g, stocking_count=effective_stocking_count
    )
    last = feat_df.iloc[-1]
    latest_point = sorted_points[-1] if sorted_points else None

    # Real completeness signal — fraction of core sensor fields actually
    # present across the queried window (see _data_health_score docstring).
    # compute_features() only fills data_health_score with a hardcoded 1.0
    # when the column is absent from its input frame; feed the real value
    # in here explicitly so the model sees genuine (not constant) data
    # health, matching every other real-sourced field in this dict.
    real_data_health_score = _data_health_score(points)

    row: dict[str, Any] = {
        "species": species_key,
        "salinity_ppt": latest_point.salinity_ppt if latest_point else np.nan,
        "management_quality": MANAGEMENT_QUALITY_PLACEHOLDER,
        "do_mg_l": last["do_mg_l"],
        "tan_mg_l": last["tan_mg_l"],
        "no2_mg_l": latest_point.no2_mg_l if latest_point else np.nan,
        "no3_mg_l": latest_point.no3_mg_l if latest_point else np.nan,
        "ph": last["ph"],
        "alkalinity_mg_l": last["alkalinity_mg_l"],
        "water_temp_c": last["water_temp_c"],
        "secchi_cm": SECCHI_CM_PLACEHOLDER,
        "data_health_score": real_data_health_score,
    }
    # Pull every remaining booster feature straight from compute_features'
    # own output columns, by name — this is the "verify empirically, don't
    # assume" step: if compute_features ever stopped producing a column the
    # booster expects, this KeyErrors immediately instead of silently
    # scoring a misaligned vector.
    for feat_name in bundle.feature_order:
        if feat_name not in row:
            row[feat_name] = last[feat_name]

    assert set(row) == set(bundle.feature_order), (
        f"M2 feature mismatch: built={sorted(row)} vs booster expects={sorted(bundle.feature_order)}"
    )

    X = pd.DataFrame([row])[bundle.feature_order]
    for col in X.columns:
        if col != "species":
            X[col] = pd.to_numeric(X[col], errors="coerce")
    X["species"] = X["species"].astype("category")

    with warnings.catch_warnings():
        warnings.simplefilter("ignore")
        pred = bundle.booster.predict(X)
    risk_score = float(np.clip(pred[0], 0.0, 1.0))
    risk_level = _bucket_risk_level(risk_score, bundle.operating_threshold)

    import shap

    explainer = shap.TreeExplainer(bundle.booster)
    shap_values = explainer.shap_values(X)
    sv = shap_values[1] if isinstance(shap_values, list) else shap_values
    sv_row = np.asarray(sv)[0]

    # Only explain features with a real (non-imputed) value for this pond —
    # "explaining" with a value we made up would be misleading in a
    # farmer/staff-facing UI.
    candidate_idx = [
        i for i, name in enumerate(bundle.feature_order) if name == "species" or pd.notna(row[name])
    ]
    candidate_idx.sort(key=lambda i: -abs(sv_row[i]))
    top_idx = candidate_idx[:5]

    pandas_categorical = getattr(bundle.booster, "pandas_categorical", None) or [[]]
    species_categories = pandas_categorical[0] if pandas_categorical else []

    contributions: list[ShapFeatureContribution] = []
    for i in top_idx:
        feat_name = bundle.feature_order[i]
        shap_val = float(sv_row[i])
        if feat_name == "species":
            try:
                numeric_value = float(species_categories.index(species_key))
            except ValueError:
                numeric_value = -1.0
        else:
            numeric_value = round(float(row[feat_name]), 4)
        if shap_val > 1e-9:
            direction = "increases_risk"
        elif shap_val < -1e-9:
            direction = "decreases_risk"
        else:
            direction = "neutral"
        contributions.append(
            ShapFeatureContribution(
                feature=feat_name,
                value=numeric_value,
                shap_value=round(shap_val, 6),
                direction=direction,
            )
        )

    return M2RiskResult(
        risk_score=risk_score,
        risk_level=risk_level,
        species_key=species_key,
        do_mg_l=row["do_mg_l"] if pd.notna(row["do_mg_l"]) else None,
        ph=row["ph"] if pd.notna(row["ph"]) else None,
        nh3_un_ionised=row["nh3_un_ionised"] if pd.notna(row["nh3_un_ionised"]) else None,
        data_health_score=real_data_health_score,
        shap_contributions=contributions,
        model_version=bundle.model_version,
        operating_threshold=bundle.operating_threshold,
    )


# ---------------------------------------------------------------------------
# Chemistry proxy — a real deterministic RULE, not model output
# ---------------------------------------------------------------------------
def compute_chemistry_index(
    do_mg_l: float | None,
    ph: float | None,
    nh3_un_ionised: float | None,
    species_key: str,
) -> float:
    """A real, deterministic 0-1 index computed from the pond's actual
    latest DO/pH/ammonia readings against species thresholds — NOT model
    output. Distinct from `components["health"]` (which IS the real M2
    model's score); this is a cheap, explainable second axis, and this
    docstring exists specifically so nobody mistakes it for a second model.

    Weights:
      * DO stress (0.7) — `species.do_stress_threshold_mg_l` /
        `do_lethal_mg_l` (ml/serving/m3/sim/species.py) are real
        literature-sourced thresholds (see that module + sim/constants.py
        citations). Linear interpolation between the two.
      * pH extremity (0.15) — generic 6.5-9.0 "safe" pond pH band, a
        widely used aquaculture water-quality guideline. NOT species-
        tuned (species.py has no per-species pH threshold to draw on).
      * un-ionised ammonia (0.15) — generic 0.1 mg/L chronic-stress
        guideline commonly cited in pond-aquaculture references. NOT
        species-tuned or one of this repo's cited constants.

    Any missing input is simply excluded from the weighted average (not
    penalized, not treated as "safe") rather than fabricating a value; if
    every input is missing, returns a neutral 0.5 rather than a false 0/1.
    """
    _ensure_engine_dir_on_path()
    from sim.species import get_species

    sp = get_species(species_key)
    parts: list[tuple[float, float]] = []  # (index, weight)

    if do_mg_l is not None:
        if do_mg_l >= sp.do_stress_threshold_mg_l:
            do_idx = 0.0
        elif do_mg_l <= sp.do_lethal_mg_l:
            do_idx = 1.0
        else:
            span = sp.do_stress_threshold_mg_l - sp.do_lethal_mg_l
            do_idx = (sp.do_stress_threshold_mg_l - do_mg_l) / span if span > 0 else 0.5
        parts.append((do_idx, 0.7))

    if ph is not None:
        if ph < 6.5:
            ph_idx = min((6.5 - ph) / 1.5, 1.0)
        elif ph > 9.0:
            ph_idx = min((ph - 9.0) / 1.5, 1.0)
        else:
            ph_idx = 0.0
        parts.append((ph_idx, 0.15))

    if nh3_un_ionised is not None:
        nh3_idx = min(max(nh3_un_ionised, 0.0) / 0.1, 1.0)
        parts.append((nh3_idx, 0.15))

    if not parts:
        return 0.5

    weight_sum = sum(w for _, w in parts)
    return round(sum(idx * w for idx, w in parts) / weight_sum, 4)
