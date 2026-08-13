"""Model registry ORM model — tracks deployed ML artifact versions."""

from __future__ import annotations

from typing import TYPE_CHECKING, Any

from sqlalchemy import Boolean, DateTime, String, Text
from sqlalchemy.dialects.postgresql import JSONB, UUID
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base, TimestampMixin, UUIDPrimaryKeyMixin

if TYPE_CHECKING:
    import uuid
    from datetime import datetime


class ModelRegistry(Base, UUIDPrimaryKeyMixin, TimestampMixin):
    """
    Registry entry for a deployed ML model artifact.

    Every training run must log:
    - dataset_hash: SHA-256 of the training dataset (immutable, reproducible)
    - adapter_version: LoRA adapter version (for LLM models)
    - mlflow_run_id: link back to the MLflow experiment run
    - metrics: dict of training/eval metrics
    """

    __tablename__ = "model_registry"

    name: Mapped[str] = mapped_column(String(200), nullable=False, index=True)
    model_type: Mapped[str] = mapped_column(
        String(50), nullable=False
    )  # lightgbm | ebm | tcn | tft | patchtst | lora_adapter
    version: Mapped[str] = mapped_column(String(100), nullable=False)
    artifact_path: Mapped[str] = mapped_column(String(1000), nullable=False)
    dataset_hash: Mapped[str] = mapped_column(String(64), nullable=False)  # SHA-256 hex
    adapter_version: Mapped[str | None] = mapped_column(String(100))  # LoRA only
    mlflow_run_id: Mapped[str | None] = mapped_column(String(200))
    metrics: Mapped[dict[str, Any] | None] = mapped_column(JSONB)
    hyperparameters: Mapped[dict[str, Any] | None] = mapped_column(JSONB)
    is_active: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False, index=True)
    promoted_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    promoted_by: Mapped[uuid.UUID | None] = mapped_column(UUID(as_uuid=True))
    notes: Mapped[str | None] = mapped_column(Text)
