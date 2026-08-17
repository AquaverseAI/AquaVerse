"""
Phase 3, step 1: build point-in-time training tables from the raw hourly
simulator output.

Two prediction targets, matching the PRD's stated priorities:

1. Overnight DO minimum forecast — "Predicting the 04:00 minimum from the
   18:00 reading is the highest-value single forecast in the whole system"
   (Hybrid Explainable Model doc, M1 grounding notes). Snapshot at 18:00,
   target = that night's night_do_min.

2. M3 daily growth increment — feeds harvest-date/size projection and the
   running FCR the farmer sees on the Crop screen. Snapshot at end of each
   day, target = next day's biomass_kg - today's biomass_kg.

Point-in-time discipline (R3, PRD Acceptance Criterion 1): every feature
used in a snapshot is computed using only data available *at* the snapshot
timestamp — no peeking at the label's own night, no using tomorrow's
weather except the forecast-known variables. This script builds snapshots
directly from the already-point-in-time-correct rolling features in
sim/features.py, so the discipline is inherited rather than re-implemented.
"""

from __future__ import annotations
from pathlib import Path

import numpy as np
import pandas as pd
from tqdm import tqdm

SNAPSHOT_FEATURE_COLS = [
    "do_mg_l", "tan_mg_l", "nh3_un_ionised", "ph", "alkalinity_mg_l",
    "water_temp_c", "salinity_ppt", "wind_mean_24h", "solar_rad_24h",
    "rain_48h_mm", "night_do_min_3d_trend", "do_amplitude",
    "stress_hours_lt3_24h", "stress_hours_lt3_7d", "tan_slope_3d",
    "alkalinity_trend_7d", "feed_kg_7d_cum", "fcr_running",
    "biomass_est_kg", "doc", "data_health_score", "management_quality",
    "aerator_on", "avg_weight_g",
]

CATEGORICAL_COLS = ["species"]


def build_do_forecast_table(raw_dir: Path, manifest: pd.DataFrame) -> pd.DataFrame:
    """One row per pond-night: features at 18:00, label = that night's DO minimum."""
    rows = []
    for _, m in tqdm(manifest.iterrows(), total=len(manifest), desc="DO forecast snapshots"):
        fp = raw_dir / f"{m.pond_uid}.parquet"
        if not fp.exists():
            continue
        df = pd.read_parquet(fp)
        snap = df[df["hour_of_day"] == 18].copy()
        # night_do_min for the night starting at this 18:00 is the same night_key's value
        snap["target_night_do_min"] = snap["night_do_min"]
        snap = snap.dropna(subset=["target_night_do_min"])
        snap["pond_uid"] = m.pond_uid
        snap["species"] = m.species
        snap["split"] = m.split
        avail_cols = [c for c in SNAPSHOT_FEATURE_COLS if c != "doc" and c in snap.columns]
        rows.append(snap[["pond_uid", "species", "split", "timestamp", "doc",
                           "target_night_do_min"] + avail_cols])
    return pd.concat(rows, ignore_index=True) if rows else pd.DataFrame()


def build_growth_table(raw_dir: Path, manifest: pd.DataFrame) -> pd.DataFrame:
    """
    One row per pond-day: features at day end (23:00 snapshot), label = next
    day's PER-INDIVIDUAL weight gain (g/animal). Raw pond-total biomass gain
    was tried first and rejected: it scales trivially with stocking count
    (a 17,000-shrimp pond and a 40-fish pond aren't comparable in raw grams),
    which dominated the loss over the actual growth physiology. Per-individual
    gain is what a growth curve means, and it's what the manufacturer feeding
    tables (PRD §5.2 anchor requirement) are keyed on.
    """
    rows = []
    for _, m in tqdm(manifest.iterrows(), total=len(manifest), desc="Growth snapshots"):
        fp = raw_dir / f"{m.pond_uid}.parquet"
        if not fp.exists():
            continue
        df = pd.read_parquet(fp)
        daily = df[df["hour_of_day"] == 23].copy().sort_values("day_of_culture").reset_index(drop=True)
        daily["avg_weight_g"] = (daily["biomass_kg"] * 1000.0) / daily["alive_count"].clip(lower=1)
        daily["next_day_avg_weight_g"] = daily["avg_weight_g"].shift(-1)
        daily["target_avg_weight_gain_g"] = daily["next_day_avg_weight_g"] - daily["avg_weight_g"]
        daily = daily.dropna(subset=["target_avg_weight_gain_g"])
        daily["pond_uid"] = m.pond_uid
        daily["species"] = m.species
        daily["split"] = m.split
        avail_cols = [c for c in SNAPSHOT_FEATURE_COLS if c not in ("doc", "avg_weight_g") and c in daily.columns]
        rows.append(daily[["pond_uid", "species", "split", "timestamp", "doc", "avg_weight_g",
                            "target_avg_weight_gain_g"] + avail_cols])
    return pd.concat(rows, ignore_index=True) if rows else pd.DataFrame()


def main():
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument("--data_dir", type=str, default="data")
    args = parser.parse_args()

    data_dir = Path(args.data_dir)
    raw_dir = data_dir / "raw"
    manifest = pd.read_parquet(data_dir / "manifest.parquet")

    print(f"Manifest has {len(manifest)} cycles; building snapshot tables...")

    do_table = build_do_forecast_table(raw_dir, manifest)
    do_table.to_parquet(data_dir / "do_forecast_table.parquet", index=False)
    print(f"DO forecast table: {len(do_table)} rows -> {data_dir / 'do_forecast_table.parquet'}")

    growth_table = build_growth_table(raw_dir, manifest)
    growth_table.to_parquet(data_dir / "growth_table.parquet", index=False)
    print(f"Growth table: {len(growth_table)} rows -> {data_dir / 'growth_table.parquet'}")


if __name__ == "__main__":
    main()
