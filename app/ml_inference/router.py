"""ML Inference — routers for ponds, risk, forecast, models, data-quality."""

from __future__ import annotations

from datetime import datetime, timedelta
from uuid import UUID, uuid4

from fastapi import APIRouter, Query

from app.core import rbac
from app.core.pagination import CursorPage
from app.core.timezones import utcnow
from app.deps import CurrentStaff, CurrentUser
from app.ml_inference.schemas import (
    DataQualityOut,
    DriftReport,
    ForecastOut,
    ForecastPoint,
    ModelMetricsOut,
    ModelOut,
    PondEventOut,
    PondOut,
    PondTimeseriesOut,
    PondTimeseriesPoint,
    RiskOut,
    ShapContribution,
    WorklistItem,
)

router = APIRouter(tags=["Ponds & ML"])

_STUB_POND_ID = UUID("00000000-0000-0000-0000-000000000001")
_STUB_MODEL_ID = UUID("00000000-0000-0000-0000-000000000002")


# ---------------------------------------------------------------------------
# Ponds
# ---------------------------------------------------------------------------
@router.get("/ponds", response_model=CursorPage[PondOut], summary="List accessible ponds")
async def list_ponds(
    user: CurrentUser,
    cursor: str | None = Query(default=None),
    limit: int = Query(default=50, ge=1, le=200),
) -> CursorPage[PondOut]:
    now = utcnow()
    stub = PondOut(
        id=_STUB_POND_ID,
        name="Kalaiselvi Pond - Block A",
        district="Nagapattinam",
        taluk="Sirkali",
        species="Litopenaeus vannamei",
        area_hectares=2.5,
        depth_meters=1.2,
        owner_user_id=uuid4(),
        created_at=now,
        updated_at=now,
    )
    return CursorPage[PondOut](items=[stub], next_cursor=None)


@router.get("/ponds/{pond_id}", response_model=PondOut, summary="Get pond details")
async def get_pond(pond_id: UUID, user: CurrentUser) -> PondOut:
    if user.role not in ("staff", "admin"):
        rbac.require_pond_scope(user.pond_ids, pond_id)
    now = utcnow()
    return PondOut(
        id=pond_id,
        name="Kalaiselvi Pond - Block A",
        district="Nagapattinam",
        species="Litopenaeus vannamei",
        area_hectares=2.5,
        depth_meters=1.2,
        owner_user_id=uuid4(),
        created_at=now,
        updated_at=now,
    )


@router.get(
    "/ponds/{pond_id}/timeseries",
    response_model=PondTimeseriesOut,
    summary="Get time-series data for a pond parameter",
    description=(
        "Returns hourly aggregated time-series for a single water quality parameter. "
        "12-month, 6-parameter hourly queries must return in <300ms p95."
    ),
)
async def get_pond_timeseries(
    pond_id: UUID,
    user: CurrentUser,
    parameter: str = Query(default="dissolved_oxygen_mgl"),
    from_ts: datetime | None = Query(default=None),
    to_ts: datetime | None = Query(default=None),
    cursor: str | None = Query(default=None),
    limit: int = Query(default=200, ge=1, le=1000),
) -> PondTimeseriesOut:
    if user.role not in ("staff", "admin"):
        rbac.require_pond_scope(user.pond_ids, pond_id)
    now = utcnow()
    return PondTimeseriesOut(
        pond_id=pond_id,
        parameter=parameter,
        points=[
            PondTimeseriesPoint(
                recorded_at=now - timedelta(hours=i),
                dissolved_oxygen_mgl=6.5 - i * 0.05,
            )
            for i in range(5)
        ],
        next_cursor=None,
    )


@router.get(
    "/ponds/{pond_id}/events",
    response_model=CursorPage[PondEventOut],
    summary="Get event timeline for a pond",
)
async def get_pond_events(
    pond_id: UUID,
    user: CurrentUser,
    cursor: str | None = Query(default=None),
    limit: int = Query(default=50, ge=1, le=200),
) -> CursorPage[PondEventOut]:
    if user.role not in ("staff", "admin"):
        rbac.require_pond_scope(user.pond_ids, pond_id)
    now = utcnow()
    stub = PondEventOut(
        id=uuid4(),
        event_type="alert",
        title="Low dissolved oxygen detected",
        occurred_at=now,
        severity="high",
    )
    return CursorPage[PondEventOut](items=[stub], next_cursor=None)


# ---------------------------------------------------------------------------
# Risk
# ---------------------------------------------------------------------------
@router.get(
    "/ponds/{pond_id}/risk",
    response_model=RiskOut,
    summary="Get current risk score for a pond",
    description=(
        "Returns a composite risk score (0–1) produced by the LightGBM/EBM quantitative layer, "
        "with per-feature SHAP attributions. Suppression state is always visible."
    ),
)
async def get_pond_risk(pond_id: UUID, user: CurrentUser) -> RiskOut:
    if user.role not in ("staff", "admin"):
        rbac.require_pond_scope(user.pond_ids, pond_id)
    now = utcnow()
    return RiskOut(
        pond_id=pond_id,
        risk_score=0.72,
        risk_level="high",
        components={"chemistry": 0.68, "health": 0.75, "production": 0.73},
        shap_contributions=[
            ShapContribution(
                feature="dissolved_oxygen_mgl",
                value=4.2,
                shap_value=0.18,
                direction="increases_risk",
            ),
            ShapContribution(
                feature="ammonia_nh3_mgl",
                value=0.8,
                shap_value=0.12,
                direction="increases_risk",
            ),
        ],
        model_version="lightgbm-v1.2.0",
        scored_at=now,
        suppressed=False,
    )


@router.get(
    "/risk/worklist",
    response_model=CursorPage[WorklistItem],
    summary="Risk worklist for staff — all ponds ranked by risk",
)
async def get_risk_worklist(
    user: CurrentStaff,
    district: str | None = Query(default=None),
    risk_level: str | None = Query(default=None),
    cursor: str | None = Query(default=None),
    limit: int = Query(default=50, ge=1, le=200),
) -> CursorPage[WorklistItem]:
    if district is not None:
        rbac.require_district(user.district, district, user.role)
    now = utcnow()
    stub = WorklistItem(
        pond_id=_STUB_POND_ID,
        pond_name="Kalaiselvi Pond - Block A",
        district="Nagapattinam",
        risk_score=0.72,
        risk_level="high",
        suppressed=False,
        last_log_at=now,
    )
    return CursorPage[WorklistItem](items=[stub], next_cursor=None)


# ---------------------------------------------------------------------------
# Forecast
# ---------------------------------------------------------------------------
@router.get(
    "/ponds/{pond_id}/forecast/do",
    response_model=ForecastOut,
    summary="Dissolved oxygen forecast with uncertainty bands",
    description=(
        "Returns a 24-hour dissolved oxygen forecast with 10th/50th/90th percentile bands "
        "from the temporal model (TCN/TFT/PatchTST). "
        "RULE: Bare point estimates are forbidden — bands are always returned."
    ),
)
async def get_do_forecast(
    pond_id: UUID,
    user: CurrentUser,
    horizon_hours: int = Query(default=24, ge=1, le=168),
) -> ForecastOut:
    if user.role not in ("staff", "admin"):
        rbac.require_pond_scope(user.pond_ids, pond_id)
    now = utcnow()
    return ForecastOut(
        pond_id=pond_id,
        parameter="dissolved_oxygen_mgl",
        horizon_hours=horizon_hours,
        points=[
            ForecastPoint(
                forecasted_at=now + timedelta(hours=i + 1),
                p10=5.2 - i * 0.05,
                p50=6.0 - i * 0.04,
                p90=6.8 - i * 0.03,
            )
            for i in range(min(horizon_hours, 24))
        ],
        model_version="patchtst-v0.3.1",
        generated_at=now,
    )


# ---------------------------------------------------------------------------
# Model registry
# ---------------------------------------------------------------------------
@router.get(
    "/models",
    response_model=CursorPage[ModelOut],
    tags=["Models"],
    summary="List registered ML models",
)
async def list_models(
    user: CurrentStaff,
    cursor: str | None = Query(default=None),
    limit: int = Query(default=50, ge=1, le=200),
) -> CursorPage[ModelOut]:
    now = utcnow()
    stub = ModelOut(
        id=_STUB_MODEL_ID,
        name="risk_lightgbm",
        model_type="lightgbm",
        version="1.2.0",
        is_active=True,
        dataset_hash="a" * 64,
        metrics={"auc": 0.92, "f1": 0.87},
        promoted_at=now,
        created_at=now,
    )
    return CursorPage[ModelOut](items=[stub], next_cursor=None)


@router.get(
    "/models/metrics",
    response_model=ModelMetricsOut,
    tags=["Models"],
    summary="Operational metrics for the model serving layer",
    description=(
        "Exposes `rejected_attempts` — the count of LLM responses that were rejected "
        "because they contained a numeral not present in the quantitative tool-call payload. "
        "This MUST read 0 in steady state."
    ),
)
async def get_model_metrics(user: CurrentStaff) -> ModelMetricsOut:
    from app.advisory.metrics import get_rejected_attempts

    now = utcnow()
    return ModelMetricsOut(
        rejected_attempts=get_rejected_attempts(),
        total_requests=0,
        avg_latency_ms=0.0,
        p95_latency_ms=0.0,
        p99_latency_ms=0.0,
        cache_hit_rate=0.0,
        as_of=now,
    )


@router.get(
    "/models/drift",
    response_model=CursorPage[DriftReport],
    tags=["Models"],
    summary="Model drift reports",
)
async def get_model_drift(
    user: CurrentStaff,
    cursor: str | None = Query(default=None),
    limit: int = Query(default=20, ge=1, le=100),
) -> CursorPage[DriftReport]:
    now = utcnow()
    stub = DriftReport(
        model_name="risk_lightgbm",
        model_version="1.2.0",
        feature_drift={"dissolved_oxygen_mgl": 0.02, "ammonia_nh3_mgl": 0.05},
        alert_threshold=0.2,
        drift_detected=False,
        evaluated_at=now,
    )
    return CursorPage[DriftReport](items=[stub], next_cursor=None)


# ---------------------------------------------------------------------------
# Data quality
# ---------------------------------------------------------------------------
@router.get(
    "/data-quality",
    response_model=DataQualityOut,
    tags=["Data Quality"],
    summary="Data quality signals across all ponds",
)
async def get_data_quality(
    user: CurrentStaff,
    pond_id: UUID | None = Query(default=None),
) -> DataQualityOut:
    now = utcnow()
    return DataQualityOut(
        pond_id=pond_id,
        total_logs_last_7d=142,
        missing_parameter_rates={
            "dissolved_oxygen_mgl": 0.03,
            "ph": 0.01,
            "ammonia_nh3_mgl": 0.12,
        },
        sensor_offline_ponds=0,
        stale_threshold_hours=4,
        evaluated_at=now,
    )
