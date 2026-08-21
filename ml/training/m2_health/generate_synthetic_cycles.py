"""Generate synthetic crop cycles for M2 training data.

PRD-AV-02 §5.1 requirement:
  ~5,000 crop cycles × 120 days × hourly resolution, swept over species,
  stocking density, season and management quality.
  Fault injection on ~20% of traces. [2]

Output: ml/datasets/synthetic_cycles/
  - One Parquet file per batch of 100 cycles (memory efficient)
  - manifest.json: metadata, dataset hash, mlflow run id
  - summary_stats.csv: per-cycle summary for quick validation

Usage:
  conda activate aquaverse-ml
  python ml/training/m2_health/generate_synthetic_cycles.py [--n-cycles 5000] [--crop-days 120]

MLflow tracking:
  Set MLFLOW_TRACKING_URI=http://localhost:5000 before running.

References
----------
[2]  AquaVerse AI Dataset Register (internal, v1).
[36] Zhang et al. — FCR 1.30 ± 0.08, survival 98.48%.
"""

from __future__ import annotations

import argparse
import csv
import hashlib
import json
import os
import random
import sys
import time
from pathlib import Path

# ---------------------------------------------------------------------------
# Path setup — allow running from repo root without installing the package
# ---------------------------------------------------------------------------
REPO_ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(REPO_ROOT))

from app.twin.simulator_adapter import (   # noqa: E402
    PondConfig,
    SimulatorState,
    simulate_trajectory,
)

# ---------------------------------------------------------------------------
# Output directories
# ---------------------------------------------------------------------------
OUTPUT_DIR = REPO_ROOT / "ml" / "datasets" / "synthetic_cycles"
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

MANIFEST_PATH = OUTPUT_DIR / "manifest.json"
SUMMARY_PATH  = OUTPUT_DIR / "summary_stats.csv"


# ---------------------------------------------------------------------------
# Parameter sweep — season and management quality [2]
# ---------------------------------------------------------------------------

SPECIES = [
    "Litopenaeus_vannamei",   # dominant Tamil Nadu species
    "Penaeus_monodon",        # tiger prawn (smaller proportion)
]

SEASONS = {
    "summer":   {"temp_offset": +2.0,  "wind_ms": 1.0},   # Mar–May
    "monsoon":  {"temp_offset": -1.5,  "wind_ms": 3.5},   # Jun–Sep
    "northeast":{"temp_offset": -0.5,  "wind_ms": 2.5},   # Oct–Dec
    "winter":   {"temp_offset": -1.0,  "wind_ms": 1.5},   # Jan–Feb
}

MANAGEMENT_QUALITY = {
    "excellent": {"feed_factor": 1.0,  "aerators_factor": 1.2, "stocking_factor": 0.8},
    "good":      {"feed_factor": 1.0,  "aerators_factor": 1.0, "stocking_factor": 1.0},
    "poor":      {"feed_factor": 1.3,  "aerators_factor": 0.7, "stocking_factor": 1.3},
    "very_poor": {"feed_factor": 1.6,  "aerators_factor": 0.5, "stocking_factor": 1.5},
}


def random_pond_config(seed: int) -> tuple[PondConfig, dict]:
    """Generate a randomised PondConfig with metadata for the sweep."""
    rng = random.Random(seed)

    species = rng.choice(SPECIES)
    season_name, season = rng.choice(list(SEASONS.items()))
    mgmt_name, mgmt = rng.choice(list(MANAGEMENT_QUALITY.items()))

    # Randomise pond geometry [2]
    length_m = rng.uniform(40, 120)
    width_m  = rng.uniform(30, 90)
    depth_m  = rng.uniform(1.0, 2.0)

    # Stocking density varies by species [2]
    base_density = rng.uniform(20, 50) if species == "Litopenaeus_vannamei" else rng.uniform(5, 20)
    stocking = base_density * mgmt["stocking_factor"]

    # Feed proportional to biomass estimate
    area = length_m * width_m
    feed_kg = area * stocking * 0.001 * rng.uniform(0.8, 1.2) * mgmt["feed_factor"]

    cfg = PondConfig(
        length_m=length_m,
        width_m=width_m,
        depth_m=depth_m,
        stocking_density_per_m2=stocking,
        feed_kg_per_day=feed_kg,
        wind_speed_ms=rng.uniform(0.5, 4.0) + season["wind_ms"],
        n_aerators=max(1, int(rng.uniform(1, 5) * mgmt["aerators_factor"])),
        aerator_power_hp=rng.choice([1.0, 1.5, 2.0, 3.0]),
    )

    meta = {
        "species": species,
        "season": season_name,
        "management_quality": mgmt_name,
        "fault_injected": False,   # set later
        "fault_type": None,
    }
    return cfg, meta


def trajectory_to_rows(
    cycle_id: int,
    history: list[SimulatorState],
    cfg: PondConfig,
    meta: dict,
    crop_days: int,
) -> list[dict]:
    """Convert a SimulatorState trajectory to flat row dicts for Parquet."""
    rows = []
    for s in history:
        rows.append({
            # Identifiers
            "cycle_id":           cycle_id,
            "hour":               s.hour,
            "day":                s.day,
            "hour_of_day":        s.hour % 24,
            # Metadata
            "species":            meta["species"],
            "season":             meta["season"],
            "management_quality": meta["management_quality"],
            "fault_injected":     meta["fault_injected"],
            "fault_type":         meta["fault_type"] or "none",
            # Pond geometry
            "pond_area_m2":       round(cfg.surface_area_m2, 1),
            "pond_depth_m":       round(cfg.depth_m, 2),
            "stocking_density":   round(cfg.stocking_density_per_m2, 1),
            "n_aerators":         cfg.n_aerators,
            # Water chemistry — surface layer (index 0)
            "do_surface_mgl":     round(s.do_mg_l[0], 4),
            "do_bottom_mgl":      round(s.do_mg_l[-1], 4),
            "do_gradient_mgl":    round(s.do_mg_l[0] - s.do_mg_l[-1], 4),
            "temp_c":             round(s.temp_c[0], 2),
            "salinity_ppt":       round(s.salinity_ppt[0], 2),
            "ph":                 round(s.ph, 3),
            "alkalinity_mgl":     round(s.alkalinity_mg_l, 2),
            "tan_mgl":            round(s.tan_mg_l, 4),
            "no2_mgl":            round(s.no2_mg_l, 4),
            "turbidity_ntu":      round(s.turbidity_ntu, 1),
            # Biomass
            "mean_weight_g":      round(s.mean_weight_g, 4),
            "survival_fraction":  round(s.survival_fraction, 6),
            "biomass_total_kg":   round(s.mean_weight_g * s.count * s.survival_fraction / 1000.0, 2),
            # Engineered features (PRD §5.2)
            "stress_hours_below_3mgl": round(s.stress_hours_below_3mgl, 1),
            "tan_slope_3d_mgl_day":    round(s.tan_slope_3d, 4),
            # State flags
            "stratified":         int(s.stratified),
            "sensor_fault":       int(s.sensor_fault_active),
            "aerator_failed":     int(s.aerator_failed),
        })
    return rows


def compute_sha256(path: Path) -> str:
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(65536), b""):
            h.update(chunk)
    return h.hexdigest()


# ---------------------------------------------------------------------------
# Main generation loop
# ---------------------------------------------------------------------------

def generate(n_cycles: int = 5000, crop_days: int = 120,
             batch_size: int = 100, seed_base: int = 0) -> None:
    """Run the full generation sweep and write outputs."""

    print(f"Generating {n_cycles} synthetic crop cycles × {crop_days} days × hourly")
    print(f"Output: {OUTPUT_DIR}")
    print(f"Fault injection on ~{int(100 * 0.20)}% of traces [Ref 2]")
    print()

    t_start = time.perf_counter()
    summary_rows: list[dict] = []
    parquet_files: list[str] = []
    batch_rows: list[dict] = []
    batch_idx = 0
    fault_count = 0

    for cycle_id in range(n_cycles):
        seed = seed_base + cycle_id
        cfg, meta = random_pond_config(seed)

        # ~20% fault injection [2]
        inject = random.Random(seed + 9999).random() < 0.20
        meta["fault_injected"] = inject
        if inject:
            fault_count += 1

        history = simulate_trajectory(
            config=cfg,
            crop_days=crop_days,
            inject_faults=inject,
            seed=seed,
        )
        if inject and history:
            # record which fault was applied (read from last state)
            last = history[-1]
            if last.sensor_fault_active:
                meta["fault_type"] = "sensor_fault"
            elif last.aerator_failed:
                meta["fault_type"] = "aerator_failure"
            elif last.stratified and last.do_mg_l[-1] < 0.5:
                meta["fault_type"] = "stratification_collapse"
            else:
                meta["fault_type"] = "other"

        # Summary row (per cycle)
        last_state = history[-1] if history else None
        if last_state:
            summary_rows.append({
                "cycle_id":           cycle_id,
                "species":            meta["species"],
                "season":             meta["season"],
                "management_quality": meta["management_quality"],
                "fault_injected":     meta["fault_injected"],
                "fault_type":         meta["fault_type"] or "none",
                "harvest_weight_g":   round(last_state.mean_weight_g, 2),
                "harvest_survival":   round(last_state.survival_fraction, 4),
                "total_stress_hours": round(last_state.stress_hours_below_3mgl, 1),
                "final_do_surface":   round(last_state.do_mg_l[0], 2),
                "final_tan_mgl":      round(last_state.tan_mg_l, 3),
                "final_ph":           round(last_state.ph, 2),
            })

        # Accumulate rows for batch Parquet write
        batch_rows.extend(trajectory_to_rows(cycle_id, history, cfg, meta, crop_days))

        # Write batch
        if len(batch_rows) >= batch_size * crop_days * 24 or cycle_id == n_cycles - 1:
            try:
                import pandas as pd
                df = pd.DataFrame(batch_rows)
                parquet_path = OUTPUT_DIR / f"batch_{batch_idx:04d}.parquet"
                df.to_parquet(parquet_path, index=False, compression="snappy")
                parquet_files.append(str(parquet_path))
                print(f"  Wrote {parquet_path.name}  ({len(df):,} rows, cycle {cycle_id - len(batch_rows)//(crop_days*24)+1}–{cycle_id})")
            except ImportError:
                # pandas / pyarrow not installed — write CSV fallback
                csv_path = OUTPUT_DIR / f"batch_{batch_idx:04d}.csv"
                with open(csv_path, "w", newline="") as f:
                    writer = csv.DictWriter(f, fieldnames=batch_rows[0].keys())
                    writer.writeheader()
                    writer.writerows(batch_rows)
                parquet_files.append(str(csv_path))
                print(f"  Wrote {csv_path.name} (CSV fallback — install pandas+pyarrow for Parquet)")
            batch_rows = []
            batch_idx += 1

        if (cycle_id + 1) % 100 == 0 or cycle_id == n_cycles - 1:
            elapsed = time.perf_counter() - t_start
            rate = (cycle_id + 1) / elapsed
            eta = (n_cycles - cycle_id - 1) / rate if rate > 0 else 0
            print(f"  Progress: {cycle_id+1}/{n_cycles}  "
                  f"({100*(cycle_id+1)/n_cycles:.0f}%)  "
                  f"rate={rate:.1f} cycles/s  ETA={eta:.0f}s")

    # Write summary CSV
    with open(SUMMARY_PATH, "w", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=summary_rows[0].keys())
        writer.writeheader()
        writer.writerows(summary_rows)

    # Compute dataset hash (hash of all parquet/csv filenames + sizes)
    hash_input = "".join(
        f"{p}:{os.path.getsize(p)}" for p in parquet_files if os.path.exists(p)
    )
    dataset_hash = hashlib.sha256(hash_input.encode()).hexdigest()

    # Write manifest
    manifest = {
        "n_cycles":      n_cycles,
        "crop_days":     crop_days,
        "fault_fraction": round(fault_count / n_cycles, 4),
        "fault_count":   fault_count,
        "seed_base":     seed_base,
        "dataset_hash":  dataset_hash,
        "parquet_files": parquet_files,
        "summary_csv":   str(SUMMARY_PATH),
        "generated_at":  time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
        "generator":     "ml/training/m2_health/generate_synthetic_cycles.py",
    }
    with open(MANIFEST_PATH, "w") as f:
        json.dump(manifest, f, indent=2)

    elapsed = time.perf_counter() - t_start
    print()
    print("=" * 60)
    print(f"✅ Done in {elapsed:.1f}s")
    print(f"   Cycles: {n_cycles}  |  Fault-injected: {fault_count} ({100*fault_count/n_cycles:.1f}%)")
    print(f"   Dataset hash: {dataset_hash}")
    print(f"   Manifest: {MANIFEST_PATH}")
    print(f"   Summary:  {SUMMARY_PATH}")
    print()

    # Log to MLflow if available
    try:
        import mlflow
        mlflow_uri = os.getenv("MLFLOW_TRACKING_URI", "http://localhost:5000")
        mlflow.set_tracking_uri(mlflow_uri)
        mlflow.set_experiment(os.getenv("MLFLOW_EXPERIMENT_NAME", "aquaverse-production"))
        with mlflow.start_run(run_name="synthetic_cycle_generation"):
            mlflow.log_params({
                "n_cycles":       n_cycles,
                "crop_days":      crop_days,
                "fault_fraction": round(fault_count / n_cycles, 4),
                "seed_base":      seed_base,
            })
            mlflow.log_metrics({
                "total_cycles":    n_cycles,
                "faulted_cycles":  fault_count,
                "generation_time_s": round(elapsed, 1),
            })
            mlflow.set_tags({
                "dataset_hash":  dataset_hash,
                "hardware":      os.getenv("MLFLOW_TAGS_HARDWARE", "local"),
                "compute":       os.getenv("MLFLOW_TAGS_COMPUTE", "local-workstation"),
                "data_type":     "synthetic_simulator",
                "ref":           "PRD-AV-02",
            })
            mlflow.log_artifact(str(MANIFEST_PATH))
            mlflow.log_artifact(str(SUMMARY_PATH))
        print(f"   MLflow run logged to {mlflow_uri}")
    except Exception as e:
        print(f"   MLflow not available ({e}) — skipping. Set MLFLOW_TRACKING_URI to enable.")


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Generate synthetic crop cycles for M2 training")
    parser.add_argument("--n-cycles",  type=int, default=5000, help="Number of crop cycles (default: 5000)")
    parser.add_argument("--crop-days", type=int, default=120,  help="Days per crop cycle (default: 120)")
    parser.add_argument("--batch-size",type=int, default=100,  help="Cycles per output file (default: 100)")
    parser.add_argument("--seed",      type=int, default=0,    help="Random seed base (default: 0)")
    args = parser.parse_args()

    generate(
        n_cycles=args.n_cycles,
        crop_days=args.crop_days,
        batch_size=args.batch_size,
        seed_base=args.seed,
    )
