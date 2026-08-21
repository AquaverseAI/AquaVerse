"""Unit tests — real Prometheus metrics snapshot (P2.7)."""

from __future__ import annotations

import os

os.environ.setdefault("DATABASE_URL", "postgresql+asyncpg://x:x@localhost/x")
os.environ.setdefault("APP_SECRET_KEY", "test_secret_key_minimum_32_chars_here")
os.environ.setdefault("INTERNAL_API_TOKEN", "test_internal_token_minimum_32_chars")

from app.core.metrics import REQUEST_COUNT, REQUEST_LATENCY, snapshot


def test_snapshot_reflects_real_recorded_observations() -> None:
    before = snapshot()

    REQUEST_COUNT.labels(method="GET", path="/v1/test", status_code=200).inc()
    REQUEST_LATENCY.labels(method="GET", path="/v1/test").observe(0.05)

    after = snapshot()
    assert after["total_requests"] == before["total_requests"] + 1
    assert after["avg_latency_ms"] >= 0.0
    assert after["p95_latency_ms"] >= 0.0
    assert after["p99_latency_ms"] >= 0.0


def test_snapshot_handles_no_data_without_error() -> None:
    # Real process-wide counters may or may not have data depending on
    # test order — this just asserts the read never raises and never
    # goes negative.
    result = snapshot()
    assert result["total_requests"] >= 0.0
    assert result["avg_latency_ms"] >= 0.0
