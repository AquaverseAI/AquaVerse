"""
Phase 2: generate the synthetic crop-cycle dataset.

MVP spec target: ~5,000 crop cycles x 120 days x hourly, ~20% fault-injected.
This script is parameter-sweep aware (species / density / season / management
quality) per the spec, and pond-wise splitting is baked in at generation time
(R3: splits are pond-wise and time-wise, never random) via a stable
`pond_uid` assigned per cycle.

Usage:
    python generate_dataset.py --n_cycles 200 --out data/ --seed 0

Writes:
    data/raw/<pond_uid>.parquet          -- one file per crop cycle, hourly
    data/manifest.parquet                -- one row per cycle: params + split assignment
"""

from __future__ import annotations
import argparse
import uuid
from pathlib import Path

import numpy as np
import pandas as pd
from tqdm import tqdm

from sim.simulator import PondSimulator
from sim.faults import inject_faults
from sim.features import compute_features
from sim.species import SPECIES

SPECIES_KEYS = list(SPECIES.keys())
SEASONS = ["southwest_monsoon", "northeast_monsoon", "dry"]


def assign_split(cycle_index: int, n_cycles: int, val_frac: float = 0.15, test_frac: float = 0.15) -> str:
    """
    Pond-wise split assigned at generation time, not after the fact.
    Deterministic on cycle_index so re-runs are reproducible (R3).
    """
    frac = cycle_index / n_cycles
    if frac < 1 - val_frac - test_frac:
        return "train"
    elif frac < 1 - test_frac:
        return "val"
    else:
        return "test"


def generate_one_cycle(cycle_index: int, n_cycles: int, rng: np.random.Generator) -> tuple[str, pd.DataFrame, dict]:
    species_key = rng.choice(SPECIES_KEYS)
    sp = SPECIES[species_key]

    pond_radius_m = rng.uniform(2.0, 15.0)
    pond_depth_m = rng.uniform(0.5, 1.8)
    stocking_density_per_m2 = rng.uniform(2.0, 25.0) if sp.water_type == "brackish" else rng.uniform(0.5, 3.0)
    pond_area_m2 = np.pi * pond_radius_m ** 2
    stocking_count = max(int(pond_area_m2 * stocking_density_per_m2), 5)

    management_quality = np.clip(rng.beta(5, 3), 0.05, 0.99)  # skewed toward competent but with a real tail
    aeration_available = rng.random() < 0.7
    season = rng.choice(SEASONS)
    salinity_ppt = rng.uniform(*sp.salinity_range_ppt) if sp.water_type == "brackish" else rng.uniform(0, 1)
    culture_days = int(sp.culture_days_typical * rng.uniform(0.85, 1.15))
    seed = int(rng.integers(0, 2**31 - 1))

    pond_uid = f"{species_key}-{cycle_index:05d}"

    sim = PondSimulator(
        species_key=species_key,
        pond_radius_m=pond_radius_m,
        pond_depth_m=pond_depth_m,
        stocking_count=stocking_count,
        salinity_ppt=salinity_ppt,
        management_quality=management_quality,
        aeration_available=aeration_available,
        season=season,
        seed=seed,
    )
    df = sim.run(days=culture_days)
    df["pond_uid"] = pond_uid

    fault_mask_df = None
    is_faulted = rng.random() < 0.20  # ~20% fault-injected, per MVP spec
    if is_faulted:
        df, fault_mask_df = inject_faults(df, rng)

    df = compute_features(df, stocking_weight_g=sp.stocking_weight_g, stocking_count=stocking_count)
    if fault_mask_df is not None:
        df["data_health_score"] = fault_mask_df["data_health_score"].values

    manifest_row = {
        "pond_uid": pond_uid,
        "species": species_key,
        "pond_radius_m": pond_radius_m,
        "pond_depth_m": pond_depth_m,
        "stocking_count": stocking_count,
        "salinity_ppt": salinity_ppt,
        "management_quality": management_quality,
        "aeration_available": aeration_available,
        "season": season,
        "culture_days": culture_days,
        "is_faulted": is_faulted,
        "split": assign_split(cycle_index, n_cycles),
        "final_biomass_kg": df["biomass_kg"].iloc[-1],
        "final_alive_count": df["alive_count"].iloc[-1],
        "final_fcr": df["fcr_running"].iloc[-1],
        "mortality_rate": 1 - (df["alive_count"].iloc[-1] / stocking_count),
    }
    return pond_uid, df, manifest_row


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--n_cycles", type=int, default=200)
    parser.add_argument("--out", type=str, default="data")
    parser.add_argument("--seed", type=int, default=0)
    args = parser.parse_args()

    out_dir = Path(args.out)
    raw_dir = out_dir / "raw"
    raw_dir.mkdir(parents=True, exist_ok=True)

    manifest_path = out_dir / "manifest.parquet"
    manifest_rows = []
    done_indices = set()
    if manifest_path.exists():
        existing = pd.read_parquet(manifest_path)
        manifest_rows = existing.to_dict("records")
        for uid in existing["pond_uid"]:
            # pond_uid format: {species}-{index:05d}
            idx = int(uid.rsplit("-", 1)[-1])
            done_indices.add(idx)
        print(f"Resuming: {len(done_indices)} cycles already complete.")

    # master_rng is re-derived per-index (not sequentially consumed) so that
    # resuming produces IDENTICAL draws for already-done and not-yet-done
    # indices regardless of where a previous run stopped.
    ss = np.random.SeedSequence(args.seed)
    child_seeds = ss.spawn(args.n_cycles)

    for i in tqdm(range(args.n_cycles), desc="Simulating crop cycles"):
        if i in done_indices:
            continue
        cycle_rng = np.random.default_rng(child_seeds[i])
        pond_uid, df, manifest_row = generate_one_cycle(i, args.n_cycles, cycle_rng)
        raw_dir.mkdir(parents=True, exist_ok=True)  # defensive: environment has been known to drop this dir mid-run
        df.to_parquet(raw_dir / f"{pond_uid}.parquet", index=False)
        manifest_rows.append(manifest_row)

        # checkpoint every 50 cycles so a crash never loses more than that
        if i % 50 == 0:
            pd.DataFrame(manifest_rows).to_parquet(manifest_path, index=False)

    manifest = pd.DataFrame(manifest_rows)
    manifest.to_parquet(manifest_path, index=False)

    print(f"\nGenerated {len(manifest)} crop cycles -> {raw_dir}")
    print(manifest["split"].value_counts())
    print(manifest["species"].value_counts())
    print(f"Faulted cycles: {manifest['is_faulted'].sum()} ({manifest['is_faulted'].mean():.1%})")
    print(f"Manifest -> {out_dir / 'manifest.parquet'}")


if __name__ == "__main__":
    main()
