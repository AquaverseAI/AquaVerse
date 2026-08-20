"""PDF report generation using ReportLab (P3.2).

`GET /v1/reports/export?format=pdf` used to return a fake `job_id` that
never progressed to an actual file. This renders a real per-pond water
quality report from real `Log` rows.
"""

from __future__ import annotations

from io import BytesIO
from typing import TYPE_CHECKING
from uuid import UUID

from reportlab.lib import colors
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import getSampleStyleSheet
from reportlab.lib.units import cm
from reportlab.platypus import Paragraph, SimpleDocTemplate, Spacer, Table, TableStyle

if TYPE_CHECKING:
    from app.db.models.log import Log
    from app.db.models.pond import Pond

_TABLE_HEADER = ["Recorded At (UTC)", "Temp °C", "DO mg/L", "pH", "Salinity ppt", "Ammonia mg/L"]


def _fmt(value: float | None) -> str:
    return f"{value:.2f}" if value is not None else "—"


def render_pond_report_pdf(
    *,
    title: str,
    generated_at_iso: str,
    ponds: list[Pond],
    logs_by_pond: dict[UUID, list[Log]],
) -> bytes:
    """Render a real PDF: one section per pond, one table row per log."""
    buf = BytesIO()
    doc = SimpleDocTemplate(buf, pagesize=A4, topMargin=1.5 * cm, bottomMargin=1.5 * cm)
    styles = getSampleStyleSheet()

    story = [
        Paragraph(title, styles["Title"]),
        Paragraph(f"Generated at {generated_at_iso}", styles["Normal"]),
        Spacer(1, 0.5 * cm),
    ]

    if not ponds:
        story.append(Paragraph("No ponds in scope for this export.", styles["Normal"]))

    for pond in ponds:
        story.append(Paragraph(f"{pond.name} — {pond.district}", styles["Heading2"]))
        logs = logs_by_pond.get(pond.id, [])
        if not logs:
            story.append(Paragraph("No log entries in the requested date range.", styles["Normal"]))
            story.append(Spacer(1, 0.5 * cm))
            continue

        data: list[list[str]] = [_TABLE_HEADER]
        for entry in logs:
            data.append(
                [
                    entry.recorded_at.isoformat(),
                    _fmt(entry.temperature_c),
                    _fmt(entry.dissolved_oxygen_mgl),
                    _fmt(entry.ph),
                    _fmt(entry.salinity_ppt),
                    _fmt(entry.ammonia_nh3_mgl),
                ]
            )
        table = Table(data, repeatRows=1)
        table.setStyle(
            TableStyle(
                [
                    ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#0f766e")),
                    ("TEXTCOLOR", (0, 0), (-1, 0), colors.white),
                    ("FONTSIZE", (0, 0), (-1, -1), 8),
                    ("GRID", (0, 0), (-1, -1), 0.25, colors.grey),
                    (
                        "ROWBACKGROUNDS",
                        (0, 1),
                        (-1, -1),
                        [colors.white, colors.HexColor("#f1f5f9")],
                    ),
                ]
            )
        )
        story.append(table)
        story.append(Spacer(1, 0.5 * cm))

    doc.build(story)
    return buf.getvalue()
