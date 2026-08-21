"""Unit tests — real PDF/XLSX rendering (P3.2), no network/containers."""

from __future__ import annotations

import os
from datetime import UTC, datetime
from uuid import uuid4

os.environ.setdefault("DATABASE_URL", "postgresql+asyncpg://x:x@localhost/x")
os.environ.setdefault("APP_SECRET_KEY", "test_secret_key_minimum_32_chars_here")
os.environ.setdefault("INTERNAL_API_TOKEN", "test_internal_token_minimum_32_chars")

from app.db.models.log import Log
from app.db.models.pond import Pond
from app.reporting.pdf import render_pond_report_pdf
from app.reporting.xlsx import render_pond_report_xlsx


def _make_pond(name: str = "Test Pond") -> Pond:
    return Pond(id=uuid4(), owner_user_id=uuid4(), name=name, district="Nagapattinam")


def _make_log(pond_id, **overrides) -> Log:  # type: ignore[no-untyped-def]
    defaults = {
        "pond_id": pond_id,
        "recorded_at": datetime.now(UTC),
        "recorded_by": uuid4(),
        "temperature_c": 29.5,
        "dissolved_oxygen_mgl": 5.2,
        "ph": 7.8,
        "salinity_ppt": 15.0,
        "ammonia_nh3_mgl": 0.1,
        "turbidity_ntu": 12.0,
    }
    defaults.update(overrides)
    return Log(**defaults)


def test_render_pdf_produces_real_pdf_bytes() -> None:
    pond = _make_pond()
    logs = [_make_log(pond.id)]
    body = render_pond_report_pdf(
        title="Test Report",
        generated_at_iso=datetime.now(UTC).isoformat(),
        ponds=[pond],
        logs_by_pond={pond.id: logs},
    )
    assert body.startswith(b"%PDF-")
    assert len(body) > 500


def test_render_pdf_handles_no_ponds() -> None:
    body = render_pond_report_pdf(
        title="Empty Report",
        generated_at_iso=datetime.now(UTC).isoformat(),
        ponds=[],
        logs_by_pond={},
    )
    assert body.startswith(b"%PDF-")


def test_render_xlsx_produces_real_workbook_bytes() -> None:
    pond = _make_pond()
    logs = [_make_log(pond.id)]
    body = render_pond_report_xlsx(ponds=[pond], logs_by_pond={pond.id: logs})
    # XLSX is a zip container — PK magic bytes.
    assert body[:2] == b"PK"
    assert len(body) > 100


def test_render_xlsx_dedupes_sheet_titles_for_same_named_ponds() -> None:
    pond_a = _make_pond(name="Same Name")
    pond_b = _make_pond(name="Same Name")
    body = render_pond_report_xlsx(
        ponds=[pond_a, pond_b], logs_by_pond={pond_a.id: [], pond_b.id: []}
    )
    assert body[:2] == b"PK"
