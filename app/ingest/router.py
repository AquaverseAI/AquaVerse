"""Ingest — routers for /v1/logs and /v1/media."""

from __future__ import annotations

from uuid import UUID, uuid4

from fastapi import APIRouter, Query, status

from app.core.pagination import CursorPage
from app.core.timezones import utcnow
from app.ingest.schemas import (
    LogIn,
    LogOut,
    MediaCommitIn,
    MediaOut,
    MediaUploadUrlIn,
    MediaUploadUrlOut,
)

router = APIRouter(tags=["Ingest"])


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
async def create_log(body: LogIn) -> LogOut:
    """Phase 1: return fixture. Phase 2: persist to DB, trigger async risk re-score."""
    now = utcnow()
    return LogOut(
        id=uuid4(),
        pond_id=body.pond_id,
        recorded_at=body.recorded_at,
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
        source="manual",
        client_log_id=body.client_log_id,
        created_at=now,
    )


@router.get(
    "/logs",
    response_model=CursorPage[LogOut],
    summary="List water quality logs",
)
async def list_logs(
    pond_id: UUID | None = Query(default=None),
    cursor: str | None = Query(default=None),
    limit: int = Query(default=50, ge=1, le=200),
) -> CursorPage[LogOut]:
    """Phase 1: return empty cursor page fixture."""
    now = utcnow()
    stub = LogOut(
        id=uuid4(),
        pond_id=pond_id or uuid4(),
        recorded_at=now,
        source="manual",
        created_at=now,
    )
    return CursorPage[LogOut](items=[stub], next_cursor=None)


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
async def media_upload_url(body: MediaUploadUrlIn) -> MediaUploadUrlOut:
    """Phase 1: return fixture URL. Phase 3: generate real presigned S3 URL."""
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
) -> MediaOut:
    """Phase 1: return fixture. Phase 3: verify S3 object exists, update DB status."""
    now = utcnow()
    return MediaOut(
        media_id=media_id,
        pond_id=uuid4(),
        filename="sample.jpg",
        mime_type="image/jpeg",
        status="committed",
        created_at=now,
    )
