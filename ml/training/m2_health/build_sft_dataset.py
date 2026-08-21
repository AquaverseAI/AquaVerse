import os
import json
import random
import re
import hashlib
from pathlib import Path
import time

def extract_numbers(text: str) -> set:
    """Extract all distinct number strings from text."""
    return set(re.findall(r'\d+', str(text)))

def main():
    print("=" * 60)
    print("M2 SFT Dataset Generation (Updated) — Phase 2, Step 2.1")
    print("=" * 60)
    
    # Setup paths
    repo_root = Path(__file__).resolve().parents[3]
    out_dir = repo_root / "ml" / "datasets" / "sft"
    out_dir.mkdir(parents=True, exist_ok=True)
    out_file = out_dir / "m2_health_sft.jsonl"
    
    num_samples = 15000
    valid_samples = []
    
    # Fault types mapping to causes/confirmations
    fault_map = {
        "sensor_drift": ("sensor biofouling or calibration drift", "cleaning and manually checking the probe"),
        "aerator_failure": ("a mechanical aerator failure", "inspecting the paddlewheels and power supply"),
        "algal_crash": ("an algal bloom crash causing rapid DO depletion", "checking Secchi disk depth and water color"),
        "high_stocking_stress": ("overcrowding-induced anoxia", "reviewing feeding rates and biomass sampling"),
        "vibrio_outbreak": ("a potential Vibrio bacterial outbreak", "plating water samples on TCBS agar")
    }
    
    seasons = ["Summer", "Monsoon", "Winter"]
    
    print("⚙️  Generating 15,000 instruction pairs...")
    t0 = time.time()
    
    while len(valid_samples) < num_samples:
        # Generate random inputs
        risk_score = round(random.uniform(0.1, 0.99), 2)
        gate_temp = round(random.uniform(0.1, 0.9), 2)
        gate_img = round(1.0 - gate_temp, 2)
        stress_hours = random.randint(0, 48)
        stock_density = random.randint(30, 120)
        season = random.choice(seasons)
        
        # 7 Clinical Concepts
        v_gill_disc = round(random.uniform(0.0, 1.0), 2)
        v_lesions = round(random.uniform(0.0, 1.0), 2)
        v_red_spots = round(random.uniform(0.0, 1.0), 2)
        v_ulcers = round(random.uniform(0.0, 1.0), 2)
        v_black_gills = round(random.uniform(0.0, 1.0), 2)
        v_white_spots = round(random.uniform(0.0, 1.0), 2)
        v_lethargy = round(random.uniform(0.0, 1.0), 2)
        
        fault_key, (disease_x, confirm_y) = random.choice(list(fault_map.items()))
        
        # Build prompt payload
        input_payload = (
            f"Calibrated Risk Score: {risk_score}\n"
            f"GMU Gate Contributions -> Temporal: {gate_temp}, Vision: {gate_img}\n"
            f"Vision Concept Activations:\n"
            f"- gill_discolouration: {v_gill_disc}\n"
            f"- lesions: {v_lesions}\n"
            f"- red_spots: {v_red_spots}\n"
            f"- ulcers: {v_ulcers}\n"
            f"- black_gills: {v_black_gills}\n"
            f"- white_spots: {v_white_spots}\n"
            f"- lethargy: {v_lethargy}\n"
            f"Accumulated Stress-Hours: {stress_hours}\n"
            f"Stocking Density: {stock_density} pcs/m2\n"
            f"Season: {season}"
        )
        
        system_instruction = "You are the AquaVerse AI assistant. Analyze the given pond sensor and vision data to determine root causes and recommend actionable interventions."
        
        # Build target reasoning
        # Rule R2: Strict guardrail phrasing required
        r2_phrase = f"this pattern is consistent with {disease_x} — confirm by {confirm_y}"
        
        target_output_no_list_nums = (
            f"Root-Cause Chain:\n"
            f"The calibrated risk score of {risk_score} is driven by the temporal gate ({gate_temp}) and vision gate ({gate_img}). "
            f"With {stress_hours} stress-hours accumulated and a stocking density of {stock_density}, {r2_phrase}.\n\n"
            f"Actionable Interventions:\n"
            f"- Immediately increase aeration if DO is low.\n"
            f"- Reduce feed temporarily.\n\n"
            f"Advisory Summary:\n"
            f"Please observe the pond closely. The lesion activation is {v_lesions} and lethargy is {v_lethargy}."
        )
        
        # Rule R1: Number hallucination check
        input_nums = extract_numbers(input_payload)
        target_nums = extract_numbers(target_output_no_list_nums)
        
        if target_nums.issubset(input_nums):
            valid_samples.append({
                "messages": [
                    {"role": "system", "content": system_instruction},
                    {"role": "user", "content": input_payload},
                    {"role": "assistant", "content": target_output_no_list_nums}
                ]
            })
            
    print(f"  Generated {len(valid_samples)} valid samples in {time.time() - t0:.2f}s")
    
    # Save JSONL
    print(f"\n💾 Saving dataset to {out_file}...")
    with open(out_file, 'w', encoding='utf-8') as f:
        for sample in valid_samples:
            f.write(json.dumps(sample) + "\n")
            
    # Hash
    hasher = hashlib.sha256()
    with open(out_file, 'rb') as f:
        buf = f.read()
        hasher.update(buf)
    file_hash = hasher.hexdigest()
    print(f"  SHA-256 Hash: {file_hash}")
    
    # MLflow
    try:
        import mlflow
        mlflow_uri = os.getenv("MLFLOW_TRACKING_URI", "http://127.0.0.1:5000")
        mlflow_exp = os.getenv("MLFLOW_EXPERIMENT_NAME", "aquaverse-production")
        mlflow.set_tracking_uri(mlflow_uri)
        mlflow.set_experiment(mlflow_exp)
        with mlflow.start_run(run_name="sft_dataset_generation_v2"):
            mlflow.log_params({
                "num_samples": num_samples,
                "dataset_hash": file_hash,
                "rule_r2_enforced": True,
                "rule_r1_enforced": True,
                "hallucination_check": "strict_numeral_subset",
                "concepts_included": True
            })
            mlflow.log_artifact(str(out_file))
            mlflow.set_tags({"phase": "2.1_sft_dataset"})
        print(f"  Logged to MLflow successfully.")
    except ImportError:
        print("  MLflow not installed, skipping logging.")
        
    print("\n✅ SFT dataset generation complete.")

if __name__ == "__main__":
    main()
