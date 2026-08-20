"""Prometheus HTTP metrics (P2.7).

`REQUEST_COUNT`/`REQUEST_LATENCY` live here rather than in `app/main.py`
so `GET /v1/models/metrics` (app/ml_inference/router.py) can read the
real, process-wide values instead of hardcoding `total_requests: 0` /
`avg_latency_ms: 0.0` regardless of actual traffic — `app/main.py`'s
middleware still owns *recording* into them.
"""

from __future__ import annotations

from prometheus_client import Counter, Histogram

REQUEST_COUNT = Counter(
    "http_requests_total",
    "Total HTTP requests",
    ["method", "path", "status_code"],
)
REQUEST_LATENCY = Histogram(
    "http_request_duration_seconds",
    "HTTP request latency in seconds",
    ["method", "path"],
    buckets=[0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1.0, 2.5, 5.0, 10.0],
)


def _quantile_from_buckets(
    buckets: dict[float, float], total_count: float, quantile: float
) -> float:
    """Approximate a quantile from cumulative Histogram bucket counts via
    linear interpolation within the bucket that crosses it — the standard
    technique for estimating a quantile from Prometheus-style bucketed
    histograms (an exact value would need the raw per-request samples,
    which Histogram never retains)."""
    if not buckets or total_count <= 0:
        return 0.0
    target = quantile * total_count
    sorted_bounds = sorted(b for b in buckets if b != float("inf"))
    prev_bound = 0.0
    prev_count = 0.0
    for bound in sorted_bounds:
        count = buckets[bound]
        if count >= target:
            if count == prev_count:
                return bound
            fraction = (target - prev_count) / (count - prev_count)
            return prev_bound + fraction * (bound - prev_bound)
        prev_bound = bound
        prev_count = count
    # Target falls in the +Inf overflow bucket — no upper bound to
    # interpolate against; the last finite boundary is the best available
    # floor estimate.
    return sorted_bounds[-1] if sorted_bounds else 0.0


def snapshot() -> dict[str, float]:
    """Real, process-wide read of the counters above: total request
    count and mean/p95/p99 latency, aggregated across every
    method/path/status label combination — the same aggregate-then-quantile
    approach Prometheus's own `histogram_quantile(sum by (le) (...))`
    uses for a multi-series histogram."""
    total_requests = 0.0
    for metric in REQUEST_COUNT.collect():
        for sample in metric.samples:
            if sample.name == "http_requests_total":
                total_requests += sample.value

    total_count = 0.0
    total_sum = 0.0
    buckets: dict[float, float] = {}
    for metric in REQUEST_LATENCY.collect():
        for sample in metric.samples:
            if sample.name == "http_request_duration_seconds_count":
                total_count += sample.value
            elif sample.name == "http_request_duration_seconds_sum":
                total_sum += sample.value
            elif sample.name == "http_request_duration_seconds_bucket":
                le = float(sample.labels["le"])
                buckets[le] = buckets.get(le, 0.0) + sample.value

    avg_latency_s = (total_sum / total_count) if total_count else 0.0
    p95_s = _quantile_from_buckets(buckets, total_count, 0.95)
    p99_s = _quantile_from_buckets(buckets, total_count, 0.99)

    return {
        "total_requests": total_requests,
        "avg_latency_ms": avg_latency_s * 1000,
        "p95_latency_ms": p95_s * 1000,
        "p99_latency_ms": p99_s * 1000,
    }
