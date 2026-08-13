"""Crop (aquaculture cycle) ORM model — stub for Phase 1."""

from __future__ import annotations

import uuid
from datetime import date
from typing import TYPE_CHECKING

from sqlalchemy import Date, Float, ForeignKey, Integer, String
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base, TimestampMixin, UUIDPrimaryKeyMixin

if TYPE_CHECKING:
    from app.db.models.pond import Pond


class Crop(Base, UUIDPrimaryKeyMixin, TimestampMixin):
    """
    An aquaculture production cycle (crop) in a pond.
    One pond can have many crops over time; only one can be active.
    """

    __tablename__ = "crops"

    pond_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("ponds.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    species: Mapped[str] = mapped_column(String(100), nullable=False)
    stocking_date: Mapped[date] = mapped_column(Date, nullable=False)
    stocking_density_per_sqm: Mapped[float | None] = mapped_column(Float)
    post_larvae_count: Mapped[int | None] = mapped_column(Integer)
    target_harvest_date: Mapped[date | None] = mapped_column(Date)
    actual_harvest_date: Mapped[date | None] = mapped_column(Date)
    status: Mapped[str] = mapped_column(
        String(20), nullable=False, default="active"
    )  # active | harvested | failed
    feed_brand: Mapped[str | None] = mapped_column(String(200))
    notes: Mapped[str | None] = mapped_column(String(1000))

    # Relationships
    pond: Mapped[Pond] = relationship("Pond", back_populates="crops")
