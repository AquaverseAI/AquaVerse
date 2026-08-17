"""
Fault injection for the synthetic sensor traces.

MVP spec: "~20% of the above [simulated cycles]" get fault injection —
drift, biofouling, stuck values, dropout, calibration error, aerator failure.
This is what makes the numeric layer and the M1 reasoner robust to real
sensor behaviour instead of learning on pristine simulator output only.

Each fault function takes a clean pandas Series and returns a faulted copy
plus a boolean mask of which timesteps were altered — the mask becomes a
label for `data_health_score` / blind-state training.
"""

from __future__ import annotations
import numpy as np
import pandas as pd


def apply_sensor_drift(series: pd.Series, rng: np.random.Generator,
                        max_drift_pct: float = 15.0) -> tuple[pd.Series, np.ndarray]:
    """Slow linear drift over the series, simulating uncalibrated probe aging."""
    n = len(series)
    drift_direction = rng.choice([-1, 1])
    drift_curve = np.linspace(0, drift_direction * max_drift_pct / 100.0, n)
    faulted = series.values * (1 + drift_curve)
    mask = np.abs(drift_curve) > 0.02
    return pd.Series(faulted, index=series.index), mask


def apply_biofouling(series: pd.Series, rng: np.random.Generator,
                      onset_frac: float = 0.6, severity_pct: float = 25.0) -> tuple[pd.Series, np.ndarray]:
    """Growing negative bias after a random onset point (DO probe fouling is classic)."""
    n = len(series)
    onset = int(n * onset_frac * rng.uniform(0.7, 1.3))
    onset = min(onset, n - 2)
    bias_curve = np.zeros(n)
    remaining = n - onset
    bias_curve[onset:] = -np.linspace(0, severity_pct / 100.0, remaining)
    faulted = series.values * (1 + bias_curve)
    mask = bias_curve < -0.01
    return pd.Series(faulted, index=series.index), mask


def apply_stuck_value(series: pd.Series, rng: np.random.Generator,
                       stuck_duration_hours: int | None = None) -> tuple[pd.Series, np.ndarray]:
    """Sensor freezes at last good reading for a stretch (common failure mode)."""
    n = len(series)
    faulted = series.values.copy()
    mask = np.zeros(n, dtype=bool)
    duration = stuck_duration_hours or rng.integers(6, 48)
    if n <= duration + 1:
        return series, mask
    start = rng.integers(0, n - duration - 1)
    stuck_val = faulted[start]
    faulted[start:start + duration] = stuck_val
    mask[start:start + duration] = True
    return pd.Series(faulted, index=series.index), mask


def apply_dropout(series: pd.Series, rng: np.random.Generator,
                   dropout_prob: float = 0.03) -> tuple[pd.Series, np.ndarray]:
    """Random missing readings (NaN) — connectivity gaps, battery, etc."""
    n = len(series)
    mask = rng.random(n) < dropout_prob
    faulted = series.values.copy().astype(float)
    faulted[mask] = np.nan
    return pd.Series(faulted, index=series.index), mask


def apply_calibration_offset(series: pd.Series, rng: np.random.Generator,
                              offset_range: tuple = (-0.5, 0.5)) -> tuple[pd.Series, np.ndarray]:
    """Constant offset from the moment of a bad calibration — step change, not drift."""
    n = len(series)
    step_at = rng.integers(int(n * 0.1), int(n * 0.9))
    offset = rng.uniform(*offset_range)
    faulted = series.values.copy().astype(float)
    faulted[step_at:] += offset
    mask = np.zeros(n, dtype=bool)
    mask[step_at:] = True
    return pd.Series(faulted, index=series.index), mask


def apply_aerator_failure(df: pd.DataFrame, rng: np.random.Generator,
                           failure_prob_per_night: float = 0.03) -> pd.DataFrame:
    """
    Aerator scheduled to run but doesn't (mechanical/power failure). This is
    injected upstream of the DO signal (regenerate DO for affected hours)
    rather than as a sensor fault — it's a true event, not a measurement error.
    Caller must re-run DO physics for flagged hours; here we just flag them.
    """
    df = df.copy()
    df["aerator_failure_flag"] = False
    nights = df["day_of_culture"].unique()
    for day in nights:
        if rng.random() < failure_prob_per_night:
            night_mask = (df["day_of_culture"] == day) & (df["aerator_on"])
            df.loc[night_mask, "aerator_failure_flag"] = True
            df.loc[night_mask, "aerator_on"] = False
    return df


FAULT_LIBRARY = {
    "drift": apply_sensor_drift,
    "biofouling": apply_biofouling,
    "stuck_value": apply_stuck_value,
    "dropout": apply_dropout,
    "calibration_offset": apply_calibration_offset,
}


def inject_faults(
    df: pd.DataFrame,
    rng: np.random.Generator,
    sensor_columns: list[str] = ("do_mg_l", "tan_mg_l", "ph", "alkalinity_mg_l"),
    n_faults: int | None = None,
) -> tuple[pd.DataFrame, pd.DataFrame]:
    """
    Applies a random subset of faults to a random subset of sensor columns.
    Returns (faulted_df, fault_mask_df) where fault_mask_df has one boolean
    column per faulted sensor, aligned to df's index, marking altered rows —
    this is the ground-truth label for `data_health_score` training.
    """
    faulted_df = df.copy()
    mask_df = pd.DataFrame(False, index=df.index, columns=[f"{c}_faulted" for c in sensor_columns])

    n_faults = n_faults or rng.integers(1, 3)
    fault_names = list(FAULT_LIBRARY.keys())

    for _ in range(n_faults):
        col = rng.choice(list(sensor_columns))
        fault_name = rng.choice(fault_names)
        fault_fn = FAULT_LIBRARY[fault_name]
        faulted_series, mask = fault_fn(faulted_df[col], rng)
        faulted_df[col] = faulted_series
        mask_df[f"{col}_faulted"] = mask_df[f"{col}_faulted"] | mask

    faulted_df = apply_aerator_failure(faulted_df, rng)

    # data_health_score: fraction of sensor columns clean at each timestep
    mask_df["data_health_score"] = 1.0 - mask_df[[c for c in mask_df.columns if c != "data_health_score"]].mean(axis=1)

    return faulted_df, mask_df
