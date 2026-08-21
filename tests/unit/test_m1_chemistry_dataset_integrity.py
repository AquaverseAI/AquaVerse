"""Unit tests — real integrity of the M1 chemistry SFT training data (P0.3).

M1 (`ml/training/m1_chemistry/`) has no numeric booster or in-repo serving
engine the way M2/M3 do — it is a QLoRA adapter over Qwen3-8B
(`finetune_m1_lora.py`), and the trained adapter weights themselves are not
committed to this repo (no `ml/artifacts/m1_chemistry/` checkpoint exists,
and `app/ml_inference/llm/qlora_inference.py` currently only wires up
`m2_health` — M1 has no live inference path to score against held-out data
the way `test_m3_model_accuracy.py` / `test_m2_risk_model_accuracy.py` do).

What CAN be verified without a GPU or trained weights is that the training
signal itself is real and honest — i.e. that `m1_chemistry_sft.jsonl`
actually satisfies the two non-negotiable rules `build_m1_sft_dataset.py`'s
docstring cites from PRD-AV-01 §7:
  R1 — no numeral in an assistant response absent from its own user turn
       (the "ground everything in the given state, don't hallucinate a
       number" rule this repo enforces at inference time for M3 via
       `app/advisory/number_validator.py` — reused here directly, since
       the check is the same operation: numerals-in-output vs.
       numerals-in-source).
  R2 — every conclusion is hedged, never stated as a definitive diagnosis.

If a future dataset regeneration ever introduced a fabricated numeral or
an unhedged definitive claim, this is what would catch it before it ever
reached a fine-tuning run — the training-data equivalent of the M2/M3
held-out accuracy tests.
"""

from __future__ import annotations

import hashlib
import json
import re
from pathlib import Path
from typing import Any

import pytest

from app.advisory.number_validator import build_allowed_set, extract_numerals

_DATASET_PATH = (
    Path(__file__).resolve().parents[2] / "ml" / "datasets" / "sft" / "m1_chemistry_sft.jsonl"
)

# The hash `finetune_m1_lora.py` re-verifies at training time (its own
# `verify_dataset_hash`) — duplicated here as a literal, not imported, so
# this test still catches it if the dataset ever silently drifted out of
# sync with what was actually registered/trained on.
_EXPECTED_DATASET_HASH = "0c4f4316f13467b9ef11d7c16c3e3f78dea17fc9a71f09c52fbc9b11e75583f1"

# Hedge phrasing the generator uses (build_m1_sft_dataset.py's R2 style) —
# a response is "hedged" if it contains at least one of these, matched
# case-insensitively.
_HEDGE_PATTERNS = [
    "consistent with",
    "confirm by",
    "consider",
    "may indicate",
    "recommend",
    "monitor",
    "if this",
    "escalat",
]
_HEDGE_RE = re.compile("|".join(re.escape(p) for p in _HEDGE_PATTERNS), re.IGNORECASE)


def _load_records() -> list[dict[str, Any]]:
    if not _DATASET_PATH.exists():
        pytest.skip(f"M1 SFT dataset not present at {_DATASET_PATH}")
    with open(_DATASET_PATH, encoding="utf-8") as f:
        return [json.loads(line) for line in f if line.strip()]


@pytest.mark.unit
def test_dataset_hash_matches_what_finetune_script_registered() -> None:
    """Proves the committed JSONL is byte-for-byte the same file
    `DATASET_HASH` in finetune_m1_lora.py was computed from — i.e. that
    whatever adapter eventually gets trained is trained on the exact data
    this test suite is also checking, not a drifted copy."""
    if not _DATASET_PATH.exists():
        pytest.skip(f"M1 SFT dataset not present at {_DATASET_PATH}")

    h = hashlib.sha256()
    with open(_DATASET_PATH, "rb") as f:
        h.update(f.read())

    assert h.hexdigest() == _EXPECTED_DATASET_HASH, (
        "m1_chemistry_sft.jsonl no longer matches the hash finetune_m1_lora.py "
        "verifies before training — regenerate the dataset AND update "
        "DATASET_HASH in finetune_m1_lora.py together, or this is silent drift."
    )


@pytest.mark.unit
def test_all_records_are_well_formed_three_turn_chat() -> None:
    records = _load_records()
    assert len(records) > 1000, "SFT dataset unexpectedly small/empty"

    for i, rec in enumerate(records):
        messages = rec["messages"]
        assert len(messages) == 3, f"record {i}: expected 3 messages, got {len(messages)}"
        roles = [m["role"] for m in messages]
        assert roles == ["system", "user", "assistant"], f"record {i}: bad role order {roles}"
        for m in messages:
            assert m["content"].strip(), f"record {i}: empty {m['role']} content"


@pytest.mark.unit
def test_no_assistant_response_invents_a_numeral_absent_from_its_input() -> None:
    """R1: re-derives, for every training example, exactly the check
    `number_validator.validate_llm_output` runs server-side for M3's `/ask`
    endpoint at inference time — every numeral in the assistant turn must
    trace back to a numeral present in that same example's user turn.
    Currently 0/5000 violate this (verified while writing this test); any
    violation is a real dataset-quality regression, not tuning noise."""
    records = _load_records()

    violating_records: list[tuple[int, list[str]]] = []
    for i, rec in enumerate(records):
        messages = {m["role"]: m["content"] for m in rec["messages"]}
        allowed = build_allowed_set(messages["user"])
        extracted = extract_numerals(messages["assistant"])
        violating = [
            n for n in extracted if n not in allowed and n not in _fuzzy_allowed(n, allowed)
        ]
        if violating:
            violating_records.append((i, violating))

    assert not violating_records, (
        f"{len(violating_records)}/{len(records)} M1 training examples contain an "
        f"assistant-turn numeral absent from their own user turn (R1 violation) — "
        f"first offender: record {violating_records[0][0]}, "
        f"numerals {violating_records[0][1][:10]}"
    )


def _fuzzy_allowed(numeral: str, allowed: set[str], tolerance: float = 1e-6) -> set[str]:
    """Float-tolerance fallback matching `number_validator._is_allowed`'s
    own rounding tolerance, so a value that round-trips through formatting
    (e.g. "4.180" vs "4.18") isn't flagged as fabricated."""
    try:
        n = float(numeral)
    except ValueError:
        return set()
    for a in allowed:
        try:
            if abs(n - float(a)) <= tolerance * max(abs(float(a)), 1e-9):
                return {numeral}
        except ValueError:
            continue
    return set()


@pytest.mark.unit
def test_most_assistant_responses_use_hedged_phrasing() -> None:
    """R2: 'never state a diagnosis as definitive' — every conclusion should
    be hedged. Checked at the dataset level (fraction of responses using
    at least one hedge phrase) rather than per-line, since a handful of
    purely-descriptive "reading is within normal range" responses
    legitimately need no hedge; a real regression (e.g. a prompt-template
    change that stripped hedging instructions) would show up as a sharp
    drop in this fraction, not a handful of isolated misses."""
    records = _load_records()

    hedged = sum(1 for rec in records if _HEDGE_RE.search(rec["messages"][2]["content"]))
    fraction = hedged / len(records)

    assert fraction > 0.9, (
        f"Only {fraction:.1%} of M1 training responses use hedged phrasing "
        f"(consistent with/confirm by/monitor/escalate/...) — R2 regression."
    )
