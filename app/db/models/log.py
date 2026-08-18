"""Water quality log ORM model — stub for Phase 1.

This table is converted to a TimescaleDB hypertable in Phase 2
(partitioned by recorded_at).
"""

from __future__ import annotations

import uuid
from datetime import datetime
from typing import TYPE_CHECKING

from sqlalchemy import DateTime, Float, ForeignKey, String, Text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base, TimestampMixin

if TYPE_CHECKING:
    from app.db.models.crop import Crop
    from app.db.models.pond import Pond


class Log(Base, TimestampMixin):
    """
    A single water-quality measurement log entry for a pond.

    Key parameters (all nullable to accommodate partial readings):
    - temperature (°C)
    - dissolved_oxygen (mg/L)
    - ph
    - salinity (ppt)
    - ammonia_nh3 (mg/L)
    - turbidity (NTU)

    TimescaleDB hypertable on recorded_at (Phase 2).
    """

    __tablename__ = "logs"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        primary_key=True,
        default=uuid.uuid4,
    )
    pond_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("ponds.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    crop_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("crops.id", ondelete="SET NULL"),
        nullable=True,
    )
    recorded_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), primary_key=True, nullable=False, index=True
    )
    recorded_by: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), nullable=False)

    # Water quality parameters
    temperature_c: Mapped[float | None] = mapped_column(Float)
    dissolved_oxygen_mgl: Mapped[float | None] = mapped_column(Float)
    ph: Mapped[float | None] = mapped_column(Float)
    salinity_ppt: Mapped[float | None] = mapped_column(Float)
    ammonia_nh3_mgl: Mapped[float | None] = mapped_column(Float)
    turbidity_ntu: Mapped[float | None] = mapped_column(Float)
    nitrite_mgl: Mapped[float | None] = mapped_column(Float)
    nitrate_mgl: Mapped[float | None] = mapped_column(Float)
    alkalinity_mgl: Mapped[float | None] = mapped_column(Float)
    hardness_mgl: Mapped[float | None] = mapped_column(Float)
    # Ambient (not water-column) readings — populated by pond-side IoT sensor
    # units via POST /v1/ingest/sensor/{pond_id}. Nullable: manual logs never
    # set these, sensor logs almost always do.
    air_temperature_c: Mapped[float | None] = mapped_column(Float)
    humidity_pct: Mapped[float | None] = mapped_column(Float)

    # Metadata
    source: Mapped[str] = mapped_column(
        String(20), nullable=False, default="manual"
    )  # manual | sensor | import
    client_log_id: Mapped[str | None] = mapped_column(
        String(200), nullable=True, unique=False, index=True
    )
    notes: Mapped[str | None] = mapped_column(Text)

    # Relationships
    pond: Mapped[Pond] = relationship("Pond", back_populates="logs")
    crop: Mapped[Crop | None] = relationship("Crop")
