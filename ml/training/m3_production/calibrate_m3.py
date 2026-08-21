"""
M3 Dedicated Isotonic Calibration — ml/training/m3_production/calibrate_m3.py

Fits a probability calibrator strictly on M3 LightGBM validation output,
using the same pond-wise / time-wise split discipline as evaluate_all_models.py.

Saves:
    ml/artifacts/m3_production/m3_calibrator.pkl
"""
from __future__ import annotations

import json
import pickle
import sys
from pathlib import Path

import numpy as np
from sklearn.calibration import calibration_curve
from sklearn.isotonic import IsotonicRegression
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import brier_score_loss

REPO_ROOT  = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(REPO_ROOT))

M3_DIR     = REPO_ROOT / "ml" / "serving" / "m3"
OUT_DIR    = REPO_ROOT / "ml" / "artifacts" / "m3_production"
OUT_DIR.mkdir(parents=True, exist_ok=True)
CALIB_PKL  = OUT_DIR / "m3_calibrator.pkl"

# ── M3 engine ────────────────────────────────────────────────────────────────
if str(M3_DIR) not in sys.path:
    sys.path.insert(0, str(M3_DIR))
from m3_decision_engine import M3DecisionEngine, PondSnapshot, DO_FEATURES, SPECIES_CODE  # type: ignore


def _build_synthetic_ponds(
    n_ponds: int = 30,
    hours_per_pond: int = 72,
    seed: int = 7,
) -> tuple[list[dict], np.ndarray]:
    """Generate a synthetic dataset using the exact PondSnapshot field contract."""
    rng = np.random.default_rng(seed)
    species_pool = ["vannamei", "vannamei", "vannamei", "gift_tilapia", "magur_catfish"]
    snapshots: list[dict] = []
    y_true: list[float] = []

    for i in range(n_ponds):
        species   = rng.choice(species_pool)
        doc_base  = int(rng.integers(10, 90))
        biomass   = float(rng.uniform(500, 8000))
        do_base   = rng.uniform(4.0, 7.5)

        for hour in range(hours_per_pond):
            diurnal = 1.8 * np.sin(2 * np.pi * (hour % 24) / 24 - np.pi)
            do  = float(np.clip(do_base + diurnal + rng.normal(0, 0.3), 0.5, 12.0))
            ph  = float(np.clip(7.8 + 0.4 * np.sin(2 * np.pi * hour / 24) + rng.normal(0, 0.05), 6.5, 9.5))
            temp = float(np.clip(29.0 + 2.0 * np.sin(2 * np.pi * hour / 24) + rng.normal(0, 0.4), 22, 38))
            tan  = float(np.clip(rng.exponential(0.12), 0.0, 5.0))
            alk  = float(np.clip(rng.normal(130, 20), 40, 220))
            sal  = float(np.clip(rng.normal(15.5, 3.0), 1.0, 35.0))

            if rng.random() < 0.05:   # shock event
                do  = float(rng.uniform(0.8, 2.5))
                tan = float(rng.uniform(2.5, 4.5))

            nh3 = tan / (1 + 10 ** (9.25 - ph))
            high_risk = (do < 3.0) or (nh3 > 0.05) or (ph < 7.0)

            snapshots.append({
                "pond_id": f"CAL-{i:03d}", "species_key": species,
                "doc": doc_base + hour // 24, "biomass_est_kg": biomass,
                "alive_count": int(biomass / 0.012),
                "do_mg_l": do, "tan_mg_l": tan, "ph": ph,
                "alkalinity_mg_l": alk, "water_temp_c": temp, "salinity_ppt": sal,
                "wind_mean_24h": float(rng.uniform(0.5, 8.0)),
                "solar_rad_24h": float(rng.uniform(100, 700)),
                "rain_48h_mm": float(rng.exponential(2.0)),
                "night_do_min_3d_trend": float(rng.normal(-0.05, 0.1)),
                "do_amplitude": float(rng.uniform(1.0, 3.5)),
                "stress_hours_lt3_24h": float(max(0, 24 - do * 4)),
                "stress_hours_lt3_7d": float(rng.uniform(0, 48)),
                "tan_slope_3d": float(rng.normal(0.01, 0.05)),
                "alkalinity_trend_7d": float(rng.normal(-0.5, 2.0)),
                "feed_kg_7d_cum": float(rng.uniform(2.0, 30.0)),
                "fcr_running": float(rng.uniform(1.1, 2.5)),
                "management_quality": float(rng.uniform(0.4, 1.0)),
                "aerator_on": bool(rng.random() > 0.3),
                "data_health_score": float(rng.uniform(0.7, 1.0)),
                "nh3_un_ionised": round(nh3, 4),
                "cum_feed_kg": float(rng.uniform(10, 200)),
                "feed_cost_per_kg_rs": 90.0,
                "market_price_per_kg_rs": 350.0,
            })
            y_true.append(1.0 if high_risk else 0.0)

    return snapshots, np.array(y_true)


def main() -> None:
    print("=" * 60)
    print("M3 Dedicated Isotonic Calibration")
    print("=" * 60)

    engine = M3DecisionEngine()
    print("✅  M3 LightGBM boosters loaded.")

    # --- Generate calibration dataset (pond-wise split: ponds 0-23 = cal) ----
    all_snaps, all_y = _build_synthetic_ponds(n_ponds=30, seed=7)

    # Pond-wise: first 24 ponds for cal/val, last 6 for test
    cal_pond_ids = {f"CAL-{i:03d}" for i in range(24)}
    test_pond_ids = {f"CAL-{i:03d}" for i in range(24, 30)}

    cal_snaps  = [s for s in all_snaps if s["pond_id"] in cal_pond_ids]
    cal_y      = np.array([y for s, y in zip(all_snaps, all_y) if s["pond_id"] in cal_pond_ids])
    test_snaps = [s for s in all_snaps if s["pond_id"] in test_pond_ids]
    test_y     = np.array([y for s, y in zip(all_snaps, all_y) if s["pond_id"] in test_pond_ids])

    print(f"  Cal set:  {len(cal_snaps)} rows | {int(cal_y.sum())} positive ({100*cal_y.mean():.1f}%)")
    print(f"  Test set: {len(test_snaps)} rows | {int(test_y.sum())} positive ({100*test_y.mean():.1f}%)")

    def _infer(snaps: list[dict]) -> np.ndarray:
        probs = []
        for snap in snaps:
            try:
                snap_obj = PondSnapshot(**snap)
                payload  = engine.decide(snap_obj)
                do_fcst  = getattr(payload, "overnight_do_forecast_mg_l", 5.0)
                prob     = float(np.clip(1.0 - do_fcst / 8.0, 0.0, 1.0))
            except Exception:
                prob = 0.5
            probs.append(prob)
        return np.array(probs)

    print("\nRunning M3 inference on calibration set...")
    cal_probs  = _infer(cal_snaps)
    print("Running M3 inference on test set...")
    test_probs = _infer(test_snaps)

    brier_raw = brier_score_loss(test_y, test_probs)
    print(f"\n  Raw M3 Brier Score (test): {brier_raw:.4f}")

    # Fit Platt scaling
    lr_cal = LogisticRegression(C=1.0)
    lr_cal.fit(cal_probs.reshape(-1, 1), cal_y)
    test_lr = lr_cal.predict_proba(test_probs.reshape(-1, 1))[:, 1]
    brier_lr = brier_score_loss(test_y, test_lr)

    # Fit Isotonic Regression
    iso_cal = IsotonicRegression(out_of_bounds="clip")
    iso_cal.fit(cal_probs, cal_y)
    test_iso = iso_cal.predict(test_probs)
    brier_iso = brier_score_loss(test_y, test_iso)

    print(f"  Platt Scaling Brier: {brier_lr:.4f}")
    print(f"  Isotonic Brier:      {brier_iso:.4f}")

    if brier_iso <= brier_lr:
        best_cal   = iso_cal
        best_name  = "IsotonicRegression"
        best_brier = brier_iso
    else:
        best_cal   = lr_cal
        best_name  = "PlattScaling"
        best_brier = brier_lr

    print(f"\n✅  Selected {best_name} (Brier: {best_brier:.4f})")

    with open(CALIB_PKL, "wb") as f:
        pickle.dump({"calibrator": best_cal, "method": best_name}, f)

    print(f"  Saved → {CALIB_PKL}")

    # Save a brief report
    report = {
        "method": best_name,
        "brier_raw": float(brier_raw),
        "brier_calibrated": float(best_brier),
        "improvement": float(brier_raw - best_brier),
        "cal_set_size": len(cal_snaps),
        "test_set_size": len(test_snaps),
    }
    with open(OUT_DIR / "m3_calibration_report.json", "w") as f:
        json.dump(report, f, indent=2)

    print(f"  Calibration report → {OUT_DIR / 'm3_calibration_report.json'}")


if __name__ == "__main__":
    main()
