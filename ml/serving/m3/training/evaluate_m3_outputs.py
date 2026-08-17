"""
Scores the fine-tuned model's OWN generations (from batch_inference_m3.py)
against 200 held-out examples. This is different from validate_sft_corpus.py
(which checked Kimi's training-data narrations) — this checks the trained
model's actual behavior on prompts it never saw.

Checks hallucination against the REAL structured payload (m3_payloads_final_50k.jsonl),
looked up by pond_id embedded in the instruction — not against Kimi's ground-truth
text, since that's a different (also valid but not identical) narration and
comparing against it would either be too strict (flagging legitimate rephrasing)
or too loose (missing real hallucination if Kimi's own text happened to omit
a number the model then invents).

Adds two checks the original validator didn't need, because they're specific
to live model generation rather than curated training data:
  - REPETITION_LOOP: the model re-states the same conclusion 3+ times
  - HARVEST_CONTRADICTION: model both gives a harvest projection AND says
    no projection is available (seen in real Studio-chat testing)
"""

from __future__ import annotations
import argparse
import json
import re
from pathlib import Path
from collections import Counter

from validate_sft_corpus import extract_numbers, payload_numbers, explainable_by_arithmetic


def detect_repetition_loop(text: str, min_repeats: int = 3) -> bool:
    """
    Flags text where a sentence (or near-duplicate of one) appears 3+ times.
    Catches exactly the "No feed today. Start again once..." looping pattern
    observed in Studio chat testing.
    """
    sentences = [s.strip().lower() for s in re.split(r'(?<=[.!?])\s+', text) if len(s.strip()) > 15]
    if len(sentences) < min_repeats:
        return False
    counts = Counter(sentences)
    if any(c >= min_repeats for c in counts.values()):
        return True
    # near-duplicate check: sentences sharing >70% of their words with an earlier one
    seen = []
    near_dup_count = 0
    for s in sentences:
        words = set(s.split())
        for prev in seen:
            prev_words = set(prev.split())
            overlap = len(words & prev_words) / max(len(words | prev_words), 1)
            if overlap > 0.7:
                near_dup_count += 1
                break
        seen.append(s)
    return near_dup_count >= min_repeats - 1


def detect_harvest_contradiction(text: str) -> bool:
    """
    Flags text that both states a specific harvest day/weight AND claims no
    projection is available - the exact bug seen in Test 2 (catfish) during
    manual Studio testing.
    """
    text_lower = text.lower()
    has_projection = bool(re.search(r'harvest.{0,30}(projected|in)\s+\d+\s+days?', text_lower))
    has_no_projection = any(phrase in text_lower for phrase in [
        "no reliable harvest", "didn't converge", "did not converge",
        "no projection available", "harvest timing can't be projected",
        "harvest timing cannot be projected",
    ])
    return has_projection and has_no_projection


def check_table_citation_logic(output_text: str, payload: dict | None) -> str | None:
    """Returns an issue string if table-citation logic is wrong, else None."""
    if payload is None:
        return None
    table_name = payload.get("manufacturer_table", "")
    hold = payload.get("feed_hold_recommended", False)
    if not hold and table_name and table_name not in output_text:
        return f"MISSING_TABLE_CITATION: '{table_name}' not named despite feeding being recommended"
    return None


def check_feed_hold_mention(output_text: str, payload: dict | None) -> str | None:
    if payload is None:
        return None
    if payload.get("feed_hold_recommended") and "hold" not in output_text.lower() \
            and "skip" not in output_text.lower() and "no feed" not in output_text.lower() \
            and "zero" not in output_text.lower():
        return "MISSING_FEED_HOLD_MENTION"
    return None


def extract_pond_id(instruction: str) -> str | None:
    m = re.search(r'SFT-\d{6}', instruction)
    return m.group(0) if m else None


def score_example(gen_row: dict, payload_lookup: dict) -> dict:
    output_text = gen_row["model_output"]
    pond_id = extract_pond_id(gen_row["instruction"])
    payload = payload_lookup.get(pond_id)

    issues = []

    if payload is not None:
        output_numbers = extract_numbers(output_text)
        allowed = payload_numbers(payload)
        hallucinated = output_numbers - allowed
        suspicious = {n for n in hallucinated if float(n) >= 3 or "." in n}
        suspicious = {n for n in suspicious if not explainable_by_arithmetic(float(n), allowed)}
        if suspicious:
            issues.append(f"NUMBER_HALLUCINATION: {suspicious}")

        citation_issue = check_table_citation_logic(output_text, payload)
        if citation_issue:
            issues.append(citation_issue)

        hold_issue = check_feed_hold_mention(output_text, payload)
        if hold_issue:
            issues.append(hold_issue)
    else:
        issues.append("NO_PAYLOAD_MATCH: could not look up original payload for scoring")

    if detect_repetition_loop(output_text):
        issues.append("REPETITION_LOOP")

    if detect_harvest_contradiction(output_text):
        issues.append("HARVEST_CONTRADICTION")

    return {"pond_id": pond_id, "valid": len(issues) == 0, "issues": issues}


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--generations", type=str, default="training/eval_generations.jsonl")
    parser.add_argument("--payloads", type=str, default="training/m3_payloads_final_50k.jsonl")
    parser.add_argument("--out", type=str, default="training/eval_scored.jsonl")
    args = parser.parse_args()

    with open(args.payloads) as f:
        payload_lookup = {json.loads(l)["pond_id"]: json.loads(l) for l in f}
    print(f"Loaded {len(payload_lookup)} reference payloads")

    with open(args.generations) as f:
        gens = [json.loads(l) for l in f]
    print(f"Scoring {len(gens)} model generations...")

    results = []
    issue_counter = Counter()
    for g in gens:
        r = score_example(g, payload_lookup)
        results.append(r)
        for issue in r["issues"]:
            issue_type = issue.split(":")[0]
            issue_counter[issue_type] += 1

    n_valid = sum(r["valid"] for r in results)
    print(f"\n=== RESULTS: {len(results)} examples ===")
    print(f"Clean (no issues): {n_valid} ({n_valid/len(results):.1%})")
    print(f"\nIssue breakdown:")
    for issue_type, count in issue_counter.most_common():
        print(f"  {issue_type}: {count} ({count/len(results):.1%})")

    out_path = Path(args.out)
    with open(out_path, "w") as f:
        for g, r in zip(gens, results):
            f.write(json.dumps({**g, "score": r}) + "\n")
    print(f"\nDetailed per-example results -> {out_path}")


if __name__ == "__main__":
    main()
