"""Integration tests — real keyset pagination on GET /v1/logs (P0.2).

Uses `db_session` to seed rows directly into a real Postgres (testcontainers)
and `db_client` to walk GET /v1/logs page by page through the real ASGI app
(lifespan actually run, unlike the shared `client` fixture — see
tests/conftest.py's db_client docstring). This proves the keyset cursor
returns disjoint, ordered, non-duplicated pages against a real database,
not just that the encode/decode helpers round-trip in isolation.
"""

from __future__ import annotations

from datetime import UTC, datetime, timedelta
from typing import TYPE_CHECKING
from uuid import uuid4

import pytest

from app.core.security import create_access_token
from app.db.models.log import Log
from app.db.models.pond import Pond

if TYPE_CHECKING:
    from httpx import AsyncClient
    from sqlalchemy.ext.asyncio import AsyncSession

NUM_LOGS = 7


async def _seed_pond_and_logs(db_session: AsyncSession) -> tuple[Pond, list[Log]]:
    pond_id = uuid4()
    owner_id = uuid4()
    pond = Pond(
        id=pond_id,
        owner_user_id=owner_id,
        name="Pagination Test Pond",
        district="Nagapattinam",
    )
    db_session.add(pond)

    t_base = datetime.now(UTC).replace(microsecond=0)
    logs = []
    for i in range(NUM_LOGS):
        log = Log(
            id=uuid4(),
            pond_id=pond_id,
            recorded_by=owner_id,
            # Two rows share the same recorded_at (i=0 and i=1) to exercise
            # the id tie-breaker in the keyset WHERE clause.
            recorded_at=t_base - timedelta(hours=(i // 2)),
            temperature_c=25.0 + i,
            source="sensor",
        )
        logs.append(log)
    db_session.add_all(logs)
    await db_session.commit()
    return pond, logs


@pytest.mark.integration
@pytest.mark.asyncio(loop_scope="session")
async def test_list_logs_keyset_pagination_walks_all_rows_once(
    db_session: AsyncSession, db_client: AsyncClient
) -> None:
    pond, logs = await _seed_pond_and_logs(db_session)

    token = create_access_token(sub=str(uuid4()), role="staff", district="Nagapattinam")
    headers = {"Authorization": f"Bearer {token}"}

    expected_order = sorted(
        [(log.recorded_at, log.id) for log in logs],
        key=lambda pair: (pair[0], pair[1]),
        reverse=True,
    )

    seen_ids: list[str] = []
    cursor: str | None = None
    page_sizes: list[int] = []
    pages_fetched = 0

    while True:
        params: dict[str, object] = {"pond_id": str(pond.id), "limit": 3}
        if cursor:
            params["cursor"] = cursor
        response = await db_client.get("/v1/logs", params=params, headers=headers)
        assert response.status_code == 200, response.text
        body = response.json()

        page_items = body["items"]
        page_sizes.append(len(page_items))
        seen_ids.extend(item["id"] for item in page_items)

        cursor = body["next_cursor"]
        pages_fetched += 1
        assert pages_fetched <= NUM_LOGS + 1, "pagination did not terminate"

        if cursor is None:
            break

    # All rows seen exactly once, no duplicates, no skips.
    assert len(seen_ids) == NUM_LOGS
    assert len(set(seen_ids)) == NUM_LOGS

    # Page sizes: limit=3 over 7 rows -> 3, 3, 1.
    assert page_sizes == [3, 3, 1]

    # Order matches (recorded_at, id) DESC across page boundaries.
    assert seen_ids == [str(log_id) for _, log_id in expected_order]


@pytest.mark.integration
@pytest.mark.asyncio(loop_scope="session")
async def test_list_logs_pages_are_disjoint(
    db_session: AsyncSession, db_client: AsyncClient
) -> None:
    """Consecutive pages never repeat a row, even across the tied-timestamp
    pair — this is the concrete case a naive OFFSET-based (or unfiltered)
    implementation gets wrong."""
    pond, logs = await _seed_pond_and_logs(db_session)

    token = create_access_token(sub=str(uuid4()), role="staff", district="Nagapattinam")
    headers = {"Authorization": f"Bearer {token}"}

    first = await db_client.get(
        "/v1/logs", params={"pond_id": str(pond.id), "limit": 4}, headers=headers
    )
    assert first.status_code == 200, first.text
    first_body = first.json()
    assert first_body["next_cursor"] is not None
    first_ids = {item["id"] for item in first_body["items"]}
    assert len(first_ids) == 4

    second = await db_client.get(
        "/v1/logs",
        params={"pond_id": str(pond.id), "limit": 4, "cursor": first_body["next_cursor"]},
        headers=headers,
    )
    assert second.status_code == 200, second.text
    second_body = second.json()
    second_ids = {item["id"] for item in second_body["items"]}

    # Disjoint pages.
    assert first_ids.isdisjoint(second_ids)
    # Together they cover every seeded row (7 total: 4 + 3).
    assert first_ids | second_ids == {str(log.id) for log in logs}
    # Final page has no further cursor.
    assert second_body["next_cursor"] is None
