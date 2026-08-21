"""Unit tests — real predictive accuracy of the M2 mortality-risk booster.

Same rationale as `test_m3_model_accuracy.py`: nothing in this repo
previously re-verified that the recorded test-set metrics in
`ml/serving/m3/models/m2_mortality_risk_baseline_results.json` are
reproducible from the actual committed booster
(`m2_mortality_risk_baseline.txt`), rather than numbers typed into a JSON
file by hand. This scores the real held-out `split == "test"` rows in
`ml/serving/m3/data/m2_health_table.parquet` through the exact same
booster `app/ml_inference/numeric/m2_risk_engine.py` serves at runtime
(via `get_m2_engine_bundle()`), and independently recomputes AUC-ROC /
AUC-PR / Brier.

Deliberately predicts straight off the held-out table's real columns
rather than through `score_pond()` — `score_pond()` exists to serve live
ponds where several inputs (`management_quality`, `secchi_cm`,
`wind_speed_ms`, ...) have no real ingestion pipeline yet and are
honestly-documented placeholders (see that module's docstring); the
held-out table was built by `build_m2_table.py` straight from the
simulator and has real values for all of those, so scoring it through the
live engine's own placeholder substitutions would silently mix in fake
data and understate the booster's real accuracy. Column order is pulled
from `bundle.feature_order` (`booster.feature_name()`) — the same
single-source-of-truth `score_pond()` itself trusts — rather than
duplicated here, so this test can't drift out of sync with what the
booster actually expects.
"""

from __future__ import annotations

import os
import warnings
from pathlib import Path

os.environ.setdefault("DATABASE_URL", "postgresql+asyncpg://x:x@localhost/x")
os.environ.setdefault("APP_SECRET_KEY", "test_secret_key_minimum_32_chars_here")
os.environ.setdefault("INTERNAL_API_TOKEN", "test_internal_token_minimum_32_chars")

import pandas as pd
import pytest
from sklearn.metrics import average_precision_score, brier_score_loss, roc_auc_score

from app.config import get_settings
from app.ml_inference.numeric.m2_risk_engine import get_m2_engine_bundle

_TARGET_COL = "elevated_mortality_next24h"

# Thresholds well below the currently-recorded test-set metrics (auc_roc
# 0.907, auc_pr 0.656 per m2_mortality_risk_baseline_results.json) — tight
# enough to catch a genuinely broken/placeholder model, loose enough not
# to flap on ordinary retrain-to-retrain noise.
_MIN_AUC_ROC = 0.85
_MIN_AUC_PR = 0.5


def _data_path() -> Path:
    return Path(get_settings().m3_engine_dir).resolve() / "data" / "m2_health_table.parquet"


@pytest.mark.unit
def test_mortality_risk_model_reproduces_recorded_test_accuracy() -> None:
    data_path = _data_path()
    if not data_path.exists():
        pytest.skip(f"held-out eval data not present at {data_path}")

    df = pd.read_parquet(data_path)
    test_rows = df[df["split"] == "test"].copy()
    assert len(test_rows) > 1000, "held-out test split unexpectedly small/empty"

    bundle = get_m2_engine_bundle()
    missing = [c for c in bundle.feature_order if c not in test_rows.columns]
    assert not missing, f"held-out table is missing booster features: {missing}"

    X = test_rows[bundle.feature_order].copy()
    X["species"] = X["species"].astype("category")
    y_true = test_rows[_TARGET_COL].to_numpy()

    with warnings.catch_warnings():
        warnings.simplefilter("ignore")
        preds = bundle.booster.predict(X)

    auc_roc = float(roc_auc_score(y_true, preds))
    auc_pr = float(average_precision_score(y_true, preds))
    brier = float(brier_score_loss(y_true, preds))

    assert auc_roc > _MIN_AUC_ROC, (
        f"M2 mortality-risk model's real AUC-ROC on held-out data dropped to "
        f"{auc_roc:.4f} (n={len(y_true)}) — below the {_MIN_AUC_ROC} floor."
    )
    assert auc_pr > _MIN_AUC_PR, (
        f"M2 mortality-risk model's real AUC-PR on held-out data dropped to "
        f"{auc_pr:.4f} (n={len(y_true)}) — below the {_MIN_AUC_PR} floor."
    )
    assert brier < 0.2, f"M2 model Brier score regressed to {brier:.4f}"


@pytest.mark.unit
def test_operating_threshold_recall_holds_on_held_out_data() -> None:
    """`bundle.operating_threshold` is the real tuned 80%-recall decision
    boundary from training (see m2_risk_engine.py's `_bucket_risk_level`
    docstring) — assert it still delivers materially-better-than-random
    recall on live-scored held-out data, not just a stale number copied
    out of results.json."""
    data_path = _data_path()
    if not data_path.exists():
        pytest.skip(f"held-out eval data not present at {data_path}")

    df = pd.read_parquet(data_path)
    test_rows = df[df["split"] == "test"].copy()
    assert len(test_rows) > 1000, "held-out test split unexpectedly small/empty"

    bundle = get_m2_engine_bundle()
    X = test_rows[bundle.feature_order].copy()
    X["species"] = X["species"].astype("category")
    y_true = test_rows[_TARGET_COL].to_numpy()

    with warnings.catch_warnings():
        warnings.simplefilter("ignore")
        preds = bundle.booster.predict(X)

    predicted_positive = preds >= bundle.operating_threshold
    actual_positive = y_true == 1
    recall = float((predicted_positive & actual_positive).sum() / actual_positive.sum())

    assert recall > 0.6, (
        f"Operating-threshold recall on held-out data dropped to {recall:.4f} "
        f"(threshold={bundle.operating_threshold:.4f}) — below the 0.6 floor "
        f"(recorded test recall at this threshold is ~0.796)."
    )
