"""
Engineered features — implements the exact feature list from PRD-AV-05 §3.3.

Non-negotiable per the PRD (R risk register): "Every feature is computable
identically at training time and at serving time from the same SQL. Any
feature that cannot be is deleted, not worked around."

This module is the *training-side* Python reference implementation. When
Prabhu/Nithish build the real Postgres materialised views, the SQL must
reproduce these exact definitions — treat this file as the spec-in-code, and
add the equality test called for in Acceptance Criterion 1 once the SQL
views exist (train extract == serving read, for a fixed timestamp).

neighbour_risk_2km is omitted here — it requires a multi-pond PostGIS
context this single-pond simulator doesn't have. Compute it downstream once
ponds are joined spatially.
"""

from __future__ import annotations
import numpy as np
import pandas as pd

from . import constants as C


def _night_mask(hour_of_day: pd.Series) -> pd.Series:
    return (hour_of_day >= 22) | (hour_of_day < 6)


def compute_features(df: pd.DataFrame, stocking_weight_g: float, stocking_count: int) -> pd.DataFrame:
    """
    Adds all PRD §3.3 features to an hourly simulator/sensor dataframe.
    Assumes columns: timestamp, do_mg_l, tan_mg_l, ph, water_temp_c,
    alkalinity_mg_l, wind_speed_ms, solar_rad_wm2, rain_mm, feed_kg,
    cum_feed_kg, biomass_kg, day_of_culture.
    """
    out = df.copy()
    out["hour_of_day"] = out["timestamp"].dt.hour
    out["date"] = out["timestamp"].dt.floor("D")
    is_night = _night_mask(out["hour_of_day"])

    # --- night_do_min: min(do) over 22:00-06:00, per pond-night ---
    # a "pond-night" is keyed to the date it started (22:00 onward + next day's 00-06)
    night_key = out["date"].where(out["hour_of_day"] >= 22, out["date"] - pd.Timedelta(days=1))
    night_min = out.loc[is_night].groupby(night_key[is_night])["do_mg_l"].min()
    out["_night_key"] = night_key
    out["night_do_min"] = out["_night_key"].map(night_min)

    # --- night_do_min_3d_trend: OLS slope of night_do_min over trailing 3 nights ---
    nightly = night_min.reset_index()
    nightly.columns = ["night_key", "night_do_min"]
    nightly = nightly.sort_values("night_key").reset_index(drop=True)
    # BUGFIX (P1.3, app/ml_inference/numeric/m2_risk_engine.py): this used to
    # unconditionally seed `slopes` with 2 NaNs regardless of `len(nightly)`,
    # which raised a length-mismatch ValueError from the assignment below
    # whenever a pond had fewer than 2 distinct nights of history (0 or 1
    # night — e.g. a brand-new pond, or the M2 engine's no-data placeholder
    # row). `min(2, len(nightly))` keeps the exact same output for every
    # pond with >=2 nights of history (unchanged: first two entries NaN,
    # then real slopes from i=2 on) and only fixes the previously-crashing
    # 0/1-night edge case.
    slopes = [np.nan] * min(2, len(nightly))
    for i in range(2, len(nightly)):
        y = nightly["night_do_min"].iloc[i - 2:i + 1].values
        x = np.arange(3)
        if np.any(np.isnan(y)):
            slopes.append(np.nan)
        else:
            slope = np.polyfit(x, y, 1)[0]
            slopes.append(slope)
    nightly["night_do_min_3d_trend"] = slopes
    trend_map = nightly.set_index("night_key")["night_do_min_3d_trend"]
    out["night_do_min_3d_trend"] = out["_night_key"].map(trend_map)

    # --- do_amplitude: daily max(do) - min(do) ---
    daily_do = out.groupby("date")["do_mg_l"].agg(["max", "min"])
    daily_do["do_amplitude"] = daily_do["max"] - daily_do["min"]
    out["do_amplitude"] = out["date"].map(daily_do["do_amplitude"])

    # --- stress_hours_lt3: hours below 3 mg/L, trailing 24h and 7d ---
    below_3 = (out["do_mg_l"] < 3.0).astype(int)
    out["stress_hours_lt3_24h"] = below_3.rolling(24, min_periods=1).sum()
    out["stress_hours_lt3_7d"] = below_3.rolling(24 * 7, min_periods=1).sum()

    # --- tan_slope_3d: mg/L/day, trailing 3 days ---
    tan_daily_mean = out.groupby("date")["tan_mg_l"].mean()
    tan_slope = tan_daily_mean.diff(3) / 3.0
    out["tan_slope_3d"] = out["date"].map(tan_slope)

    # --- alkalinity_trend_7d ---
    alk_daily_mean = out.groupby("date")["alkalinity_mg_l"].mean()
    alk_slope_7d = alk_daily_mean.diff(7) / 7.0
    out["alkalinity_trend_7d"] = out["date"].map(alk_slope_7d)

    # --- nh3_un_ionised: from TAN, pH, temp [ref 5] ---
    out["nh3_un_ionised"] = out["tan_mg_l"] * out.apply(
        lambda r: C.unionised_nh3_fraction(r["ph"], r["water_temp_c"]), axis=1
    )

    # --- rain_48h_mm ---
    out["rain_48h_mm"] = out["rain_mm"].rolling(48, min_periods=1).sum()

    # --- wind_mean_24h ---
    out["wind_mean_24h"] = out["wind_speed_ms"].rolling(24, min_periods=1).mean()

    # --- solar_rad_24h ---
    out["solar_rad_24h"] = out["solar_rad_wm2"].rolling(24, min_periods=1).mean()

    # --- feed_kg_7d_cum ---
    out["feed_kg_7d_cum"] = out["feed_kg"].rolling(24 * 7, min_periods=1).sum()

    # --- fcr_running ---
    stocked_biomass_kg = stocking_weight_g * stocking_count / 1000.0
    biomass_gain = (out["biomass_kg"] - stocked_biomass_kg).clip(lower=0.01)
    out["fcr_running"] = out["cum_feed_kg"] / biomass_gain

    # --- biomass_est_kg ---
    out["biomass_est_kg"] = out["biomass_kg"]

    # --- doc: days of culture ---
    out["doc"] = out["day_of_culture"]

    # --- neighbour_risk_2km: requires multi-pond PostGIS context, stubbed ---
    out["neighbour_risk_2km"] = np.nan  # filled downstream once ponds are joined spatially

    # --- data_health_score: filled by faults.inject_faults() if faults were applied ---
    if "data_health_score" not in out.columns:
        out["data_health_score"] = 1.0

    out = out.drop(columns=["_night_key"])
    return out


FEATURE_COLUMNS = [
    "night_do_min", "night_do_min_3d_trend", "do_amplitude",
    "stress_hours_lt3_24h", "stress_hours_lt3_7d", "tan_slope_3d",
    "alkalinity_trend_7d", "nh3_un_ionised", "rain_48h_mm", "wind_mean_24h",
    "solar_rad_24h", "feed_kg_7d_cum", "fcr_running", "biomass_est_kg",
    "doc", "neighbour_risk_2km", "data_health_score",
]
