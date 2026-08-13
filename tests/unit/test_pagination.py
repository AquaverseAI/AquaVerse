"""Unit tests for pagination helpers."""

from __future__ import annotations

import pytest

from app.core.pagination import CursorPage, clamp_limit, decode_cursor, encode_cursor


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
