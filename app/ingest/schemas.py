"""Ingest — Pydantic v2 schemas for logs and media endpoints."""

from __future__ import annotations

from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, Field


# ---------------------------------------------------------------------------
# Log (water quality measurement)
# ---------------------------------------------------------------------------
class LogIn(BaseModel):
    pond_id: UUID
    recorded_at: datetime = Field(..., description="ISO 8601 with timezone offset")
    client_log_id: str | None = Field(
        default=None,
        description=(
            "Client-generated idempotency key. Replays with the same key return "
            "the original record with HTTP 200 instead of creating a duplicate."
        ),
        max_length=200,
    )
    temperature_c: float | None = Field(default=None, ge=0, le=50)
    dissolved_oxygen_mgl: float | None = Field(default=None, ge=0, le=30)
    ph: float | None = Field(default=None, ge=0, le=14)
    salinity_ppt: float | None = Field(default=None, ge=0, le=60)
    ammonia_nh3_mgl: float | None = Field(default=None, ge=0)
    turbidity_ntu: float | None = Field(default=None, ge=0)
    nitrite_mgl: float | None = Field(default=None, ge=0)
    nitrate_mgl: float | None = Field(default=None, ge=0)
    alkalinity_mgl: float | None = Field(default=None, ge=0)
    hardness_mgl: float | None = Field(default=None, ge=0)
    notes: str | None = Field(default=None, max_length=1000)


class LogOut(BaseModel):
    id: UUID
    pond_id: UUID
    recorded_at: datetime
    temperature_c: float | None = None
    dissolved_oxygen_mgl: float | None = None
    ph: float | None = None
    salinity_ppt: float | None = None
    ammonia_nh3_mgl: float | None = None
    turbidity_ntu: float | None = None
    nitrite_mgl: float | None = None
    nitrate_mgl: float | None = None
    alkalinity_mgl: float | None = None
    hardness_mgl: float | None = None
    air_temperature_c: float | None = None
    humidity_pct: float | None = None
    source: str
    client_log_id: str | None = None
    created_at: datetime


# ---------------------------------------------------------------------------
# Sensor ingest (IoT device webhook — raw pond sensor unit push)
# ---------------------------------------------------------------------------
class SensorIngestIn(BaseModel):
    """Raw payload shape as pushed by the pond sensor unit's firmware.

    Field names intentionally mirror the device's own JSON keys (not the
    `_c` / `_mgl` / `_ntu`-suffixed DB column names used elsewhere in this
    module) — this schema accepts exactly what the hardware already sends,
    no firmware changes required.
    """

    ph: float = Field(..., ge=0, le=14)
    air_temperature: float = Field(..., ge=-10, le=60, description="Ambient air temperature, °C")
    humidity: float = Field(..., ge=0, le=100, description="Relative humidity, %")
    water_temperature: float = Field(..., ge=0, le=45, description="Water temperature, °C")
    turbidity: float = Field(..., ge=0, description="Turbidity, NTU")


class SensorIngestOut(BaseModel):
    id: UUID
    pond_id: UUID
    recorded_at: datetime
    ph: float | None = None
    air_temperature_c: float | None = None
    humidity_pct: float | None = None
    water_temperature_c: float | None = None
    turbidity_ntu: float | None = None
    source: str


# ---------------------------------------------------------------------------
# Media
# ---------------------------------------------------------------------------
class MediaUploadUrlIn(BaseModel):
    pond_id: UUID
    filename: str = Field(..., max_length=500)
    mime_type: str = Field(..., description="e.g. image/jpeg, video/mp4")
    size_bytes: int | None = Field(default=None, ge=1)
    client_log_id: str | None = Field(default=None, max_length=200)


class MediaUploadUrlOut(BaseModel):
    media_id: UUID
    upload_url: str = Field(..., description="Presigned S3/R2 PUT URL, valid for 15 minutes")
    expires_at: datetime


class MediaCommitIn(BaseModel):
    pond_id: UUID
    client_log_id: str | None = Field(default=None, max_length=200)


class MediaOut(BaseModel):
    media_id: UUID
    pond_id: UUID
    filename: str
    mime_type: str
    size_bytes: int | None = None
    status: str  # pending | committed | failed
    created_at: datetime
