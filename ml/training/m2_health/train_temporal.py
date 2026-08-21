"""Train the M2 Temporal Branch — PRD-AV-02 Phase 1, Step 1.1.

Sequential training order (MANDATORY — do not train jointly):
  Step 1.1 → Temporal branch  ← YOU ARE HERE
  Step 1.2 → Image branch (standalone, then freeze)
  Step 1.3 → Gated fusion + head
  Step 1.4 → End-to-end fine-tune at 1/10th LR
  Step 1.5 → Calibration

Model selection (PRD §5.4):
  If ≥ 50 real ponds available → Temporal Fusion Transformer [Ref 9]
  Else                         → PatchTST [Ref 10]  (synthetic only)
  Fallback                     → EBM over engineered features [Ref 12]

Splits: POND-WISE AND TIME-WISE. Never random. (Rule R3)
Loss:   Focal or class-balanced BCE (outbreaks are rare).
Device: cuda:0 — RTX 5070 12 GB

Engineered features (PRD §5.4):
  night_DO_min, DO_amplitude, stress_hours_below_3mgl, TAN_slope_3d,
  alkalinity_trend, rain_last_48h (stubbed until weather API connected)

MLflow tags:
  hardware=RTX5070-12GB, cuda=13.2, compute=local-workstation

Usage:
  conda activate aquaverse-ml
  python ml/training/m2_health/train_temporal.py [--model ebm|patchtst|tft] [--epochs 20]

References
----------
[9]  Lim et al. (2021). Temporal Fusion Transformers. Int. J. Forecasting 37(4).
[10] Nie et al. (2023). PatchTST. ICLR 2023.
[12] Nori et al. (2019). InterpretML / Explainable Boosting Machine. arXiv:1909.09223.
[3]  AquaVerse AI Hybrid Explainable Multimodal Model (internal, v1).
"""

from __future__ import annotations

import argparse
import json
import os
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(REPO_ROOT))

DATASET_DIR  = REPO_ROOT / "ml" / "datasets" / "synthetic_cycles"
MANIFEST     = DATASET_DIR / "manifest.json"
ARTIFACTS    = REPO_ROOT / "ml" / "artifacts" / "m2_health" / "temporal"
ARTIFACTS.mkdir(parents=True, exist_ok=True)

MLFLOW_URI   = os.getenv("MLFLOW_TRACKING_URI", "http://127.0.0.1:5000")
MLFLOW_EXP   = os.getenv("MLFLOW_EXPERIMENT_NAME", "aquaverse-production")


# ---------------------------------------------------------------------------
# Feature engineering — PRD §5.4
# ---------------------------------------------------------------------------

def engineer_features(df: "pd.DataFrame") -> "pd.DataFrame":
    """
    Compute the engineered temporal features described in PRD §5.4.
    Input: raw hourly rows from the synthetic-cycle Parquet files.
    Output: same DataFrame with extra feature columns.
    """
    import numpy as np

    # Night minimum DO: min DO between 22:00 and 05:00 local hour
    df["is_night"] = (df["hour_of_day"] >= 22) | (df["hour_of_day"] <= 5)
    night_do = (df[df["is_night"]]
                .groupby(["cycle_id", "day"])["do_surface_mgl"]
                .min()
                .reset_index()
                .rename(columns={"do_surface_mgl": "night_DO_min"}))
    df = df.merge(night_do, on=["cycle_id", "day"], how="left")

    # Diurnal DO amplitude: max - min per day
    daily_do = (df.groupby(["cycle_id", "day"])["do_surface_mgl"]
                .agg(do_max="max", do_min="min")
                .reset_index())
    daily_do["DO_amplitude"] = daily_do["do_max"] - daily_do["do_min"]
    df = df.merge(daily_do[["cycle_id", "day", "DO_amplitude"]], on=["cycle_id", "day"], how="left")

    # Stress-hours below 3 mg/L — already in the raw data
    # (stress_hours_below_3mgl is cumulative — take daily delta)
    df = df.sort_values(["cycle_id", "hour"])
    df["stress_hours_24h"] = (df.groupby("cycle_id")["stress_hours_below_3mgl"]
                              .diff().fillna(0).clip(lower=0))

    # 3-day TAN slope (mg/L/day) — from raw tan column
    df["TAN_slope_3d"] = (df.groupby("cycle_id")["tan_mgl"]
                          .transform(lambda x: x.diff(periods=72).fillna(0) / 3.0))

    # Alkalinity trend (3-day slope, mg/L/day)
    df["alk_trend_3d"] = (df.groupby("cycle_id")["alkalinity_mgl"]
                          .transform(lambda x: x.diff(periods=72).fillna(0) / 3.0))

    # Rain last 48h — stubbed at 0 until Open-Meteo [Ref 38] is wired
    df["rain_last_48h_mm"] = 0.0

    return df


def build_daily_features(df: "pd.DataFrame") -> "pd.DataFrame":
    """
    Collapse hourly data to daily summary rows — one row per (cycle_id, day).
    These are the rows used to train the risk model.
    """
    import numpy as np
    agg = df.groupby(["cycle_id", "day"]).agg(
        species            =("species", "first"),
        season             =("season", "first"),
        management_quality =("management_quality", "first"),
        fault_injected     =("fault_injected", "first"),
        fault_type         =("fault_type", "first"),
        pond_area_m2       =("pond_area_m2", "first"),
        stocking_density   =("stocking_density", "first"),
        n_aerators         =("n_aerators", "first"),
        # Water chemistry (daily mean)
        do_mean            =("do_surface_mgl", "mean"),
        do_min             =("do_surface_mgl", "min"),
        do_max             =("do_surface_mgl", "max"),
        night_DO_min       =("night_DO_min", "min"),
        DO_amplitude       =("DO_amplitude", "first"),
        temp_mean          =("temp_c", "mean"),
        ph_mean            =("ph", "mean"),
        tan_mean           =("tan_mgl", "mean"),
        no2_mean           =("no2_mgl", "mean"),
        alkalinity_mean    =("alkalinity_mgl", "mean"),
        TAN_slope_3d       =("TAN_slope_3d", "last"),
        alk_trend_3d       =("alk_trend_3d", "last"),
        stress_hours_24h   =("stress_hours_24h", "sum"),
        stress_hours_total =("stress_hours_below_3mgl", "max"),
        rain_last_48h_mm   =("rain_last_48h_mm", "first"),
        # Biomass
        mean_weight_g      =("mean_weight_g", "last"),
        survival_fraction  =("survival_fraction", "last"),
        # Flags
        stratified         =("stratified", "max"),
        sensor_fault       =("sensor_fault", "max"),
        aerator_failed     =("aerator_failed", "max"),
    ).reset_index()

    # Label: health risk = 1 when the pond shows a stress signature.
    # Uses OR logic so we capture all fault types in the synthetic dataset.
    # Positive rate ≈ fault_injection_rate (20%) — matches PRD §5.1 [2].
    # Real labels from Vishi's disease data will replace this proxy (PRD-AV-03).
    agg["risk_label"] = (
        agg["fault_injected"].astype(int) |
        (agg["do_min"] < 3.0).astype(int) |
        (agg["stress_hours_24h"] > 1.0).astype(int) |
        agg["aerator_failed"].astype(int)
    ).astype(int).clip(0, 1)

    return agg


# ---------------------------------------------------------------------------
# Train / validation split — POND-WISE AND TIME-WISE (Rule R3)
# ---------------------------------------------------------------------------

def split_pond_time_wise(df: "pd.DataFrame",
                         val_fraction: float = 0.15,
                         test_fraction: float = 0.15,
                         seed: int = 42) -> tuple:
    """
    Pond-wise split: hold out the last `test_fraction` of pond IDs
    (sorted by cycle_id) for test.  Within remaining ponds, hold out
    the last `val_fraction` of days for validation.

    RULE R3: Never use random row-level splits — adjacent hours leak completely.
    """
    import numpy as np

    all_cycles = sorted(df["cycle_id"].unique())
    n = len(all_cycles)

    n_test = max(1, int(n * test_fraction))
    n_val_ponds = max(1, int((n - n_test) * 0.3))  # 30% of train ponds → time-wise val

    test_cycles  = set(all_cycles[-n_test:])
    val_cycles   = set(all_cycles[-(n_test + n_val_ponds):-n_test])
    train_cycles = set(all_cycles[:-(n_test + n_val_ponds)])

    train_df = df[df["cycle_id"].isin(train_cycles)].copy()
    val_df   = df[df["cycle_id"].isin(val_cycles)].copy()
    test_df  = df[df["cycle_id"].isin(test_cycles)].copy()

    # Time-wise: for validation ponds, further restrict to last 30 days only
    max_day = df["day"].max()
    val_df  = val_df[val_df["day"] >= max_day * (1 - val_fraction)]

    print(f"  Split (pond-wise + time-wise) [Rule R3]:")
    print(f"    Train: {len(train_cycles)} ponds, {len(train_df):,} rows, "
          f"label_rate={train_df['risk_label'].mean():.3f}")
    print(f"    Val:   {len(val_cycles)} ponds (last {val_fraction*100:.0f}% days), "
          f"{len(val_df):,} rows")
    print(f"    Test:  {len(test_cycles)} ponds, {len(test_df):,} rows")

    return train_df, val_df, test_df


# ---------------------------------------------------------------------------
# EBM (Explainable Boosting Machine) — fallback, works on all data sizes [12]
# ---------------------------------------------------------------------------

FEATURE_COLS = [
    "day", "stocking_density", "n_aerators", "pond_area_m2",
    "do_mean", "do_min", "do_max", "night_DO_min", "DO_amplitude",
    "temp_mean", "ph_mean", "tan_mean", "no2_mean", "alkalinity_mean",
    "TAN_slope_3d", "alk_trend_3d",
    "stress_hours_24h", "stress_hours_total", "rain_last_48h_mm",
    "stratified", "aerator_failed",
]


def train_ebm(train_df: "pd.DataFrame", val_df: "pd.DataFrame") -> tuple:
    """Train an Explainable Boosting Machine on daily features. [12]"""
    from interpret.glassbox import ExplainableBoostingClassifier
    from sklearn.metrics import roc_auc_score, average_precision_score, brier_score_loss
    import numpy as np

    X_train = train_df[FEATURE_COLS].fillna(0).values
    y_train = train_df["risk_label"].values
    X_val   = val_df[FEATURE_COLS].fillna(0).values
    y_val   = val_df["risk_label"].values

    # Class-balanced weights (outbreaks are rare — PRD §5.5)
    pos_weight = (y_train == 0).sum() / max((y_train == 1).sum(), 1)
    sample_weight = np.where(y_train == 1, pos_weight, 1.0)

    model = ExplainableBoostingClassifier(
        n_jobs=-1,
        random_state=42,
        max_rounds=300,
        learning_rate=0.05,
        min_samples_leaf=5,
    )
    model.fit(X_train, y_train, sample_weight=sample_weight)

    val_proba = model.predict_proba(X_val)[:, 1]
    metrics = {
        "val_auc_pr":    float(average_precision_score(y_val, val_proba)),
        "val_auc_roc":   float(roc_auc_score(y_val, val_proba)) if y_val.sum() > 0 else 0.0,
        "val_brier":     float(brier_score_loss(y_val, val_proba)),
        "val_pos_rate":  float(y_val.mean()),
    }
    return model, metrics


def train_lightgbm(train_df: "pd.DataFrame", val_df: "pd.DataFrame") -> tuple:
    """Train a LightGBM model — faster than EBM, similar SHAP support. [11]"""
    import lightgbm as lgb
    import numpy as np
    from sklearn.metrics import average_precision_score, roc_auc_score, brier_score_loss

    X_train = train_df[FEATURE_COLS].fillna(0).values
    y_train = train_df["risk_label"].values
    X_val   = val_df[FEATURE_COLS].fillna(0).values
    y_val   = val_df["risk_label"].values

    pos_weight = (y_train == 0).sum() / max((y_train == 1).sum(), 1)

    model = lgb.LGBMClassifier(
        n_estimators=500,
        learning_rate=0.05,
        num_leaves=31,
        scale_pos_weight=pos_weight,
        random_state=42,
        n_jobs=-1,
        device="gpu",
        verbose=-1,
    )
    model.fit(
        X_train, y_train,
        eval_set=[(X_val, y_val)],
        callbacks=[lgb.early_stopping(50, verbose=False), lgb.log_evaluation(period=100)],
    )

    val_proba = model.predict_proba(X_val)[:, 1]
    metrics = {
        "val_auc_pr":    float(average_precision_score(y_val, val_proba)),
        "val_auc_roc":   float(roc_auc_score(y_val, val_proba)) if y_val.sum() > 0 else 0.0,
        "val_brier":     float(brier_score_loss(y_val, val_proba)),
        "val_pos_rate":  float(y_val.mean()),
    }
    return model, metrics


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main(model_type: str = "lightgbm", n_batches: int | None = None) -> None:
    import pickle, time
    import numpy as np

    try:
        import pandas as pd
    except ImportError:
        print("❌ pandas not installed. Run: pip install pandas pyarrow")
        sys.exit(1)

    print("=" * 60)
    print("M2 Temporal Branch Training — PRD-AV-02 Phase 1, Step 1.1")
    print(f"Model: {model_type.upper()} | Rule R3: pond-wise + time-wise split")
    print("=" * 60)

    if not MANIFEST.exists():
        print(f"❌ Dataset manifest not found: {MANIFEST}")
        print("   Run generate_synthetic_cycles.py first.")
        sys.exit(1)

    manifest = json.load(open(MANIFEST))
    parquet_files = manifest["parquet_files"]
    if n_batches:
        parquet_files = parquet_files[:n_batches]

    # Load dataset
    print(f"\n📂 Loading {len(parquet_files)} parquet files …")
    t0 = time.perf_counter()
    dfs = []
    for pf in parquet_files:
        if Path(pf).exists():
            dfs.append(pd.read_parquet(pf))
        else:
            print(f"  ⚠️  Missing: {pf}")
    if not dfs:
        print("❌ No parquet files found. Re-run generate_synthetic_cycles.py")
        sys.exit(1)
    raw = pd.concat(dfs, ignore_index=True)
    print(f"  Loaded {len(raw):,} rows in {time.perf_counter()-t0:.1f}s")

    # Feature engineering
    print("\n⚙️  Engineering features (PRD §5.4) …")
    raw = engineer_features(raw)
    daily = build_daily_features(raw)
    print(f"  Daily rows: {len(daily):,}  |  risk_label rate: {daily['risk_label'].mean():.3f}")

    # Split
    print("\n✂️  Splitting dataset …")
    train_df, val_df, test_df = split_pond_time_wise(daily)

    # Train
    print(f"\n🏋️  Training {model_type.upper()} …")
    t_train = time.perf_counter()

    if model_type == "ebm":
        try:
            model, metrics = train_ebm(train_df, val_df)
        except ImportError:
            print("  interpret not installed — falling back to LightGBM")
            model_type = "lightgbm"
            model, metrics = train_lightgbm(train_df, val_df)
    else:
        try:
            model, metrics = train_lightgbm(train_df, val_df)
        except ImportError:
            print("  lightgbm not installed — falling back to EBM")
            model_type = "ebm"
            model, metrics = train_ebm(train_df, val_df)

    train_time = time.perf_counter() - t_train
    print(f"  Training done in {train_time:.1f}s")

    # Test evaluation
    from sklearn.metrics import average_precision_score, roc_auc_score, brier_score_loss
    X_test  = test_df[FEATURE_COLS].fillna(0).values
    y_test  = test_df["risk_label"].values
    test_proba = model.predict_proba(X_test)[:, 1]
    # Calculate average lead time (hours) on test set
    test_df_copy = test_df.copy()
    test_df_copy["pred_prob"] = test_proba
    test_df_copy["pred_class"] = (test_proba > 0.5).astype(int)
    
    lead_times = []
    for cid, group in test_df_copy.groupby("cycle_id"):
        # Check if fault actually occurs in this cycle
        fault_days = group[group["risk_label"] == 1]["day"]
        if not fault_days.empty:
            actual_first_day = fault_days.min()
            # Find earliest predicted fault day at or before the actual fault
            pred_days = group[(group["pred_class"] == 1) & (group["day"] <= actual_first_day)]["day"]
            if not pred_days.empty:
                pred_first_day = pred_days.min()
                lead_time_hours = (actual_first_day - pred_first_day) * 24.0
                lead_times.append(lead_time_hours)
    
    avg_lead_time_hr = float(np.mean(lead_times)) if lead_times else 0.0

    test_metrics = {
        "test_auc_pr":  float(average_precision_score(y_test, test_proba)),
        "test_auc_roc": float(roc_auc_score(y_test, test_proba)) if y_test.sum() > 0 else 0.0,
        "test_brier":   float(brier_score_loss(y_test, test_proba)),
        "test_lead_time_hours": avg_lead_time_hr,
    }
    metrics.update(test_metrics)
    metrics["train_time_s"] = round(train_time, 1)

    print(f"\n📊 Metrics:")
    print(f"  Val  AUC-PR:  {metrics['val_auc_pr']:.4f}   (use this — not AUC-ROC)")
    print(f"  Val  AUC-ROC: {metrics['val_auc_roc']:.4f}")
    print(f"  Val  Brier:   {metrics['val_brier']:.4f}")
    print(f"  Test AUC-PR:  {metrics['test_auc_pr']:.4f}")
    print(f"  Test Brier:   {metrics['test_brier']:.4f}")
    print(f"  Test Lead Time: {metrics['test_lead_time_hours']:.1f} hours")

    # Save artefact
    model_path = ARTIFACTS / f"temporal_{model_type}_v1.pkl"
    with open(model_path, "wb") as f:
        pickle.dump({"model": model, "feature_cols": FEATURE_COLS,
                     "model_type": model_type, "metrics": metrics,
                     "dataset_hash": manifest["dataset_hash"]}, f)

    metrics_path = ARTIFACTS / "metrics.json"
    with open(metrics_path, "w") as f:
        json.dump({**metrics, "model_type": model_type,
                   "dataset_hash": manifest["dataset_hash"],
                   "feature_cols": FEATURE_COLS}, f, indent=2)
    print(f"\n  Model saved: {model_path}")
    print(f"  Metrics saved: {metrics_path}")

    # MLflow
    try:
        import mlflow
        mlflow.set_tracking_uri(MLFLOW_URI)
        mlflow.set_experiment(MLFLOW_EXP)
        with mlflow.start_run(run_name=f"temporal_branch_{model_type}_v1"):
            mlflow.log_params({
                "model_type":     model_type,
                "n_train_ponds":  daily["cycle_id"].nunique(),
                "n_features":     len(FEATURE_COLS),
                "split":          "pond-wise+time-wise (R3)",
                "dataset_hash":   manifest["dataset_hash"],
            })
            mlflow.log_metrics(metrics)
            mlflow.set_tags({
                "phase":     "1.1_temporal_branch",
                "hardware":  os.getenv("MLFLOW_TAGS_HARDWARE", "RTX5070-12GB"),
                "compute":   os.getenv("MLFLOW_TAGS_COMPUTE", "local-workstation"),
                "ref":       "[9,10,12]",
                "rule_r3":   "pond-wise-time-wise-split",
            })
            mlflow.log_artifact(str(model_path))
            mlflow.log_artifact(str(metrics_path))
            run_id = mlflow.active_run().info.run_id
        print(f"  MLflow run: {run_id}")
    except Exception as e:
        print(f"  MLflow not available ({e})")

    print(f"\n✅ Temporal branch training complete.")
    print(f"   Next step: train_image_branch.py (Step 1.2)")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--model",    choices=["lightgbm", "ebm"], default="lightgbm")
    parser.add_argument("--batches",  type=int, default=None,
                        help="Limit number of Parquet batches to load (for quick testing)")
    args = parser.parse_args()
    main(model_type=args.model, n_batches=args.batches)
