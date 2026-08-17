"""
Validates the Kimi-narrated SFT corpus BEFORE it touches Unsloth. This is
the training-data-side analog of the R1 number-hallucination validator that
must exist at serving time — same principle, applied one stage earlier: an
LLM narrating a payload can still slip in a number that isn't there, and an
LLM grading its own output can't be trusted to catch its own mistake
reliably. This checks programmatically.

Usage:
    python validate_sft_corpus.py --payloads training/m3_payloads_final_50k.jsonl \
                                   --narrated training/m3_sft_kimi_output.jsonl \
                                   --out training/m3_sft_validated.jsonl

Expects `narrated` to be a JSONL file where line i is Kimi's output for
payload i in `payloads` (same order, same count — see kimi_prompt_template.md
batching guidance on why order must be preserved).
"""

from __future__ import annotations
import argparse
import json
import re
from pathlib import Path
from collections import Counter


def extract_numbers(text: str) -> set[str]:
    """Extract every numeral in text, normalized (strip trailing .0, commas)."""
    raw = re.findall(r"\d[\d,]*\.?\d*", text)
    normalized = set()
    for r in raw:
        cleaned = r.replace(",", "")
        try:
            val = float(cleaned)
            # normalize e.g. "3.0" and "3" to the same key
            normalized.add(f"{val:g}")
        except ValueError:
            continue
    return normalized


def payload_numbers(payload: dict) -> set[str]:
    """All numerals present anywhere in the payload's values (flattened)."""
    nums = set()

    def walk(v):
        if isinstance(v, (int, float)) and not isinstance(v, bool):
            nums.add(f"{float(v):g}")
        elif isinstance(v, str):
            nums.update(extract_numbers(v))
        elif isinstance(v, dict):
            for vv in v.values():
                walk(vv)
        elif isinstance(v, list):
            for vv in v:
                walk(vv)

    walk(payload)
    return nums


def explainable_by_arithmetic(number: float, payload_nums: set[str], tol: float = 0.02) -> bool:
    """
    Checks whether `number` is a simple derived value (sum, difference,
    ratio, or percentage) of any TWO numbers already in the payload. Kimi
    and the fine-tuned model both legitimately do this kind of arithmetic
    (e.g. "0.75 mg/L below the 4.0 threshold", or "0.56 kg is 4.69% of
    biomass" when biomass=11.94kg) - that's not hallucination, it's correct
    math on real payload numbers. The percentage case specifically was found
    missing during the first batch-eval run: 155/200 flagged examples turned
    out to be legitimate feed_kg/biomass_kg*100 calculations the original
    difference/sum/ratio checks didn't cover.
    """
    vals = [float(n) for n in payload_nums]
    for i, a in enumerate(vals):
        for b in vals[i + 1:]:
            if abs(abs(a - b) - number) < tol:
                return True
            if abs((a + b) - number) < tol:
                return True
            if b != 0 and abs((a / b) - number) < tol:
                return True
            if a != 0 and abs((b / a) - number) < tol:
                return True
            # percentage derivations: (a/b)*100 or (b/a)*100, with a looser
            # tolerance since percentages are often rounded to 1-2dp
            if b != 0 and abs((a / b) * 100 - number) < max(tol * 20, 0.1):
                return True
            if a != 0 and abs((b / a) * 100 - number) < max(tol * 20, 0.1):
                return True
    return False


def validate_example(payload: dict, narrated: dict) -> dict:
    """Returns a dict of check results for one example."""
    issues = []

    if "instruction" not in narrated or "output" not in narrated:
        issues.append("SCHEMA: missing instruction or output field")
        return {"valid": False, "issues": issues}

    output_text = narrated["output"]
    output_numbers = extract_numbers(output_text)
    allowed_numbers = payload_numbers(payload)

    hallucinated = output_numbers - allowed_numbers
    # small integers (0, 1, 2...) are near-universally safe (counts, "first", etc.)
    # and would create too many false positives if flagged - only flag numbers
    # that look like they could be a real measurement (>= 3, or has a decimal point)
    suspicious = {n for n in hallucinated if float(n) >= 3 or "." in n}
    # of those, drop any explainable as simple arithmetic on two real payload numbers
    suspicious = {n for n in suspicious if not explainable_by_arithmetic(float(n), allowed_numbers)}
    if suspicious:
        issues.append(f"NUMBER_HALLUCINATION: {suspicious} not found in payload")

    if payload.get("feed_hold_recommended") and "hold" not in output_text.lower() \
            and "skip" not in output_text.lower():
        issues.append("MISSING_FEED_HOLD_MENTION: payload says hold, output doesn't clearly say so")

    table_name = payload.get("manufacturer_table", "")
    if not payload.get("feed_hold_recommended") and table_name and table_name not in output_text:
        issues.append(f"MISSING_TABLE_CITATION: '{table_name}' not named in output")

    if payload.get("do_forecast_confidence") == "low_data":
        confidence_terms = ["confidence", "uncertain", "limited data", "data quality", "sensor"]
        if not any(t in output_text.lower() for t in confidence_terms):
            issues.append("MISSING_CONFIDENCE_FLAG: low_data confidence not mentioned")

    disease_terms = ["wssv", "ehp", "ahpnd", "white spot", "disease confirmed", "has vibrio"]
    if any(t in output_text.lower() for t in disease_terms):
        issues.append("SCOPE_VIOLATION: M3 output mentions specific disease diagnosis")

    return {"valid": len(issues) == 0, "issues": issues}


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--payloads", type=str, required=True)
    parser.add_argument("--narrated", type=str, required=True)
    parser.add_argument("--out", type=str, default="training/m3_sft_validated.jsonl")
    args = parser.parse_args()

    with open(args.payloads) as f:
        payloads = [json.loads(line) for line in f]
    with open(args.narrated) as f:
        narrated = [json.loads(line) for line in f]

    if len(payloads) != len(narrated):
        print(f"WARNING: count mismatch — {len(payloads)} payloads vs {len(narrated)} narrated. "
              f"Order alignment may already be broken. Truncating to shorter length.")
        n = min(len(payloads), len(narrated))
        payloads, narrated = payloads[:n], narrated[:n]

    results = []
    issue_counter = Counter()
    for p, n in zip(payloads, narrated):
        r = validate_example(p, n)
        results.append(r)
        for issue in r["issues"]:
            issue_type = issue.split(":")[0]
            issue_counter[issue_type] += 1

    n_valid = sum(r["valid"] for r in results)
    print(f"Validated {len(results)} examples: {n_valid} clean ({n_valid/len(results):.1%}), "
          f"{len(results)-n_valid} flagged")
    print("\nIssue breakdown:")
    for issue_type, count in issue_counter.most_common():
        print(f"  {issue_type}: {count} ({count/len(results):.1%})")

    if issue_counter.get("NUMBER_HALLUCINATION", 0) / max(len(results), 1) > 0.05:
        print("\n*** WARNING: >5% of examples have suspected number hallucination. ***")
        print("*** Do not train on this corpus until the Kimi prompt is fixed and regenerated. ***")

    out_path = Path(args.out)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    n_written = 0
    with open(out_path, "w") as f:
        for p, n, r in zip(payloads, narrated, results):
            if r["valid"]:
                f.write(json.dumps({"instruction": n["instruction"], "output": n["output"]}) + "\n")
                n_written += 1

    print(f"\nWrote {n_written} clean examples -> {out_path}")
    print("This is the file to upload to Unsloth Studio, NOT the raw Kimi output.")


if __name__ == "__main__":
    main()
