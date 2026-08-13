"""Pond ORM model — stub for Phase 1. Full columns in Phase 2 migration."""

from __future__ import annotations

import uuid
from typing import TYPE_CHECKING

from geoalchemy2 import Geometry
from sqlalchemy import Float, String, Text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base, TimestampMixin, UUIDPrimaryKeyMixin

if TYPE_CHECKING:
    from app.db.models.alert import Alert
    from app.db.models.crop import Crop
    from app.db.models.log import Log


class Pond(Base, UUIDPrimaryKeyMixin, TimestampMixin):
    """
    A physical aquaculture pond belonging to a farmer.

    Geometry stored as PostGIS Point (centroid) or Polygon.
    Full geometry + metadata columns added in Phase 2 migration.
    """

    __tablename__ = "ponds"

    owner_user_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), nullable=False, index=True)
    name: Mapped[str] = mapped_column(String(200), nullable=False)
    district: Mapped[str] = mapped_column(String(100), nullable=False, index=True)
    taluk: Mapped[str | None] = mapped_column(String(100))
    village: Mapped[str | None] = mapped_column(String(200))
    area_hectares: Mapped[float | None] = mapped_column(Float)
    depth_meters: Mapped[float | None] = mapped_column(Float)
    species: Mapped[str | None] = mapped_column(String(100))  # e.g. "Litopenaeus vannamei"
    notes: Mapped[str | None] = mapped_column(Text)

    # PostGIS geometry — EPSG:4326 point or polygon
    geom: Mapped[object | None] = mapped_column(
        Geometry(geometry_type="GEOMETRY", srid=4326),
        nullable=True,
    )

    # Relationships (populated in Phase 2)
    crops: Mapped[list[Crop]] = relationship(
        "Crop", back_populates="pond", cascade="all, delete-orphan"
    )
    logs: Mapped[list[Log]] = relationship(
        "Log", back_populates="pond", cascade="all, delete-orphan"
    )
    alerts: Mapped[list[Alert]] = relationship(
        "Alert", back_populates="pond", cascade="all, delete-orphan"
    )
