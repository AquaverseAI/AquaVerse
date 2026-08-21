from unsloth import FastLanguageModel
import os
import torch
import json
from datasets import load_dataset
from trl import SFTTrainer
from transformers import TrainingArguments


def main():
    print("=" * 60)
    print("M2 LLM Reasoner QLoRA Fine-tuning — Phase 2, Step 2.2")
    print("=" * 60)
    
    # 1. Base Model Configuration (strictly Qwen3-8B)
    model_id = "unsloth/Qwen3-8B"
    max_seq_length = 2048
    
    print(f"Loading Base Model: {model_id} in 4-bit...")
    model, tokenizer = FastLanguageModel.from_pretrained(
        model_name = model_id,
        max_seq_length = max_seq_length,
        dtype = None,
        load_in_4bit = True,
    )
    
    # 2. Unsloth QLoRA Configuration
    print("Applying QLoRA Adapter (r=16, alpha=32, dropout=0.05)...")
    model = FastLanguageModel.get_peft_model(
        model,
        r = 16,
        target_modules = ["q_proj", "k_proj", "v_proj", "o_proj",
                          "gate_proj", "up_proj", "down_proj"],
        lora_alpha = 32,
        lora_dropout = 0.05,
        bias = "none",
        use_gradient_checkpointing = "unsloth",
        random_state = 42,
    )
    
    # 3. Training Data & Hyperparameters
    print("Loading 15,000 instruction pairs...")
    dataset_path = "ml/datasets/sft/m2_health_sft.jsonl"
    dataset = load_dataset("json", data_files=dataset_path, split="train")
    
    def formatting_prompts_func(examples):
        texts = []
        for messages in examples["messages"]:
            system = messages[0]["content"]
            user = messages[1]["content"]
            assistant = messages[2]["content"]
            text = f"<|im_start|>system\n{system}<|im_end|>\n<|im_start|>user\n{user}<|im_end|>\n<|im_start|>assistant\n{assistant}<|im_end|>"
            texts.append(text)
        return { "text" : texts }
        
    dataset = dataset.map(formatting_prompts_func, batched = True)
    
    print("Configuring Trainer (LR: 2e-4, Cosine Decay, Batch: 2, Grad Accum: 4)...")
    trainer = SFTTrainer(
        model = model,
        tokenizer = tokenizer,
        train_dataset = dataset,
        dataset_text_field = "text",
        max_seq_length = max_seq_length,
        dataset_num_proc = 2,
        args = TrainingArguments(
            per_device_train_batch_size = 2,
            gradient_accumulation_steps = 4,
            warmup_steps = 5,
            # For demonstration in the local loop, limit steps so it doesn't take 3 hours. 
            # 15,000 samples / (2*4) = 1875 steps per epoch. 
            max_steps = 10,  # <-- Set to 10 for rapid local CI/CD pipeline execution
            learning_rate = 2e-4,
            fp16 = not torch.cuda.is_bf16_supported(),
            bf16 = torch.cuda.is_bf16_supported(),
            logging_steps = 1,
            optim = "adamw_8bit",
            weight_decay = 0.01,
            lr_scheduler_type = "cosine",
            seed = 42,
            output_dir = "outputs",
        ),
    )
    
    # 4. MLflow Tracking
    mlflow_uri = os.getenv("MLFLOW_TRACKING_URI", "http://127.0.0.1:5000")
    mlflow_exp = os.getenv("MLFLOW_EXPERIMENT_NAME", "aquaverse-production")
    
    dataset_hash = "88569777f54a19371071d03df0fce1ef6eaf96e8cb1f49eb733669f8476a6771"
    adapter_name = "m2_health-lora-0.1.0"
    out_dir = f"ml/artifacts/m2_health/{adapter_name}"
    
    try:
        import mlflow
        mlflow.set_tracking_uri(mlflow_uri)
        mlflow.set_experiment(mlflow_exp)
        
        with mlflow.start_run(run_name=adapter_name):
            mlflow.log_params({
                "model": model_id,
                "r": 16,
                "lora_alpha": 32,
                "lora_dropout": 0.05,
                "dataset_hash": dataset_hash,
                "learning_rate": 2e-4,
                "lr_scheduler_type": "cosine",
                "per_device_train_batch_size": 2,
                "gradient_accumulation_steps": 4
            })
            mlflow.set_tags({
                "phase": "2.2_qlora_finetuning",
                "hardware": "RTX5070-12GB",
                "environment": "local CUDA"
            })
            
            print("🚀 Commencing QLoRA Training...")
            trainer.train()
            
            print(f"💾 Saving LoRA adapter to {out_dir}...")
            os.makedirs(out_dir, exist_ok=True)
            model.save_pretrained(out_dir)
            tokenizer.save_pretrained(out_dir)
            
            mlflow.log_artifact(out_dir)
            print("✅ Successfully logged to MLflow.")
            
    except ImportError:
        print("MLflow not found. Training without MLflow...")
        trainer.train()
        os.makedirs(out_dir, exist_ok=True)
        model.save_pretrained(out_dir)
        tokenizer.save_pretrained(out_dir)

if __name__ == "__main__":
    main()
