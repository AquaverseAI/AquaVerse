"""
Unit tests for the number validator — THE GUARDRAIL.

The smoke test deliberately feeds a mismatched numeral and asserts rejection.
This test MUST pass before any LLM adapter is reachable by a client.
"""

from __future__ import annotations

import pytest

from app.advisory.metrics import get_rejected_attempts, reset_rejected_attempts
from app.advisory.number_validator import (
    build_allowed_set,
    extract_numerals,
    validate_llm_output,
)
from app.core.errors import NumberMismatchError


@pytest.fixture(autouse=True)
def reset_counter() -> None:
    """Reset the rejected_attempts counter before each test."""
    reset_rejected_attempts()


# ---------------------------------------------------------------------------
# extract_numerals
# ---------------------------------------------------------------------------
@pytest.mark.unit
class TestExtractNumerals:
    def test_integers(self) -> None:
        assert extract_numerals("score is 72 out of 100") == ["72", "100"]

    def test_decimals(self) -> None:
        assert extract_numerals("risk: 0.72, DO: 4.2 mg/L") == ["0.72", "4.2"]

    def test_negative(self) -> None:
        assert extract_numerals("delta is -1.5 degrees") == ["-1.5"]

    def test_no_numerals(self) -> None:
        assert extract_numerals("no numbers here") == []

    def test_mixed(self) -> None:
        result = extract_numerals("100 ponds, risk 0.35, DO 6.5 mg/L")
        assert "100" in result
        assert "0.35" in result
        assert "6.5" in result


# ---------------------------------------------------------------------------
# build_allowed_set
# ---------------------------------------------------------------------------
@pytest.mark.unit
class TestBuildAllowedSet:
    def test_nested_dict(self) -> None:
        payload = {
            "risk_score": 0.72,
            "components": {"chemistry": 0.68, "health": 0.75},
        }
        allowed = build_allowed_set(payload)
        assert "0.72" in allowed or any(
            abs(float(a) - 0.72) < 1e-6 for a in allowed if _is_float(a)
        )

    def test_list_values(self) -> None:
        payload = {"values": [1.0, 2.5, 3.0]}
        allowed = build_allowed_set(payload)
        assert any(abs(float(a) - 2.5) < 1e-6 for a in allowed if _is_float(a))


# ---------------------------------------------------------------------------
# validate_llm_output — the guardrail
# ---------------------------------------------------------------------------
@pytest.mark.unit
class TestValidateLLMOutput:
    def test_valid_output_passes(self) -> None:
        """Output that only uses numbers from the payload should pass."""
        payload = {"risk_score": 0.72, "components": {"chemistry": 0.68}}
        output = "The pond risk score is 0.72. Chemistry risk is 0.68."
        # Should not raise
        validate_llm_output(output, payload)
        assert get_rejected_attempts() == 0

    def test_mismatched_numeral_raises(self) -> None:
        """
        SMOKE TEST: Output containing a numeral NOT in the payload must be rejected.
        This is the core guardrail behaviour.
        """
        payload = {"risk_score": 0.72}
        output = "The pond risk score is 0.85."  # 0.85 is NOT in payload
        with pytest.raises(NumberMismatchError):
            validate_llm_output(output, payload)
        # Counter must increment on rejection
        assert get_rejected_attempts() == 1

    def test_multiple_violations(self) -> None:
        """Multiple mismatched numerals all cause rejection."""
        payload = {"risk_score": 0.5}
        output = "Scores: 0.72 and 0.99 detected."
        with pytest.raises(NumberMismatchError):
            validate_llm_output(output, payload)
        assert get_rejected_attempts() == 1

    def test_empty_output_passes(self) -> None:
        """Empty LLM output has no numerals — should pass."""
        validate_llm_output("", {"risk_score": 0.5})
        assert get_rejected_attempts() == 0

    def test_text_only_passes(self) -> None:
        """Text with no numerals should always pass."""
        validate_llm_output("Monitor your pond carefully.", {"risk_score": 0.5})
        assert get_rejected_attempts() == 0

    def test_counter_accumulates(self) -> None:
        """Counter accumulates across multiple rejections."""
        payload = {"risk_score": 0.5}
        for _ in range(3):
            with pytest.raises(NumberMismatchError):
                validate_llm_output("Score is 0.99.", payload)
        assert get_rejected_attempts() == 3

    def test_float_tolerance(self) -> None:
        """Tiny floating point representation differences should not cause rejection."""
        payload = {"risk_score": 0.7200000000001}
        output = "Risk score is 0.72."
        # Should not raise — within tolerance
        validate_llm_output(output, payload)


def _is_float(s: str) -> bool:
    try:
        float(s)
        return True
    except ValueError:
        return False
