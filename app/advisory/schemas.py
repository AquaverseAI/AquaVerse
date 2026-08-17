"""Advisory — Pydantic v2 schemas for /v1/reason and /v1/ask."""

from __future__ import annotations

from datetime import datetime
from typing import TYPE_CHECKING
from uuid import UUID

from pydantic import BaseModel, Field

if TYPE_CHECKING:
    pass


# ---------------------------------------------------------------------------
# Reason (internal only — POST /v1/reason)
# ---------------------------------------------------------------------------
class ToolCallPayload(BaseModel):
    """
    Quantitative output that must be passed to the reasoning layer.
    Every numeral the LLM is allowed to mention must appear here.
    """

    risk_score: float
    risk_level: str
    components: dict[str, float]
    shap_contributions: list[dict[str, object]]
    forecast_p10: float | None = None
    forecast_p50: float | None = None
    forecast_p90: float | None = None
    raw_measurements: dict[str, float | None] = Field(default_factory=dict)


class ReasonIn(BaseModel):
    pond_id: UUID
    adapter: str = Field(
        ...,
        description="LoRA adapter to use: m1_chemistry | m2_health | m3_production",
    )
    tool_call_payload: ToolCallPayload
    context: str | None = Field(
        default=None,
        max_length=2000,
        description="Additional context text (farmer's question, recent observations)",
    )
    language: str = Field(default="ta", description="BCP-47 language code")
    max_retries: int = Field(default=3, ge=1, le=5)


class ReasonOut(BaseModel):
    pond_id: UUID
    adapter: str
    explanation: str = Field(
        ...,
        description=(
            "Explanation from the reasoning layer. "
            "Health/disease language uses 'consistent with X, confirm by Y' phrasing — "
            "never a confident diagnosis."
        ),
    )
    rejected_attempts_this_request: int = Field(
        ...,
        description="Number of times the validator rejected a response for this request.",
    )
    model_version: str
    generated_at: datetime


# ---------------------------------------------------------------------------
# Ask (farmer-facing — POST /v1/ask)
# ---------------------------------------------------------------------------
class AskIn(BaseModel):
    pond_id: UUID
    question: str = Field(..., max_length=1000)
    language: str = Field(default="ta", description="BCP-47 language code")
    include_tts: bool = Field(default=False, description="Return TTS audio URL in response")


class AskOut(BaseModel):
    pond_id: UUID
    question: str
    answer: str
    language: str
    tts_url: str | None = None
    generated_at: datetime
    rejected_attempts_this_request: int


# ---------------------------------------------------------------------------
# Advisories
# ---------------------------------------------------------------------------
class AdvisoryOut(BaseModel):
    id: UUID
    title: str
    body: str
    language: str
    target_district: str | None = None
    target_species: str | None = None
    severity: str | None = None
    issued_at: datetime
    expires_at: datetime | None = None


class BroadcastIn(BaseModel):
    title: str = Field(..., max_length=500)
    body: str = Field(..., max_length=5000)
    language: str = Field(default="ta")
    target_district: str | None = None
    target_species: str | None = None
    severity: str | None = Field(
        default=None,
        description="info | warning | critical",
    )
    expires_at: datetime | None = None

# ---------------------------------------------------------------------------
# M3 Serving Integration Schemas
# ---------------------------------------------------------------------------
class M3PondSnapshotRequest(BaseModel):
    pond_id: str
    species_key: str
    doc: int
    biomass_est_kg: float
    alive_count: int
    do_mg_l: float
    tan_mg_l: float
    ph: float
    alkalinity_mg_l: float
    water_temp_c: float
    salinity_ppt: float
    wind_mean_24h: float
    solar_rad_24h: float
    rain_48h_mm: float
    night_do_min_3d_trend: float = 0.0
    do_amplitude: float = 0.0
    stress_hours_lt3_24h: float = 0.0
    stress_hours_lt3_7d: float = 0.0
    tan_slope_3d: float = 0.0
    alkalinity_trend_7d: float = 0.0
    feed_kg_7d_cum: float = 0.0
    fcr_running: float = 0.0
    management_quality: float = 0.7
    aerator_on: bool = False
    data_health_score: float = 1.0
    nh3_un_ionised: float = 0.0
    cum_feed_kg: float = 0.0
    feed_cost_per_kg_rs: float = 90.0
    market_price_per_kg_rs: float = 350.0

class M3ReasonResponse(BaseModel):
    pond_id: str
    payload: dict
    narration: str
    hallucination_check_passed: bool
    regeneration_attempts: int
    latency_ms: float
