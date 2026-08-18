"""Integration tests — health check and basic endpoint smoke tests."""

from __future__ import annotations

import os
from typing import TYPE_CHECKING

import pytest

if TYPE_CHECKING:
    from httpx import AsyncClient

# Ensure env vars before app import
os.environ.setdefault("DATABASE_URL", "postgresql+asyncpg://x:x@localhost/x")
os.environ.setdefault("APP_SECRET_KEY", "test_secret_key_minimum_32_chars_here")
os.environ.setdefault("INTERNAL_API_TOKEN", "test_internal_token_minimum_32_chars")


@pytest.mark.integration
@pytest.mark.asyncio
async def test_health_check(client: AsyncClient) -> None:
    response = await client.get("/v1/health")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "ok"
    assert "version" in data


@pytest.mark.integration
@pytest.mark.asyncio
async def test_openapi_json_reachable(client: AsyncClient) -> None:
    response = await client.get("/openapi.json")
    assert response.status_code == 200
    data = response.json()
    assert "paths" in data
    assert "info" in data


@pytest.mark.integration
@pytest.mark.asyncio(loop_scope="session")
async def test_all_stub_endpoints_return_non_500(db_client: AsyncClient) -> None:
    """Smoke test every GET stub endpoint — none should 500.

    Uses `db_client` (real lifespan, real testcontainers Postgres) rather
    than `client`. `GET /v1/logs` is DB-backed since P0.2 — `client`'s
    ASGITransport never runs lifespan, so `init_db()` never fires and the
    `session: DbSession` dependency raises a bare `RuntimeError` before
    auth even resolves, 500ing unconditionally regardless of the stub
    token below. See `db_client`'s docstring in conftest.py.
    """
    from uuid import uuid4

    pond_id = str(uuid4())
    bearer = "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.stub"
    headers = {"Authorization": bearer}

    endpoints = [
        "/v1/ponds",
        f"/v1/ponds/{pond_id}",
        f"/v1/ponds/{pond_id}/timeseries",
        f"/v1/ponds/{pond_id}/events",
        "/v1/logs",
        f"/v1/ponds/{pond_id}/risk",
        "/v1/risk/worklist",
        f"/v1/ponds/{pond_id}/forecast/do",
        "/v1/geo/ponds",
        "/v1/geo/clusters",
        f"/v1/twin/{pond_id}/state",
        "/v1/alerts",
        "/v1/advisories",
        "/v1/models",
        "/v1/models/metrics",
        "/v1/models/drift",
        "/v1/data-quality",
        "/v1/reports/export",
    ]

    for path in endpoints:
        response = await db_client.get(path, headers=headers)
        assert response.status_code < 500, (
            f"GET {path} returned {response.status_code}: {response.text}"
        )
