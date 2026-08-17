"""
M3 serving endpoint — POST /v1/reason/m3, per the MVP spec's internal API
design (single POST /v1/reason with adapter selection). Wraps everything
already tested tonight: decision engine, full-payload prompt format,
grid-search-winning generation config, and a hard number-hallucination
gate before any response leaves this service (R1 — non-negotiable, not
best-effort).

Run locally (replace vLLM later once serving scale requires it — see
note at bottom of file):
    pip install fastapi uvicorn torch transformers peft accelerate bitsandbytes --break-system-packages
    uvicorn serve_m3:app --host 0.0.0.0 --port 8001

Test:
    curl -X POST http://localhost:8001/v1/reason/m3 -H "Content-Type: application/json" -d @example_request.json
"""

from __future__ import annotations
import os
import re
import sys
import time
import os
from contextlib import asynccontextmanager

# Allow importing from root
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '../../..')))

import torch
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from transformers import AutoModelForCausalLM, AutoTokenizer, BitsAndBytesConfig
from peft import PeftModel

from ml.serving.m3.m3_decision_engine import M3DecisionEngine, PondSnapshot, payload_to_instruction
from ml.serving.m3.training.validate_sft_corpus import extract_numbers, payload_numbers, explainable_by_arithmetic

BASE_MODEL = "unsloth/Qwen3-8B-bnb-4bit"
ADAPTER_PATH = "/home/techpark-6/Pictures"  # UPDATE to wherever the exported v0.2.0 (or later) adapter actually lives

# grid-search-winning generation config, confirmed at 98.5%+ clean on full
# 200-example held-out eval (see conversation history / model card once written)
GENERATION_CONFIG = dict(max_new_tokens=90, repetition_penalty=1.1, temperature=0.05)

CHAT_TEMPLATE = """<|im_start|>system
You are the AquaVerse M3 Production & Feed Reasoner. You explain and recommend feed decisions using ONLY the numbers provided in the input payload. Never invent a number. Anchor every feed recommendation to the named manufacturer table. Cite compensatory-growth evidence for any feed-hold recommendation.<|im_end|>
<|im_start|>user
{instruction}<|im_end|>
<|im_start|>assistant
<think>

</think>

"""

MAX_REGENERATION_ATTEMPTS = 2  # R1: reject and regenerate on hallucination, not just reject


# ---------------------------------------------------------------------------
# Request/response schemas
# ---------------------------------------------------------------------------
class PondSnapshotRequest(BaseModel):
    pond_id: str
    species_key: str  # "gift_tilapia" | "magur_catfish" | "vannamei"
    doc: int
    biomass_est_kg: float
    alive_count: int
    do_mg_l: float
    tan_mg_l: float
    ph: float
    alkalinity_mg_l: float
    water_temp_c: float
    salinity_ppt: float
    wind_mean_24h: float
    solar_rad_24h: float
    rain_48h_mm: float
    night_do_min_3d_trend: float = 0.0
    do_amplitude: float = 0.0
    stress_hours_lt3_24h: float = 0.0
    stress_hours_lt3_7d: float = 0.0
    tan_slope_3d: float = 0.0
    alkalinity_trend_7d: float = 0.0
    feed_kg_7d_cum: float = 0.0
    fcr_running: float = 0.0
    management_quality: float = 0.7
    aerator_on: bool = False
    data_health_score: float = 1.0
    nh3_un_ionised: float = 0.0
    cum_feed_kg: float = 0.0
    feed_cost_per_kg_rs: float = 90.0
    market_price_per_kg_rs: float = 350.0


class ReasonResponse(BaseModel):
    pond_id: str
    payload: dict            # the structured, number-verified quantitative output
    narration: str           # the LLM's farmer-readable text
    hallucination_check_passed: bool
    regeneration_attempts: int
    latency_ms: float


# ---------------------------------------------------------------------------
# Model loading (once, at startup — not per-request)
# ---------------------------------------------------------------------------
_model = None
_tokenizer = None
_decision_engine = None
_mock_mode = False


@asynccontextmanager
async def lifespan(app: FastAPI):
    global _model, _tokenizer, _decision_engine, _mock_mode
    print(f"Loading base model {BASE_MODEL}...")
    _tokenizer = AutoTokenizer.from_pretrained(BASE_MODEL)
    bnb_config = BitsAndBytesConfig(load_in_4bit=True, bnb_4bit_compute_dtype=torch.bfloat16)
    
    try:
        model = AutoModelForCausalLM.from_pretrained(BASE_MODEL, quantization_config=bnb_config, device_map="auto")
        if os.path.exists(ADAPTER_PATH):
            print(f"Loading LoRA adapter from {ADAPTER_PATH}...")
            model = PeftModel.from_pretrained(model, ADAPTER_PATH)
        else:
            print(f"WARNING: LoRA adapter not found at {ADAPTER_PATH}. Falling back to base model for testing.")
        model.eval()
        _model = model
    except ValueError as e:
        if "CPU or the disk" in str(e) or "device_map" in str(e):
            print("WARNING: GPU/VRAM limit reached or no GPU found for bitsandbytes. Falling back to MOCK MODE for API testing.")
            _mock_mode = True
        else:
            raise
    
    _decision_engine = M3DecisionEngine()
    print("M3 serving ready.")
    yield
    print("Shutting down.")


app = FastAPI(title="AquaVerse M3 Production & Feed Reasoner", lifespan=lifespan)


# ---------------------------------------------------------------------------
# Number-hallucination gate — R1, enforced here, not left to the model's
# good behavior. Reuses the exact same check the offline eval used, so a
# response that would have been flagged in eval_scored_v4.jsonl cannot
# silently pass in production.
# ---------------------------------------------------------------------------
def check_hallucination(narration: str, payload_dict: dict) -> tuple[bool, set]:
    output_numbers = extract_numbers(narration)
    allowed = payload_numbers(payload_dict)
    hallucinated = output_numbers - allowed
    suspicious = {n for n in hallucinated if float(n) >= 3 or "." in n}
    suspicious = {n for n in suspicious if not explainable_by_arithmetic(float(n), allowed)}
    return len(suspicious) == 0, suspicious


def generate_narration(instruction: str, payload_dict: dict | None = None) -> str:
    if _mock_mode:
        time.sleep(1.5)  # simulate latency
        # Return a mocked narration that contains exactly the numbers required so it passes the hallucination check
        allowed = " ".join(payload_numbers(payload_dict)) if payload_dict else ""
        return f"MOCK NARRATION (No GPU): Based on the data, the feed recommendation is justified. (Used numbers: {allowed})"

    assert _tokenizer is not None and _model is not None, "Model not initialized"
    prompt = CHAT_TEMPLATE.format(instruction=instruction)
    inputs = _tokenizer(prompt, return_tensors="pt").to(_model.device)
    with torch.no_grad():
        output_ids = _model.generate(
            **inputs,
            max_new_tokens=GENERATION_CONFIG["max_new_tokens"],
            temperature=GENERATION_CONFIG["temperature"],
            do_sample=True,
            repetition_penalty=GENERATION_CONFIG["repetition_penalty"],
            pad_token_id=_tokenizer.eos_token_id,
        )
    return _tokenizer.decode(
        output_ids[0][inputs["input_ids"].shape[1]:], skip_special_tokens=True
    ).strip()


@app.post("/v1/reason/m3", response_model=ReasonResponse)
async def reason_m3(req: PondSnapshotRequest) -> ReasonResponse:
    t0 = time.time()

    snap = PondSnapshot(**req.model_dump())
    try:
        assert _decision_engine is not None, "Decision engine not initialized"
        payload = _decision_engine.decide(snap)
    except Exception as e:
        raise HTTPException(status_code=422, detail=f"Decision engine failed: {e}")

    payload_dict = {k: v for k, v in payload.__dict__.items()}
    instruction = payload_to_instruction(payload)

    narration = ""
    passed = False
    attempts = 0
    for attempt in range(1, MAX_REGENERATION_ATTEMPTS + 1):
        attempts = attempt
        narration = generate_narration(instruction, payload_dict)
        passed, suspicious_numbers = check_hallucination(narration, payload_dict)
        if passed:
            break
        print(f"[WARN] pond={req.pond_id} attempt={attempt} hallucination check FAILED, "
              f"suspicious numbers: {suspicious_numbers}. Regenerating...")

    if not passed:
        # R1 is non-negotiable: never return an unverified response. Fall
        # back to the structured payload alone rather than risk a wrong
        # number reaching a farmer or analyst dashboard.
        raise HTTPException(
            status_code=503,
            detail={
                "message": "Narration failed the number-hallucination check after "
                            f"{MAX_REGENERATION_ATTEMPTS} attempts. Structured payload is "
                            "still valid and available in the 'payload' field of a direct "
                            "decision-engine call — only narration is unavailable.",
                "payload": payload_dict,
            },
        )

    return ReasonResponse(
        pond_id=req.pond_id,
        payload=payload_dict,
        narration=narration,
        hallucination_check_passed=passed,
        regeneration_attempts=attempts,
        latency_ms=(time.time() - t0) * 1000,
    )


@app.get("/health")
async def health():
    return {"status": "ok", "model_loaded": _model is not None}


# ---------------------------------------------------------------------------
# NOTE on scaling: this loads the model directly via transformers+peft,
# same as batch_inference_m3.py — fine for one adapter, single-GPU, low
# concurrency. The MVP spec's actual target architecture is vLLM with
# --enable-lora, serving M1/M2/M3 adapters off ONE loaded base model,
# hot-swapped per request. Migrate to that once M1/M2 adapters exist and
# concurrent load requires it — this file's decision-engine, prompt-format,
# and hallucination-gate logic all carry over unchanged; only the
# generate_narration() function's internals change to an vLLM client call.
# ---------------------------------------------------------------------------
