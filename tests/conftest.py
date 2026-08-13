"""
Test configuration — testcontainers for PostgreSQL+TimescaleDB+PostGIS and Redis.

All integration tests use real containers spun up in CI via testcontainers-python.
Unit tests use no containers.
"""

from __future__ import annotations

from typing import TYPE_CHECKING, Any

import pytest
import pytest_asyncio
from httpx import ASGITransport, AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine

if TYPE_CHECKING:
    from collections.abc import AsyncGenerator, Generator


# ---------------------------------------------------------------------------
# Postgres + TimescaleDB + PostGIS container
# ---------------------------------------------------------------------------
@pytest.fixture(scope="session")
def postgres_container() -> Generator[Any, None, None]:
    """Spin up a TimescaleDB container for the test session."""
    pytest.importorskip("testcontainers", reason="testcontainers not installed")

    try:
        import docker

        client = docker.from_env()
        client.ping()
    except Exception as e:
        pytest.skip(f"Docker is not available: {e}")

    from testcontainers.postgres import PostgresContainer

    with PostgresContainer(
        image="timescale/timescaledb-ha:pg16",
        username="test",
        password="test",
        dbname="aquaverse_test",
    ) as pg:
        yield pg


@pytest.fixture(scope="session")
def redis_container() -> Generator[Any, None, None]:
    """Spin up a Redis container for the test session."""
    pytest.importorskip("testcontainers", reason="testcontainers not installed")

    try:
        import docker

        client = docker.from_env()
        client.ping()
    except Exception as e:
        pytest.skip(f"Docker is not available: {e}")

    from testcontainers.redis import RedisContainer

    with RedisContainer(image="redis:7-alpine") as redis:
        yield redis


# ---------------------------------------------------------------------------
# Async DB session for integration tests
# ---------------------------------------------------------------------------
@pytest_asyncio.fixture(scope="session")
async def db_engine(postgres_container: Any) -> AsyncGenerator[Any, None]:
    """Create an async engine pointed at the test container."""
    url = postgres_container.get_connection_url().replace("psycopg2", "asyncpg")
    engine = create_async_engine(url, echo=False)
    # Create all tables
    from app.db.base import Base

    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    yield engine
    await engine.dispose()


@pytest_asyncio.fixture
async def db_session(db_engine: Any) -> AsyncGenerator[AsyncSession, None]:
    """Yield a test DB session that rolls back after each test."""
    session_factory = async_sessionmaker(bind=db_engine, expire_on_commit=False)
    async with session_factory() as session:
        yield session
        await session.rollback()


# ---------------------------------------------------------------------------
# FastAPI test client
# ---------------------------------------------------------------------------
@pytest_asyncio.fixture
async def client() -> AsyncGenerator[AsyncClient, None]:
    """Async HTTPX client pointed at the test app (no real DB needed for unit tests)."""
    import os

    # Minimal env for the app to boot without a real DB
    os.environ.setdefault("DATABASE_URL", "postgresql+asyncpg://x:x@localhost/x")
    os.environ.setdefault("APP_SECRET_KEY", "test_secret_key_minimum_32_chars_here")
    os.environ.setdefault("INTERNAL_API_TOKEN", "test_internal_token_minimum_32_chars")

    from app.main import create_app

    app = create_app()

    async with AsyncClient(
        transport=ASGITransport(app=app),
        base_url="http://test",
    ) as ac:
        yield ac
