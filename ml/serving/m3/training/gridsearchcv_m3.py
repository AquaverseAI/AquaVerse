"""
GridSearchCV over M3 generation hyperparameters, using sklearn properly.

Why this instead of the earlier flat sweep (grid_search_m3.py): that script
tested each config on ONE fixed 20-example subset - a single sample, which
is exactly what produced the 90%-vs-54.5% gap between the 20-example sweep
and the full 200-example run. K-fold cross-validation tests each config on
multiple independent subsets and reports mean +/- std, so a config that
looks good by luck on one fold shows up as high-variance rather than
silently winning.

IMPORTANT: this tunes DECODING behavior only (max_new_tokens,
repetition_penalty, temperature). It does NOT fix the root-cause grounding
problem found in the v0.2.0 eval (model confabulating feed/harvest numbers
because training instructions never included them). Run this against the
v0.3.0 adapter (trained on m3_sft_final_corpus_v2.jsonl) for a number that
actually matters - running it against v0.2.0 mainly confirms what we
already know: decode-tuning helps other symptoms but can't fix missing
grounding.

Usage:
    python3 gridsearchcv_m3.py \
        --adapter_path /home/techpark-6/Pictures \
        --eval_set eval_set_200_v2.jsonl \
        --payloads m3_payloads_final_50k.jsonl \
        --n_examples 60 --cv 3
"""

import argparse
import json
import re

import numpy as np
import torch
from transformers import AutoModelForCausalLM, AutoTokenizer, BitsAndBytesConfig
from peft import PeftModel
from sklearn.base import BaseEstimator
from sklearn.model_selection import GridSearchCV, KFold

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

# module-level globals: model loaded ONCE, referenced by every cloned
# estimator instance. sklearn's GridSearchCV clones the estimator per
# param combo via get_params/set_params - if model loading lived in
# __init__, it would reload an 8B model on every clone. Loading it once
# at module scope and having predict() reference these globals avoids that.
_MODEL = None
_TOKENIZER = None


def load_model_once(adapter_path: str):
    global _MODEL, _TOKENIZER
    if _MODEL is None:
        print(f"Loading base model {BASE_MODEL} (once)...")
        _TOKENIZER = AutoTokenizer.from_pretrained(BASE_MODEL)
        bnb_config = BitsAndBytesConfig(load_in_4bit=True, bnb_4bit_compute_dtype=torch.bfloat16)
        model = AutoModelForCausalLM.from_pretrained(BASE_MODEL, quantization_config=bnb_config, device_map="auto")
        print(f"Loading LoRA adapter from {adapter_path} (once)...")
        model = PeftModel.from_pretrained(model, adapter_path)
        model.eval()
        _MODEL = model
    return _MODEL, _TOKENIZER


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
        if check_table_citation_logic(output_text, payload):
            issues.append("MISSING_TABLE_CITATION")
        if check_feed_hold_mention(output_text, payload):
            issues.append("MISSING_FEED_HOLD_MENTION")
    if detect_repetition_loop(output_text):
        issues.append("REPETITION_LOOP")
    if detect_harvest_contradiction(output_text):
        issues.append("HARVEST_CONTRADICTION")
    return issues


class M3GenerationEstimator(BaseEstimator):
    """
    sklearn-compatible wrapper around the frozen fine-tuned model. fit() is
    a no-op (the model doesn't train here, only decoding params vary) -
    this is a legitimate, if unusual, use of BaseEstimator: GridSearchCV's
    cross-validation machinery (fold splitting, mean/std aggregation) is
    useful even when there's no actual training step.
    """
    def __init__(self, adapter_path=None, max_new_tokens=100, repetition_penalty=1.2, temperature=0.1):
        self.adapter_path = adapter_path
        self.max_new_tokens = max_new_tokens
        self.repetition_penalty = repetition_penalty
        self.temperature = temperature

    def fit(self, X, y=None):
        load_model_once(self.adapter_path)  # no-op after first call
        return self

    def predict(self, X):
        model, tokenizer = _MODEL, _TOKENIZER
        outputs = []
        for instruction in X:
            prompt = CHAT_TEMPLATE.format(instruction=instruction)
            inputs = tokenizer(prompt, return_tensors="pt").to(model.device)
            with torch.no_grad():
                output_ids = model.generate(
                    **inputs, max_new_tokens=self.max_new_tokens, temperature=self.temperature,
                    do_sample=True, repetition_penalty=self.repetition_penalty,
                    pad_token_id=tokenizer.eos_token_id,
                )
            generated = tokenizer.decode(
                output_ids[0][inputs["input_ids"].shape[1]:], skip_special_tokens=True
            ).strip()
            outputs.append(generated)
        return outputs


def m3_clean_rate_scorer(estimator, X, y):
    """y is the parallel list of payload dicts (or None if unmatched)."""
    preds = estimator.predict(X)
    clean = sum(1 for pred, payload in zip(preds, y) if not score_output(pred, payload))
    return clean / len(preds)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--adapter_path", type=str, required=True)
    parser.add_argument("--eval_set", type=str, default="eval_set_200_v2.jsonl")
    parser.add_argument("--payloads", type=str, default="m3_payloads_final_50k.jsonl")
    parser.add_argument("--n_examples", type=int, default=60)
    parser.add_argument("--cv", type=int, default=3)
    args = parser.parse_args()

    with open(args.eval_set) as f:
        eval_rows = [json.loads(l) for l in f][:args.n_examples]
    with open(args.payloads) as f:
        payload_lookup = {json.loads(l)["pond_id"]: json.loads(l) for l in f}

    X = [row["instruction"] for row in eval_rows]
    y = [payload_lookup.get(extract_pond_id(row["instruction"])) for row in eval_rows]
    print(f"Loaded {len(X)} examples for GridSearchCV ({args.cv}-fold)")

    # refined grid around the earlier flat-sweep winner (100/1.2/0.1) -
    # tighter range since we already know the rough direction (shorter,
    # lower temperature, moderate repetition_penalty all help)
    param_grid = {
        "max_new_tokens": [70, 100, 130],
        "repetition_penalty": [1.1, 1.2, 1.3],
        "temperature": [0.05, 0.1],
    }
    n_combos = 3 * 3 * 2
    print(f"Grid: {n_combos} combinations x {len(X)} examples = {n_combos * len(X)} total generations")
    print(f"Estimated time at ~9s/generation: ~{n_combos * len(X) * 9 / 60:.0f} minutes\n")

    estimator = M3GenerationEstimator(adapter_path=args.adapter_path)
    cv = KFold(n_splits=args.cv, shuffle=True, random_state=42)

    gs = GridSearchCV(
        estimator, param_grid, cv=cv,
        scoring=m3_clean_rate_scorer, refit=False, verbose=2,
    )
    gs.fit(X, y)

    results = gs.cv_results_
    ranking = np.argsort(-results["mean_test_score"])

    print("\n=== RANKED RESULTS (best first), mean +/- std across folds ===")
    for idx in ranking:
        params = results["params"][idx]
        mean = results["mean_test_score"][idx]
        std = results["std_test_score"][idx]
        print(f"  clean={mean:.1%} (+/-{std:.1%})  {params}")

    best_idx = ranking[0]
    print(f"\nBest config: {results['params'][best_idx]}")
    print(f"Mean clean rate: {results['mean_test_score'][best_idx]:.1%}, "
          f"std: {results['std_test_score'][best_idx]:.1%} across {args.cv} folds")
    if results["std_test_score"][best_idx] > 0.1:
        print("NOTE: std > 10pp - this config's performance varies a lot across folds. "
              "Treat the mean with caution; consider more folds or more examples per fold.")


if __name__ == "__main__":
    main()
