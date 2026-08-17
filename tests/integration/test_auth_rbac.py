"""Integration tests — auth/RBAC enforcement (P0.1).

Independently verifies commits b92eea2 / d18b405, which wired the existing
CurrentUser/CurrentStaff dependencies (app/deps.py) and
require_pond_scope/require_district (app/core/rbac.py) into every router
that previously had zero auth.

Notes on scope:
  * Endpoints exercised here are picked to avoid the DbSession dependency
    (GET /v1/logs, and both /v1/auth/* endpoints touch the DB). The
    `client` fixture in conftest.py builds its AsyncClient on top of
    httpx.ASGITransport, which — unlike TestClient — never runs the
    FastAPI lifespan, so app.db.session.init_db() never executes and any
    endpoint touching DbSession raises a bare RuntimeError instead of
    returning a response. This is the exact, pre-existing, documented
    cause of the `test_all_stub_endpoints_return_non_500` baseline
    failure (its one DB-touching endpoint, GET /v1/logs, hits this) and
    is unrelated to auth. The login-flow tests below work around it by
    asserting on that specific RuntimeError rather than a status code —
    see test_login_endpoints_not_gated_by_auth_header.
"""

from __future__ import annotations

import os
from typing import TYPE_CHECKING
from uuid import uuid4

import pytest

if TYPE_CHECKING:
    from httpx import AsyncClient

# Ensure env vars before app import (mirrors test_health.py / conftest.client fixture)
os.environ.setdefault("DATABASE_URL", "postgresql+asyncpg://x:x@localhost/x")
os.environ.setdefault("APP_SECRET_KEY", "test_secret_key_minimum_32_chars_here")
os.environ.setdefault("INTERNAL_API_TOKEN", "test_internal_token_minimum_32_chars")

from app.core.security import create_access_token  # noqa: E402

# ---------------------------------------------------------------------------
# Fixtures / helpers
# ---------------------------------------------------------------------------
FARMER_POND_ID = "11111111-1111-1111-1111-111111111111"
OTHER_POND_ID = "22222222-2222-2222-2222-222222222222"
DISTRICT_A = "Nagapattinam"
DISTRICT_B = "Thanjavur"

# Previously-open, now-protected GET endpoints (per audit / commit message).
PROTECTED_GET_ENDPOINTS = [
    "/v1/ponds",
    "/v1/alerts",
    "/v1/geo/ponds",
]

# The exact malformed bearer used by the pre-existing
# test_all_stub_endpoints_return_non_500 smoke test — reused here to
# cross-check the two tests agree on the expected status code.
SMOKE_TEST_STUB_BEARER = "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.stub"


def _farmer_token(pond_ids: list[str] | None = None, district: str | None = DISTRICT_A) -> str:
    return create_access_token(
        sub=str(uuid4()),
        role="farmer",
        pond_ids=pond_ids if pond_ids is not None else [FARMER_POND_ID],
        district=district,
    )


def _staff_token(district: str | None = DISTRICT_A) -> str:
    return create_access_token(sub=str(uuid4()), role="staff", district=district)


def _admin_token(district: str | None = None) -> str:
    return create_access_token(sub=str(uuid4()), role="admin", district=district)


def _auth(token: str) -> dict[str, str]:
    return {"Authorization": f"Bearer {token}"}


# ---------------------------------------------------------------------------
# 1. No Authorization header -> 401
# ---------------------------------------------------------------------------
@pytest.mark.integration
@pytest.mark.asyncio
@pytest.mark.parametrize("path", PROTECTED_GET_ENDPOINTS)
async def test_missing_auth_header_returns_401(client: AsyncClient, path: str) -> None:
    response = await client.get(path)
    assert response.status_code == 401, (
        f"GET {path} with no Authorization header returned "
        f"{response.status_code}, expected 401: {response.text}"
    )
    assert response.json()["detail"] == "Missing or malformed Bearer token"


# ---------------------------------------------------------------------------
# 2. Garbage / invalid bearer token -> 401, never 500
# ---------------------------------------------------------------------------
@pytest.mark.integration
@pytest.mark.asyncio
@pytest.mark.parametrize("path", PROTECTED_GET_ENDPOINTS)
async def test_garbage_bearer_token_returns_401_not_500(client: AsyncClient, path: str) -> None:
    response = await client.get(path, headers=_auth("this-is-not-a-jwt"))
    assert response.status_code == 401, (
        f"GET {path} with a garbage bearer token returned "
        f"{response.status_code}, expected 401: {response.text}"
    )


@pytest.mark.integration
@pytest.mark.asyncio
@pytest.mark.parametrize(
    "path",
    [*PROTECTED_GET_ENDPOINTS, "/v1/risk/worklist", "/v1/models", "/v1/advisories"],
)
async def test_smoke_test_stub_bearer_matches_401_not_500(client: AsyncClient, path: str) -> None:
    """Cross-check against test_all_stub_endpoints_return_non_500's exact bearer.

    That smoke test sends `Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.stub` and
    only asserts status < 500. This test pins down the *specific* code it
    actually gets (401) so a regression that turns this into e.g. a 500 is
    caught precisely instead of just "still under 500".
    """
    response = await client.get(
        path, headers={"Authorization": SMOKE_TEST_STUB_BEARER}
    )
    assert response.status_code == 401, (
        f"GET {path} with the smoke-test's stub bearer returned "
        f"{response.status_code}, expected 401: {response.text}"
    )


# ---------------------------------------------------------------------------
# 3. Farmer pond-scoping: own pond OK, other pond 403
# ---------------------------------------------------------------------------
@pytest.mark.integration
@pytest.mark.asyncio
async def test_farmer_can_access_own_pond_risk(client: AsyncClient) -> None:
    token = _farmer_token(pond_ids=[FARMER_POND_ID])
    response = await client.get(f"/v1/ponds/{FARMER_POND_ID}/risk", headers=_auth(token))
    assert response.status_code == 200, response.text


@pytest.mark.integration
@pytest.mark.asyncio
async def test_farmer_cannot_access_other_pond_risk(client: AsyncClient) -> None:
    token = _farmer_token(pond_ids=[FARMER_POND_ID])
    response = await client.get(f"/v1/ponds/{OTHER_POND_ID}/risk", headers=_auth(token))
    assert response.status_code == 403, response.text


@pytest.mark.integration
@pytest.mark.asyncio
async def test_farmer_can_commit_media_for_own_pond(client: AsyncClient) -> None:
    token = _farmer_token(pond_ids=[FARMER_POND_ID])
    media_id = str(uuid4())
    response = await client.post(
        f"/v1/media/{media_id}/commit",
        json={"pond_id": FARMER_POND_ID},
        headers=_auth(token),
    )
    assert response.status_code == 200, response.text
    assert response.json()["pond_id"] == FARMER_POND_ID


@pytest.mark.integration
@pytest.mark.asyncio
async def test_farmer_cannot_commit_media_for_other_pond(client: AsyncClient) -> None:
    token = _farmer_token(pond_ids=[FARMER_POND_ID])
    media_id = str(uuid4())
    response = await client.post(
        f"/v1/media/{media_id}/commit",
        json={"pond_id": OTHER_POND_ID},
        headers=_auth(token),
    )
    assert response.status_code == 403, response.text


# ---------------------------------------------------------------------------
# 4. Staff-only endpoints: farmer 403, staff OK
# ---------------------------------------------------------------------------
@pytest.mark.integration
@pytest.mark.asyncio
async def test_farmer_cannot_access_risk_worklist(client: AsyncClient) -> None:
    response = await client.get("/v1/risk/worklist", headers=_auth(_farmer_token()))
    assert response.status_code == 403, response.text


@pytest.mark.integration
@pytest.mark.asyncio
async def test_staff_can_access_risk_worklist(client: AsyncClient) -> None:
    response = await client.get("/v1/risk/worklist", headers=_auth(_staff_token()))
    assert response.status_code == 200, response.text


@pytest.mark.integration
@pytest.mark.asyncio
async def test_farmer_cannot_list_models(client: AsyncClient) -> None:
    response = await client.get("/v1/models", headers=_auth(_farmer_token()))
    assert response.status_code == 403, response.text


@pytest.mark.integration
@pytest.mark.asyncio
async def test_staff_can_list_models(client: AsyncClient) -> None:
    response = await client.get("/v1/models", headers=_auth(_staff_token()))
    assert response.status_code == 200, response.text


@pytest.mark.integration
@pytest.mark.asyncio
async def test_farmer_cannot_broadcast_advisory(client: AsyncClient) -> None:
    body = {"title": "Test advisory", "body": "Body text"}
    response = await client.post(
        "/v1/advisories/broadcast", json=body, headers=_auth(_farmer_token())
    )
    assert response.status_code == 403, response.text


@pytest.mark.integration
@pytest.mark.asyncio
async def test_staff_can_broadcast_advisory(client: AsyncClient) -> None:
    body = {"title": "Test advisory", "body": "Body text"}
    response = await client.post(
        "/v1/advisories/broadcast", json=body, headers=_auth(_staff_token())
    )
    assert response.status_code == 201, response.text


# ---------------------------------------------------------------------------
# 5. District scoping (GET /v1/risk/worklist?district=...)
# ---------------------------------------------------------------------------
@pytest.mark.integration
@pytest.mark.asyncio
async def test_staff_district_mismatch_returns_403(client: AsyncClient) -> None:
    token = _staff_token(district=DISTRICT_A)
    response = await client.get(
        "/v1/risk/worklist", params={"district": DISTRICT_B}, headers=_auth(token)
    )
    assert response.status_code == 403, response.text


@pytest.mark.integration
@pytest.mark.asyncio
async def test_staff_district_match_returns_200(client: AsyncClient) -> None:
    token = _staff_token(district=DISTRICT_A)
    response = await client.get(
        "/v1/risk/worklist", params={"district": DISTRICT_A}, headers=_auth(token)
    )
    assert response.status_code == 200, response.text


@pytest.mark.integration
@pytest.mark.asyncio
async def test_staff_with_no_district_claim_fails_closed(client: AsyncClient) -> None:
    """A staff token with no district claim must NOT be treated as unrestricted."""
    token = _staff_token(district=None)
    response = await client.get(
        "/v1/risk/worklist", params={"district": DISTRICT_A}, headers=_auth(token)
    )
    assert response.status_code == 403, response.text


@pytest.mark.integration
@pytest.mark.asyncio
async def test_admin_bypasses_district_scoping(client: AsyncClient) -> None:
    token = _admin_token(district=None)
    response = await client.get(
        "/v1/risk/worklist", params={"district": DISTRICT_B}, headers=_auth(token)
    )
    assert response.status_code == 200, response.text


# ---------------------------------------------------------------------------
# 6. Login endpoints are NOT gated behind the Authorization header
# ---------------------------------------------------------------------------
@pytest.mark.integration
@pytest.mark.asyncio
async def test_login_endpoints_not_gated_by_auth_header(client: AsyncClient) -> None:
    """POST /v1/auth/otp/request and POST /v1/auth/token must remain reachable
    with no Authorization header — i.e. P0.1 must not have accidentally wired
    CurrentUser/CurrentStaff into the login flow itself.

    Neither route declares a CurrentUser/CurrentStaff dependency (verified by
    reading app/identity/router.py), so a missing/invalid bearer token can
    never produce a 401/403 for them. What *does* happen in this sandbox is
    that both routes touch the DB (user lookup) and the `client` fixture's
    ASGITransport never runs the app lifespan, so DB access raises a bare
    RuntimeError("Database not initialised...") — the same pre-existing,
    environmental condition responsible for the documented
    test_all_stub_endpoints_return_non_500 baseline failure. That RuntimeError
    is the signature of "reached DB code", proving these requests sailed
    straight past any auth dependency instead of being rejected by one.
    """
    with pytest.raises(RuntimeError, match="Database not initialised"):
        await client.post("/v1/auth/otp/request", json={"phone": "+919876543210"})

    with pytest.raises(RuntimeError, match="Database not initialised"):
        await client.post(
            "/v1/auth/token",
            json={"grant_type": "password", "username": "someuser", "password": "somepass"},
        )
