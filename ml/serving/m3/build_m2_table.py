"""
Phase 3b: M2 (Health/Mortality) numeric baseline table.

IMPORTANT — HONESTY NOTE, read before using these outputs anywhere near a
funding report: this simulator models environmental-stress-driven mortality
(DO crashes, chronic stress) only. It does NOT model pathogen dynamics
(WSSV, EHP, AHPND, Vibrio). Tier-2 disease datasets (WSD farmer survey,
WSSV spatial susceptibility) are not yet integrated. What this baseline
predicts is "elevated mortality risk from water-quality stress" — a real
and useful M2 sub-problem, but it is NOT a disease-outbreak classifier.
Label it as such in any report; the PRD's R2 rule ("never a confident
diagnosis") applies just as much to what we call our own baseline.

Snapshot cadence: once per day at 06:00 (the farmer's morning check-in,
matching the app's actual decision point). Target: did next-24h mortality
exceed a population-scaled "elevated" threshold, defined empirically below
so the positive class is a genuine minority (outbreak framing), not "any
death at all," which is true on almost every cycle-day and would be a
useless label.
"""

from __future__ import annotations
import argparse
from pathlib import Path

import numpy as np
import pandas as pd
from tqdm import tqdm

from sim.features import FEATURE_COLUMNS

SNAPSHOT_HOUR = 6

STATIC_COLS = ["species", "salinity_ppt", "management_quality"]
FEATURE_COLS_FOR_M2 = [c for c in FEATURE_COLUMNS if c != "neighbour_risk_2km"]  # single-pond corpus, no spatial join yet
RAW_SENSOR_COLS = ["do_mg_l", "tan_mg_l", "no2_mg_l", "no3_mg_l", "ph", "alkalinity_mg_l",
                    "water_temp_c", "secchi_cm"]


def build_one_cycle(path: Path) -> pd.DataFrame:
    df = pd.read_parquet(path)
    df["date"] = df["timestamp"].dt.floor("D")

    snapshots = df[df["hour_of_day"] == SNAPSHOT_HOUR].copy() if "hour_of_day" in df.columns else \
        df[df["timestamp"].dt.hour == SNAPSHOT_HOUR].copy()
    snapshots = snapshots.sort_values("timestamp").reset_index(drop=True)

    # daily mortality + alive_count at day start, for next-day target
    daily = df.groupby("day_of_culture").agg(
        deaths=("mortality_count", "sum"),
        alive_start=("alive_count", "first"),
    ).reset_index()
    daily["daily_mortality_rate"] = daily["deaths"] / daily["alive_start"].clip(lower=1)

    # shift so row for day D holds day D+1's outcome (next-24h-ahead target)
    daily["next_day_mortality_rate"] = daily["daily_mortality_rate"].shift(-1)
    daily["next_day_deaths"] = daily["deaths"].shift(-1)

    snapshots = snapshots.merge(daily[["day_of_culture", "next_day_mortality_rate", "next_day_deaths"]],
                                 on="day_of_culture", how="left")
    snapshots = snapshots.dropna(subset=["next_day_mortality_rate"])
    snapshots = snapshots.dropna(subset=[c for c in FEATURE_COLS_FOR_M2 if c in snapshots.columns])

    keep_cols = (["pond_uid", "timestamp", "day_of_culture", "split"] + STATIC_COLS +
                 RAW_SENSOR_COLS +
                 [c for c in FEATURE_COLS_FOR_M2 if c in snapshots.columns] +
                 ["next_day_mortality_rate", "next_day_deaths"])
    keep_cols = [c for c in keep_cols if c in snapshots.columns]
    return snapshots[keep_cols]


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--data_dir", type=str, default="data")
    args = parser.parse_args()

    data_dir = Path(args.data_dir)
    manifest = pd.read_parquet(data_dir / "manifest.parquet")
    split_map = manifest.set_index("pond_uid")["split"]

    tables = []
    for pond_uid in tqdm(manifest["pond_uid"], desc="Building M2 snapshots"):
        path = data_dir / "raw" / f"{pond_uid}.parquet"
        if not path.exists():
            continue
        t = build_one_cycle(path)
        t["split"] = split_map.get(pond_uid, "train")
        tables.append(t)

    m2_table = pd.concat(tables, ignore_index=True)

    # empirically set "elevated mortality" threshold at the 85th percentile of
    # observed next-day mortality rate -> genuinely a minority-class outbreak-style label
    threshold = m2_table.loc[m2_table["split"] == "train", "next_day_mortality_rate"].quantile(0.85)
    m2_table["elevated_mortality_next24h"] = (m2_table["next_day_mortality_rate"] > threshold).astype(int)

    out_path = data_dir / "m2_health_table.parquet"
    m2_table.to_parquet(out_path, index=False)

    print(f"M2 table: {len(m2_table)} snapshots -> {out_path}")
    print(f"Elevated-mortality threshold (85th pct of train next-day rate): {threshold:.5f}")
    print(m2_table["elevated_mortality_next24h"].value_counts(normalize=True))
    print(m2_table.groupby("split")["elevated_mortality_next24h"].mean())


if __name__ == "__main__":
    main()
