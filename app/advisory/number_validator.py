"""
Number Validator — THE GUARDRAIL.

Architecture rule (non-negotiable):
  The reasoning layer (Qwen3-8B + LoRA) is architecturally FORBIDDEN from emitting
  any numeral that the quantitative layer did not produce.

Enforcement:
  1. Regex-extract every numeral from the raw LLM output string.
  2. Cross-check each extracted numeral against the allowed set from the tool-call payload.
  3. On ANY mismatch → raise NumberMismatchError (caller must reject + regenerate).
  4. Increment `rejected_attempts` counter.

This check runs SERVER-SIDE in the request path — never as a client-side validation.
"""

from __future__ import annotations

import re
from typing import Any

import structlog

from app.advisory.metrics import increment_rejected_attempts
from app.core.errors import NumberMismatchError

log = structlog.get_logger(__name__)

# Regex that matches integers and decimals (positive and negative)
# Examples matched: 0.72, 6.5, 4.2, -1.3, 12, 100, 0.001
_NUMERAL_RE = re.compile(r"-?\d+(?:\.\d+)?")

# Allowed relative tolerance for float comparisons
# A numeral from LLM output matches a payload value if abs(llm - allowed) / max(abs(allowed), 1e-9) <= this
_TOLERANCE = 1e-6


def extract_numerals(text: str) -> list[str]:
    """Extract all numeral strings from LLM output text."""
    return _NUMERAL_RE.findall(text)


def build_allowed_set(tool_call_payload: dict[str, Any]) -> set[str]:
    """
    Recursively walk the tool-call payload dict and collect every numeric value
    as a canonical string. This becomes the whitelist for the validator.
    """
    allowed: set[str] = set()
    _collect_numerals(tool_call_payload, allowed)
    return allowed


def _collect_numerals(obj: object, out: set[str]) -> None:

    if isinstance(obj, (int, float)):
        out.add(str(obj))
        # Also add rounded variants (e.g. 0.7200000000001 → "0.72")
        out.add(f"{obj:.6f}".rstrip("0").rstrip("."))
    elif isinstance(obj, str):
        for m in _NUMERAL_RE.findall(obj):
            out.add(m)
    elif isinstance(obj, dict):
        for v in obj.values():
            _collect_numerals(v, out)
    elif isinstance(obj, (list, tuple)):
        for item in obj:
            _collect_numerals(item, out)


def _is_allowed(numeral: str, allowed_set: set[str]) -> bool:
    """
    Check if a numeral string is allowed.
    Exact string match OR within float tolerance of any allowed value.
    """
    if numeral in allowed_set:
        return True
    try:
        n = float(numeral)
    except ValueError:
        return False
    for a in allowed_set:
        try:
            av = float(a)
            if abs(n - av) <= _TOLERANCE * max(abs(av), 1e-9):
                return True
        except ValueError:
            continue
    return False


def validate_llm_output(
    llm_output: str,
    tool_call_payload: dict[str, Any],
) -> None:
    """
    Validate that every numeral in `llm_output` exists in `tool_call_payload`.

    Raises:
        NumberMismatchError: if any numeral in the LLM output is not accounted for
                             by the quantitative tool-call payload.

    This function MUST be called before any LLM response is returned to a client.
    On NumberMismatchError, the caller should:
    1. Increment the rejected_attempts counter (done inside this function).
    2. Regenerate the LLM response (retry with same payload).
    3. Raise NumberMismatchError again after max retries exhausted.
    """
    extracted = extract_numerals(llm_output)
    allowed = build_allowed_set(tool_call_payload)

    violating: list[str] = [n for n in extracted if not _is_allowed(n, allowed)]

    if violating:
        increment_rejected_attempts()
        log.error(
            "number_validator.mismatch",
            violating_numerals=violating,
            allowed_count=len(allowed),
            output_preview=llm_output[:200],
        )
        raise NumberMismatchError(
            detail=(
                f"LLM output contains {len(violating)} numeral(s) not present in the "
                f"quantitative payload: {violating[:10]}. "
                "Response rejected. Regenerating."
            )
        )

    log.debug("number_validator.ok", extracted_count=len(extracted))
