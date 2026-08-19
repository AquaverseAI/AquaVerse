"""Ingest — routers for /v1/logs, /v1/media, and /v1/ingest/sensor."""

from __future__ import annotations

import hmac
from datetime import datetime
from uuid import UUID, uuid4

from fastapi import APIRouter, Header, HTTPException, Query, Response, status
from sqlalchemy import and_, or_, select

from app.config import get_settings
from app.core import rbac
from app.core.pagination import CursorPage, clamp_limit, decode_keyset_cursor, encode_keyset_cursor
from app.core.timezones import utcnow
from app.db.models.crop import Crop
from app.db.models.log import Log
from app.db.models.pond import Pond
from app.deps import CurrentUser, DbSession
from app.ingest.schemas import (
    LogIn,
    LogOut,
    MediaCommitIn,
    MediaOut,
    MediaUploadUrlIn,
    MediaUploadUrlOut,
    SensorIngestIn,
    SensorIngestOut,
)

router = APIRouter(tags=["Ingest"])

# Sentinel `recorded_by` for logs written by an unattended sensor device —
# there's no human user account to attribute these to. `Log.recorded_by` is
# a plain UUID column with no FK constraint (see app/db/models/log.py), so
# this is safe to use without a matching `users` row.
_SENSOR_DEVICE_USER_ID = UUID("00000000-0000-0000-0000-0000000000fe")


# ---------------------------------------------------------------------------
# Logs
# ---------------------------------------------------------------------------
@router.post(
    "/logs",
    response_model=LogOut,
    status_code=status.HTTP_201_CREATED,
    summary="Submit a water quality log entry",
    description=(
        "Submit a water quality measurement for a pond. "
        "Accepts a `client_log_id` for idempotency — replays return `200` with the original record."
    ),
)
async def create_log(body: LogIn, session: DbSession, user: CurrentUser, response: Response) -> LogOut:
    """Phase 2: persist to DB, trigger async risk re-score."""
    # Check idempotency
    if body.client_log_id:
        stmt = select(Log).where(Log.client_log_id == body.client_log_id).limit(1)
        existing = (await session.execute(stmt)).scalar_one_or_none()
        if existing:
            response.status_code = status.HTTP_200_OK
            return LogOut.model_validate(existing, from_attributes=True)

    # Find active crop for this pond
    crop_stmt = select(Crop.id).where(
        Crop.pond_id == body.pond_id,
        Crop.status == "active"
    ).limit(1)
    active_crop_id = (await session.execute(crop_stmt)).scalar_one_or_none()

    log_entry = Log(
        pond_id=body.pond_id,
        crop_id=active_crop_id,
        recorded_at=body.recorded_at,
        recorded_by=UUID(user.sub),
        temperature_c=body.temperature_c,
        dissolved_oxygen_mgl=body.dissolved_oxygen_mgl,
        ph=body.ph,
        salinity_ppt=body.salinity_ppt,
        ammonia_nh3_mgl=body.ammonia_nh3_mgl,
        turbidity_ntu=body.turbidity_ntu,
        nitrite_mgl=body.nitrite_mgl,
        nitrate_mgl=body.nitrate_mgl,
        alkalinity_mgl=body.alkalinity_mgl,
        hardness_mgl=body.hardness_mgl,
        notes=body.notes,
        source="manual", # TODO: Phase 2 IoT should set to 'sensor' based on token?
        client_log_id=body.client_log_id,
    )
    session.add(log_entry)
    await session.commit()
    await session.refresh(log_entry)

    return LogOut.model_validate(log_entry, from_attributes=True)


@router.get(
    "/logs",
    response_model=CursorPage[LogOut],
    summary="List water quality logs",
    description=(
        "Keyset-paginated on `(recorded_at, id)` DESC. Pass the previous page's "
        "`next_cursor` back as `cursor` to fetch the next page; a `null` "
        "`next_cursor` means there is no further page."
    ),
)
async def list_logs(
    session: DbSession,
    user: CurrentUser,
    pond_id: UUID | None = Query(default=None),
    cursor: str | None = Query(default=None),
    limit: int | None = Query(default=None),
) -> CursorPage[LogOut]:
    """Real keyset pagination — sorted by recorded_at DESC, id DESC."""
    if pond_id is not None and user.role not in ("staff", "admin"):
        rbac.require_pond_scope(user.pond_ids, pond_id)

    effective_limit = clamp_limit(limit)

    stmt = select(Log)
    if pond_id:
        stmt = stmt.where(Log.pond_id == pond_id)

    decoded = decode_keyset_cursor(cursor)
    if decoded is not None:
        last_recorded_at_raw, last_id_raw = decoded
        try:
            last_recorded_at = datetime.fromisoformat(last_recorded_at_raw)
            last_id = UUID(last_id_raw)
        except ValueError:
            # Malformed/tampered cursor — fail open to the first page rather
            # than 500, matching decode_cursor's existing tolerant behaviour.
            last_recorded_at = None
            last_id = None

        if last_recorded_at is not None and last_id is not None:
            stmt = stmt.where(
                or_(
                    Log.recorded_at < last_recorded_at,
                    and_(Log.recorded_at == last_recorded_at, Log.id < last_id),
                )
            )

    # Sort by recorded_at DESC, id DESC — id breaks ties for rows sharing a
    # recorded_at timestamp, which is what makes the keyset WHERE above exact.
    stmt = stmt.order_by(Log.recorded_at.desc(), Log.id.desc())

    # Fetch one extra row to detect whether a next page exists, without a
    # separate COUNT query.
    stmt = stmt.limit(effective_limit + 1)

    result = await session.execute(stmt)
    logs = list(result.scalars().all())

    has_next = len(logs) > effective_limit
    logs = logs[:effective_limit]

    next_cursor: str | None = None
    if has_next and logs:
        last_row = logs[-1]
        next_cursor = encode_keyset_cursor(last_row.recorded_at.isoformat(), last_row.id)

    items = [LogOut.model_validate(log, from_attributes=True) for log in logs]
    return CursorPage[LogOut](items=items, next_cursor=next_cursor)


# ---------------------------------------------------------------------------
# Media
# ---------------------------------------------------------------------------
@router.post(
    "/media/upload-url",
    response_model=MediaUploadUrlOut,
    status_code=status.HTTP_201_CREATED,
    summary="Request a presigned upload URL",
    description=(
        "Returns a presigned S3/R2 PUT URL. The client uploads directly to object storage, "
        "then calls POST /v1/media/{media_id}/commit to finalise."
    ),
)
async def media_upload_url(body: MediaUploadUrlIn, user: CurrentUser) -> MediaUploadUrlOut:
    """Phase 1: return fixture URL. Phase 3: generate real presigned S3 URL."""
    if user.role not in ("staff", "admin"):
        rbac.require_pond_scope(user.pond_ids, body.pond_id)
    media_id = uuid4()
    expires_at = utcnow().replace(minute=utcnow().minute + 15)
    return MediaUploadUrlOut(
        media_id=media_id,
        upload_url=f"https://storage.aquaverse.example.com/media/{media_id}?X-Amz-Signature=stub",
        expires_at=expires_at,
    )


@router.post(
    "/media/{media_id}/commit",
    response_model=MediaOut,
    status_code=status.HTTP_200_OK,
    summary="Commit an uploaded media file",
    description="Mark an upload as committed after the client has PUT the file to the presigned URL.",
)
async def media_commit(
    media_id: UUID,
    body: MediaCommitIn,
    user: CurrentUser,
) -> MediaOut:
    """Phase 1: return fixture. Phase 3: verify S3 object exists, update DB status."""
    if user.role not in ("staff", "admin"):
        rbac.require_pond_scope(user.pond_ids, body.pond_id)
    now = utcnow()
    return MediaOut(
        media_id=media_id,
        pond_id=body.pond_id,
        filename="sample.jpg",
        mime_type="image/jpeg",
        status="committed",
        created_at=now,
    )


# ---------------------------------------------------------------------------
# Sensor ingest (IoT device webhook)
# ---------------------------------------------------------------------------
def _check_device_key(x_device_key: str | None) -> None:
    """Validate the optional per-deployment shared secret.

    `settings.iot_device_key` empty (the default) disables this check
    entirely — see app/config.py. Once set, the header is required and
    compared in constant time.
    """
    settings = get_settings()
    if not settings.iot_device_key:
        return
    if not x_device_key or not hmac.compare_digest(x_device_key, settings.iot_device_key):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Missing or invalid X-Device-Key.",
        )


@router.post(
    "/ingest/sensor/{pond_id}",
    response_model=SensorIngestOut,
    status_code=status.HTTP_201_CREATED,
    summary="Push a reading from a pond's IoT sensor unit",
    description=(
        "Webhook for pond-side sensor hardware — accepts the device's raw JSON shape "
        "(`ph`, `air_temperature`, `humidity`, `water_temperature`, `turbidity`) directly, "
        "no farmer/staff login required. Persisted as a `Log` row with `source=\"sensor\"`, "
        "timestamped at server receipt time, and immediately visible via "
        "GET /v1/logs and GET /v1/ponds/{pond_id}/timeseries. "
        "Optionally gated by a shared `X-Device-Key` header — see app/config.py."
    ),
)
async def ingest_sensor_reading(
    pond_id: UUID,
    body: SensorIngestIn,
    session: DbSession,
    x_device_key: str | None = Header(default=None),
) -> SensorIngestOut:
    _check_device_key(x_device_key)

    pond_exists = (await session.execute(select(Pond.id).where(Pond.id == pond_id))).scalar_one_or_none()
    if pond_exists is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Pond not found")

    crop_stmt = select(Crop.id).where(Crop.pond_id == pond_id, Crop.status == "active").limit(1)
    active_crop_id = (await session.execute(crop_stmt)).scalar_one_or_none()

    log_entry = Log(
        pond_id=pond_id,
        crop_id=active_crop_id,
        recorded_at=utcnow(),
        recorded_by=_SENSOR_DEVICE_USER_ID,
        temperature_c=body.water_temperature,
        ph=body.ph,
        turbidity_ntu=body.turbidity,
        air_temperature_c=body.air_temperature,
        humidity_pct=body.humidity,
        source="sensor",
    )
    session.add(log_entry)
    await session.commit()
    await session.refresh(log_entry)

    return SensorIngestOut(
        id=log_entry.id,
        pond_id=log_entry.pond_id,
        recorded_at=log_entry.recorded_at,
        ph=log_entry.ph,
        air_temperature_c=log_entry.air_temperature_c,
        humidity_pct=log_entry.humidity_pct,
        water_temperature_c=log_entry.temperature_c,
        turbidity_ntu=log_entry.turbidity_ntu,
        source=log_entry.source,
    )
