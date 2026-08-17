"""Run just the growth-model training, with SHAP computed on a capped sample
so it finishes in reasonable time on 280k+ rows. Same logic as train_baseline.py."""
import numpy as np, pandas as pd, lightgbm as lgb, shap, mlflow, json
from pathlib import Path
from sklearn.metrics import mean_absolute_error, mean_squared_error, r2_score
from build_training_tables import SNAPSHOT_FEATURE_COLS, CATEGORICAL_COLS

data_dir, out_dir = Path("data"), Path("models")
table = pd.read_parquet(data_dir / "growth_table.parquet")
target_col = "target_avg_weight_gain_g"
model_name = "m3_daily_growth_baseline"

df = table.copy()
for c in CATEGORICAL_COLS:
    df[c] = df[c].astype("category")
feature_cols = [c for c in SNAPSHOT_FEATURE_COLS if c in df.columns] + CATEGORICAL_COLS
df["aerator_on"] = df["aerator_on"].astype(int)
X = df[feature_cols]; y = df[target_col]; split = df["split"]

train_mask, val_mask, test_mask = split=="train", split=="val", split=="test"
X_train, y_train = X[train_mask], y[train_mask]
X_val, y_val = X[val_mask], y[val_mask]
X_test, y_test = X[test_mask], y[test_mask]
print(f"train={len(X_train)} val={len(X_val)} test={len(X_test)} features={len(feature_cols)}")

train_set = lgb.Dataset(X_train, y_train, categorical_feature=CATEGORICAL_COLS, free_raw_data=False)
val_set = lgb.Dataset(X_val, y_val, categorical_feature=CATEGORICAL_COLS, reference=train_set, free_raw_data=False)
params = {"objective":"regression","metric":"mae","learning_rate":0.05,"num_leaves":31,
          "min_data_in_leaf": max(5, len(X_train)//50), "feature_fraction":0.8,
          "bagging_fraction":0.8,"bagging_freq":1,"verbosity":-1,"seed":0}

mlflow.set_tracking_uri(f"sqlite:///{(out_dir/'mlflow.db').resolve()}")
mlflow.set_experiment("aquaverse_m3_growth")

with mlflow.start_run(run_name=model_name):
    mlflow.log_params(params)
    booster = lgb.train(params, train_set, num_boost_round=500,
                         valid_sets=[train_set, val_set],
                         callbacks=[lgb.early_stopping(30, verbose=False), lgb.log_evaluation(0)])
    results = {}
    for name, Xs, ys in [("train",X_train,y_train),("val",X_val,y_val),("test",X_test,y_test)]:
        preds = booster.predict(Xs, num_iteration=booster.best_iteration)
        mae = mean_absolute_error(ys, preds); rmse = mean_squared_error(ys, preds)**0.5
        r2 = r2_score(ys, preds)
        results[name] = {"mae": mae, "rmse": rmse, "r2": r2, "n": len(Xs)}
        mlflow.log_metric(f"{name}_mae", mae); mlflow.log_metric(f"{name}_rmse", rmse); mlflow.log_metric(f"{name}_r2", r2)
        print(f"  {name:5s}: MAE={mae:.4f}  RMSE={rmse:.4f}  R2={r2:.4f}  (n={len(Xs)})")

    preds_c = booster.predict(X_test, num_iteration=booster.best_iteration)
    cal_df = pd.DataFrame({"y_true": y_test.values, "y_pred": preds_c})
    cal_df["decile"] = pd.qcut(cal_df["y_pred"], q=10, duplicates="drop")
    calibration = cal_df.groupby("decile", observed=True).agg(
        pred_mean=("y_pred","mean"), true_mean=("y_true","mean"), n=("y_true","size")).reset_index(drop=True)
    calibration.to_csv(out_dir / f"{model_name}_calibration_test.csv", index=False)

    # SHAP on a capped random sample for speed
    shap_sample = X_test.sample(n=min(3000, len(X_test)), random_state=0)
    explainer = shap.TreeExplainer(booster)
    shap_values = explainer.shap_values(shap_sample)
    mean_abs_shap = np.abs(shap_values).mean(axis=0)
    importance = pd.DataFrame({"feature": feature_cols, "mean_abs_shap": mean_abs_shap}).sort_values("mean_abs_shap", ascending=False)
    importance.to_csv(out_dir / f"{model_name}_shap_importance.csv", index=False)
    print("Top SHAP features:"); print(importance.head(8).to_string(index=False))

    booster.save_model(str(out_dir / f"{model_name}.txt"))
    with open(out_dir / f"{model_name}_results.json", "w") as f:
        json.dump(results, f, indent=2)
print("done")
