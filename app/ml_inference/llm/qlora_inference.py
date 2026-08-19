"""
QLoRA Inference — Runs Unsloth Qwen3-8B 4-bit in-process.
"""
import asyncio
from pathlib import Path
from app.config import get_settings

class QLoRAInference:
    def __init__(self):
        settings = get_settings()
        repo_root = Path(settings.m3_engine_dir).resolve().parents[2]
        self.adapter_path = repo_root / "ml" / "artifacts" / "m2_health" / "m2_health-lora-0.1.0"
        
        self.model = None
        self.tokenizer = None
        self.max_seq_length = 2048

    def _load(self):
        if self.model is not None:
            return
        from unsloth import FastLanguageModel
        import torch
        
        # Load the base model and LoRA adapter natively in 4-bit precision
        self.model, self.tokenizer = FastLanguageModel.from_pretrained(
            model_name=str(self.adapter_path),
            max_seq_length=self.max_seq_length,
            dtype=torch.float16, 
            load_in_4bit=True,
        )
        FastLanguageModel.for_inference(self.model)

    def _generate_sync(self, prompt: str) -> str:
        self._load()
        # Ensure we use EOS token correctly for chat/generation
        inputs = self.tokenizer([prompt], return_tensors="pt").to("cuda")
        outputs = self.model.generate(**inputs, max_new_tokens=512, use_cache=True, pad_token_id=self.tokenizer.eos_token_id)
        return self.tokenizer.batch_decode(outputs, skip_special_tokens=True)[0]

    async def generate(self, prompt: str) -> str:
        # Run the blocking LLM inference in a background thread to prevent starving the FastAPI event loop
        return await asyncio.to_thread(self._generate_sync, prompt)

_instance = QLoRAInference()

async def generate_advisory(payload: dict) -> str:
    """Format payload and generate advisory"""
    
    prompt = "You are an expert aquaculture AI. Generate a root-cause chain, actionable interventions, and advisory summary.\n\n"
    prompt += "Input Payload:\n"
    prompt += f"Calibrated Risk Score: {payload['calibrated_risk_score']}\n"
    prompt += f"GMU Gate Contributions -> Temporal: {payload['gate_temporal']}, Vision: {payload['gate_vision']}\n"
    prompt += "Vision Concept Activations:\n"
    for k, v in payload['concept_activations'].items():
        prompt += f"- {k}: {v}\n"
    prompt += f"Accumulated Stress-Hours: {payload['stress_hours']}\n"
    if payload.get('stocking_density'):
        prompt += f"Stocking Density: {payload['stocking_density']}\n"
        
    prompt += "\nResponse:\n"
    
    out = await _instance.generate(prompt)
    
    # Extract only the response text
    if "Response:\n" in out:
        out = out.split("Response:\n")[1].strip()
        
    return out
