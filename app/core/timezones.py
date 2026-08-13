"""Timezone helpers — UTC storage, Asia/Kolkata serving.

Rule:
- All datetime values are stored in the DB as UTC.
- All datetime values are served to clients in Asia/Kolkata (+05:30).
- Naive datetimes are NEVER returned from any API endpoint.
"""

from __future__ import annotations

from datetime import UTC, datetime
from zoneinfo import ZoneInfo

KOLKATA_TZ = ZoneInfo("Asia/Kolkata")
UTC_TZ = UTC


def utcnow() -> datetime:
    """Return the current UTC time as a timezone-aware datetime."""
    return datetime.now(UTC_TZ)


def to_kolkata(dt: datetime) -> datetime:
    """Convert any timezone-aware datetime to Asia/Kolkata."""
    if dt.tzinfo is None:
        raise ValueError(
            "Received a naive datetime. All datetimes must be timezone-aware. "
            "Use utcnow() to create timestamps."
        )
    return dt.astimezone(KOLKATA_TZ)


def to_utc(dt: datetime) -> datetime:
    """Normalise any timezone-aware datetime to UTC for DB storage."""
    if dt.tzinfo is None:
        raise ValueError("Received a naive datetime. All datetimes must be timezone-aware.")
    return dt.astimezone(UTC_TZ)


def ensure_utc(dt: datetime) -> datetime:
    """
    Accept a datetime that may already be UTC or may be in another zone.
    Returns UTC datetime. If naive, assumes UTC (logs a warning).
    """
    import structlog

    log = structlog.get_logger(__name__)
    if dt.tzinfo is None:
        log.warning("timezone.naive_datetime_assumed_utc", dt=str(dt))
        return dt.replace(tzinfo=UTC_TZ)
    return dt.astimezone(UTC_TZ)


def format_iso(dt: datetime) -> str:
    """Format a datetime as ISO 8601 with explicit +05:30 offset."""
    return to_kolkata(dt).isoformat()
