"""ML Inference — routers for ponds, risk, forecast, models, data-quality."""

from __future__ import annotations

from datetime import datetime, timedelta
from uuid import UUID

from fastapi import APIRouter, HTTPException, Query
from sqlalchemy import and_, or_, select

from app.core import rbac
from app.core.pagination import CursorPage, clamp_limit, decode_keyset_cursor, encode_keyset_cursor
from app.core.timezones import utcnow
from app.db.models.log import Log
from app.db.models.pond import Pond
from app.deps import CurrentStaff, CurrentUser, DbSession
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
    session: DbSession,
    district: str | None = Query(default=None),
    cursor: str | None = Query(default=None),
    limit: int | None = Query(default=None),
) -> CursorPage[PondOut]:
    """Real keyset pagination — sorted by created_at DESC, id DESC.

    Scoping:
      * admin — unrestricted, or filtered to `district` if given.
      * staff — filtered to `district` (validated via rbac.require_district)
        if given, else defaulted to the caller's own district claim; a
        staff token with no district claim gets an empty page (fail closed).
      * farmer — always scoped to ponds they own; `district` is ignored.
    """
    effective_limit = clamp_limit(limit)
    stmt = select(Pond)

    if user.role == "admin":
        if district is not None:
            stmt = stmt.where(Pond.district == district)
    elif user.role == "staff":
        if district is not None:
            rbac.require_district(user.district, district, user.role)
            stmt = stmt.where(Pond.district == district)
        elif user.district is None:
            # No district claim and no explicit filter — fail closed, not
            # an unscoped global list.
            return CursorPage[PondOut](items=[], next_cursor=None)
        else:
            stmt = stmt.where(Pond.district == user.district)
    else:  # farmer
        try:
            owner_id = UUID(user.sub)
        except ValueError as exc:
            raise HTTPException(
                status_code=400, detail="Token 'sub' claim is not a valid UUID."
            ) from exc
        stmt = stmt.where(Pond.owner_user_id == owner_id)

    decoded = decode_keyset_cursor(cursor)
    if decoded is not None:
        last_created_at_raw, last_id_raw = decoded
        try:
            last_created_at = datetime.fromisoformat(last_created_at_raw)
            last_id = UUID(last_id_raw)
        except ValueError:
            last_created_at = None
            last_id = None

        if last_created_at is not None and last_id is not None:
            stmt = stmt.where(
                or_(
                    Pond.created_at < last_created_at,
                    and_(Pond.created_at == last_created_at, Pond.id < last_id),
                )
            )

    stmt = stmt.order_by(Pond.created_at.desc(), Pond.id.desc())
    stmt = stmt.limit(effective_limit + 1)

    result = await session.execute(stmt)
    ponds = list(result.scalars().all())

    has_next = len(ponds) > effective_limit
    ponds = ponds[:effective_limit]

    next_cursor: str | None = None
    if has_next and ponds:
        last_row = ponds[-1]
        next_cursor = encode_keyset_cursor(last_row.created_at.isoformat(), last_row.id)

    items = [PondOut.model_validate(pond, from_attributes=True) for pond in ponds]
    return CursorPage[PondOut](items=items, next_cursor=next_cursor)


@router.get("/ponds/{pond_id}", response_model=PondOut, summary="Get pond details")
async def get_pond(pond_id: UUID, user: CurrentUser, session: DbSession) -> PondOut:
    if user.role not in ("staff", "admin"):
        rbac.require_pond_scope(user.pond_ids, pond_id)
    pond = await session.get(Pond, pond_id)
    if pond is None:
        raise HTTPException(status_code=404, detail="Pond not found")
    return PondOut.model_validate(pond, from_attributes=True)


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
    session: DbSession,
    parameter: str = Query(default="dissolved_oxygen_mgl"),
    from_ts: datetime | None = Query(default=None),
    to_ts: datetime | None = Query(default=None),
    cursor: str | None = Query(default=None),
    limit: int | None = Query(default=None),
) -> PondTimeseriesOut:
    if user.role not in ("staff", "admin"):
        rbac.require_pond_scope(user.pond_ids, pond_id)

    pond_exists = (
        await session.execute(select(Pond.id).where(Pond.id == pond_id))
    ).scalar_one_or_none()
    if pond_exists is None:
        raise HTTPException(status_code=404, detail="Pond not found")

    effective_limit = clamp_limit(limit)
    stmt = select(Log).where(Log.pond_id == pond_id)
    if from_ts is not None:
        stmt = stmt.where(Log.recorded_at >= from_ts)
    if to_ts is not None:
        stmt = stmt.where(Log.recorded_at <= to_ts)

    decoded = decode_keyset_cursor(cursor)
    if decoded is not None:
        last_recorded_at_raw, last_id_raw = decoded
        try:
            last_recorded_at = datetime.fromisoformat(last_recorded_at_raw)
            last_id = UUID(last_id_raw)
        except ValueError:
            last_recorded_at = None
            last_id = None

        if last_recorded_at is not None and last_id is not None:
            stmt = stmt.where(
                or_(
                    Log.recorded_at < last_recorded_at,
                    and_(Log.recorded_at == last_recorded_at, Log.id < last_id),
                )
            )

    stmt = stmt.order_by(Log.recorded_at.desc(), Log.id.desc())
    stmt = stmt.limit(effective_limit + 1)

    result = await session.execute(stmt)
    logs = list(result.scalars().all())

    has_next = len(logs) > effective_limit
    logs = logs[:effective_limit]

    next_cursor: str | None = None
    if has_next and logs:
        last_row = logs[-1]
        next_cursor = encode_keyset_cursor(last_row.recorded_at.isoformat(), last_row.id)

    points = [
        PondTimeseriesPoint(
            recorded_at=log.recorded_at,
            temperature_c=log.temperature_c,
            dissolved_oxygen_mgl=log.dissolved_oxygen_mgl,
            ph=log.ph,
            salinity_ppt=log.salinity_ppt,
            ammonia_nh3_mgl=log.ammonia_nh3_mgl,
            turbidity_ntu=log.turbidity_ntu,
        )
        for log in logs
    ]
    return PondTimeseriesOut(
        pond_id=pond_id,
        parameter=parameter,
        points=points,
        next_cursor=next_cursor,
    )


@router.get(
    "/ponds/{pond_id}/events",
    response_model=CursorPage[PondEventOut],
    summary="Get event timeline for a pond",
)
async def get_pond_events(
    pond_id: UUID,
    user: CurrentUser,
    session: DbSession,
    cursor: str | None = Query(default=None),
    limit: int | None = Query(default=None),
) -> CursorPage[PondEventOut]:
    """Synthesizes events from real Log rows.

    There is no dedicated events table. `Alert` (app/db/models/alert.py) is a
    real table but nothing populates it yet — raising real alerts is P2.1's
    job. The alert-sourced half of this endpoint's `event_type` space is
    intentionally deferred, not forgotten; today every event is
    `event_type="log"`.
    """
    if user.role not in ("staff", "admin"):
        rbac.require_pond_scope(user.pond_ids, pond_id)

    pond_exists = (
        await session.execute(select(Pond.id).where(Pond.id == pond_id))
    ).scalar_one_or_none()
    if pond_exists is None:
        raise HTTPException(status_code=404, detail="Pond not found")

    effective_limit = clamp_limit(limit)
    stmt = select(Log).where(Log.pond_id == pond_id)

    decoded = decode_keyset_cursor(cursor)
    if decoded is not None:
        last_recorded_at_raw, last_id_raw = decoded
        try:
            last_recorded_at = datetime.fromisoformat(last_recorded_at_raw)
            last_id = UUID(last_id_raw)
        except ValueError:
            last_recorded_at = None
            last_id = None

        if last_recorded_at is not None and last_id is not None:
            stmt = stmt.where(
                or_(
                    Log.recorded_at < last_recorded_at,
                    and_(Log.recorded_at == last_recorded_at, Log.id < last_id),
                )
            )

    stmt = stmt.order_by(Log.recorded_at.desc(), Log.id.desc())
    stmt = stmt.limit(effective_limit + 1)

    result = await session.execute(stmt)
    logs = list(result.scalars().all())

    has_next = len(logs) > effective_limit
    logs = logs[:effective_limit]

    next_cursor: str | None = None
    if has_next and logs:
        last_row = logs[-1]
        next_cursor = encode_keyset_cursor(last_row.recorded_at.isoformat(), last_row.id)

    parameter_fields = (
        "temperature_c",
        "dissolved_oxygen_mgl",
        "ph",
        "salinity_ppt",
        "ammonia_nh3_mgl",
        "turbidity_ntu",
        "nitrite_mgl",
        "nitrate_mgl",
        "alkalinity_mgl",
        "hardness_mgl",
    )
    items = [
        PondEventOut(
            id=log.id,
            event_type="log",
            title=f"Water quality log recorded ({log.source})",
            occurred_at=log.recorded_at,
            severity=None,
            metadata={
                field: value
                for field in parameter_fields
                if (value := getattr(log, field)) is not None
            },
        )
        for log in logs
    ]
    return CursorPage[PondEventOut](items=items, next_cursor=next_cursor)


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
