"""Unit tests — real PSI computation (P2.7), no network/containers."""

from __future__ import annotations

import os
import random

os.environ.setdefault("DATABASE_URL", "postgresql+asyncpg://x:x@localhost/x")
os.environ.setdefault("APP_SECRET_KEY", "test_secret_key_minimum_32_chars_here")
os.environ.setdefault("INTERNAL_API_TOKEN", "test_internal_token_minimum_32_chars")

from app.ml_inference.drift import _psi


def test_psi_is_near_zero_for_identical_distributions() -> None:
    rng = random.Random(1)
    baseline = [rng.gauss(7.5, 0.3) for _ in range(200)]
    same = [rng.gauss(7.5, 0.3) for _ in range(200)]
    assert _psi(baseline, same) < 0.1


def test_psi_is_large_for_shifted_distributions() -> None:
    rng = random.Random(1)
    baseline = [rng.gauss(7.5, 0.3) for _ in range(200)]
    shifted = [rng.gauss(9.5, 0.3) for _ in range(200)]
    assert _psi(baseline, shifted) > 0.2


def test_psi_returns_zero_below_minimum_sample_size() -> None:
    assert _psi([1.0, 2.0, 3.0], [1.0, 2.0, 3.0]) == 0.0


def test_psi_returns_zero_for_empty_inputs() -> None:
    assert _psi([], []) == 0.0
