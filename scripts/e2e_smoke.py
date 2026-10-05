#!/usr/bin/env python3
"""Authenticated smoke test for a running AquaVerse stack (MSW is not involved)."""

from __future__ import annotations

import os
import sys
import time
from typing import Any

import httpx

BASE_URL = os.getenv("AQUAVERSE_BASE_URL", "http://localhost:8000").rstrip("/")
USERNAME = os.getenv("AQUAVERSE_SMOKE_USERNAME", "aquaverse_admin")
PASSWORD = os.getenv("AQUAVERSE_SMOKE_PASSWORD", "AquaAdmin@2026!")


def request(client: httpx.Client, method: str, path: str, **kwargs: Any) -> Any:
    response = client.request(method, path, **kwargs)
    if not response.is_success:
        raise RuntimeError(f"{method} {path}: HTTP {response.status_code}: {response.text[:300]}")
    print(f"PASS {method:4} {path}")
    return response.json()


def main() -> int:
    with httpx.Client(base_url=BASE_URL, timeout=30) as client:
        request(client, "GET", "/v1/health")
        token = request(
            client,
            "POST",
            "/v1/auth/token",
            json={"grant_type": "password", "username": USERNAME, "password": PASSWORD},
        )["access_token"]
        client.headers["Authorization"] = f"Bearer {token}"
        request(client, "GET", "/v1/auth/me")
        ponds = request(client, "GET", "/v1/ponds")
        if not ponds.get("items"):
            raise RuntimeError("GET /v1/ponds returned no seeded ponds")
        pond_id = ponds["items"][0]["id"]

        checks = [
            ("GET", f"/v1/ponds/{pond_id}"),
            ("GET", f"/v1/logs?pond_id={pond_id}"),
            ("GET", f"/v1/ponds/{pond_id}/risk"),
            ("GET", f"/v1/ponds/{pond_id}/forecast/do"),
            ("GET", f"/v1/twin/{pond_id}/state"),
            ("GET", "/v1/geo/ponds"),
            ("GET", "/v1/alerts"),
            ("GET", "/v1/advisories"),
            ("GET", "/v1/models"),
            ("GET", "/v1/data-quality"),
        ]
        for method, path in checks:
            request(client, method, path)

        report = request(client, "GET", "/v1/reports/export?format=pdf")
        job_id = report["job_id"]
        for _ in range(30):
            state = request(client, "GET", f"/v1/reports/export/{job_id}")
            if state["status"] == "completed":
                if not state.get("download_url"):
                    raise RuntimeError("Completed report has no download URL")
                print("PASS report artifact ready")
                return 0
            if state["status"] == "failed":
                raise RuntimeError(f"Report failed: {state.get('error')}")
            time.sleep(1)
        raise RuntimeError("Report job did not finish within 30 seconds")


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except Exception as exc:
        print(f"FAIL {exc}", file=sys.stderr)
        raise SystemExit(1) from exc
