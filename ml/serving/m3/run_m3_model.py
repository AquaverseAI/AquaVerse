import argparse
import json
import os
import sys
import torch
from transformers import AutoModelForCausalLM, AutoTokenizer, BitsAndBytesConfig
from peft import PeftModel

# Allow importing local decision engine
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '../../..')))
sys.path.insert(0, os.path.abspath(os.path.dirname(__file__)))

from m3_decision_engine import M3DecisionEngine, PondSnapshot, payload_to_instruction

BASE_MODEL = "unsloth/Qwen3-8B-bnb-4bit"
ADAPTER_PATH = "/home/techpark-6/Pictures"

CHAT_TEMPLATE = """<|im_start|>system
You are the AquaVerse M3 Production & Feed Reasoner. You explain and recommend feed decisions using ONLY the numbers provided in the input payload. Never invent a number. Anchor every feed recommendation to the named manufacturer table. Cite compensatory-growth evidence for any feed-hold recommendation.<|im_end|>
<|im_start|>user
{instruction}<|im_end|>
<|im_start|>assistant
<think>

</think>

"""

def main():
    parser = argparse.ArgumentParser(description="Directly run AquaVerse M3 LoRA model inference")
    parser.add_argument("--adapter_path", type=str, default=ADAPTER_PATH, help="Path to LoRA adapter")
    parser.add_argument("--prompt", type=str, default=None, help="Custom prompt/instruction string")
    parser.add_argument("--request_json", type=str, default=os.path.join(os.path.dirname(__file__), "example_request.json"), help="Path to snapshot JSON file")
    parser.add_argument("--max_new_tokens", type=int, default=150)
    parser.add_argument("--temperature", type=float, default=0.05)
    parser.add_argument("--repetition_penalty", type=float, default=1.1)

    args = parser.parse_args()

    # Step 1: Obtain instruction text
    if args.prompt:
        instruction = args.prompt
    else:
        print(f"Loading request payload from {args.request_json}...")
        with open(args.request_json, "r") as f:
            req_dict = json.load(f)
        engine = M3DecisionEngine()
        snap = PondSnapshot(**req_dict)
        payload = engine.decide(snap)
        instruction = payload_to_instruction(payload)
        print("\n--- Decision Engine Formatted Instruction ---")
        print(instruction)
        print("---------------------------------------------\n")

    # Step 2: Load base model + LoRA adapter
    print(f"Loading base model '{BASE_MODEL}'...")
    tokenizer = AutoTokenizer.from_pretrained(BASE_MODEL)
    bnb_config = BitsAndBytesConfig(load_in_4bit=True, bnb_4bit_compute_dtype=torch.bfloat16)

    model = AutoModelForCausalLM.from_pretrained(
        BASE_MODEL,
        quantization_config=bnb_config,
        device_map="auto"
    )

    if os.path.exists(args.adapter_path):
        print(f"Loading LoRA adapter from {args.adapter_path}...")
        model = PeftModel.from_pretrained(model, args.adapter_path)
    else:
        print(f"WARNING: LoRA adapter not found at {args.adapter_path}. Using base model.")

    model.eval()

    # Step 3: Run Inference
    prompt = CHAT_TEMPLATE.format(instruction=instruction)
    inputs = tokenizer(prompt, return_tensors="pt").to(model.device)

    print("Generating model narration...")
    with torch.no_grad():
        output_ids = model.generate(
            **inputs,
            max_new_tokens=args.max_new_tokens,
            temperature=args.temperature,
            do_sample=True if args.temperature > 0 else False,
            repetition_penalty=args.repetition_penalty,
            pad_token_id=tokenizer.eos_token_id,
        )

    generated_text = tokenizer.decode(
        output_ids[0][inputs["input_ids"].shape[1]:], skip_special_tokens=True
    ).strip()

    print("\n================ MODEL OUTPUT ================")
    print(generated_text)
    print("==============================================\n")

if __name__ == "__main__":
    main()
