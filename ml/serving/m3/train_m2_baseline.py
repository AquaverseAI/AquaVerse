"""
Phase 3b: M2 baseline classifier — "elevated mortality risk from
environmental stress," NOT a disease classifier. See build_m2_table.py
docstring for the honesty caveat; it applies here too.

Evaluation matches MVP spec section 2 exactly: AUC-PR (not AUC-ROC, outbreaks
are rare), Brier score for calibration. Also reports precision/recall at the
operating threshold the dashboard would actually alert on.
"""
import json
from pathlib import Path

import numpy as np
import pandas as pd
import lightgbm as lgb
import shap
import mlflow
from sklearn.metrics import (average_precision_score, brier_score_loss,
                              roc_auc_score, precision_recall_curve)

data_dir, out_dir = Path("data"), Path("models")
out_dir.mkdir(exist_ok=True)

table = pd.read_parquet(data_dir / "m2_health_table.parquet")
target_col = "elevated_mortality_next24h"

CATEGORICAL_COLS = ["species"]
EXCLUDE = {"pond_uid", "timestamp", "day_of_culture", "split",
           "next_day_mortality_rate", "next_day_deaths", target_col}
feature_cols = [c for c in table.columns if c not in EXCLUDE]

df = table.copy()
for c in CATEGORICAL_COLS:
    df[c] = df[c].astype("category")
df["aerator_on"] = df["aerator_on"].astype(int) if "aerator_on" in df.columns else 0

X = df[feature_cols]
y = df[target_col]
split = df["split"]

train_mask, val_mask, test_mask = split == "train", split == "val", split == "test"
X_train, y_train = X[train_mask], y[train_mask]
X_val, y_val = X[val_mask], y[val_mask]
X_test, y_test = X[test_mask], y[test_mask]
print(f"train={len(X_train)} val={len(X_val)} test={len(X_test)} features={len(feature_cols)}")
print(f"positive rate: train={y_train.mean():.3f} val={y_val.mean():.3f} test={y_test.mean():.3f}")

train_set = lgb.Dataset(X_train, y_train, categorical_feature=CATEGORICAL_COLS, free_raw_data=False)
val_set = lgb.Dataset(X_val, y_val, categorical_feature=CATEGORICAL_COLS, reference=train_set, free_raw_data=False)

params = {
    "objective": "binary",
    "metric": "average_precision",
    "learning_rate": 0.05,
    "num_leaves": 31,
    "min_data_in_leaf": max(20, len(X_train) // 500),
    "feature_fraction": 0.8,
    "bagging_fraction": 0.8,
    "bagging_freq": 1,
    "scale_pos_weight": (1 - y_train.mean()) / y_train.mean(),  # rare-class weighting
    "verbosity": -1,
    "seed": 0,
}

mlflow.set_tracking_uri(f"sqlite:///{(out_dir/'mlflow.db').resolve()}")
mlflow.set_experiment("aquaverse_m2_mortality_risk")

with mlflow.start_run(run_name="m2_elevated_mortality_baseline"):
    mlflow.log_params(params)
    booster = lgb.train(
        params, train_set, num_boost_round=500,
        valid_sets=[train_set, val_set],
        callbacks=[lgb.early_stopping(30, verbose=False), lgb.log_evaluation(0)],
    )

    results = {}
    for name, Xs, ys in [("train", X_train, y_train), ("val", X_val, y_val), ("test", X_test, y_test)]:
        preds = booster.predict(Xs, num_iteration=booster.best_iteration)
        auc_pr = average_precision_score(ys, preds)
        auc_roc = roc_auc_score(ys, preds)
        brier = brier_score_loss(ys, preds)
        results[name] = {"auc_pr": auc_pr, "auc_roc": auc_roc, "brier": brier, "n": len(Xs), "pos_rate": float(ys.mean())}
        mlflow.log_metric(f"{name}_auc_pr", auc_pr)
        mlflow.log_metric(f"{name}_auc_roc", auc_roc)
        mlflow.log_metric(f"{name}_brier", brier)
        print(f"  {name:5s}: AUC-PR={auc_pr:.4f}  AUC-ROC={auc_roc:.4f}  Brier={brier:.4f}  (n={len(Xs)}, pos={ys.mean():.3f})")

    # operating point: threshold that gives ~80% recall on val (catch most events, accept some false alarms)
    preds_val = booster.predict(X_val, num_iteration=booster.best_iteration)
    precisions, recalls, thresholds = precision_recall_curve(y_val, preds_val)
    idx = np.argmin(np.abs(recalls[:-1] - 0.80))
    op_threshold = thresholds[idx]
    op_precision = precisions[idx]

    preds_test = booster.predict(X_test, num_iteration=booster.best_iteration)
    test_pred_labels = (preds_test >= op_threshold).astype(int)
    test_precision_at_op = (test_pred_labels & y_test.values).sum() / max(test_pred_labels.sum(), 1)
    test_recall_at_op = (test_pred_labels & y_test.values).sum() / max(y_test.sum(), 1)

    results["operating_point"] = {
        "threshold": float(op_threshold),
        "val_precision_at_threshold": float(op_precision),
        "test_precision_at_threshold": float(test_precision_at_op),
        "test_recall_at_threshold": float(test_recall_at_op),
    }
    print(f"\n  Operating point (target 80% recall, tuned on val): threshold={op_threshold:.4f}")
    print(f"    test precision={test_precision_at_op:.3f}  test recall={test_recall_at_op:.3f}")
    print(f"    -> at this threshold, {test_precision_at_op:.0%} of alerts are real elevated-mortality days,")
    print(f"       catching {test_recall_at_op:.0%} of them. Compare against the < 1 false-alarm/pond-week target.")

    shap_sample = X_test.sample(n=min(3000, len(X_test)), random_state=0)
    explainer = shap.TreeExplainer(booster)
    shap_values = explainer.shap_values(shap_sample)
    sv = shap_values[1] if isinstance(shap_values, list) else shap_values
    mean_abs_shap = np.abs(sv).mean(axis=0)
    importance = pd.DataFrame({"feature": feature_cols, "mean_abs_shap": mean_abs_shap}).sort_values(
        "mean_abs_shap", ascending=False)
    importance.to_csv(out_dir / "m2_mortality_risk_shap_importance.csv", index=False)
    print("\nTop SHAP features:")
    print(importance.head(10).to_string(index=False))

    booster.save_model(str(out_dir / "m2_mortality_risk_baseline.txt"))
    with open(out_dir / "m2_mortality_risk_baseline_results.json", "w") as f:
        json.dump(results, f, indent=2)

print("\ndone")
