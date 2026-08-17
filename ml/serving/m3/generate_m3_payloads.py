"""
M3 SFT payload generator, Phase 4 (Kimi-narrated version).

Design principle: Kimi does NOT invent pond states or numbers. This script
samples real (pond_uid, day) snapshots from the already-simulated 2,000-cycle
corpus, runs each through the ALREADY-TESTED m3_decision_engine.py, and
produces a grounded, internally-consistent payload — feed quantity,
feed-hold flag + reason, harvest projection, FCR, cost/margin, all real
outputs of real models. Kimi's only job (see kimi_prompt_template.md) is
narrating that payload into natural advisory prose. This mirrors the
production architecture (quant layer computes, LLM narrates) inside the
training data itself.

Stratification: deliberately over-samples the late-cycle + high-DO-stress
combination (day 90+, stress_hours_lt3_24h >= 6) because the accuracy audit
found this is where the growth model's errors concentrate. An SFT corpus
that under-represents exactly the case that matters most would just repeat
the same blind spot at the reasoning layer.
"""

from __future__ import annotations
import argparse
import json
from pathlib import Path

import numpy as np
import pandas as pd
from tqdm import tqdm

from m3_decision_engine import M3DecisionEngine, PondSnapshot, FEED_TABLES


def row_to_snapshot(row: pd.Series, pond_id: str, engine_defaults: dict) -> PondSnapshot:
    return PondSnapshot(
        pond_id=pond_id,
        species_key=row.species,
        doc=int(row.doc),
        biomass_est_kg=float(row.biomass_est_kg),
        alive_count=max(int(row.biomass_est_kg * 1000 / max(row.avg_weight_g, 0.01)), 1),
        do_mg_l=float(row.do_mg_l),
        tan_mg_l=float(row.tan_mg_l),
        ph=float(row.ph),
        alkalinity_mg_l=float(row.alkalinity_mg_l),
        water_temp_c=float(row.water_temp_c),
        salinity_ppt=float(row.salinity_ppt),
        wind_mean_24h=float(row.wind_mean_24h),
        solar_rad_24h=float(row.solar_rad_24h),
        rain_48h_mm=float(row.rain_48h_mm),
        night_do_min_3d_trend=float(row.night_do_min_3d_trend) if pd.notna(row.night_do_min_3d_trend) else 0.0,
        do_amplitude=float(row.do_amplitude),
        stress_hours_lt3_24h=float(row.stress_hours_lt3_24h),
        stress_hours_lt3_7d=float(row.stress_hours_lt3_7d),
        tan_slope_3d=float(row.tan_slope_3d) if pd.notna(row.tan_slope_3d) else 0.0,
        alkalinity_trend_7d=float(row.alkalinity_trend_7d) if pd.notna(row.alkalinity_trend_7d) else 0.0,
        feed_kg_7d_cum=float(row.feed_kg_7d_cum),
        fcr_running=float(row.fcr_running),
        management_quality=float(row.management_quality),
        aerator_on=bool(row.aerator_on),
        data_health_score=float(row.data_health_score),
        nh3_un_ionised=float(row.nh3_un_ionised),
        cum_feed_kg=float(row.feed_kg_7d_cum),  # proxy; real deployment reads true cumulative from DB
    )


def stratified_sample(df: pd.DataFrame, n_total: int, rng: np.random.Generator) -> pd.DataFrame:
    """
    Buckets: species x (early/mid/late DOC) x (normal/stressed DO).
    Late+stressed gets 3x the weight of other buckets — this is the
    deliberate over-representation of the accuracy-audit weak spot.
    """
    df = df.copy()
    df["doc_stage"] = pd.cut(df["doc"], bins=[-1, 30, 90, 999], labels=["early", "mid", "late"])
    df["stress_flag"] = np.where(df["stress_hours_lt3_24h"] >= 6, "stressed", "normal")
    df["bucket"] = df["species"].astype(str) + "|" + df["doc_stage"].astype(str) + "|" + df["stress_flag"]

    weights = {}
    for b in df["bucket"].unique():
        weights[b] = 3.0 if b.endswith("late|stressed") else 1.0
    total_weight = sum(weights[b] * (df["bucket"] == b).sum() > 0 for b in weights) or 1
    bucket_counts = df["bucket"].value_counts()
    n_buckets = len(bucket_counts)
    raw_alloc = {b: weights[b] for b in bucket_counts.index}
    weight_sum = sum(raw_alloc.values())
    target_per_bucket = {b: int(n_total * (w / weight_sum)) for b, w in raw_alloc.items()}

    samples = []
    for b, target_n in target_per_bucket.items():
        pool = df[df["bucket"] == b]
        take = min(target_n, len(pool))
        if take > 0:
            samples.append(pool.sample(n=take, random_state=int(rng.integers(0, 2**31 - 1))))
    result = pd.concat(samples, ignore_index=True) if samples else df.sample(n=min(n_total, len(df)))
    if len(result) < n_total:
        # top up from general pool to hit exact target
        remaining = n_total - len(result)
        extra = df.sample(n=min(remaining, len(df)), random_state=0)
        result = pd.concat([result, extra], ignore_index=True)
    return result.sample(frac=1.0, random_state=1).reset_index(drop=True).head(n_total)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--data_dir", type=str, default="data")
    parser.add_argument("--n_payloads", type=int, default=50000)
    parser.add_argument("--out", type=str, default="training/m3_payloads_for_kimi.jsonl")
    parser.add_argument("--seed", type=int, default=0)
    args = parser.parse_args()

    rng = np.random.default_rng(args.seed)
    data_dir = Path(args.data_dir)
    growth_table = pd.read_parquet(data_dir / "growth_table.parquet")

    print(f"Pool: {len(growth_table)} real snapshots. Sampling {args.n_payloads} (stratified, "
          f"3x weight on late-cycle+high-stress)...")
    sampled = stratified_sample(growth_table, args.n_payloads, rng)
    print(sampled.groupby(["species", "doc_stage", "stress_flag"], observed=True).size())

    engine = M3DecisionEngine()
    out_path = Path(args.out)
    out_path.parent.mkdir(parents=True, exist_ok=True)

    n_written = 0
    with open(out_path, "w") as f:
        for i, row in tqdm(sampled.iterrows(), total=len(sampled), desc="Running decision engine"):
            pond_id = f"SFT-{i:06d}"
            snap = row_to_snapshot(row, pond_id, {})
            # inject a real-looking manufacturer table name (still placeholder VALUES,
            # but a real NAME so Kimi's narration references something concrete;
            # swap for genuine table lookups once Vishi's digitization lands)
            try:
                payload = engine.decide(snap)
            except Exception as e:
                continue  # skip pathological snapshots (e.g. zero alive_count edge cases)
            payload_dict = {
                "pond_id": payload.pond_id,
                "species": payload.species,
                "doc": payload.doc,
                "biomass_est_kg": payload.biomass_est_kg,
                "avg_weight_g": payload.avg_weight_g,
                "overnight_do_forecast_mg_l": payload.overnight_do_forecast_mg_l,
                "do_forecast_confidence": payload.do_forecast_confidence,
                "feed_hold_recommended": payload.feed_hold_recommended,
                "feed_hold_reason": payload.feed_hold_reason,
                "recommended_feed_kg": payload.recommended_feed_kg,
                "feed_pct_biomass": payload.feed_pct_biomass,
                "manufacturer_table": FEED_TABLES[snap.species_key],
                "predicted_daily_gain_g": payload.predicted_daily_gain_g,
                "projected_harvest_date_days_out": payload.projected_harvest_date_days_out,
                "projected_harvest_weight_g": payload.projected_harvest_weight_g,
                "running_fcr": payload.running_fcr,
                "cost_per_kg_so_far_rs": payload.cost_per_kg_so_far_rs,
                "market_price_per_kg_rs": payload.market_price_per_kg_rs,
                "margin_per_kg_rs": payload.margin_per_kg_rs,
                "warnings": payload.warnings,
                "_stratum": row.get("bucket", "unknown"),  # for post-hoc diversity auditing, strip before training
            }
            f.write(json.dumps(payload_dict) + "\n")
            n_written += 1

    print(f"\nWrote {n_written} grounded payloads -> {out_path}")
    print("Next: run these through Kimi using kimi_prompt_template.md, then validate with validate_sft_corpus.py")


if __name__ == "__main__":
    main()
