"""Unit tests — real M3 quantitative engine wrapper (P0.3).

Exercises app/ml_inference/numeric/m3_engine.py directly: no HTTP, no DB, no
containers — pure Python + LightGBM inference against the real trained
boosters in ml/serving/m3/models/. Must run fast in any environment.
"""

from __future__ import annotations

import os
from dataclasses import asdict

# Settings requires these (app_secret_key/internal_api_token/database_url are
# required fields) — set before importing anything that touches
# app.config.get_settings(), mirroring tests/integration/test_auth_rbac.py.
os.environ.setdefault("DATABASE_URL", "postgresql+asyncpg://x:x@localhost/x")
os.environ.setdefault("APP_SECRET_KEY", "test_secret_key_minimum_32_chars_here")
os.environ.setdefault("INTERNAL_API_TOKEN", "test_internal_token_minimum_32_chars")

import pytest  # noqa: E402

from app.advisory.number_validator import validate_llm_output  # noqa: E402
from app.ml_inference.numeric.m3_engine import get_m3_engine_bundle  # noqa: E402


def _sample_snapshot(bundle):
    """A realistic pond snapshot — same shape as the static values
    app/advisory/router.py's POST /v1/ask currently builds."""
    return bundle.PondSnapshot(
        pond_id="test-pond-1",
        species_key="vannamei",
        doc=52,
        biomass_est_kg=12.3,
        alive_count=180,
        do_mg_l=2.74,
        tan_mg_l=0.15,
        ph=7.9,
        alkalinity_mg_l=140.0,
        water_temp_c=29.5,
        salinity_ppt=15.0,
        wind_mean_24h=3.2,
        solar_rad_24h=450.0,
        rain_48h_mm=0.0,
        night_do_min_3d_trend=-0.1,
        do_amplitude=2.1,
        stress_hours_lt3_24h=6.0,
        stress_hours_lt3_7d=14.0,
        tan_slope_3d=0.02,
        alkalinity_trend_7d=-1.5,
        feed_kg_7d_cum=8.4,
        fcr_running=1.3,
        management_quality=0.75,
        aerator_on=True,
        data_health_score=1.0,
        nh3_un_ionised=0.01,
        cum_feed_kg=8.4,
        feed_cost_per_kg_rs=90.0,
        market_price_per_kg_rs=350.0,
    )


@pytest.mark.unit
def test_engine_bundle_is_cached_singleton() -> None:
    """LightGBM boosters must load once per process, not once per call."""
    bundle1 = get_m3_engine_bundle()
    bundle2 = get_m3_engine_bundle()
    assert bundle1 is bundle2
    assert bundle1.engine is bundle2.engine


@pytest.mark.unit
def test_decide_returns_real_payload_with_sane_types() -> None:
    bundle = get_m3_engine_bundle()
    snap = _sample_snapshot(bundle)

    payload = bundle.engine.decide(snap)

    assert isinstance(payload, bundle.M3Payload)
    assert payload.pond_id == "test-pond-1"
    assert payload.species == "Litopenaeus vannamei"
    assert payload.doc == 52

    # overnight_do_forecast_mg_l is a real LightGBM regression output over
    # realistic feature ranges — must be a float in a physically sane band,
    # not a placeholder constant.
    assert isinstance(payload.overnight_do_forecast_mg_l, float)
    assert -5.0 < payload.overnight_do_forecast_mg_l < 20.0

    assert isinstance(payload.feed_hold_recommended, bool)
    assert isinstance(payload.recommended_feed_kg, float)
    assert payload.recommended_feed_kg >= 0.0
    assert isinstance(payload.predicted_daily_gain_g, float)
    assert isinstance(payload.running_fcr, float)
    assert isinstance(payload.margin_per_kg_rs, float)


@pytest.mark.unit
def test_decide_is_deterministic_for_same_input() -> None:
    """LightGBM inference is deterministic given identical features — a
    regression here would mean something non-deterministic crept into the
    prediction path (e.g. an unseeded random source)."""
    bundle = get_m3_engine_bundle()
    snap = _sample_snapshot(bundle)

    payload1 = bundle.engine.decide(snap)
    payload2 = bundle.engine.decide(snap)

    assert payload1.overnight_do_forecast_mg_l == payload2.overnight_do_forecast_mg_l
    assert payload1.predicted_daily_gain_g == payload2.predicted_daily_gain_g
    assert payload1.recommended_feed_kg == payload2.recommended_feed_kg


@pytest.mark.unit
def test_decide_responds_to_input_changes() -> None:
    """A materially worse DO reading should be reflected in the model's
    forecast — proves this isn't a canned/constant response."""
    bundle = get_m3_engine_bundle()
    healthy = _sample_snapshot(bundle)
    stressed = bundle.PondSnapshot(**{**asdict(healthy), "do_mg_l": 0.8, "night_do_min_3d_trend": -1.5})

    payload_healthy = bundle.engine.decide(healthy)
    payload_stressed = bundle.engine.decide(stressed)

    assert payload_healthy.overnight_do_forecast_mg_l != payload_stressed.overnight_do_forecast_mg_l


@pytest.mark.unit
def test_narration_passes_number_validator_guardrail() -> None:
    """This is the exact guardrail POST /v1/ask relies on: every numeral in
    payload_to_instruction()'s narration must be traceable back to the
    engine's own payload — i.e. validate_llm_output() must NOT raise."""
    bundle = get_m3_engine_bundle()
    snap = _sample_snapshot(bundle)

    payload = bundle.engine.decide(snap)
    narration = bundle.payload_to_instruction(payload)

    assert "MOCK" not in narration.upper()
    assert "PLACEHOLDER" not in narration.upper()
    assert str(snap.pond_id) in narration

    # Must not raise NumberMismatchError — proves narration invents no
    # numbers beyond what the quantitative engine actually produced.
    validate_llm_output(narration, asdict(payload))
