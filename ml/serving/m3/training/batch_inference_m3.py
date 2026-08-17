"""
Batch inference: base model + exported LoRA adapter, run against 200 held-out
examples never seen during training. Produces the raw generations for
evaluate_m3_outputs.py to score.

Run this on your machine (RTX 5070), NOT in a sandbox — needs the actual GPU
and the exported adapter files.

Setup (one-time):
    pip install torch transformers peft accelerate bitsandbytes

Usage:
    python batch_inference_m3.py \
        --adapter_path ~/m3_production_lora_v0.2.0 \
        --eval_set training/eval_set_200.jsonl \
        --out training/eval_generations.jsonl \
        --max_new_tokens 250

If you exported via Unsloth Studio, --adapter_path should point at the
folder containing adapter_config.json + adapter_model.safetensors.
"""

import argparse
import json
import re
from pathlib import Path

import torch
from transformers import AutoModelForCausalLM, AutoTokenizer, BitsAndBytesConfig
from peft import PeftModel
from tqdm import tqdm

BASE_MODEL = "unsloth/Qwen3-8B-bnb-4bit"  # match whatever base Studio actually used

CHAT_TEMPLATE = """<|im_start|>system
You are the AquaVerse M3 Production & Feed Reasoner. You explain and recommend feed decisions using ONLY the numbers provided in the input payload. Never invent a number. Anchor every feed recommendation to the named manufacturer table. Cite compensatory-growth evidence for any feed-hold recommendation.<|im_end|>
<|im_start|>user
{instruction}<|im_end|>
<|im_start|>assistant
<think>

</think>

"""
# The empty <think></think> block above is the documented way to hard-disable
# Qwen3's native thinking mode at the prompt level - without it, the model
# inserts its own unsupervised reasoning preamble and burns most of the
# token budget before ever reaching the real answer, which is exactly what
# happened in the first eval run (every output started with <think> and was
# truncated mid-sentence at max_new_tokens=250). This matches the effect of
# Studio's "Thinking" toggle, just applied at the raw-prompt level since
# we're not going through Studio's UI here.


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--adapter_path", type=str, required=True)
    parser.add_argument("--eval_set", type=str, default="training/eval_set_200.jsonl")
    parser.add_argument("--out", type=str, default="training/eval_generations.jsonl")
    parser.add_argument("--max_new_tokens", type=int, default=100)  # grid-search winner (90% clean @ n=20); longer = more drift/hallucination
    parser.add_argument("--repetition_penalty", type=float, default=1.2)  # grid-search winner (90% clean @ n=20)
    parser.add_argument("--temperature", type=float, default=0.1)  # grid-search winner (90% clean @ n=20)
    parser.add_argument("--thinking", action="store_true", help="Enable Qwen3 native thinking mode (NOT recommended given training format)")
    args = parser.parse_args()

    print(f"Loading base model {BASE_MODEL}...")
    tokenizer = AutoTokenizer.from_pretrained(BASE_MODEL)
    bnb_config = BitsAndBytesConfig(load_in_4bit=True, bnb_4bit_compute_dtype=torch.bfloat16)
    model = AutoModelForCausalLM.from_pretrained(
        BASE_MODEL, quantization_config=bnb_config, device_map="auto"
    )
    print(f"Loading LoRA adapter from {args.adapter_path}...")
    model = PeftModel.from_pretrained(model, args.adapter_path)
    model.eval()

    with open(args.eval_set) as f:
        eval_rows = [json.loads(l) for l in f]
    print(f"Loaded {len(eval_rows)} held-out examples")

    out_path = Path(args.out)
    out_path.parent.mkdir(parents=True, exist_ok=True)

    with open(out_path, "w") as f_out:
        for row in tqdm(eval_rows, desc="Generating"):
            prompt = CHAT_TEMPLATE.format(instruction=row["instruction"])
            inputs = tokenizer(prompt, return_tensors="pt").to(model.device)

            with torch.no_grad():
                output_ids = model.generate(
                    **inputs,
                    max_new_tokens=args.max_new_tokens,
                    temperature=args.temperature,
                    do_sample=True,
                    repetition_penalty=args.repetition_penalty,  # explicit fix for the Studio-chat looping we saw
                    pad_token_id=tokenizer.eos_token_id,
                )
            generated = tokenizer.decode(
                output_ids[0][inputs["input_ids"].shape[1]:], skip_special_tokens=True
            )

            result = {
                "instruction": row["instruction"],
                "ground_truth_output": row["output"],  # kept for comparison, NOT used in generation
                "model_output": generated.strip(),
            }
            f_out.write(json.dumps(result) + "\n")

    print(f"\nWrote {len(eval_rows)} generations -> {out_path}")
    print("Next: run evaluate_m3_outputs.py against this file")


if __name__ == "__main__":
    main()
