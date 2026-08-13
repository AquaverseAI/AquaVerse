"""Async SQLAlchemy engine and session factory."""

from __future__ import annotations

import structlog
from sqlalchemy.ext.asyncio import (
    AsyncEngine,
    AsyncSession,
    async_sessionmaker,
    create_async_engine,
)

from app.config import get_settings

log = structlog.get_logger(__name__)

# Module-level engine and session factory (initialised at startup)
_engine: AsyncEngine | None = None
AsyncSessionLocal: async_sessionmaker[AsyncSession] = None  # type: ignore[assignment]


async def init_db() -> None:
    """Create the async engine and session factory. Called at app startup."""
    global _engine, AsyncSessionLocal

    settings = get_settings()

    _engine = create_async_engine(
        settings.database_url,
        pool_size=settings.database_pool_size,
        max_overflow=settings.database_max_overflow,
        echo=settings.database_echo,
        pool_pre_ping=True,  # reconnect on stale connections
        pool_recycle=1800,  # recycle connections every 30 min
    )

    AsyncSessionLocal = async_sessionmaker(
        bind=_engine,
        class_=AsyncSession,
        expire_on_commit=False,
        autoflush=False,
        autocommit=False,
    )

    log.info("db.initialized", url=_redact_url(settings.database_url))


async def close_db() -> None:
    """Dispose the engine pool. Called at app shutdown."""
    global _engine
    if _engine is not None:
        await _engine.dispose()
        log.info("db.closed")
        _engine = None


def get_engine() -> AsyncEngine:
    if _engine is None:
        raise RuntimeError("Database not initialised. Call init_db() first.")
    return _engine


def _redact_url(url: str) -> str:
    """Hide password from log output."""
    from urllib.parse import urlparse, urlunparse

    parsed = urlparse(url)
    redacted = parsed._replace(netloc=f"{parsed.username}:***@{parsed.hostname}:{parsed.port}")
    return urlunparse(redacted)
