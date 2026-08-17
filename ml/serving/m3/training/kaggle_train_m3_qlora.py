# AquaVerse AI — M3 (Production & Feed Reasoner) QLoRA fine-tune
# Run this as a Kaggle Notebook: Settings -> Accelerator: GPU T4 x2, Internet: On
# Matches PRD-AV-05 section 5.2 and the MVP spec section 2 exactly.
#
# Cost/time: ~4-8h on Kaggle's free 30 GPU-h/week T4x2 allocation for ~15k samples.
# Swap MODEL_NAME / ADAPTER_NAME / DATA_PATH per adapter (m1_chemistry, m2_health, m3_production).

# ---------------------------------------------------------------------------
# Cell 1 — install (pinned versions; unsloth moves fast and breaks silently)
# ---------------------------------------------------------------------------
# !pip install --no-deps "unsloth[kaggle-new] @ git+https://github.com/unslothai/unsloth.git"
# !pip install --no-deps "xformers<0.0.27" trl peft accelerate bitsandbytes triton
# !pip install mlflow

# ---------------------------------------------------------------------------
# Cell 2 — imports and config
# ---------------------------------------------------------------------------
import json
import hashlib
from pathlib import Path

import torch
from unsloth import FastLanguageModel
from trl import SFTTrainer, SFTConfig
from datasets import load_dataset
import mlflow

# --- config: this is the only block you edit to switch adapters ---
ADAPTER_KEY = "m3_production"          # m1_chemistry | m2_health | m3_production
ADAPTER_SEMVER = "0.1.0"
BASE_MODEL = "unsloth/Qwen3-8B-bnb-4bit"   # pre-quantised, faster download than quantising yourself
MAX_SEQ_LEN = 2048
DATA_PATH = "/kaggle/input/aquaverse-m3-sft/m3_sft_pairs.jsonl"   # Phase 4 artifact goes here
OUTPUT_DIR = f"/kaggle/working/{ADAPTER_KEY}-lora-{ADAPTER_SEMVER}"
MLFLOW_DB = "/kaggle/working/mlflow.db"   # copy this file out after the run — it's your audit trail

# ---------------------------------------------------------------------------
# Cell 3 — load base model in 4-bit
# ---------------------------------------------------------------------------
model, tokenizer = FastLanguageModel.from_pretrained(
    model_name=BASE_MODEL,
    max_seq_length=MAX_SEQ_LEN,
    load_in_4bit=True,
    dtype=None,  # auto-detect bf16/fp16 per GPU
)

# ---------------------------------------------------------------------------
# Cell 4 — attach LoRA adapters
# ---------------------------------------------------------------------------
model = FastLanguageModel.get_peft_model(
    model,
    r=16,
    target_modules=[
        "q_proj", "k_proj", "v_proj", "o_proj",
        "gate_proj", "up_proj", "down_proj",
    ],
    lora_alpha=16,
    lora_dropout=0,          # 0 is optimised in Unsloth's fused kernels
    bias="none",
    use_gradient_checkpointing="unsloth",  # ~30% less VRAM, enables longer context on a T4
    random_state=42,
)

# ---------------------------------------------------------------------------
# Cell 5 — load and format the SFT corpus
#
# Expected JSONL schema, one object per line:
#   {"instruction": "<pond state + question>",
#    "reasoning":    "<chain of reasoning, cites the manufacturer table by name,
#                      cites compensatory-growth evidence for any feed-hold>",
#    "output":       "<final farmer-readable advisory, numbers ONLY from payload>"}
#
# This is exactly the Phase 4 artifact (~5,000 pairs) built from growth curves +
# feed tables + economics, per PRD-AV-05 section 5.2. Point DATA_PATH at it.
# ---------------------------------------------------------------------------
CHAT_TEMPLATE = """<|im_start|>system
You are the AquaVerse M3 Production & Feed Reasoner. You explain and recommend feed decisions using ONLY the numbers provided in the input payload. Never invent a number. Anchor every feed recommendation to the named manufacturer table. Cite compensatory-growth evidence for any feed-hold recommendation.<|im_end|>
<|im_start|>user
{instruction}<|im_end|>
<|im_start|>assistant
{reasoning}

{output}<|im_end|>"""


def format_example(example):
    return {"text": CHAT_TEMPLATE.format(**example)}


dataset = load_dataset("json", data_files=DATA_PATH, split="train")
dataset = dataset.map(format_example)

# compute a hash of the training data for the MLflow audit trail (PRD citation discipline)
with open(DATA_PATH, "rb") as f:
    data_hash = hashlib.sha256(f.read()).hexdigest()[:16]

# ---------------------------------------------------------------------------
# Cell 6 — train
# ---------------------------------------------------------------------------
sft_config = SFTConfig(
    output_dir=OUTPUT_DIR,
    dataset_text_field="text",
    max_seq_length=MAX_SEQ_LEN,
    per_device_train_batch_size=2,
    gradient_accumulation_steps=8,   # effective batch size 16
    num_train_epochs=3,
    learning_rate=2e-4,
    lr_scheduler_type="cosine",
    warmup_ratio=0.03,
    logging_steps=10,
    save_strategy="epoch",
    optim="adamw_8bit",              # halves optimiser memory vs fp32 adamw
    weight_decay=0.01,
    seed=42,
    bf16=torch.cuda.is_bf16_supported(),
    fp16=not torch.cuda.is_bf16_supported(),
    report_to=[],                    # we log to MLflow ourselves below, not HF's built-in reporters
)

trainer = SFTTrainer(
    model=model,
    tokenizer=tokenizer,
    train_dataset=dataset,
    args=sft_config,
)

mlflow.set_tracking_uri(f"sqlite:///{MLFLOW_DB}")
mlflow.set_experiment(f"aquaverse_{ADAPTER_KEY}_sft")

with mlflow.start_run(run_name=f"{ADAPTER_KEY}-lora-{ADAPTER_SEMVER}"):
    mlflow.log_param("base_model", BASE_MODEL)
    mlflow.log_param("adapter_key", ADAPTER_KEY)
    mlflow.log_param("adapter_semver", ADAPTER_SEMVER)
    mlflow.log_param("lora_r", 16)
    mlflow.log_param("lora_alpha", 16)
    mlflow.log_param("train_data_path", DATA_PATH)
    mlflow.log_param("train_data_sha256_16", data_hash)   # <- the audit-trail line PRD S10 requires
    mlflow.log_param("n_train_examples", len(dataset))

    train_result = trainer.train()

    mlflow.log_metric("final_train_loss", train_result.training_loss)

    # ---------------------------------------------------------------------
    # Cell 7 — save adapter only (not merged model) — 100-200MB, matches
    # vLLM --enable-lora hot-swap design from the MVP spec
    # ---------------------------------------------------------------------
    model.save_pretrained(OUTPUT_DIR)
    tokenizer.save_pretrained(OUTPUT_DIR)
    mlflow.log_artifacts(OUTPUT_DIR, artifact_path="adapter")

print(f"Adapter saved to {OUTPUT_DIR}")
print(f"Training data hash logged: {data_hash}")
print("Next: copy this folder + mlflow.db out of /kaggle/working before the session recycles.")

# ---------------------------------------------------------------------------
# Cell 8 — smoke test + number-hallucination check (R1, do this before you
# consider the adapter done — not optional)
# ---------------------------------------------------------------------------
import re

FastLanguageModel.for_inference(model)  # 2x faster inference via Unsloth's native path

test_payload = {
    "pond_id": "NGP-047",
    "species": "vannamei",
    "doc": 42,
    "biomass_est_kg": 38.2,
    "overnight_do_forecast_mg_l": 2.1,
    "manufacturer_table": "CP Aquaculture Vannamei Feeding Table v3",
    "recommended_feed_kg": 4.6,
}

prompt = CHAT_TEMPLATE.split("<|im_start|>assistant")[0].format(
    instruction=f"Pond state: {json.dumps(test_payload)}. What should today's 06:00 feed be?"
)

inputs = tokenizer(prompt, return_tensors="pt").to("cuda")
output_ids = model.generate(**inputs, max_new_tokens=300, temperature=0.3)
generated = tokenizer.decode(output_ids[0], skip_special_tokens=True)

# extract every numeral the model produced downstream of the prompt
generated_numbers = set(re.findall(r"\d+\.?\d*", generated[len(prompt):]))
payload_numbers = set(re.findall(r"\d+\.?\d*", json.dumps(test_payload)))
hallucinated = generated_numbers - payload_numbers

print("Generated:\n", generated[len(prompt):])
print("\nNumbers in output not present in payload (should be empty set):", hallucinated)
if hallucinated:
    print("FAIL R1 — adapter is inventing numbers. Do not ship. Check training data for "
          "leaked ground-truth numbers not routed through the payload format.")
else:
    print("PASS R1 — no invented numbers in this smoke test. Run the full 200-item human "
          "eval (PRD Acceptance Criterion 8) before calling the adapter done.")
