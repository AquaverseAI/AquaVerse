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
  * P1.3 wired GET /v1/ponds/{id}/risk and GET /v1/risk/worklist onto real
    Postgres (real Pond/Log/Crop queries + the real M2 LightGBM risk
    engine). Their *success*-path assertions below have moved onto the
    `db_session` + `db_client` fixtures (real lifespan, real testcontainers
    Postgres — same pattern as tests/integration/test_ponds.py), with a
    real seeded Pond row matching whatever hardcoded pond id the test
    exercises. The pure-RBAC-*rejection* cases (403s) are unaffected and
    stay on the plain `client` fixture, because rbac.require_pond_scope /
    require_district raise before any query reaches the DB — same
    precedent as GET /v1/logs going DB-backed under P0.2 (see git log for
    that commit) and the Ponds domain doing the same under P1.2.
"""

from __future__ import annotations

import os
from typing import TYPE_CHECKING
from uuid import UUID, uuid4

import pytest

if TYPE_CHECKING:
    from httpx import AsyncClient
    from sqlalchemy.ext.asyncio import AsyncSession

# Ensure env vars before app import (mirrors test_health.py / conftest.client fixture)
os.environ.setdefault("DATABASE_URL", "postgresql+asyncpg://x:x@localhost/x")
os.environ.setdefault("APP_SECRET_KEY", "test_secret_key_minimum_32_chars_here")
os.environ.setdefault("INTERNAL_API_TOKEN", "test_internal_token_minimum_32_chars")

from app.core.security import create_access_token
from app.db.models.media import Media
from app.db.models.pond import Pond

# ---------------------------------------------------------------------------
# Fixtures / helpers
# ---------------------------------------------------------------------------
FARMER_POND_ID = "11111111-1111-1111-1111-111111111111"
OTHER_POND_ID = "22222222-2222-2222-2222-222222222222"
DISTRICT_A = "Nagapattinam"
DISTRICT_B = "Thanjavur"


async def _seed_pond(db_session: AsyncSession, pond_id: str, district: str = DISTRICT_A) -> Pond:
    """Seed a minimal real Pond row for a risk/media-endpoint success-path
    test. Idempotent: FARMER_POND_ID is a fixed UUID shared across several
    tests in this file (test_farmer_can_access_own_pond_risk,
    test_farmer_can_commit_media_for_own_pond, ...) — whichever runs first
    creates the row for real; later callers just reuse it rather than
    hitting ponds_pkey's unique constraint.

    Owner is an unrelated random UUID — GET /v1/ponds/{id}/risk's
    farmer-scoping check (rbac.require_pond_scope) works off the token's
    `pond_ids` claim, not `Pond.owner_user_id`, so it doesn't need to match.
    """
    existing = await db_session.get(Pond, UUID(pond_id))
    if existing is not None:
        return existing
    pond = Pond(id=UUID(pond_id), owner_user_id=uuid4(), name="RBAC Test Pond", district=district)
    db_session.add(pond)
    await db_session.commit()
    return pond


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
    response = await client.get(path, headers={"Authorization": SMOKE_TEST_STUB_BEARER})
    assert response.status_code == 401, (
        f"GET {path} with the smoke-test's stub bearer returned "
        f"{response.status_code}, expected 401: {response.text}"
    )


# ---------------------------------------------------------------------------
# 2b. Login endpoints are NOT gated behind the Authorization header
#
# Deliberately placed here, BEFORE any `db_client`-fixture test in this
# file (see section 3 onward): `db_client`'s lifespan startup calls
# app.db.session.init_db(), and its shutdown disposes the engine but does
# NOT reset the module-level `AsyncSessionLocal` sessionmaker back to None
# (app/db/session.py close_db() — a real, pre-existing gap, not something
# this change fixes). Once any `db_client` test has run earlier in the same
# process, `get_async_session()` stops raising RuntimeError("Database not
# initialised") for the plain `client` fixture below — this test's
# `pytest.raises(RuntimeError, ...)` would then fail with "DID NOT RAISE"
# even though the actual DB-not-gated-behind-auth assertion is still true.
# Verified empirically while wiring P1.3's risk endpoints onto `db_client`.
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


# ---------------------------------------------------------------------------
# 3. Farmer pond-scoping: own pond OK, other pond 403
# ---------------------------------------------------------------------------
@pytest.mark.integration
@pytest.mark.asyncio(loop_scope="session")
async def test_farmer_can_access_own_pond_risk(
    db_session: AsyncSession, db_client: AsyncClient
) -> None:
    await _seed_pond(db_session, FARMER_POND_ID)
    token = _farmer_token(pond_ids=[FARMER_POND_ID])
    response = await db_client.get(f"/v1/ponds/{FARMER_POND_ID}/risk", headers=_auth(token))
    assert response.status_code == 200, response.text


@pytest.mark.integration
@pytest.mark.asyncio(loop_scope="session")
async def test_farmer_cannot_access_other_pond_risk(db_client: AsyncClient) -> None:
    """Uses `db_client`, not `client`: GET /v1/ponds/{id}/risk now declares a
    `session: DbSession` dependency for its real DB-backed logic. FastAPI
    resolves ALL declared top-level dependencies before the route body
    runs, in signature order — `user: CurrentUser` succeeds for this valid
    (if wrongly-scoped) farmer token, so `session: DbSession` still gets
    resolved next regardless of what the body's `rbac.require_pond_scope`
    check would decide. On the lifespan-less `client` fixture that raises a
    bare RuntimeError before the 403 body check ever runs (verified
    empirically). No Pond row needs seeding: require_pond_scope rejects
    before any query is issued.
    """
    token = _farmer_token(pond_ids=[FARMER_POND_ID])
    response = await db_client.get(f"/v1/ponds/{OTHER_POND_ID}/risk", headers=_auth(token))
    assert response.status_code == 403, response.text


@pytest.mark.integration
@pytest.mark.asyncio(loop_scope="session")
async def test_farmer_can_commit_media_for_own_pond(
    db_session: AsyncSession,
    media_client: AsyncClient,
    minio_container: dict[str, str],
) -> None:
    """Uses `media_client`, not `client`: POST /v1/media/{id}/commit went
    real (DB row lookup + a genuine S3 HEAD check) under P2.5 — same
    precedent as test_farmer_can_access_own_pond_risk above. A real Media
    row pointing at a real uploaded S3 object is required for a 200:
    an arbitrary media_id (the old assumption, back when this endpoint
    was a stub) now correctly 404s instead.
    """
    await _seed_pond(db_session, FARMER_POND_ID)
    token = _farmer_token(pond_ids=[FARMER_POND_ID])

    media_id = uuid4()
    s3_key = f"ponds/{FARMER_POND_ID}/{media_id}/test.jpg"
    media = Media(
        id=media_id,
        pond_id=UUID(FARMER_POND_ID),
        uploaded_by=uuid4(),
        filename="test.jpg",
        mime_type="image/jpeg",
        s3_key=s3_key,
        status="pending",
    )
    db_session.add(media)
    await db_session.commit()

    import boto3

    s3_client = boto3.client(
        "s3",
        endpoint_url=minio_container["endpoint_url"],
        aws_access_key_id=minio_container["access_key_id"],
        aws_secret_access_key=minio_container["secret_access_key"],
        region_name="us-east-1",
    )
    s3_client.put_object(
        Bucket=minio_container["bucket_name"], Key=s3_key, Body=b"fake-image-bytes"
    )

    response = await media_client.post(
        f"/v1/media/{media_id}/commit",
        json={"pond_id": FARMER_POND_ID},
        headers=_auth(token),
    )
    assert response.status_code == 200, response.text
    assert response.json()["pond_id"] == FARMER_POND_ID


@pytest.mark.integration
@pytest.mark.asyncio(loop_scope="session")
async def test_farmer_cannot_commit_media_for_other_pond(db_client: AsyncClient) -> None:
    """Uses `db_client`, not `client`: same session-dependency-resolution-
    order reasoning as test_farmer_cannot_access_other_pond_risk above —
    `session: DbSession` is resolved before the body's
    `rbac.require_pond_scope` 403 check runs, even though that check
    itself never queries anything. No Pond/Media row needs seeding for
    the same reason.
    """
    token = _farmer_token(pond_ids=[FARMER_POND_ID])
    media_id = str(uuid4())
    response = await db_client.post(
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
@pytest.mark.asyncio(loop_scope="session")
async def test_staff_can_access_risk_worklist(
    db_session: AsyncSession, db_client: AsyncClient
) -> None:
    await _seed_pond(db_session, str(uuid4()), district=DISTRICT_A)
    response = await db_client.get("/v1/risk/worklist", headers=_auth(_staff_token()))
    assert response.status_code == 200, response.text


@pytest.mark.integration
@pytest.mark.asyncio
async def test_farmer_cannot_list_models(client: AsyncClient) -> None:
    response = await client.get("/v1/models", headers=_auth(_farmer_token()))
    assert response.status_code == 403, response.text


@pytest.mark.integration
@pytest.mark.asyncio(loop_scope="session")
async def test_staff_can_list_models(db_client: AsyncClient) -> None:
    """Uses `db_client`, not `client`: GET /v1/models is now DB-backed
    (P2.7, app/ml_inference/model_registry_sync.py) rather than a static
    fixture — same precedent as the risk endpoints above."""
    response = await db_client.get("/v1/models", headers=_auth(_staff_token()))
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
@pytest.mark.asyncio(loop_scope="session")
async def test_staff_can_broadcast_advisory(db_client: AsyncClient) -> None:
    """Uses `db_client`, not `client`: POST /v1/advisories/broadcast went
    DB-backed under P2.4 (real Advisory row persisted) — same precedent
    as GET /v1/ponds/{id}/risk and GET /v1/risk/worklist noted in this
    file's module docstring. The 403 rejection case above stays on
    `client` since CurrentStaff raises before any query reaches the DB.
    """
    body = {"title": "Test advisory", "body": "Body text"}
    response = await db_client.post(
        "/v1/advisories/broadcast", json=body, headers=_auth(_staff_token())
    )
    assert response.status_code == 201, response.text


# ---------------------------------------------------------------------------
# 5. District scoping (GET /v1/risk/worklist?district=...)
# ---------------------------------------------------------------------------
@pytest.mark.integration
@pytest.mark.asyncio(loop_scope="session")
async def test_staff_district_mismatch_returns_403(db_client: AsyncClient) -> None:
    """Uses `db_client`: see test_farmer_cannot_access_other_pond_risk's
    docstring above — GET /v1/risk/worklist now declares `session:
    DbSession` too, so the same dependency-resolution-order argument
    applies (`user: CurrentStaff` succeeds for a valid staff token; the
    district-mismatch rejection is a body-level `rbac.require_district`
    call that only runs after `session` has already been resolved).
    """
    token = _staff_token(district=DISTRICT_A)
    response = await db_client.get(
        "/v1/risk/worklist", params={"district": DISTRICT_B}, headers=_auth(token)
    )
    assert response.status_code == 403, response.text


@pytest.mark.integration
@pytest.mark.asyncio(loop_scope="session")
async def test_staff_district_match_returns_200(
    db_session: AsyncSession, db_client: AsyncClient
) -> None:
    await _seed_pond(db_session, str(uuid4()), district=DISTRICT_A)
    token = _staff_token(district=DISTRICT_A)
    response = await db_client.get(
        "/v1/risk/worklist", params={"district": DISTRICT_A}, headers=_auth(token)
    )
    assert response.status_code == 200, response.text


@pytest.mark.integration
@pytest.mark.asyncio(loop_scope="session")
async def test_staff_with_no_district_claim_fails_closed(db_client: AsyncClient) -> None:
    """A staff token with no district claim must NOT be treated as
    unrestricted. Uses `db_client` for the same reason as
    test_staff_district_mismatch_returns_403 above."""
    token = _staff_token(district=None)
    response = await db_client.get(
        "/v1/risk/worklist", params={"district": DISTRICT_A}, headers=_auth(token)
    )
    assert response.status_code == 403, response.text


@pytest.mark.integration
@pytest.mark.asyncio(loop_scope="session")
async def test_admin_bypasses_district_scoping(db_client: AsyncClient) -> None:
    token = _admin_token(district=None)
    response = await db_client.get(
        "/v1/risk/worklist", params={"district": DISTRICT_B}, headers=_auth(token)
    )
    assert response.status_code == 200, response.text
