"""Integration tests — real Alerts domain (P2.1).

`GET /v1/alerts`, `POST /{id}/ack`, `POST /{id}/feedback` used to return
one hardcoded fixture and discard ack/feedback input. This exercises the
real path: `POST /v1/logs` breaching a species DO threshold raises a real
`Alert` row (via `app/alerts/rules.py`), visible through `GET /v1/alerts`,
with ack/feedback persisting to the DB.
"""

from __future__ import annotations

from datetime import UTC, datetime, timedelta
from typing import TYPE_CHECKING
from uuid import uuid4

import pytest
from sqlalchemy import select

from app.core.security import create_access_token
from app.db.models.alert import Alert
from app.db.models.pond import Pond

if TYPE_CHECKING:
    from httpx import AsyncClient
    from sqlalchemy.ext.asyncio import AsyncSession


async def _seed_pond(db_session: AsyncSession, *, species: str = "Litopenaeus vannamei") -> Pond:
    pond = Pond(
        id=uuid4(),
        owner_user_id=uuid4(),
        name="Alerts Test Pond",
        district="Nagapattinam",
        species=species,
    )
    db_session.add(pond)
    await db_session.commit()
    return pond


def _admin_headers() -> dict[str, str]:
    token = create_access_token(sub=str(uuid4()), role="admin")
    return {"Authorization": f"Bearer {token}"}


@pytest.mark.integration
@pytest.mark.asyncio(loop_scope="session")
async def test_low_do_log_raises_a_real_alert(
    db_session: AsyncSession, db_client: AsyncClient
) -> None:
    pond = await _seed_pond(db_session)
    headers = _admin_headers()

    # vannamei's do_stress_threshold_mg_l is well above 1.0 mg/L.
    log_resp = await db_client.post(
        "/v1/logs",
        json={
            "pond_id": str(pond.id),
            "recorded_at": datetime.now(UTC).isoformat(),
            "dissolved_oxygen_mgl": 1.0,
        },
        headers=headers,
    )
    assert log_resp.status_code == 201, log_resp.text

    alerts_resp = await db_client.get(f"/v1/alerts?pond_id={pond.id}", headers=headers)
    assert alerts_resp.status_code == 200, alerts_resp.text
    items = alerts_resp.json()["items"]
    assert len(items) == 1
    alert = items[0]
    assert alert["pond_id"] == str(pond.id)
    assert alert["alert_type"] == "low_dissolved_oxygen"
    assert alert["parameter"] == "dissolved_oxygen_mgl"
    assert alert["measured_value"] == 1.0
    assert alert["acked"] is False
    # Suppression is always visible on the payload, whichever way it goes.
    assert "suppressed" in alert


@pytest.mark.integration
@pytest.mark.asyncio(loop_scope="session")
async def test_healthy_log_raises_no_alert(
    db_session: AsyncSession, db_client: AsyncClient
) -> None:
    pond = await _seed_pond(db_session)
    headers = _admin_headers()

    resp = await db_client.post(
        "/v1/logs",
        json={
            "pond_id": str(pond.id),
            "recorded_at": datetime.now(UTC).isoformat(),
            "dissolved_oxygen_mgl": 6.0,
            "ph": 7.8,
            "ammonia_nh3_mgl": 0.1,
        },
        headers=headers,
    )
    assert resp.status_code == 201, resp.text

    alerts_resp = await db_client.get(f"/v1/alerts?pond_id={pond.id}", headers=headers)
    assert alerts_resp.json()["items"] == []


@pytest.mark.integration
@pytest.mark.asyncio(loop_scope="session")
async def test_repeated_breach_within_dedup_window_does_not_duplicate(
    db_session: AsyncSession, db_client: AsyncClient
) -> None:
    pond = await _seed_pond(db_session)
    headers = _admin_headers()

    for _ in range(2):
        resp = await db_client.post(
            "/v1/logs",
            json={
                "pond_id": str(pond.id),
                "recorded_at": datetime.now(UTC).isoformat(),
                "dissolved_oxygen_mgl": 1.0,
            },
            headers=headers,
        )
        assert resp.status_code == 201, resp.text

    alerts_resp = await db_client.get(f"/v1/alerts?pond_id={pond.id}", headers=headers)
    assert len(alerts_resp.json()["items"]) == 1


@pytest.mark.integration
@pytest.mark.asyncio(loop_scope="session")
async def test_ack_alert_persists(db_session: AsyncSession, db_client: AsyncClient) -> None:
    pond = await _seed_pond(db_session)
    headers = _admin_headers()

    await db_client.post(
        "/v1/logs",
        json={
            "pond_id": str(pond.id),
            "recorded_at": datetime.now(UTC).isoformat(),
            "dissolved_oxygen_mgl": 1.0,
        },
        headers=headers,
    )
    alert_id = (await db_client.get(f"/v1/alerts?pond_id={pond.id}", headers=headers)).json()[
        "items"
    ][0]["id"]

    ack_resp = await db_client.post(
        f"/v1/alerts/{alert_id}/ack", json={"note": "checked pump, restarted"}, headers=headers
    )
    assert ack_resp.status_code == 200, ack_resp.text
    assert ack_resp.json()["acked"] is True

    row = (await db_session.execute(select(Alert).where(Alert.id == alert_id))).scalar_one()
    assert row.acked is True
    assert row.acked_at is not None
    assert row.ack_note == "checked pump, restarted"

    # Reflected back through the list too.
    alerts_resp = await db_client.get(f"/v1/alerts?pond_id={pond.id}&acked=true", headers=headers)
    assert len(alerts_resp.json()["items"]) == 1


@pytest.mark.integration
@pytest.mark.asyncio(loop_scope="session")
async def test_alert_feedback_persists(db_session: AsyncSession, db_client: AsyncClient) -> None:
    pond = await _seed_pond(db_session)
    headers = _admin_headers()

    await db_client.post(
        "/v1/logs",
        json={
            "pond_id": str(pond.id),
            "recorded_at": datetime.now(UTC).isoformat(),
            "dissolved_oxygen_mgl": 1.0,
        },
        headers=headers,
    )
    alert_id = (await db_client.get(f"/v1/alerts?pond_id={pond.id}", headers=headers)).json()[
        "items"
    ][0]["id"]

    feedback_resp = await db_client.post(
        f"/v1/alerts/{alert_id}/feedback",
        json={"useful": False, "comment": "sensor was miscalibrated", "false_positive": True},
        headers=headers,
    )
    assert feedback_resp.status_code == 200, feedback_resp.text
    assert feedback_resp.json()["feedback_recorded"] is True

    row = (await db_session.execute(select(Alert).where(Alert.id == alert_id))).scalar_one()
    assert row.feedback_useful is False
    assert row.feedback_false_positive is True
    assert row.feedback_comment == "sensor was miscalibrated"
    assert row.feedback_at is not None


@pytest.mark.integration
@pytest.mark.asyncio(loop_scope="session")
async def test_farmer_cannot_ack_alert_outside_pond_scope(
    db_session: AsyncSession, db_client: AsyncClient
) -> None:
    pond = await _seed_pond(db_session)
    admin_headers = _admin_headers()

    await db_client.post(
        "/v1/logs",
        json={
            "pond_id": str(pond.id),
            "recorded_at": datetime.now(UTC).isoformat(),
            "dissolved_oxygen_mgl": 1.0,
        },
        headers=admin_headers,
    )
    alert_id = (await db_client.get(f"/v1/alerts?pond_id={pond.id}", headers=admin_headers)).json()[
        "items"
    ][0]["id"]

    farmer_token = create_access_token(sub=str(uuid4()), role="farmer", pond_ids=[])
    farmer_headers = {"Authorization": f"Bearer {farmer_token}"}

    resp = await db_client.post(f"/v1/alerts/{alert_id}/ack", json={}, headers=farmer_headers)
    assert resp.status_code == 403


@pytest.mark.integration
@pytest.mark.asyncio(loop_scope="session")
async def test_ack_unknown_alert_returns_404(db_client: AsyncClient) -> None:
    resp = await db_client.post(f"/v1/alerts/{uuid4()}/ack", json={}, headers=_admin_headers())
    assert resp.status_code == 404


@pytest.mark.integration
@pytest.mark.asyncio(loop_scope="session")
async def test_blind_state_pond_produces_suppressed_alert(
    db_session: AsyncSession, db_client: AsyncClient
) -> None:
    """A DO breach on a pond whose only prior reading is stale (> the
    configured threshold) must still surface the alert — suppressed=True,
    never silently dropped."""
    from app.db.models.log import Log

    pond = await _seed_pond(db_session)
    stale_log = Log(
        pond_id=pond.id,
        recorded_at=datetime.now(UTC) - timedelta(hours=48),
        recorded_by=uuid4(),
        dissolved_oxygen_mgl=6.0,
        source="manual",
    )
    db_session.add(stale_log)
    await db_session.commit()

    headers = _admin_headers()
    resp = await db_client.post(
        "/v1/logs",
        json={
            "pond_id": str(pond.id),
            "recorded_at": (datetime.now(UTC) - timedelta(hours=47)).isoformat(),
            "dissolved_oxygen_mgl": 1.0,
        },
        headers=headers,
    )
    assert resp.status_code == 201, resp.text

    alerts_resp = await db_client.get(f"/v1/alerts?pond_id={pond.id}", headers=headers)
    items = alerts_resp.json()["items"]
    assert len(items) == 1
    assert items[0]["suppressed"] is True
    assert items[0]["suppression_reason"] is not None
