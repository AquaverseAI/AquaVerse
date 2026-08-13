"""Cursor pagination helpers — generic, type-safe."""

from __future__ import annotations

import base64
import json
from typing import Generic, TypeVar

from pydantic import BaseModel, Field

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


# ---------------------------------------------------------------------------
# Limit sanitiser
# ---------------------------------------------------------------------------
def clamp_limit(limit: int | None) -> int:
    """Clamp a client-supplied limit to valid bounds."""
    if limit is None or limit < 1:
        return _DEFAULT_LIMIT
    return min(limit, _MAX_LIMIT)
