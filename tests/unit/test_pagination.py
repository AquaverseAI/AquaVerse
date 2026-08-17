"""Unit tests for pagination helpers."""

from __future__ import annotations

import pytest

from app.core.pagination import (
    CursorPage,
    clamp_limit,
    decode_cursor,
    decode_keyset_cursor,
    encode_cursor,
    encode_keyset_cursor,
)


@pytest.mark.unit
class TestCursorEncoding:
    def test_roundtrip_string(self) -> None:
        val = "00000000-0000-0000-0000-000000000001"
        assert decode_cursor(encode_cursor(val)) == val

    def test_roundtrip_uuid(self) -> None:
        from uuid import uuid4

        val = str(uuid4())
        assert decode_cursor(encode_cursor(val)) == val

    def test_none_cursor_returns_none(self) -> None:
        assert decode_cursor(None) is None

    def test_empty_cursor_returns_none(self) -> None:
        assert decode_cursor("") is None

    def test_invalid_cursor_returns_none(self) -> None:
        assert decode_cursor("not-valid-base64!!") is None


@pytest.mark.unit
class TestKeysetCursorEncoding:
    """Composite (sort_value, id) keyset cursor — the format list_logs uses."""

    def test_roundtrip_datetime_and_uuid(self) -> None:
        from datetime import UTC, datetime
        from uuid import uuid4

        recorded_at = datetime(2026, 8, 17, 12, 30, 0, tzinfo=UTC)
        log_id = uuid4()

        cursor = encode_keyset_cursor(recorded_at.isoformat(), log_id)
        decoded = decode_keyset_cursor(cursor)

        assert decoded is not None
        sort_value_str, id_str = decoded
        # Round-trips as strings; caller re-parses into real types.
        assert datetime.fromisoformat(sort_value_str) == recorded_at
        assert id_str == str(log_id)

    def test_distinct_rows_produce_distinct_cursors(self) -> None:
        """Two rows sharing the same recorded_at must still get distinct
        cursors — the id tie-breaker is what makes keyset pagination exact
        for rows with identical sort values (unlike a bare OFFSET)."""
        from datetime import UTC, datetime
        from uuid import uuid4

        same_time = datetime(2026, 8, 17, 12, 30, 0, tzinfo=UTC).isoformat()
        id_a, id_b = uuid4(), uuid4()

        cursor_a = encode_keyset_cursor(same_time, id_a)
        cursor_b = encode_keyset_cursor(same_time, id_b)

        assert cursor_a != cursor_b
        assert decode_keyset_cursor(cursor_a) == (same_time, str(id_a))
        assert decode_keyset_cursor(cursor_b) == (same_time, str(id_b))

    def test_none_cursor_returns_none(self) -> None:
        assert decode_keyset_cursor(None) is None

    def test_empty_cursor_returns_none(self) -> None:
        assert decode_keyset_cursor("") is None

    def test_invalid_cursor_returns_none(self) -> None:
        assert decode_keyset_cursor("not-valid-base64!!") is None

    def test_single_value_cursor_does_not_decode_as_keyset(self) -> None:
        """The two cursor formats are distinct — a plain encode_cursor()
        cursor (no id component) must not be silently accepted here."""
        cursor = encode_cursor("00000000-0000-0000-0000-000000000001")
        assert decode_keyset_cursor(cursor) is None

    def test_keyset_cursor_does_not_decode_as_single_value(self) -> None:
        from uuid import uuid4

        cursor = encode_keyset_cursor("2026-08-17T12:30:00+00:00", uuid4())
        assert decode_cursor(cursor) is None


@pytest.mark.unit
class TestClampLimit:
    def test_default(self) -> None:
        assert clamp_limit(None) == 50

    def test_zero_returns_default(self) -> None:
        assert clamp_limit(0) == 50

    def test_negative_returns_default(self) -> None:
        assert clamp_limit(-5) == 50

    def test_max_clamp(self) -> None:
        assert clamp_limit(9999) == 200

    def test_valid_value(self) -> None:
        assert clamp_limit(25) == 25


@pytest.mark.unit
class TestCursorPage:
    def test_empty_page(self) -> None:
        page: CursorPage[str] = CursorPage(items=[], next_cursor=None)
        assert page.items == []
        assert page.next_cursor is None

    def test_page_with_items(self) -> None:
        page: CursorPage[str] = CursorPage(items=["a", "b"], next_cursor="cursor123")
        assert len(page.items) == 2
        assert page.next_cursor == "cursor123"
