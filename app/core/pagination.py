"""Cursor pagination helpers — generic, type-safe.

Two cursor formats are supported, both opaque base64(JSON) strings:

1. **Single-value cursor** — ``encode_cursor(value)`` / ``decode_cursor(cursor)``.
   Encodes one arbitrary value as ``{"v": str(value)}``. This is the original,
   simplest form; kept for callers that only ever sort on one unique column
   (e.g. a monotonic id) where no tie-breaking is needed.

2. **Keyset (composite) cursor** — ``encode_keyset_cursor(sort_value, id_)`` /
   ``decode_keyset_cursor(cursor)``. Encodes a ``(sort_value, id)`` pair as
   ``{"s": str(sort_value), "i": str(id_)}``. This is real keyset pagination:
   ``sort_value`` is the primary sort column (e.g. ``recorded_at``) and ``id``
   is a unique tie-breaker for rows that share the same ``sort_value``. A
   listing endpoint applies it as a WHERE clause of the form
   ``(sort_value, id) < (:last_sort_value, :last_id)`` (for a DESC-ordered
   listing), which is what makes pagination stable under concurrent inserts —
   unlike ``OFFSET``, which skips/duplicates rows as the underlying table
   changes between page fetches.

   Both parts round-trip as strings — it's the caller's job to parse them
   back into the right type (e.g. ``datetime.fromisoformat`` / ``UUID(...)``)
   since this module has no knowledge of the sort column's type.
"""

from __future__ import annotations

import base64
import json
from typing import TYPE_CHECKING, Generic, TypeVar

from pydantic import BaseModel, Field

if TYPE_CHECKING:
    from uuid import UUID

T = TypeVar("T")

_MAX_LIMIT = 200
_DEFAULT_LIMIT = 50


# ---------------------------------------------------------------------------
# Response envelope
# ---------------------------------------------------------------------------
class CursorPage(BaseModel, Generic[T]):
    """
    Cursor-paginated response envelope.

    Usage in a router:
        return CursorPage[MyItem](items=rows, next_cursor=encode_cursor(last_id))
    """

    items: list[T]
    next_cursor: str | None = Field(
        default=None,
        description="Opaque cursor for the next page. None when this is the last page.",
    )
    total_hint: int | None = Field(
        default=None,
        description=(
            "Optional approximate total — use for progress bars only, "
            "not for exact counts (may be stale)."
        ),
    )


# ---------------------------------------------------------------------------
# Cursor encode / decode
# ---------------------------------------------------------------------------
def encode_cursor(value: object) -> str:
    """Encode an arbitrary value (typically UUID or timestamp str) as a cursor."""
    raw = json.dumps({"v": str(value)}).encode()
    return base64.urlsafe_b64encode(raw).decode()


def decode_cursor(cursor: str | None) -> str | None:
    """Decode a cursor string; returns None for empty/invalid cursors."""
    if not cursor:
        return None
    try:
        raw = base64.urlsafe_b64decode(cursor.encode())
        data = json.loads(raw)
        if isinstance(data, dict):
            val = data.get("v")
            return str(val) if val is not None else None
        return None
    except Exception:
        return None


def encode_keyset_cursor(sort_value: object, id_: UUID | str) -> str:
    """
    Encode a ``(sort_value, id)`` keyset pair as an opaque cursor.

    Usage in a router (DESC-ordered listing):
        return CursorPage[MyItem](
            items=rows,
            next_cursor=encode_keyset_cursor(last_row.sort_col, last_row.id),
        )
    """
    raw = json.dumps({"s": str(sort_value), "i": str(id_)}).encode()
    return base64.urlsafe_b64encode(raw).decode()


def decode_keyset_cursor(cursor: str | None) -> tuple[str, str] | None:
    """
    Decode a keyset cursor into its ``(sort_value, id)`` string pair.

    Returns None for empty/invalid/malformed cursors (including single-value
    cursors produced by ``encode_cursor`` — the two formats are distinct and
    do not decode as each other). The caller is responsible for parsing the
    returned strings into the sort column's real type and a UUID.
    """
    if not cursor:
        return None
    try:
        raw = base64.urlsafe_b64decode(cursor.encode())
        data = json.loads(raw)
        if isinstance(data, dict) and "s" in data and "i" in data:
            return str(data["s"]), str(data["i"])
        return None
    except Exception:
        return None


# ---------------------------------------------------------------------------
# Limit sanitiser
# ---------------------------------------------------------------------------
def clamp_limit(limit: int | None) -> int:
    """Clamp a client-supplied limit to valid bounds."""
    if limit is None or limit < 1:
        return _DEFAULT_LIMIT
    return min(limit, _MAX_LIMIT)
