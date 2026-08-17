"""
Phase 4 corpus fix: rebuild `instruction` to contain the FULL payload, not a
compressed natural-language question.

ROOT CAUSE this fixes: the original corpus paired a short question
("Pond X, species Y, day Z. DO forecast N. What should feeding be?") with
Kimi-generated output that correctly cited feed_kg, table name, harvest
projection, and cost figures — because Kimi was given the FULL payload
during generation. But the trained model only ever saw the compressed
question as input. It was never taught to copy numbers from its input,
because the numbers it needed to report weren't IN its input. It learned to
confabulate plausible-looking numbers instead — which is exactly what a
live batch-eval run found: 45% of outputs stated a feed quantity or harvest
figure that didn't match the real payload, in some cases by a large margin
(12x on one feed_kg value).

No new Kimi calls needed — the existing `output` text is already correct
(grounded in the full payload at generation time). This script just rejoins
each output with the FULL payload as its instruction, keyed by pond_id.

Usage:
    python3 rebuild_corpus_full_payload.py \
        --old_corpus m3_sft_final_corpus.jsonl \
        --payloads m3_payloads_final_50k.jsonl \
        --out m3_sft_final_corpus_v2.jsonl
"""

import argparse
import json
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent))  # so m3_decision_engine is importable from training/
from m3_decision_engine import payload_to_instruction  # noqa: E402 - single source of truth, see that module's docstring


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--old_corpus", type=str, default="m3_sft_final_corpus.jsonl")
    parser.add_argument("--payloads", type=str, default="m3_payloads_final_50k.jsonl")
    parser.add_argument("--out", type=str, default="m3_sft_final_corpus_v2.jsonl")
    args = parser.parse_args()

    with open(args.payloads) as f:
        payload_lookup = {json.loads(l)["pond_id"]: json.loads(l) for l in f}
    print(f"Loaded {len(payload_lookup)} reference payloads")

    n_written, n_skipped = 0, 0
    with open(args.old_corpus) as f_in, open(args.out, "w") as f_out:
        for line in f_in:
            row = json.loads(line)
            m = re.search(r"SFT-\d{6}", row["instruction"])
            if not m:
                n_skipped += 1
                continue
            payload = payload_lookup.get(m.group(0))
            if payload is None:
                n_skipped += 1
                continue

            new_instruction = payload_to_instruction(payload)
            f_out.write(json.dumps({"instruction": new_instruction, "output": row["output"]}) + "\n")
            n_written += 1

    print(f"Rebuilt {n_written} examples with full-payload instructions -> {args.out}")
    print(f"Skipped {n_skipped} (couldn't match pond_id to a payload)")
    print("\nNext: retrain in Unsloth Studio on this file as m3_production-lora-0.3.0")


if __name__ == "__main__":
    main()
