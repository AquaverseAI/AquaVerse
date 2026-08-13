"""
Number Validator Smoke Test Script.

Deliberately feeds a mismatched numeral to the validator and asserts rejection.
Run: python scripts/check_number_validator.py

Exit code 0 = guardrail is working correctly.
Exit code 1 = guardrail is broken — DO NOT deploy.
"""

from __future__ import annotations

import sys

sys.path.insert(0, ".")

from app.advisory.metrics import get_rejected_attempts, reset_rejected_attempts
from app.advisory.number_validator import validate_llm_output
from app.core.errors import NumberMismatchError


def test_rejects_mismatched_numeral() -> None:
    """The validator MUST reject LLM output containing a numeral not in the payload."""
    reset_rejected_attempts()

    payload = {"risk_score": 0.72, "components": {"chemistry": 0.68}}
    bad_output = "The pond risk score is 0.85 — action required."  # 0.85 not in payload

    try:
        validate_llm_output(bad_output, payload)
        print("FAIL: Validator did NOT reject mismatched numeral 0.85")
        print("      This means the guardrail is BROKEN. Do not deploy.")
        sys.exit(1)
    except NumberMismatchError as e:
        print(f"PASS: Validator correctly REJECTED output containing 0.85")
        print(f"      Error: {e}")

    assert get_rejected_attempts() == 1, (
        f"FAIL: expected rejected_attempts=1, got {get_rejected_attempts()}"
    )
    print(f"PASS: rejected_attempts counter = {get_rejected_attempts()}")


def test_allows_matching_numeral() -> None:
    """The validator MUST allow LLM output that only uses payload numerals."""
    reset_rejected_attempts()

    payload = {"risk_score": 0.72, "components": {"chemistry": 0.68}}
    good_output = "The pond risk score is 0.72. Chemistry component: 0.68."

    try:
        validate_llm_output(good_output, payload)
        print("PASS: Validator correctly ALLOWED output with matching numerals")
    except NumberMismatchError as e:
        print(f"FAIL: Validator incorrectly REJECTED valid output: {e}")
        sys.exit(1)

    assert get_rejected_attempts() == 0
    print(f"PASS: rejected_attempts counter = {get_rejected_attempts()} (expected 0)")


def main() -> None:
    print("=" * 60)
    print("AquaVerse AI — Number Validator Smoke Test")
    print("=" * 60)
    print()

    test_rejects_mismatched_numeral()
    print()
    test_allows_matching_numeral()
    print()
    print("=" * 60)
    print("ALL SMOKE TESTS PASSED — guardrail is operational.")
    print("=" * 60)


if __name__ == "__main__":
    main()
