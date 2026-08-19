"""Integration tests — POST /v1/ask wired to the real in-process M3 engine (P0.3).

Independently verifies that /v1/ask no longer depends on the hardcoded
`http://172.17.0.1:8001/v1/reason/m3` mock service: these tests run with
NO other service listening anywhere, which is itself the proof the
hardcoded-IP coupling is gone. A `httpx.AsyncClient.post` patch below turns
any accidental network call into a hard test failure rather than a silent
pass/fail depending on what happens to be running on the host.
"""

from __future__ import annotations

import os
from typing import TYPE_CHECKING
from uuid import uuid4

import pytest

if TYPE_CHECKING:
    from httpx import AsyncClient

os.environ.setdefault("DATABASE_URL", "postgresql+asyncpg://x:x@localhost/x")
os.environ.setdefault("APP_SECRET_KEY", "test_secret_key_minimum_32_chars_here")
os.environ.setdefault("INTERNAL_API_TOKEN", "test_internal_token_minimum_32_chars")

from app.core.security import create_access_token

FARMER_POND_ID = "11111111-1111-1111-1111-111111111111"


def _farmer_token(pond_ids: list[str] | None = None) -> str:
    return create_access_token(
        sub=str(uuid4()),
        role="farmer",
        pond_ids=pond_ids if pond_ids is not None else [FARMER_POND_ID],
        district="Nagapattinam",
    )


def _auth(token: str) -> dict[str, str]:
    return {"Authorization": f"Bearer {token}"}


@pytest.fixture(autouse=True)
def _fail_on_any_outbound_socket(monkeypatch: pytest.MonkeyPatch) -> None:
    """Turn any real outbound TCP connection into a hard failure.

    /v1/ask used to call out to a hardcoded Docker-host IP; this fixture
    makes it impossible for that pattern to silently reappear (and pass)
    just because nothing happens to be listening on 172.17.0.1:8001 in this
    sandbox.

    We patch `socket.socket.connect` / `connect_ex` — the lowest-level
    methods every outbound connection funnels through, sync or async (this
    is the same technique `pytest-socket`'s `disable_socket()` uses) —
    rather than the module-level `socket.create_connection()` free
    function. That free function is only called by httpcore's SYNC
    backend; httpx.AsyncClient over asyncio routes through httpcore's
    AnyIOBackend -> anyio's asyncio backend ->
    `asyncio.base_events.BaseEventLoop.create_connection`, which builds a
    raw `socket.socket()` and calls `.connect()`/`.connect_ex()` on it
    directly, never touching `socket.create_connection()`. Patching only
    the free function therefore left the async path (what /v1/ask actually
    uses) completely unguarded — verified experimentally: a throwaway
    async httpx call against an unreachable address sailed straight past
    the old patch and hit a real `ConnectTimeout` instead of our
    AssertionError. Patching `socket.socket.connect`/`connect_ex` catches
    both paths. We keep the `socket.create_connection` patch too, as
    belt-and-suspenders for any sync callers.

    We do NOT patch `httpx.AsyncClient.post`/`.request` directly, because
    the `client` fixture itself is an httpx.AsyncClient (over in-memory
    ASGITransport, which opens no real socket at all) — blocking httpx
    calls outright would also block the test's own request to the app.
    """
    import socket

    def _forbidden_connect(*args, **kwargs):
        raise AssertionError(
            "POST /v1/ask opened a real network connection — it must run "
            "the M3 engine fully in-process (P0.3), no external service."
        )

    def _forbidden_socket_connect(self, *args, **kwargs):
        raise AssertionError(
            "POST /v1/ask opened a real network connection — it must run "
            "the M3 engine fully in-process (P0.3), no external service."
        )

    monkeypatch.setattr(socket, "create_connection", _forbidden_connect)
    monkeypatch.setattr(socket.socket, "connect", _forbidden_socket_connect)
    monkeypatch.setattr(socket.socket, "connect_ex", _forbidden_socket_connect)


@pytest.mark.integration
@pytest.mark.asyncio
async def test_ask_returns_real_narration_with_no_external_service(
    client: AsyncClient,
) -> None:
    """Proves the hardcoded-IP dependency is gone: this passes with zero
    other services running (no mock_m3.py, no vLLM, nothing on :8001)."""
    token = _farmer_token(pond_ids=[FARMER_POND_ID])
    response = await client.post(
        "/v1/ask",
        json={
            "pond_id": FARMER_POND_ID,
            "question": "Should I feed the pond tonight?",
            "language": "en",
        },
        headers=_auth(token),
    )

    assert response.status_code == 200, response.text
    body = response.json()

    assert body["pond_id"] == FARMER_POND_ID
    assert body["rejected_attempts_this_request"] == 0

    answer = body["answer"]
    assert isinstance(answer, str)
    assert len(answer) > 0
    # Not the old canned mock string, and not an obvious stub marker.
    assert "MOCK" not in answer.upper()
    assert "STUB" not in answer.upper()
    # Grounded in the real engine's output — the pond's DOC (52) and the
    # narration's own DO-forecast line are the model's real numbers.
    assert "day 52 of culture" in answer
    assert "Overnight DO forecast" in answer


@pytest.mark.integration
@pytest.mark.asyncio
async def test_ask_enforces_pond_scope_for_farmer(client: AsyncClient) -> None:
    other_pond_id = "22222222-2222-2222-2222-222222222222"
    token = _farmer_token(pond_ids=[FARMER_POND_ID])

    response = await client.post(
        "/v1/ask",
        json={
            "pond_id": other_pond_id,
            "question": "Should I feed the pond tonight?",
            "language": "en",
        },
        headers=_auth(token),
    )

    assert response.status_code == 403, response.text
