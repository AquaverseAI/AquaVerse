"""
Hyperparameter grid search for M3 generation quality.

Diagnostic purpose: the full 200-example eval showed 37.5% clean, with the
dominant failure being the model rambling past its trained answer length,
self-contradicting on harvest projection, and drifting numbers the longer
it talks. Before assuming this needs a training-data fix, test whether
tighter generation settings alone resolve it - much cheaper than a retrain.

Loads the model ONCE, then sweeps combinations of max_new_tokens,
repetition_penalty, and temperature across a small subset (default 20) of
held-out examples, scoring each combo with the same logic as
evaluate_m3_outputs.py. Prints a ranked summary so you can pick a winner
before committing to a full 200-example re-run with that config.

Usage:
    python3 grid_search_m3.py --adapter_path /home/techpark-6/Pictures \
        --eval_set eval_set_200.jsonl --payloads m3_payloads_final_50k.jsonl \
        --n_examples 20
"""

import argparse
import itertools
import json
import re
from pathlib import Path

import torch
from transformers import AutoModelForCausalLM, AutoTokenizer, BitsAndBytesConfig
from peft import PeftModel
from tqdm import tqdm

from evaluate_m3_outputs import (
    extract_pond_id, detect_repetition_loop, detect_harvest_contradiction,
    check_table_citation_logic, check_feed_hold_mention,
)
from validate_sft_corpus import extract_numbers, payload_numbers, explainable_by_arithmetic

BASE_MODEL = "unsloth/Qwen3-8B-bnb-4bit"

CHAT_TEMPLATE = """<|im_start|>system
You are the AquaVerse M3 Production & Feed Reasoner. You explain and recommend feed decisions using ONLY the numbers provided in the input payload. Never invent a number. Anchor every feed recommendation to the named manufacturer table. Cite compensatory-growth evidence for any feed-hold recommendation.<|im_end|>
<|im_start|>user
{instruction}<|im_end|>
<|im_start|>assistant
<think>

</think>

"""

GRID = {
    "max_new_tokens": [100, 150, 220],
    "repetition_penalty": [1.2, 1.5],
    "temperature": [0.1, 0.4],
}


def score_output(output_text: str, payload: dict | None) -> list[str]:
    issues = []
    if payload is not None:
        output_numbers = extract_numbers(output_text)
        allowed = payload_numbers(payload)
        hallucinated = output_numbers - allowed
        suspicious = {n for n in hallucinated if float(n) >= 3 or "." in n}
        suspicious = {n for n in suspicious if not explainable_by_arithmetic(float(n), allowed)}
        if suspicious:
            issues.append("NUMBER_HALLUCINATION")
        c = check_table_citation_logic(output_text, payload)
        if c:
            issues.append("MISSING_TABLE_CITATION")
        h = check_feed_hold_mention(output_text, payload)
        if h:
            issues.append("MISSING_FEED_HOLD_MENTION")
    if detect_repetition_loop(output_text):
        issues.append("REPETITION_LOOP")
    if detect_harvest_contradiction(output_text):
        issues.append("HARVEST_CONTRADICTION")
    return issues


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--adapter_path", type=str, required=True)
    parser.add_argument("--eval_set", type=str, default="eval_set_200.jsonl")
    parser.add_argument("--payloads", type=str, default="m3_payloads_final_50k.jsonl")
    parser.add_argument("--n_examples", type=int, default=20)
    args = parser.parse_args()

    print(f"Loading base model {BASE_MODEL}...")
    tokenizer = AutoTokenizer.from_pretrained(BASE_MODEL)
    bnb_config = BitsAndBytesConfig(load_in_4bit=True, bnb_4bit_compute_dtype=torch.bfloat16)
    model = AutoModelForCausalLM.from_pretrained(BASE_MODEL, quantization_config=bnb_config, device_map="auto")
    print(f"Loading LoRA adapter from {args.adapter_path}...")
    model = PeftModel.from_pretrained(model, args.adapter_path)
    model.eval()

    with open(args.eval_set) as f:
        eval_rows = [json.loads(l) for l in f][:args.n_examples]
    with open(args.payloads) as f:
        payload_lookup = {json.loads(l)["pond_id"]: json.loads(l) for l in f}
    print(f"Loaded {len(eval_rows)} examples for grid search, {len(payload_lookup)} reference payloads")

    combos = list(itertools.product(GRID["max_new_tokens"], GRID["repetition_penalty"], GRID["temperature"]))
    print(f"Testing {len(combos)} combinations x {len(eval_rows)} examples = {len(combos)*len(eval_rows)} generations\n")

    results_summary = []

    for max_new_tokens, rep_penalty, temp in combos:
        clean_count = 0
        issue_tally = {}
        for row in tqdm(eval_rows, desc=f"mnt={max_new_tokens} rp={rep_penalty} t={temp}", leave=False):
            prompt = CHAT_TEMPLATE.format(instruction=row["instruction"])
            inputs = tokenizer(prompt, return_tensors="pt").to(model.device)
            with torch.no_grad():
                output_ids = model.generate(
                    **inputs, max_new_tokens=max_new_tokens, temperature=temp,
                    do_sample=True, repetition_penalty=rep_penalty,
                    pad_token_id=tokenizer.eos_token_id,
                )
            generated = tokenizer.decode(
                output_ids[0][inputs["input_ids"].shape[1]:], skip_special_tokens=True
            ).strip()

            pond_id = extract_pond_id(row["instruction"])
            payload = payload_lookup.get(pond_id)
            issues = score_output(generated, payload)
            if not issues:
                clean_count += 1
            for issue in issues:
                issue_tally[issue] = issue_tally.get(issue, 0) + 1

        clean_rate = clean_count / len(eval_rows)
        results_summary.append({
            "max_new_tokens": max_new_tokens, "repetition_penalty": rep_penalty,
            "temperature": temp, "clean_rate": clean_rate, "issues": issue_tally,
        })
        print(f"  mnt={max_new_tokens:4d} rp={rep_penalty:.1f} t={temp:.1f}  ->  "
              f"clean={clean_count}/{len(eval_rows)} ({clean_rate:.0%})  {issue_tally}")

    print("\n=== RANKED RESULTS (best first) ===")
    results_summary.sort(key=lambda r: -r["clean_rate"])
    for r in results_summary:
        print(f"  clean={r['clean_rate']:.0%}  max_new_tokens={r['max_new_tokens']} "
              f"repetition_penalty={r['repetition_penalty']} temperature={r['temperature']}  "
              f"issues={r['issues']}")

    best = results_summary[0]
    print(f"\nBest config: max_new_tokens={best['max_new_tokens']}, "
          f"repetition_penalty={best['repetition_penalty']}, temperature={best['temperature']}")
    print("Next: re-run batch_inference_m3.py with these settings on the full 200-example set.")


if __name__ == "__main__":
    main()
