"""
Phase 3, step 2: LightGBM numeric baseline.

Trains two regressors:
  1. overnight_do_min  -- the highest-value single forecast in the system
  2. daily_biomass_gain -- feeds M3 harvest-date/size projection and running FCR

Both respect pond-wise/time-wise split assignment from the manifest (R3) --
no random row split, ever. Logs to a local MLflow file store (no network
required, satisfies R9 free-tier and the citation-discipline / audit-trail
requirement from PRD §10).

Evaluation matches what the PRD and MVP spec say reviewers will check:
  - MAE / RMSE, not just R^2 (a fisheries officer wants "how many mg/L off")
  - calibration: predicted vs observed on binned deciles
  - SHAP attribution, exact for tree models -- this becomes the
    `top_temporal_features` payload the M1/M3 reasoning LLM narrates,
    never invents.
"""

from __future__ import annotations
import argparse
import json
from pathlib import Path

import numpy as np
import pandas as pd
import lightgbm as lgb
import shap
import mlflow
from sklearn.metrics import mean_absolute_error, mean_squared_error, r2_score

from build_training_tables import SNAPSHOT_FEATURE_COLS, CATEGORICAL_COLS


def prepare_xy(table: pd.DataFrame, target_col: str):
    df = table.copy()
    for c in CATEGORICAL_COLS:
        df[c] = df[c].astype("category")
    feature_cols = [c for c in SNAPSHOT_FEATURE_COLS if c in df.columns] + CATEGORICAL_COLS
    df["aerator_on"] = df["aerator_on"].astype(int)
    X = df[feature_cols]
    y = df[target_col]
    return X, y, feature_cols, df["split"]


def train_one_target(table_path: Path, target_col: str, model_name: str,
                      mlflow_experiment: str, out_dir: Path):
    table = pd.read_parquet(table_path)
    X, y, feature_cols, split = prepare_xy(table, target_col)

    train_mask = split == "train"
    val_mask = split == "val"
    test_mask = split == "test"

    X_train, y_train = X[train_mask], y[train_mask]
    X_val, y_val = X[val_mask], y[val_mask]
    X_test, y_test = X[test_mask], y[test_mask]

    print(f"\n=== {model_name} ===")
    print(f"train={len(X_train)}  val={len(X_val)}  test={len(X_test)}  features={len(feature_cols)}")

    if len(X_train) < 20 or len(X_val) < 5:
        print("WARNING: too few rows for a meaningful split on this trial batch — "
              "results below are a pipeline smoke test, not a real evaluation. "
              "Re-run once the full 5,000-cycle corpus finishes generating.")

    train_set = lgb.Dataset(X_train, y_train, categorical_feature=CATEGORICAL_COLS, free_raw_data=False)
    val_set = lgb.Dataset(X_val, y_val, categorical_feature=CATEGORICAL_COLS, reference=train_set, free_raw_data=False)

    params = {
        "objective": "regression",
        "metric": "mae",
        "learning_rate": 0.05,
        "num_leaves": 31,
        "min_data_in_leaf": max(5, len(X_train) // 50),
        "feature_fraction": 0.8,
        "bagging_fraction": 0.8,
        "bagging_freq": 1,
        "verbosity": -1,
        "seed": 0,
    }

    mlflow.set_tracking_uri(f"sqlite:///{(out_dir / 'mlflow.db').resolve()}")
    mlflow.set_experiment(mlflow_experiment)

    with mlflow.start_run(run_name=model_name):
        mlflow.log_params(params)
        mlflow.log_param("n_train", len(X_train))
        mlflow.log_param("n_val", len(X_val))
        mlflow.log_param("n_test", len(X_test))
        mlflow.log_param("features", feature_cols)

        booster = lgb.train(
            params,
            train_set,
            num_boost_round=500,
            valid_sets=[train_set, val_set] if len(X_val) else [train_set],
            callbacks=[lgb.early_stopping(30, verbose=False), lgb.log_evaluation(0)],
        )

        results = {}
        for name, Xs, ys in [("train", X_train, y_train), ("val", X_val, y_val), ("test", X_test, y_test)]:
            if len(Xs) == 0:
                continue
            preds = booster.predict(Xs, num_iteration=booster.best_iteration)
            mae = mean_absolute_error(ys, preds)
            rmse = mean_squared_error(ys, preds) ** 0.5
            r2 = r2_score(ys, preds) if len(ys) > 1 else float("nan")
            results[name] = {"mae": mae, "rmse": rmse, "r2": r2, "n": len(Xs)}
            mlflow.log_metric(f"{name}_mae", mae)
            mlflow.log_metric(f"{name}_rmse", rmse)
            mlflow.log_metric(f"{name}_r2", r2)
            print(f"  {name:5s}: MAE={mae:.4f}  RMSE={rmse:.4f}  R2={r2:.4f}  (n={len(Xs)})")

        # calibration: predicted vs observed in deciles, on whichever split has enough rows
        cal_split = "test" if len(X_test) >= 20 else ("val" if len(X_val) >= 20 else "train")
        Xc, yc = {"train": (X_train, y_train), "val": (X_val, y_val), "test": (X_test, y_test)}[cal_split]
        if len(Xc) >= 10:
            preds_c = booster.predict(Xc, num_iteration=booster.best_iteration)
            cal_df = pd.DataFrame({"y_true": yc.values, "y_pred": preds_c})
            cal_df["decile"] = pd.qcut(cal_df["y_pred"], q=min(10, len(cal_df) // 2), duplicates="drop")
            calibration = cal_df.groupby("decile", observed=True).agg(
                pred_mean=("y_pred", "mean"), true_mean=("y_true", "mean"), n=("y_true", "size")
            ).reset_index(drop=True)
            calibration.to_csv(out_dir / f"{model_name}_calibration_{cal_split}.csv", index=False)
            mlflow.log_artifact(str(out_dir / f"{model_name}_calibration_{cal_split}.csv"))

        # SHAP attribution -- exact for tree models, this is what the LLM narrates
        shap_split = cal_split
        if len(Xc) >= 5:
            explainer = shap.TreeExplainer(booster)
            shap_values = explainer.shap_values(Xc)
            mean_abs_shap = np.abs(shap_values).mean(axis=0)
            importance = pd.DataFrame({
                "feature": feature_cols, "mean_abs_shap": mean_abs_shap
            }).sort_values("mean_abs_shap", ascending=False)
            importance.to_csv(out_dir / f"{model_name}_shap_importance.csv", index=False)
            mlflow.log_artifact(str(out_dir / f"{model_name}_shap_importance.csv"))
            print(f"  Top SHAP features ({shap_split}):")
            print(importance.head(8).to_string(index=False))

        model_path = out_dir / f"{model_name}.txt"
        booster.save_model(str(model_path))
        mlflow.log_artifact(str(model_path))

        with open(out_dir / f"{model_name}_results.json", "w") as f:
            json.dump(results, f, indent=2)

    return booster, results


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--data_dir", type=str, default="data")
    parser.add_argument("--out_dir", type=str, default="models")
    args = parser.parse_args()

    data_dir = Path(args.data_dir)
    out_dir = Path(args.out_dir)
    out_dir.mkdir(parents=True, exist_ok=True)

    train_one_target(
        data_dir / "do_forecast_table.parquet",
        target_col="target_night_do_min",
        model_name="do_overnight_min_baseline",
        mlflow_experiment="aquaverse_m1_do_forecast",
        out_dir=out_dir,
    )

    train_one_target(
        data_dir / "growth_table.parquet",
        target_col="target_avg_weight_gain_g",
        model_name="m3_daily_growth_baseline",
        mlflow_experiment="aquaverse_m3_growth",
        out_dir=out_dir,
    )


if __name__ == "__main__":
    main()
