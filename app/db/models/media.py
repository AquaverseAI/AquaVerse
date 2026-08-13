"""Media ORM model — stub for Phase 1."""

from __future__ import annotations

import uuid
from typing import TYPE_CHECKING

from sqlalchemy import BigInteger, ForeignKey, String
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base, TimestampMixin, UUIDPrimaryKeyMixin

if TYPE_CHECKING:
    from app.db.models.pond import Pond


class Media(Base, UUIDPrimaryKeyMixin, TimestampMixin):
    """
    Uploaded media file (image, video, document) associated with a pond or log.

    Upload flow:
    1. Client calls POST /v1/media/upload-url → receives presigned S3 URL + media_id
    2. Client uploads directly to S3
    3. Client calls POST /v1/media/{media_id}/commit → status set to 'committed'
    """

    __tablename__ = "media"

    pond_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("ponds.id", ondelete="SET NULL"),
        nullable=True,
        index=True,
    )
    log_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True),
        nullable=True,
        index=True,
    )
    uploaded_by: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), nullable=False)

    filename: Mapped[str] = mapped_column(String(500), nullable=False)
    mime_type: Mapped[str] = mapped_column(String(100), nullable=False)
    size_bytes: Mapped[int | None] = mapped_column(BigInteger)
    s3_key: Mapped[str] = mapped_column(String(1000), nullable=False)
    status: Mapped[str] = mapped_column(
        String(20), nullable=False, default="pending"
    )  # pending | committed | failed
    client_log_id: Mapped[str | None] = mapped_column(
        String(200), nullable=True, unique=True, index=True
    )

    # Relationships
    pond: Mapped[Pond | None] = relationship("Pond")
