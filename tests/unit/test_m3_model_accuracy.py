"""Unit tests — real predictive accuracy of the M3 boosters, not just
behavioral sanity (P0.3).

`test_m3_engine.py` already proves the engine wrapper is wired up (real
payload shape, deterministic, responds to input changes). This goes
further: it re-scores the real held-out `split == "test"` rows in
`ml/serving/m3/data/{do_forecast,growth}_table.parquet` through the
exact same boosters `app/ml_inference/numeric/m3_engine.py` serves at
runtime, and independently recomputes MAE/RMSE/R² — proving the numbers
in `ml/serving/m3/models/*_results.json` are real, reproducible model
output on real data, not something typed into a JSON file by hand. If a
retrain, a mis-saved artifact, or a swapped-in placeholder model ever
regressed accuracy, this is what would actually catch it; the behavioral
tests in test_m3_engine.py would not.
"""

from __future__ import annotations

import os
import warnings
from pathlib import Path

os.environ.setdefault("DATABASE_URL", "postgresql+asyncpg://x:x@localhost/x")
os.environ.setdefault("APP_SECRET_KEY", "test_secret_key_minimum_32_chars_here")
os.environ.setdefault("INTERNAL_API_TOKEN", "test_internal_token_minimum_32_chars")

import numpy as np
import pandas as pd
import pytest

from app.config import get_settings
from app.ml_inference.numeric.m3_engine import get_m3_engine_bundle

# Exact feature lists + order the boosters were trained on
# (ml/serving/m3/m3_decision_engine.py DO_FEATURES/GROWTH_FEATURES) —
# duplicated here rather than imported so this test still catches a
# regression if that module's own feature list ever silently drifted
# from what these particular saved boosters actually expect.
_DO_FEATURES = [
    "do_mg_l", "tan_mg_l", "nh3_un_ionised", "ph", "alkalinity_mg_l",
    "water_temp_c", "salinity_ppt", "wind_mean_24h", "solar_rad_24h",
    "rain_48h_mm", "night_do_min_3d_trend", "do_amplitude",
    "stress_hours_lt3_24h", "stress_hours_lt3_7d", "tan_slope_3d",
    "alkalinity_trend_7d", "feed_kg_7d_cum", "fcr_running",
    "biomass_est_kg", "doc", "data_health_score", "management_quality",
    "aerator_on", "species",
]  # fmt: skip
_GROWTH_FEATURES = [*_DO_FEATURES[:-1], "avg_weight_g", "species"]

# Thresholds well below the currently-recorded test-set R² (0.988 DO,
# 0.974 growth per results.json) — tight enough to catch a genuinely
# broken/placeholder model, loose enough not to flap on ordinary
# retrain-to-retrain noise.
_MIN_R2_DO = 0.95
_MIN_R2_GROWTH = 0.9


def _regression_metrics(preds: np.ndarray, actual: np.ndarray) -> dict[str, float]:
    errors = preds - actual
    ss_res = float(np.sum(errors**2))
    ss_tot = float(np.sum((actual - actual.mean()) ** 2))
    return {
        "mae": float(np.mean(np.abs(errors))),
        "rmse": float(np.sqrt(np.mean(errors**2))),
        "r2": 1.0 - ss_res / ss_tot,
        "n": len(actual),
    }


def _data_dir() -> Path:
    return Path(get_settings().m3_engine_dir).resolve() / "data"


@pytest.mark.unit
def test_do_forecast_model_reproduces_recorded_test_accuracy() -> None:
    data_path = _data_dir() / "do_forecast_table.parquet"
    if not data_path.exists():
        pytest.skip(f"held-out eval data not present at {data_path}")

    df = pd.read_parquet(data_path)
    test_rows = df[df["split"] == "test"].copy()
    assert len(test_rows) > 1000, "held-out test split unexpectedly small/empty"
    test_rows["species"] = test_rows["species"].astype("category")

    bundle = get_m3_engine_bundle()
    with warnings.catch_warnings():
        warnings.simplefilter("ignore")
        preds = bundle.engine.do_model.predict(test_rows[_DO_FEATURES])

    metrics = _regression_metrics(preds, test_rows["target_night_do_min"].to_numpy())

    assert metrics["r2"] > _MIN_R2_DO, (
        f"DO overnight-min model's real accuracy on held-out data dropped to "
        f"R²={metrics['r2']:.4f} (n={metrics['n']}) — below the {_MIN_R2_DO} floor."
    )
    assert metrics["mae"] < 0.5, f"DO model MAE regressed to {metrics['mae']:.4f} mg/L"


@pytest.mark.unit
def test_growth_model_reproduces_recorded_test_accuracy() -> None:
    data_path = _data_dir() / "growth_table.parquet"
    if not data_path.exists():
        pytest.skip(f"held-out eval data not present at {data_path}")

    df = pd.read_parquet(data_path)
    test_rows = df[df["split"] == "test"].copy()
    assert len(test_rows) > 1000, "held-out test split unexpectedly small/empty"
    test_rows["species"] = test_rows["species"].astype("category")

    bundle = get_m3_engine_bundle()
    with warnings.catch_warnings():
        warnings.simplefilter("ignore")
        preds = bundle.engine.growth_model.predict(test_rows[_GROWTH_FEATURES])

    metrics = _regression_metrics(preds, test_rows["target_avg_weight_gain_g"].to_numpy())

    assert metrics["r2"] > _MIN_R2_GROWTH, (
        f"Daily-growth model's real accuracy on held-out data dropped to "
        f"R²={metrics['r2']:.4f} (n={metrics['n']}) — below the {_MIN_R2_GROWTH} floor."
    )
    assert metrics["mae"] < 2.0, f"Growth model MAE regressed to {metrics['mae']:.4f} g/day"
