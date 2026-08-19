"""User ORM model — farmer, staff, and admin accounts."""

from __future__ import annotations

from sqlalchemy import Boolean, String
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base, TimestampMixin, UUIDPrimaryKeyMixin


class User(Base, UUIDPrimaryKeyMixin, TimestampMixin):
    """
    Application user — three roles share this table.

    - farmer:   phone login via OTP (no password)
    - staff:    phone login via OTP; may also have username+password
    - admin:    username+password only; NOT accessible via OTP flow
    """

    __tablename__ = "users"

    # Identity columns — at least one must be set
    phone: Mapped[str | None] = mapped_column(String(20), unique=True, nullable=True, index=True)
    username: Mapped[str | None] = mapped_column(
        String(100), unique=True, nullable=True, index=True
    )

    # Password hash — bcrypt; NULL for farmer-only accounts
    password_hash: Mapped[str | None] = mapped_column(String(255), nullable=True)

    # Role — controls what endpoints are accessible
    role: Mapped[str] = mapped_column(String(50), nullable=False, default="farmer")

    # Profile
    name: Mapped[str] = mapped_column(String(200), nullable=False)
    district: Mapped[str | None] = mapped_column(String(100), nullable=True, index=True)

    # Soft-disable without deleting
    is_active: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)
