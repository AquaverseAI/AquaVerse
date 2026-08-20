"""XLSX report generation using openpyxl (P3.2).

`GET /v1/reports/export?format=xlsx` used to return a fake `job_id` that
never progressed to an actual file. This renders a real workbook — one
sheet per pond, one row per real `Log` entry.
"""

from __future__ import annotations

import re
from io import BytesIO
from typing import TYPE_CHECKING
from uuid import UUID

from openpyxl import Workbook
from openpyxl.styles import Font

if TYPE_CHECKING:
    from app.db.models.log import Log
    from app.db.models.pond import Pond

_HEADERS = [
    "Recorded At (UTC)",
    "Temperature (C)",
    "Dissolved Oxygen (mg/L)",
    "pH",
    "Salinity (ppt)",
    "Ammonia (mg/L)",
    "Turbidity (NTU)",
]

# Excel sheet titles: 31 chars max, and reject [ ] : * ? / \
_INVALID_SHEET_CHARS = re.compile(r"[\[\]:*?/\\]")


def _sheet_title(pond: Pond) -> str:
    safe = _INVALID_SHEET_CHARS.sub("-", pond.name).strip() or str(pond.id)
    return safe[:31]


def render_pond_report_xlsx(*, ponds: list[Pond], logs_by_pond: dict[UUID, list[Log]]) -> bytes:
    wb = Workbook()
    used_titles: set[str] = set()

    if not ponds:
        sheet = wb.active
        sheet.title = "Report"
        sheet.append(["No ponds in scope for this export."])
        return _save(wb)

    first = True
    for pond in ponds:
        sheet = wb.active if first else wb.create_sheet()
        first = False

        title = _sheet_title(pond)
        # Sheet titles must be unique within a workbook — disambiguate
        # ponds that share a (truncated) name.
        deduped = title
        suffix = 2
        while deduped in used_titles:
            deduped = f"{title[:28]}-{suffix}"
            suffix += 1
        used_titles.add(deduped)
        sheet.title = deduped

        sheet.append(_HEADERS)
        for cell in sheet[1]:
            cell.font = Font(bold=True)

        for entry in logs_by_pond.get(pond.id, []):
            sheet.append(
                [
                    entry.recorded_at.isoformat(),
                    entry.temperature_c,
                    entry.dissolved_oxygen_mgl,
                    entry.ph,
                    entry.salinity_ppt,
                    entry.ammonia_nh3_mgl,
                    entry.turbidity_ntu,
                ]
            )

    return _save(wb)


def _save(wb: Workbook) -> bytes:
    buf = BytesIO()
    wb.save(buf)
    return buf.getvalue()
