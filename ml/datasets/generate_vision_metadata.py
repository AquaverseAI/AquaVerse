import os
from pathlib import Path
import pandas as pd

def main():
    print("=" * 60)
    print("M2 Vision Concept Bottleneck Metadata Generation")
    print("=" * 60)

    repo_root = Path(__file__).resolve().parents[2]
    datasets_dir = repo_root / "ml" / "datasets"
    
    shrimp_dir = datasets_dir / "raw_images" / "shrimp_diseases" / "An Image Dataset for Computer Vision-Based Detection of Shrimp Diseases" / "Original"
    fish_dir = datasets_dir / "raw_images" / "freshwater_fish" / "An image dataset of freshwater fish"
    
    out_file = datasets_dir / "vision_metadata.csv"
    
    symptom_cols = ["gill_discolouration", "lesions", "red_spots", "ulcers", "black_gills", "white_spots", "lethargy"]
    
    folder_map = {
        "Bacterial Gill Diseases": {"gill_discolouration": 1, "lesions": 1},
        "Bacterial Red Diseases": {"red_spots": 1, "lesions": 1},
        "Epizootic Ulcerative Syndrome (EUS)": {"ulcers": 1, "lesions": 1},
        "Healthy Fish": {},
        "BG": {"black_gills": 1},
        "WSSV": {"white_spots": 1, "lethargy": 1},
        "WSSV_BG": {"white_spots": 1, "lethargy": 1, "black_gills": 1},
        "Healthy": {}
    }
    
    data = []
    
    directories_to_scan = [
        shrimp_dir / "Disease",
        shrimp_dir / "Healthy",
        fish_dir
    ]
    
    for base_dir in directories_to_scan:
        if not base_dir.exists():
            print(f"Directory not found: {base_dir}")
            continue
            
        for root, dirs, files in os.walk(base_dir):
            if "Augmented" in root:
                continue
                
            folder_name = os.path.basename(root)
            if folder_name in folder_map:
                symptoms = folder_map[folder_name]
                for file in files:
                    if file.lower().endswith(('.png', '.jpg', '.jpeg')):
                        filepath = os.path.join(root, file)
                        # Initialize row with all 0s
                        row = {"filepath": filepath}
                        for col in symptom_cols:
                            row[col] = 0
                            
                        # Apply 1s based on map
                        for k, v in symptoms.items():
                            row[k] = v
                            
                        data.append(row)
                        
    if not data:
        print("No images found! Please ensure datasets are pasted in the correct location.")
        return
        
    df = pd.DataFrame(data)
    
    # Save to csv
    df.to_csv(out_file, index=False)
    print(f"Generated {len(df)} records.")
    print(f"Saved to {out_file}")
    
if __name__ == "__main__":
    main()
