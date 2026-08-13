"""
Advisory metrics — rejected_attempts counter.

Exposed on GET /v1/models/metrics.
MUST read 0 in steady state.
"""

from __future__ import annotations

import threading

from prometheus_client import Counter

# Prometheus counter (persists for the lifetime of the process)
_REJECTED_ATTEMPTS_COUNTER = Counter(
    "llm_rejected_attempts_total",
    "Number of LLM responses rejected because they contained a numeral "
    "not present in the quantitative tool-call payload. Must be 0 in steady state.",
)

# In-memory counter for the REST API response (fast read, no Prometheus scrape needed)
_in_memory_count: int = 0
_lock = threading.Lock()


def increment_rejected_attempts() -> None:
    """Increment both the Prometheus counter and the in-memory counter."""
    global _in_memory_count
    _REJECTED_ATTEMPTS_COUNTER.inc()
    with _lock:
        _in_memory_count += 1


def get_rejected_attempts() -> int:
    """Return the current rejected_attempts count for the REST API."""
    with _lock:
        return _in_memory_count


def reset_rejected_attempts() -> None:
    """
    Reset the in-memory counter.
    Used in tests only — Prometheus counter is never reset (monotonic by design).
    """
    global _in_memory_count
    with _lock:
        _in_memory_count = 0
