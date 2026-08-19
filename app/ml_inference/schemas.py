"""ML Inference — Pydantic v2 schemas for risk, forecast, ponds, and model endpoints."""

from __future__ import annotations

from datetime import datetime
from typing import TYPE_CHECKING, Any
from uuid import UUID

from pydantic import BaseModel, Field

if TYPE_CHECKING:
    pass


# ---------------------------------------------------------------------------
# Pond
# ---------------------------------------------------------------------------
class PondOut(BaseModel):
    id: UUID
    name: str
    district: str
    taluk: str | None = None
    village: str | None = None
    area_hectares: float | None = None
    depth_meters: float | None = None
    species: str | None = None
    owner_user_id: UUID
    created_at: datetime
    updated_at: datetime


class PondTimeseriesPoint(BaseModel):
    recorded_at: datetime
    temperature_c: float | None = None
    dissolved_oxygen_mgl: float | None = None
    ph: float | None = None
    salinity_ppt: float | None = None
    ammonia_nh3_mgl: float | None = None
    turbidity_ntu: float | None = None
    # Ambient (not water-column) readings from pond-side IoT sensor units —
    # see POST /v1/ingest/sensor/{pond_id}. Null for manually-logged rows.
    air_temperature_c: float | None = None
    humidity_pct: float | None = None


class PondTimeseriesOut(BaseModel):
    pond_id: UUID
    parameter: str
    points: list[PondTimeseriesPoint]
    next_cursor: str | None = None


class PondEventOut(BaseModel):
    id: UUID
    event_type: str  # alert | log | crop_event | advisory
    title: str
    occurred_at: datetime
    severity: str | None = None
    metadata: dict[str, Any] | None = None


# ---------------------------------------------------------------------------
# Risk score
# ---------------------------------------------------------------------------
class ShapContribution(BaseModel):
    feature: str
    value: float
    shap_value: float
    direction: str  # increases_risk | decreases_risk | neutral


class RiskOut(BaseModel):
    pond_id: UUID
    risk_score: float = Field(..., ge=0.0, le=1.0, description="0–1 composite risk score")
    risk_level: str  # critical | high | medium | low
    components: dict[str, float] = Field(
        ...,
        description="Per-component risk scores: chemistry, health, production",
    )
    shap_contributions: list[ShapContribution]
    model_version: str
    scored_at: datetime

    # RULE: Suppression is ALWAYS visible
    suppressed: bool = Field(
        ...,
        description=(
            "True if sensor data is stale / in blind state. "
            "Score may be unreliable — always surface this to the user."
        ),
    )
    suppression_reason: str | None = None


# ---------------------------------------------------------------------------
# Worklist (risk across all accessible ponds)
# ---------------------------------------------------------------------------
class WorklistItem(BaseModel):
    pond_id: UUID
    pond_name: str
    district: str
    risk_score: float
    risk_level: str
    suppressed: bool
    suppression_reason: str | None = None
    last_log_at: datetime | None = None


# ---------------------------------------------------------------------------
# Forecast (dissolved oxygen example — all bands required)
# ---------------------------------------------------------------------------
class ForecastPoint(BaseModel):
    forecasted_at: datetime
    p10: float = Field(..., description="10th percentile (lower bound)")
    p50: float = Field(..., description="Median forecast")
    p90: float = Field(..., description="90th percentile (upper bound)")


class ForecastOut(BaseModel):
    pond_id: UUID
    parameter: str  # dissolved_oxygen | temperature | ph | etc.
    horizon_hours: int
    points: list[ForecastPoint]
    model_version: str
    generated_at: datetime
    # RULE: bands required — never a bare point estimate
    uncertainty_note: str = (
        "Forecast bands represent the 10th–90th percentile range from the ensemble. "
        "Do not use the median alone for management decisions."
    )


# ---------------------------------------------------------------------------
# Model registry
# ---------------------------------------------------------------------------
class ModelOut(BaseModel):
    id: UUID
    name: str
    model_type: str
    version: str
    is_active: bool
    dataset_hash: str
    metrics: dict[str, Any] | None = None
    promoted_at: datetime | None = None
    created_at: datetime


class ModelMetricsOut(BaseModel):
    """
    Operational metrics for the serving layer.

    rejected_attempts: number of LLM responses rejected because they contained
    a numeral not present in the quantitative tool-call payload.
    MUST read 0 in steady state.
    """

    rejected_attempts: int = Field(
        ...,
        description=(
            "Count of LLM responses rejected due to numeral mismatch. "
            "Non-zero values indicate a problem with the reasoning layer."
        ),
    )
    total_requests: int
    avg_latency_ms: float
    p95_latency_ms: float
    p99_latency_ms: float
    cache_hit_rate: float
    as_of: datetime


class DriftReport(BaseModel):
    model_name: str
    model_version: str
    feature_drift: dict[str, float]  # feature → PSI score
    label_drift: float | None = None
    alert_threshold: float
    drift_detected: bool
    evaluated_at: datetime


# ---------------------------------------------------------------------------
# Data quality
# ---------------------------------------------------------------------------
class DataQualityOut(BaseModel):
    pond_id: UUID | None = None
    total_logs_last_7d: int
    missing_parameter_rates: dict[str, float]  # parameter → fraction missing
    sensor_offline_ponds: int
    stale_threshold_hours: int
    evaluated_at: datetime
