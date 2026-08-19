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
@pytest_asyncio.fixture(scope="session", loop_scope="session")
async def db_engine(postgres_container: Any) -> AsyncGenerator[Any, None]:
    """Create an async engine pointed at the test container."""
    url = postgres_container.get_connection_url().replace("psycopg2", "asyncpg")
    engine = create_async_engine(url, echo=False)
    # Create all tables. PostGIS must be enabled first — Pond.geom is a
    # Geometry column, and the base timescale/timescaledb-ha image ships the
    # extension but doesn't enable it by default (unlike infra/postgres/init.sql
    # in real deployments), so create_all() would otherwise fail the whole
    # transaction with "type geometry does not exist" for every table.
    from sqlalchemy import text

    from app.db.base import Base

    async with engine.begin() as conn:
        await conn.execute(text("CREATE EXTENSION IF NOT EXISTS postgis"))
        await conn.run_sync(Base.metadata.create_all)
    yield engine
    await engine.dispose()


@pytest_asyncio.fixture(loop_scope="session")
async def db_session(db_engine: Any) -> AsyncGenerator[AsyncSession, None]:
    """Yield a test DB session that rolls back after each test.

    `loop_scope="session"` matches `db_engine`'s — without it, this
    (function-scoped) fixture and the session-scoped engine end up driven
    from two different event loops, and asyncpg raises
    "Future attached to a different loop" the moment a query is awaited.
    Tests consuming this fixture (or `db_client` below) must run with
    `@pytest.mark.asyncio(loop_scope="session")` for the same reason.
    """
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


@pytest_asyncio.fixture(loop_scope="session")
async def db_client(postgres_container: Any, db_engine: Any) -> AsyncGenerator[AsyncClient, None]:
    """HTTPX client whose ASGI app actually runs FastAPI's lifespan against
    the real testcontainers Postgres, so DB-backed routes (e.g. GET
    /v1/logs) can be exercised end-to-end.

    This is deliberately a *separate, additive* fixture rather than a fix to
    `client` above. `client`'s ASGITransport never runs lifespan (see its
    docstring) — `init_db()` never fires, so any DB-backed route raises a
    bare `RuntimeError("Database not initialised")`. That is a known,
    pre-existing gap (it's why `test_all_stub_endpoints_return_non_500` has
    a documented baseline failure), but `tests/integration/test_auth_rbac.py`
    has since written *positive* assertions against that exact RuntimeError
    signature (see its `test_login_endpoints_not_gated_by_auth_header`), to
    prove certain routes reach DB code without being blocked by auth. Making
    `client` run lifespan would flip those from "RuntimeError: Database not
    initialised" to a real asyncpg connection error against a fake DSN,
    breaking already-reviewed P0.1 test coverage for no benefit to this
    endpoint. `db_client` unblocks real DB-backed integration testing (here,
    and for any future route) without touching that.
    """
    import os

    from app.config import get_settings

    db_url = postgres_container.get_connection_url().replace("psycopg2", "asyncpg")
    prev_database_url = os.environ.get("DATABASE_URL")
    os.environ["DATABASE_URL"] = db_url
    os.environ.setdefault("APP_SECRET_KEY", "test_secret_key_minimum_32_chars_here")
    os.environ.setdefault("INTERNAL_API_TOKEN", "test_internal_token_minimum_32_chars")
    get_settings.cache_clear()

    from app.main import create_app

    app = create_app()

    try:
        async with (
            app.router.lifespan_context(app),
            AsyncClient(
                transport=ASGITransport(app=app),
                base_url="http://test",
            ) as ac,
        ):
            yield ac
    finally:
        if prev_database_url is None:
            os.environ.pop("DATABASE_URL", None)
        else:
            os.environ["DATABASE_URL"] = prev_database_url
        get_settings.cache_clear()
