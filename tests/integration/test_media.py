"""Integration tests — real Media domain (P2.5).

`POST /v1/media/upload-url` used to return a fixture URL
(`?X-Amz-Signature=stub`) with no DB row behind it, and
`POST /v1/media/{id}/commit` always returned `status=committed` with no
verification. This exercises the real path against a real MinIO
container (`media_client` fixture, tests/conftest.py): a real presigned
PUT URL that a plain HTTP client can actually upload to, and a real HEAD
check on commit that fails honestly when nothing was uploaded.

Every test seeds a real `Pond` row first — `Media.pond_id` is a real FK
to `ponds.id` (app/db/models/media.py), so an arbitrary UUID with no
matching pond row is rejected at the DB level, not just a fixture choice.
"""

from __future__ import annotations

from typing import TYPE_CHECKING
from uuid import uuid4

import httpx
import pytest

from app.core.security import create_access_token
from app.db.models.pond import Pond

if TYPE_CHECKING:
    from httpx import AsyncClient
    from sqlalchemy.ext.asyncio import AsyncSession


def _staff_headers() -> dict[str, str]:
    token = create_access_token(sub=str(uuid4()), role="staff", district="Nagapattinam")
    return {"Authorization": f"Bearer {token}"}


async def _seed_pond(db_session: AsyncSession) -> Pond:
    pond = Pond(
        id=uuid4(),
        owner_user_id=uuid4(),
        name="Media Test Pond",
        district="Nagapattinam",
        species="Litopenaeus vannamei",
    )
    db_session.add(pond)
    await db_session.commit()
    return pond


@pytest.mark.integration
@pytest.mark.asyncio(loop_scope="session")
async def test_upload_url_returns_real_presigned_url(
    db_session: AsyncSession, media_client: AsyncClient
) -> None:
    pond = await _seed_pond(db_session)
    resp = await media_client.post(
        "/v1/media/upload-url",
        json={"pond_id": str(pond.id), "filename": "pond.jpg", "mime_type": "image/jpeg"},
        headers=_staff_headers(),
    )
    assert resp.status_code == 201, resp.text
    body = resp.json()
    assert body["media_id"]
    # Real presigned URL, not the old fixture with X-Amz-Signature=stub.
    assert "X-Amz-Signature=stub" not in body["upload_url"]
    assert "AWSAccessKeyId=" in body["upload_url"]


@pytest.mark.integration
@pytest.mark.asyncio(loop_scope="session")
async def test_commit_without_upload_returns_409(
    db_session: AsyncSession, media_client: AsyncClient
) -> None:
    pond = await _seed_pond(db_session)
    upload_resp = await media_client.post(
        "/v1/media/upload-url",
        json={
            "pond_id": str(pond.id),
            "filename": "never_uploaded.jpg",
            "mime_type": "image/jpeg",
        },
        headers=_staff_headers(),
    )
    assert upload_resp.status_code == 201, upload_resp.text
    media_id = upload_resp.json()["media_id"]

    commit_resp = await media_client.post(
        f"/v1/media/{media_id}/commit",
        json={"pond_id": str(pond.id)},
        headers=_staff_headers(),
    )
    assert commit_resp.status_code == 409, commit_resp.text


@pytest.mark.integration
@pytest.mark.asyncio(loop_scope="session")
async def test_commit_after_real_upload_succeeds_with_verified_size(
    db_session: AsyncSession, media_client: AsyncClient
) -> None:
    pond = await _seed_pond(db_session)
    upload_resp = await media_client.post(
        "/v1/media/upload-url",
        json={"pond_id": str(pond.id), "filename": "real.jpg", "mime_type": "image/jpeg"},
        headers=_staff_headers(),
    )
    assert upload_resp.status_code == 201, upload_resp.text
    body = upload_resp.json()
    media_id = body["media_id"]
    upload_url = body["upload_url"]

    # A real client PUTting real bytes to the real presigned URL.
    payload = b"\xff\xd8\xff" + b"fake-jpeg-bytes" * 100
    async with httpx.AsyncClient() as raw_client:
        put_resp = await raw_client.put(
            upload_url, content=payload, headers={"Content-Type": "image/jpeg"}
        )
    assert put_resp.status_code in (200, 204), put_resp.text

    commit_resp = await media_client.post(
        f"/v1/media/{media_id}/commit",
        json={"pond_id": str(pond.id)},
        headers=_staff_headers(),
    )
    assert commit_resp.status_code == 200, commit_resp.text
    committed = commit_resp.json()
    assert committed["status"] == "committed"
    # Real, HEAD-verified size — not a client-supplied estimate.
    assert committed["size_bytes"] == len(payload)


@pytest.mark.integration
@pytest.mark.asyncio(loop_scope="session")
async def test_commit_unknown_media_id_returns_404(media_client: AsyncClient) -> None:
    resp = await media_client.post(
        f"/v1/media/{uuid4()}/commit",
        json={"pond_id": str(uuid4())},
        headers=_staff_headers(),
    )
    assert resp.status_code == 404


@pytest.mark.integration
@pytest.mark.asyncio(loop_scope="session")
async def test_commit_pond_id_mismatch_returns_400(
    db_session: AsyncSession, media_client: AsyncClient
) -> None:
    pond = await _seed_pond(db_session)
    other_pond = await _seed_pond(db_session)
    upload_resp = await media_client.post(
        "/v1/media/upload-url",
        json={"pond_id": str(pond.id), "filename": "x.jpg", "mime_type": "image/jpeg"},
        headers=_staff_headers(),
    )
    media_id = upload_resp.json()["media_id"]

    resp = await media_client.post(
        f"/v1/media/{media_id}/commit",
        json={"pond_id": str(other_pond.id)},
        headers=_staff_headers(),
    )
    assert resp.status_code == 400


@pytest.mark.integration
@pytest.mark.asyncio(loop_scope="session")
async def test_farmer_outside_pond_scope_cannot_request_upload_url(
    media_client: AsyncClient,
) -> None:
    """No Pond needs seeding: rbac.require_pond_scope rejects an empty
    pond_ids claim before the handler ever builds a Media row."""
    farmer_token = create_access_token(sub=str(uuid4()), role="farmer", pond_ids=[])
    resp = await media_client.post(
        "/v1/media/upload-url",
        json={"pond_id": str(uuid4()), "filename": "x.jpg", "mime_type": "image/jpeg"},
        headers={"Authorization": f"Bearer {farmer_token}"},
    )
    assert resp.status_code == 403
