"""ML Inference — routers for ponds, risk, forecast, models, data-quality."""

from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime, timedelta
from uuid import UUID

from fastapi import APIRouter, HTTPException, Query, UploadFile, File
from sqlalchemy import and_, case, func, or_, select

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
from app.db.models.model_registry import ModelRegistry
from app.db.models.pond import Pond
from app.db.models.model_registry import ModelRegistry
from app.deps import CurrentStaff, CurrentUser, DbSession
from app.ml_inference.drift import compute_drift_report
from app.ml_inference.model_registry_sync import ensure_active_model_registered
from app.ml_inference.numeric import do_forecast, m2_risk_engine
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
from PIL import Image
import io

router = APIRouter(tags=["Ponds & ML"])


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
        "Returns a dissolved oxygen forecast (default 24h, up to 168h) with 10th/50th/90th "
        "percentile bands computed from this pond's own real historical DO readings, bucketed "
        "by hour-of-day. This is an honest empirical seasonal-naive baseline, NOT a trained "
        "temporal model — no TCN/TFT/PatchTST exists anywhere in this repo (see "
        "app/ml_inference/numeric/do_forecast.py module docstring). "
        "RULE: Bare point estimates are forbidden — bands are always returned."
    ),
)
async def get_do_forecast(
    pond_id: UUID,
    user: CurrentUser,
    session: DbSession,
    horizon_hours: int = Query(default=24, ge=1, le=168),
) -> ForecastOut:
    if user.role not in ("staff", "admin"):
        rbac.require_pond_scope(user.pond_ids, pond_id)
    pond = await session.get(Pond, pond_id)
    if pond is None:
        raise HTTPException(status_code=404, detail="Pond not found")

    now = utcnow()
    # Reuses the same lookback window and log-fetch helper as risk scoring
    # (_fetch_recent_logs / _RISK_LOOKBACK_DAYS, defined above in the Risk
    # section) rather than inventing a second constant: 30 days of this
    # pond's (typically hourly-seeded) logs already gives ~30+ samples per
    # hour-of-day bucket, comfortably clearing do_forecast.MIN_BUCKET_SAMPLES,
    # and keeps one "how far back do we look at this pond's history" answer
    # per codebase instead of two.
    logs = await _fetch_recent_logs(session, pond_id, now - timedelta(days=_RISK_LOOKBACK_DAYS))
    species_key = m2_risk_engine.resolve_species_key(pond.species)
    forecast = do_forecast.build_do_forecast(
        historical_readings=[
            (log.recorded_at, log.dissolved_oxygen_mgl)
            for log in logs
            if log.dissolved_oxygen_mgl is not None
        ],
        target_timestamps=[now + timedelta(hours=i) for i in range(1, horizon_hours + 1)],
        species_key=species_key,
    )
    return ForecastOut(
        pond_id=pond_id,
        parameter="dissolved_oxygen_mgl",
        horizon_hours=horizon_hours,
        points=[
            ForecastPoint(
                forecasted_at=forecasted_at,
                p10=band.p10,
                p50=band.p50,
                p90=band.p90,
            )
            for forecasted_at, band in forecast.bands_by_timestamp
        ],
        model_version=forecast.model_version,
        generated_at=now,
        uncertainty_note=forecast.uncertainty_note,
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
    session: DbSession,
    cursor: str | None = Query(default=None),
    limit: int = Query(default=50, ge=1, le=200),
) -> CursorPage[ModelOut]:
    """Real keyset pagination over `model_registry`, same shape as
    `list_ponds`. `ensure_active_model_registered` keeps that table
    synced to whatever M2 bundle is actually loaded before every read —
    see app/ml_inference/model_registry_sync.py for why this can't just
    be a one-time seed."""
    await ensure_active_model_registered(session)
    effective_limit = clamp_limit(limit)
    stmt = select(ModelRegistry)

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
                    ModelRegistry.created_at < last_created_at,
                    and_(ModelRegistry.created_at == last_created_at, ModelRegistry.id < last_id),
                )
            )

    stmt = stmt.order_by(ModelRegistry.created_at.desc(), ModelRegistry.id.desc())
    stmt = stmt.limit(effective_limit + 1)

    result = await session.execute(stmt)
    rows = list(result.scalars().all())
    has_next = len(rows) > effective_limit
    rows = rows[:effective_limit]

    next_cursor: str | None = None
    if has_next and rows:
        last_row = rows[-1]
        next_cursor = encode_keyset_cursor(last_row.created_at.isoformat(), last_row.id)

    items = [ModelOut.model_validate(row, from_attributes=True) for row in rows]
    return CursorPage[ModelOut](items=items, next_cursor=next_cursor)


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
    from app.core.metrics import snapshot

    now = utcnow()
    live = snapshot()
    return ModelMetricsOut(
        rejected_attempts=get_rejected_attempts(),
        total_requests=int(live["total_requests"]),
        avg_latency_ms=round(live["avg_latency_ms"], 2),
        p95_latency_ms=round(live["p95_latency_ms"], 2),
        p99_latency_ms=round(live["p99_latency_ms"], 2),
        # No response cache exists anywhere in the model-serving layer
        # (the Redis cache app/i18n/cache.py has is for translations, a
        # different domain) — honestly 0.0 rather than a placeholder
        # standing in for a cache that isn't there.
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
    session: DbSession,
    cursor: str | None = Query(default=None),
    limit: int = Query(default=20, ge=1, le=100),
) -> CursorPage[DriftReport]:
    """Real PSI-based drift signal for the one actively-served model — see
    app/ml_inference/drift.py for what this does and doesn't measure.
    `cursor`/`limit` are accepted for response-shape compatibility; there
    is exactly one active model to report on, so this never actually
    paginates."""
    active_model = await ensure_active_model_registered(session)
    report = await compute_drift_report(
        session, model_name=active_model.name, model_version=active_model.version
    )
    return CursorPage[DriftReport](items=[report], next_cursor=None)


# ---------------------------------------------------------------------------
# Data quality
# ---------------------------------------------------------------------------
# Core water-quality parameters tracked for completeness — the same
# fields Alerts' threshold evaluation (app/alerts/rules.py) and the M2
# risk engine actually consume, not an arbitrary pick.
_CORE_PARAMETERS = (
    "temperature_c",
    "dissolved_oxygen_mgl",
    "ph",
    "salinity_ppt",
    "ammonia_nh3_mgl",
)


async def _scoped_pond_ids_for_data_quality(
    user: CurrentUser, session: DbSession, pond_id: UUID | None
) -> list[UUID] | None:
    """Returns the real pond ids in scope, or None to mean "no ponds in
    scope" (fail closed for a staff token with no district claim), never
    an unscoped global query a caller didn't ask for."""
    if pond_id is not None:
        exists = (
            await session.execute(select(Pond.id).where(Pond.id == pond_id))
        ).scalar_one_or_none()
        if exists is None:
            raise HTTPException(status_code=404, detail="Pond not found")
        return [pond_id]

    stmt = select(Pond.id)
    if user.role == "staff":
        if user.district is None:
            return None
        stmt = stmt.where(Pond.district == user.district)
    # admin: unrestricted
    return list((await session.execute(stmt)).scalars().all())


@router.get(
    "/data-quality",
    response_model=DataQualityOut,
    tags=["Data Quality"],
    summary="Data quality signals across all ponds",
)
async def get_data_quality(
    user: CurrentStaff,
    session: DbSession,
    pond_id: UUID | None = Query(default=None),
) -> DataQualityOut:
    """Real signals over real `Log` rows from the last 7 days, scoped the
    same way GET /v1/ponds is: a specific `pond_id` if given, else a
    staff caller's own district (fail closed if their token has none),
    else — for admin — every pond.

    `sensor_offline_ponds` reuses `_STALE_LOG_THRESHOLD_HOURS`, the exact
    threshold Alerts' blind-state suppression already uses (see that
    constant's docstring) — one "how old is too old" answer per
    codebase, not a second invented number.
    """
    now = utcnow()
    scoped_pond_ids = await _scoped_pond_ids_for_data_quality(user, session, pond_id)

    if not scoped_pond_ids:
        return DataQualityOut(
            pond_id=pond_id,
            total_logs_last_7d=0,
            missing_parameter_rates=dict.fromkeys(_CORE_PARAMETERS, 0.0),
            sensor_offline_ponds=0,
            stale_threshold_hours=_STALE_LOG_THRESHOLD_HOURS,
            evaluated_at=now,
        )

    window_start = now - timedelta(days=7)
    missing_sums = [
        func.sum(case((getattr(Log, param).is_(None), 1), else_=0)).label(f"missing_{param}")
        for param in _CORE_PARAMETERS
    ]
    agg_row = (
        await session.execute(
            select(func.count().label("total"), *missing_sums).where(
                Log.pond_id.in_(scoped_pond_ids), Log.recorded_at >= window_start
            )
        )
    ).one()

    total_logs = agg_row.total or 0
    missing_rates = {
        param: round((getattr(agg_row, f"missing_{param}") or 0) / total_logs, 4)
        if total_logs
        else 0.0
        for param in _CORE_PARAMETERS
    }

    latest_rows = await session.execute(
        select(Log.pond_id, func.max(Log.recorded_at))
        .where(Log.pond_id.in_(scoped_pond_ids))
        .group_by(Log.pond_id)
    )
    latest_by_pond: dict[UUID, datetime | None] = {row[0]: row[1] for row in latest_rows}
    stale_cutoff = now - timedelta(hours=_STALE_LOG_THRESHOLD_HOURS)
    sensor_offline_ponds = 0
    for pid in scoped_pond_ids:
        last_at = latest_by_pond.get(pid)
        if last_at is None or last_at < stale_cutoff:
            sensor_offline_ponds += 1

    return DataQualityOut(
        pond_id=pond_id,
        total_logs_last_7d=total_logs,
        missing_parameter_rates=missing_rates,
        sensor_offline_ponds=sensor_offline_ponds,
        stale_threshold_hours=_STALE_LOG_THRESHOLD_HOURS,
        evaluated_at=now,
    )

# ---------------------------------------------------------------------------
# Multimodal M2
# ---------------------------------------------------------------------------
@router.post(
    "/ponds/{pond_id}/multimodal_risk",
    summary="Compute multimodal risk score using PyTorch Fusion (M2)",
    description="Fuses Tabular Sensor Data with Image Concept Bottleneck outputs.",
)
async def compute_multimodal_risk(
    pond_id: UUID,
    user: CurrentUser,
    session: DbSession,
    image: UploadFile | None = File(default=None),
    image_age_hours: float = Query(default=0.0)
):
    if user.role not in ("staff", "admin"):
        rbac.require_pond_scope(user.pond_ids, pond_id)
    pond = await session.get(Pond, pond_id)
    if pond is None:
        raise HTTPException(status_code=404, detail="Pond not found")

    now = utcnow()
    since = now - timedelta(days=_RISK_LOOKBACK_DAYS)
    logs = await _fetch_recent_logs(session, pond.id, since)
    crop = await _fetch_active_crop(session, pond.id)

    doc_value = max((now.date() - crop.stocking_date).days, 0) if crop else None
    stocking_count = crop.post_larvae_count if crop else None

    pil_image = None
    if image is not None:
        contents = await image.read()
        pil_image = Image.open(io.BytesIO(contents))

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

    from app.ml_inference.multimodal_m2_engine import score_multimodal
    
    result = score_multimodal(
        points=points,
        doc_value=doc_value,
        stocking_count=stocking_count,
        now=now,
        image=pil_image,
        image_age_hours=image_age_hours
    )

    return result

