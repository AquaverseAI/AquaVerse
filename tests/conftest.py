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
def minio_container() -> Generator[dict[str, str], None, None]:
    """Spin up a real MinIO container for the test session, expose its
    connection config, and pre-create the test bucket.

    Uses `testcontainers.core.container.DockerContainer` directly (not
    `testcontainers.minio.MinioContainer`) — that module hard-imports the
    `minio` Python client package, which isn't a project dependency; this
    repo already depends on `boto3` (the same client `app/core/s3.py`
    uses), so we drive the container with that instead.
    """
    pytest.importorskip("testcontainers", reason="testcontainers not installed")

    try:
        import docker

        client = docker.from_env()
        client.ping()
    except Exception as e:
        pytest.skip(f"Docker is not available: {e}")

    import boto3
    from testcontainers.core.container import DockerContainer
    from testcontainers.core.waiting_utils import wait_for_logs

    container = (
        DockerContainer("minio/minio:latest")
        .with_env("MINIO_ROOT_USER", "minioadmin")
        .with_env("MINIO_ROOT_PASSWORD", "minioadmin123")
        .with_exposed_ports(9000)
        .with_command("server /data")
    )
    with container:
        wait_for_logs(container, "API:")
        host = container.get_container_host_ip()
        port = container.get_exposed_port(9000)
        config = {
            "endpoint_url": f"http://{host}:{port}",
            "access_key_id": "minioadmin",
            "secret_access_key": "minioadmin123",
            "bucket_name": "aquaverse-media-test",
        }
        s3_client = boto3.client(
            "s3",
            endpoint_url=config["endpoint_url"],
            aws_access_key_id=config["access_key_id"],
            aws_secret_access_key=config["secret_access_key"],
            region_name="us-east-1",
        )
        s3_client.create_bucket(Bucket=config["bucket_name"])
        yield config


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


@pytest_asyncio.fixture
async def i18n_client(redis_container: Any) -> AsyncGenerator[AsyncClient, None]:
    """Async HTTPX client wired up to a real Redis container — for the
    i18n domain (P3.1), where `POST /v1/translate` genuinely reads/writes
    a Redis translation cache. No DB/lifespan needed: the route never
    touches Postgres.

    Deliberately function-scoped (unlike `db_client`/`media_client`): the
    module-level lazy Redis client in `app.i18n.router` is reset to None
    on every use so each test's client is opened against *that test's*
    event loop, avoiding the same "Future attached to a different loop"
    failure `db_session` documents for a session-scoped engine reused
    across function-scoped loops.
    """
    import os

    from app.config import get_settings

    # RedisContainer (unlike PostgresContainer) exposes no
    # get_connection_url() — build the DSN from its host/port ourselves.
    host = redis_container.get_container_host_ip()
    port = redis_container.get_exposed_port(redis_container.port)
    redis_url = f"redis://{host}:{port}/0"
    prev_redis_url = os.environ.get("REDIS_URL")
    os.environ["REDIS_URL"] = redis_url
    os.environ.setdefault("DATABASE_URL", "postgresql+asyncpg://x:x@localhost/x")
    os.environ.setdefault("APP_SECRET_KEY", "test_secret_key_minimum_32_chars_here")
    os.environ.setdefault("INTERNAL_API_TOKEN", "test_internal_token_minimum_32_chars")
    get_settings.cache_clear()

    import app.i18n.router as i18n_router_module

    i18n_router_module._redis_client = None

    from app.main import create_app

    app = create_app()

    try:
        async with AsyncClient(
            transport=ASGITransport(app=app),
            base_url="http://test",
        ) as ac:
            yield ac
    finally:
        i18n_router_module._redis_client = None
        if prev_redis_url is None:
            os.environ.pop("REDIS_URL", None)
        else:
            os.environ["REDIS_URL"] = prev_redis_url
        get_settings.cache_clear()


@pytest_asyncio.fixture(loop_scope="session")
async def media_client(
    postgres_container: Any, db_engine: Any, minio_container: dict[str, str]
) -> AsyncGenerator[AsyncClient, None]:
    """Like `db_client`, additionally pointed at a real MinIO container —
    for the Media domain (P2.5), where `POST /v1/media/{id}/commit`
    genuinely HEADs the object store rather than being a no-op DB read.
    Separate from `db_client` so every other suite doesn't pay the extra
    container-startup cost for a dependency it never touches.
    """
    import os

    from app.config import get_settings

    db_url = postgres_container.get_connection_url().replace("psycopg2", "asyncpg")
    prev_env = {
        k: os.environ.get(k)
        for k in (
            "DATABASE_URL",
            "S3_ENDPOINT_URL",
            "S3_ACCESS_KEY_ID",
            "S3_SECRET_ACCESS_KEY",
            "S3_BUCKET_NAME",
        )
    }
    os.environ["DATABASE_URL"] = db_url
    os.environ["S3_ENDPOINT_URL"] = minio_container["endpoint_url"]
    os.environ["S3_ACCESS_KEY_ID"] = minio_container["access_key_id"]
    os.environ["S3_SECRET_ACCESS_KEY"] = minio_container["secret_access_key"]
    os.environ["S3_BUCKET_NAME"] = minio_container["bucket_name"]
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
        for k, v in prev_env.items():
            if v is None:
                os.environ.pop(k, None)
            else:
                os.environ[k] = v
        get_settings.cache_clear()


@pytest_asyncio.fixture(loop_scope="session")
async def reports_client(
    postgres_container: Any,
    db_engine: Any,
    minio_container: dict[str, str],
    redis_container: Any,
) -> AsyncGenerator[AsyncClient, None]:
    """Like `media_client`, additionally pointed at a real Redis container
    — for the Reporting domain (P3.2), where `GET /v1/reports/export`
    genuinely enqueues an ARQ job (app/reporting/router.py's lazy
    `_arq_pool`) and the resulting file is genuinely uploaded to S3.

    `loop_scope="session"` (matching `db_client`/`media_client`) means
    every test using this fixture runs on the same event loop, so the
    module-level lazy `_arq_pool` singleton — opened once, on that loop —
    stays valid across tests without needing a per-test reset, the same
    reasoning that already applies to `media_client`'s S3 client.
    """
    import os

    from app.config import get_settings

    host = redis_container.get_container_host_ip()
    port = redis_container.get_exposed_port(redis_container.port)
    redis_url = f"redis://{host}:{port}/0"

    db_url = postgres_container.get_connection_url().replace("psycopg2", "asyncpg")
    prev_env = {
        k: os.environ.get(k)
        for k in (
            "DATABASE_URL",
            "REDIS_URL",
            "S3_ENDPOINT_URL",
            "S3_ACCESS_KEY_ID",
            "S3_SECRET_ACCESS_KEY",
            "S3_BUCKET_NAME",
        )
    }
    os.environ["DATABASE_URL"] = db_url
    os.environ["REDIS_URL"] = redis_url
    os.environ["S3_ENDPOINT_URL"] = minio_container["endpoint_url"]
    os.environ["S3_ACCESS_KEY_ID"] = minio_container["access_key_id"]
    os.environ["S3_SECRET_ACCESS_KEY"] = minio_container["secret_access_key"]
    os.environ["S3_BUCKET_NAME"] = minio_container["bucket_name"]
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
        for k, v in prev_env.items():
            if v is None:
                os.environ.pop(k, None)
            else:
                os.environ[k] = v
        get_settings.cache_clear()
