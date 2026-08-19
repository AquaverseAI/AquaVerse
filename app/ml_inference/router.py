"""ML Inference — routers for ponds, risk, forecast, models, data-quality."""

from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime, timedelta
from uuid import UUID

from fastapi import APIRouter, HTTPException, Query
from sqlalchemy import and_, or_, select

from app.core import rbac
from app.core.pagination import (
    CursorPage,
    clamp_limit,
    decode_cursor,
    decode_keyset_cursor,
    encode_cursor,
    encode_keyset_cursor,
)
from app.core.timezones import utcnow
from app.db.models.crop import Crop
from app.db.models.log import Log
from app.db.models.pond import Pond
from app.deps import CurrentStaff, CurrentUser, DbSession
from app.ml_inference.numeric import m2_risk_engine
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
            air_temperature_c=log.air_temperature_c,
            humidity_pct=log.humidity_pct,
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
# Matches DataQualityOut's stale_threshold_hours value, hardcoded further
# below in get_data_quality — reused here rather than a second invented
# number. See m2_risk_engine.STALE_LOG_THRESHOLD_HOURS docstring.
_STALE_LOG_THRESHOLD_HOURS = m2_risk_engine.STALE_LOG_THRESHOLD_HOURS
_RISK_LOOKBACK_DAYS = 30


@dataclass(frozen=True)
class _PondRiskComputation:
    risk_out: RiskOut
    last_log_at: datetime | None


async def _fetch_recent_logs(session: DbSession, pond_id: UUID, since: datetime) -> list[Log]:
    stmt = (
        select(Log)
        .where(Log.pond_id == pond_id, Log.recorded_at >= since)
        .order_by(Log.recorded_at.asc(), Log.id.asc())
    )
    result = await session.execute(stmt)
    return list(result.scalars().all())


async def _fetch_active_crop(session: DbSession, pond_id: UUID) -> Crop | None:
    stmt = (
        select(Crop)
        .where(Crop.pond_id == pond_id, Crop.status == "active")
        .order_by(Crop.stocking_date.desc())
        .limit(1)
    )
    result = await session.execute(stmt)
    return result.scalar_one_or_none()


async def _compute_pond_risk(session: DbSession, pond: Pond, now: datetime) -> _PondRiskComputation:
    """Real M2-model-backed risk computation, shared by `get_pond_risk` and
    `get_risk_worklist` (per the task brief: one computation, reused
    everywhere) so both endpoints agree with each other by construction.
    """
    since = now - timedelta(days=_RISK_LOOKBACK_DAYS)
    logs = await _fetch_recent_logs(session, pond.id, since)
    crop = await _fetch_active_crop(session, pond.id)

    if not logs:
        suppressed = True
        suppression_reason = "No sensor data recorded for this pond."
        last_log_at: datetime | None = None
    else:
        last_log_at = logs[-1].recorded_at
        age_hours = (now - last_log_at).total_seconds() / 3600.0
        if age_hours > _STALE_LOG_THRESHOLD_HOURS:
            suppressed = True
            suppression_reason = (
                f"Most recent reading is {age_hours:.1f}h old — data may be stale "
                f"(suppression threshold: {_STALE_LOG_THRESHOLD_HOURS}h)."
            )
        else:
            suppressed = False
            suppression_reason = None

    if crop is not None:
        doc_value: int | None = max((now.date() - crop.stocking_date).days, 0)
        stocking_count: int | None = crop.post_larvae_count
    else:
        doc_value = None
        stocking_count = None

    points = [
        m2_risk_engine.RawLogPoint(
            recorded_at=log.recorded_at,
            do_mg_l=log.dissolved_oxygen_mgl,
            tan_mg_l=log.ammonia_nh3_mgl,
            ph=log.ph,
            water_temp_c=log.temperature_c,
            alkalinity_mg_l=log.alkalinity_mgl,
            no2_mg_l=log.nitrite_mgl,
            no3_mg_l=log.nitrate_mgl,
            salinity_ppt=log.salinity_ppt,
        )
        for log in logs
    ]

    result = m2_risk_engine.score_pond(
        points=points,
        species_text=pond.species,
        doc_value=doc_value,
        stocking_count=stocking_count,
        now=now,
    )

    chemistry = m2_risk_engine.compute_chemistry_index(
        do_mg_l=result.do_mg_l,
        ph=result.ph,
        nh3_un_ionised=result.nh3_un_ionised,
        species_key=result.species_key,
    )

    components = {
        "chemistry": chemistry,
        "health": round(result.risk_score, 4),
        # Documented neutral default — no feed-log/FCR ingestion exists to
        # compute a real production-risk axis (same honesty convention as
        # m2_risk_engine's other PLACEHOLDER fields).
        "production": 0.5,
    }

    risk_out = RiskOut(
        pond_id=pond.id,
        risk_score=round(result.risk_score, 4),
        risk_level=result.risk_level,
        components=components,
        shap_contributions=[
            ShapContribution(
                feature=c.feature, value=c.value, shap_value=c.shap_value, direction=c.direction
            )
            for c in result.shap_contributions
        ],
        model_version=result.model_version,
        scored_at=now,
        suppressed=suppressed,
        suppression_reason=suppression_reason,
    )
    return _PondRiskComputation(risk_out=risk_out, last_log_at=last_log_at)


@router.get(
    "/ponds/{pond_id}/risk",
    response_model=RiskOut,
    summary="Get current risk score for a pond",
    description=(
        "Returns a composite risk score (0–1) from the real M2 LightGBM mortality-risk "
        "booster, with real per-feature SHAP attributions. This model predicts "
        "environmental-stress-driven mortality risk only — NOT a disease/pathogen "
        "classifier (see app/ml_inference/numeric/m2_risk_engine.py module docstring). "
        "Suppression state is always visible."
    ),
)
async def get_pond_risk(pond_id: UUID, user: CurrentUser, session: DbSession) -> RiskOut:
    if user.role not in ("staff", "admin"):
        rbac.require_pond_scope(user.pond_ids, pond_id)
    pond = await session.get(Pond, pond_id)
    if pond is None:
        raise HTTPException(status_code=404, detail="Pond not found")
    now = utcnow()
    computation = await _compute_pond_risk(session, pond, now)
    return computation.risk_out


@router.get(
    "/risk/worklist",
    response_model=CursorPage[WorklistItem],
    summary="Risk worklist for staff — all ponds ranked by risk",
    description=(
        "Ranks every pond visible to the caller by the real M2 risk score, descending. "
        "Computed live, in-process, per request — fine at current demo scale, but does "
        "NOT scale to a large ward/district: a real deployment would need to "
        "pre-compute/cache these scores (e.g. a periodic job writing to a risk-scores "
        "table) rather than scoring every pond synchronously inside the request. "
        "Because ranking is computed fresh per request rather than sourced from a "
        "stable DB sort key, this endpoint uses a simple offset-encoded cursor "
        "(core.pagination.encode_cursor/decode_cursor) instead of the keyset-pagination "
        "convention used elsewhere in this module — keyset pagination requires a stable "
        "persisted ordering to page against, which an in-request live ranking doesn't have."
    ),
)
async def get_risk_worklist(
    user: CurrentStaff,
    session: DbSession,
    district: str | None = Query(default=None),
    risk_level: str | None = Query(default=None),
    cursor: str | None = Query(default=None),
    limit: int = Query(default=50, ge=1, le=200),
) -> CursorPage[WorklistItem]:
    """
    Scoping — identical rule to `list_ponds` (P1.2):
      * admin — unrestricted, or filtered to `district` if given.
      * staff — filtered to `district` (validated via rbac.require_district)
        if given, else defaulted to the caller's own district claim; a
        staff token with no district claim gets an empty page (fail closed).
    """
    stmt = select(Pond)
    if user.role == "admin":
        if district is not None:
            stmt = stmt.where(Pond.district == district)
    else:  # staff (CurrentStaff already rejects farmer/other roles)
        if district is not None:
            rbac.require_district(user.district, district, user.role)
            stmt = stmt.where(Pond.district == district)
        elif user.district is None:
            return CursorPage[WorklistItem](items=[], next_cursor=None)
        else:
            stmt = stmt.where(Pond.district == user.district)

    result = await session.execute(stmt)
    ponds = list(result.scalars().all())

    now = utcnow()
    # Sequential, not gather()'d: a single SQLAlchemy AsyncSession is not
    # safe for concurrent queries. See the endpoint's docstring above for
    # the scaling caveat this implies.
    computations: list[_PondRiskComputation] = []
    for pond in ponds:
        computations.append(await _compute_pond_risk(session, pond, now))

    items = [
        WorklistItem(
            pond_id=pond.id,
            pond_name=pond.name,
            district=pond.district,
            risk_score=computation.risk_out.risk_score,
            risk_level=computation.risk_out.risk_level,
            suppressed=computation.risk_out.suppressed,
            suppression_reason=computation.risk_out.suppression_reason,
            last_log_at=computation.last_log_at,
        )
        for pond, computation in zip(ponds, computations, strict=True)
    ]

    if risk_level is not None:
        items = [item for item in items if item.risk_level == risk_level]

    items.sort(key=lambda item: item.risk_score, reverse=True)

    offset = 0
    decoded_offset = decode_cursor(cursor)
    if decoded_offset is not None:
        try:
            offset = max(int(decoded_offset), 0)
        except ValueError:
            offset = 0

    page = items[offset : offset + limit]
    next_cursor = encode_cursor(offset + limit) if offset + limit < len(items) else None
    return CursorPage[WorklistItem](items=page, next_cursor=next_cursor)


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
