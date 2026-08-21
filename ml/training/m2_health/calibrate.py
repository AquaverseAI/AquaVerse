import os
import json
import sys
import pickle
import matplotlib.pyplot as plt
from pathlib import Path

import torch
import torch.nn as nn
from torch.utils.data import DataLoader
from sklearn.linear_model import LogisticRegression
from sklearn.isotonic import IsotonicRegression
from sklearn.calibration import calibration_curve
from sklearn.metrics import brier_score_loss

REPO_ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(REPO_ROOT))

# Import the fusion model and dataset stub
from ml.training.m2_health.train_fusion import AquaVerseMultimodal, MultimodalStubDataset

ARTIFACTS_DIR = REPO_ROOT / "ml" / "artifacts" / "m2_health"
CALIB_DIR = REPO_ROOT / "ml" / "artifacts" / "calibration"
CALIB_DIR.mkdir(parents=True, exist_ok=True)

IMAGE_BRANCH_PT = ARTIFACTS_DIR / "image_branch" / "frozen_image_branch.pt"
FUSION_PT = ARTIFACTS_DIR / "fusion" / "fusion_stage2_best.pt"
TEMPORAL_METRICS = ARTIFACTS_DIR / "temporal" / "metrics.json"

MLFLOW_URI = os.getenv("MLFLOW_TRACKING_URI", "http://127.0.0.1:5000")
MLFLOW_EXP = os.getenv("MLFLOW_EXPERIMENT_NAME", "aquaverse-production")

def main():
    print("=" * 60)
    print("M2 Probability Calibration — Phase 1, Step 1.5")
    print("=" * 60)

    device = "cuda" if torch.cuda.is_available() else "cpu"
    print(f"Device: {device}")

    # Load Model
    temp_meta = json.load(open(TEMPORAL_METRICS))
    n_features = len(temp_meta["feature_cols"])
    
    model = AquaVerseMultimodal(n_temporal_features=n_features, image_branch_pt=IMAGE_BRANCH_PT)
    model.load_state_dict(torch.load(FUSION_PT, map_location=device, weights_only=True))
    model.to(device)
    model.eval()

    # Create Validation and Test Splits using Stub for Calibration
    torch.manual_seed(42)
    val_ds = MultimodalStubDataset(512, n_features)
    test_ds = MultimodalStubDataset(512, n_features)
    
    val_loader = DataLoader(val_ds, batch_size=32, shuffle=False)
    test_loader = DataLoader(test_ds, batch_size=32, shuffle=False)

    def get_predictions(loader):
        all_preds = []
        all_y = []
        with torch.no_grad():
            for x_t, img, mask, age, y in loader:
                x_t, img, mask, age = x_t.to(device), img.to(device), mask.to(device), age.to(device)
                logits, _ = model(x_t, img, mask, age)
                probs = torch.sigmoid(logits.squeeze())
                all_preds.append(probs.cpu())
                all_y.append(y)
        return torch.cat(all_preds).numpy(), torch.cat(all_y).numpy()

    print("Generating raw predictions...")
    val_preds, val_y = get_predictions(val_loader)
    test_preds, test_y = get_predictions(test_loader)

    print("Fitting Calibrators...")
    # Platt Scaling (Logistic Regression)
    lr_calibrator = LogisticRegression()
    # Scikit-learn requires 2D arrays for features
    lr_calibrator.fit(val_preds.reshape(-1, 1), val_y)
    
    # Isotonic Regression
    iso_calibrator = IsotonicRegression(out_of_bounds='clip')
    iso_calibrator.fit(val_preds, val_y)

    print("Evaluating Calibrators on Test Set...")
    brier_uncalibrated = brier_score_loss(test_y, test_preds)
    
    test_preds_lr = lr_calibrator.predict_proba(test_preds.reshape(-1, 1))[:, 1]
    brier_lr = brier_score_loss(test_y, test_preds_lr)
    
    test_preds_iso = iso_calibrator.predict(test_preds)
    brier_iso = brier_score_loss(test_y, test_preds_iso)

    print(f"  Uncalibrated Brier: {brier_uncalibrated:.4f}")
    print(f"  Platt Scaling Brier: {brier_lr:.4f}")
    print(f"  Isotonic Brier:     {brier_iso:.4f}")

    # Select best
    if brier_lr < brier_iso:
        best_calibrator = lr_calibrator
        best_name = "Platt Scaling"
        best_brier = brier_lr
        best_preds = test_preds_lr
    else:
        best_calibrator = iso_calibrator
        best_name = "Isotonic Regression"
        best_brier = brier_iso
        best_preds = test_preds_iso

    print(f"\n✅ Selected {best_name} as the best calibrator (Brier: {best_brier:.4f})")

    # Plot Reliability Diagram
    plt.figure(figsize=(8, 8))
    
    fraction_of_positives_uncal, mean_predicted_value_uncal = calibration_curve(test_y, test_preds, n_bins=10)
    fraction_of_positives_cal, mean_predicted_value_cal = calibration_curve(test_y, best_preds, n_bins=10)

    plt.plot(mean_predicted_value_uncal, fraction_of_positives_uncal, "s-", label="Uncalibrated")
    plt.plot(mean_predicted_value_cal, fraction_of_positives_cal, "s-", label=f"Calibrated ({best_name})")
    plt.plot([0, 1], [0, 1], "k:", label="Perfectly calibrated")
    
    plt.ylabel("Fraction of positives")
    plt.xlabel("Mean predicted value")
    plt.title("Reliability Diagram (Calibration Curve)")
    plt.legend(loc="lower right")
    plt.grid(True)
    
    plot_path = CALIB_DIR / "reliability_diagram.png"
    plt.savefig(plot_path)
    plt.close()
    
    # Save the selected calibrator
    calibrator_path = ARTIFACTS_DIR / "calibrator.pkl"
    with open(calibrator_path, "wb") as f:
        pickle.dump(best_calibrator, f)
        
    print(f"Saved calibrator artifact to {calibrator_path}")
    print(f"Saved reliability diagram to {plot_path}")

    # MLflow
    try:
        import mlflow
        mlflow.set_tracking_uri(MLFLOW_URI)
        mlflow.set_experiment(MLFLOW_EXP)
        with mlflow.start_run(run_name="probability_calibration"):
            mlflow.log_params({"best_calibrator": best_name})
            mlflow.log_metrics({"brier_uncalibrated": float(brier_uncalibrated),
                                "brier_calibrated": float(best_brier),
                                "brier_improvement": float(brier_uncalibrated - best_brier)})
            mlflow.set_tags({"phase": "1.5_calibration"})
            mlflow.log_artifact(str(calibrator_path))
            mlflow.log_artifact(str(plot_path))
        print("Logged to MLflow successfully.")
    except Exception as e:
        print(f"MLflow error: {e}")

if __name__ == "__main__":
    main()
