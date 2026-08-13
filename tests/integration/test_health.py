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


@pytest.mark.asyncio
async def test_health_check(client: AsyncClient) -> None:
    response = await client.get("/v1/health")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "ok"
    assert "version" in data


@pytest.mark.asyncio
async def test_openapi_json_reachable(client: AsyncClient) -> None:
    response = await client.get("/openapi.json")
    assert response.status_code == 200
    data = response.json()
    assert "paths" in data
    assert "info" in data


@pytest.mark.asyncio
async def test_all_stub_endpoints_return_non_500(client: AsyncClient) -> None:
    """Smoke test every GET stub endpoint — none should 500."""
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
        response = await client.get(path, headers=headers)
        assert response.status_code < 500, (
            f"GET {path} returned {response.status_code}: {response.text}"
        )
