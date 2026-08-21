import os
import sys
import time
from pathlib import Path
from PIL import Image
import pandas as pd

import torch
import torch.nn as nn
import torch.optim as optim
from torch.utils.data import DataLoader, random_split, Dataset
import torchvision.transforms as T

# Paths
REPO_ROOT  = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(REPO_ROOT))

CSV_PATH   = REPO_ROOT / "ml" / "datasets" / "vision_metadata.csv"
ARTIFACTS  = REPO_ROOT / "ml" / "artifacts" / "m2_health" / "image_branch"
ARTIFACTS.mkdir(parents=True, exist_ok=True)

MLFLOW_URI = os.getenv("MLFLOW_TRACKING_URI", "http://127.0.0.1:5000")
MLFLOW_EXP = os.getenv("MLFLOW_EXPERIMENT_NAME", "aquaverse-production")

SYMPTOM_COLS = ["gill_discolouration", "lesions", "red_spots", "ulcers", "black_gills", "white_spots", "lethargy"]

# Dataset Wrapper for Modality Dropout [3]
class ConceptDataset(Dataset):
    def __init__(self, df, transform, dropout_p: float = 0.5):
        self.df = df
        self.transform = transform
        self.dropout_p = dropout_p

    def __len__(self):
        return len(self.df)

    def __getitem__(self, idx):
        row = self.df.iloc[idx]
        img_path = row["filepath"]
        
        try:
            img = Image.open(img_path).convert('RGB')
        except:
            # Fallback if image corrupt
            img = Image.new('RGB', (224, 224))
            
        img = self.transform(img)
        
        # Multi-hot label
        label = torch.tensor(row[SYMPTOM_COLS].values.astype(float), dtype=torch.float32)
        
        # Modality dropout p=0.5
        if self.dropout_p > 0 and torch.rand(1).item() < self.dropout_p:
            img = torch.zeros_like(img)
            mask = torch.tensor(0.0)
        else:
            mask = torch.tensor(1.0)
            
        return img, label, mask

def build_model(backbone: str, num_concepts: int):
    try:
        import timm
    except ImportError:
        raise ImportError("Install: pip install timm")

    # Shared backbone
    model = timm.create_model(backbone, pretrained=True, num_classes=0)
    embed_dim = model.num_features
    
    # Unified Concept Head
    concept_head = nn.Sequential(
        nn.Dropout(0.2),
        nn.Linear(embed_dim, num_concepts)
        # Note: Sigmoid is applied internally by BCEWithLogitsLoss during training
        # and manually during inference via torch.sigmoid()
    )
    
    return model, concept_head, embed_dim

def train_image_branch(
    backbone: str = "efficientnet_b0",
    epochs:   int = 10,
    batch_size: int = 32,
    lr: float = 1e-3,
    device: str | None = None,
):
    device = device or ("cuda" if torch.cuda.is_available() else "cpu")
    print(f"  Device: {device}")
    
    transform = T.Compose([
        T.Resize(256), T.CenterCrop(224),
        T.RandomHorizontalFlip(), T.RandomRotation(15),
        T.ColorJitter(brightness=0.2, contrast=0.2, saturation=0.1),
        T.ToTensor(),
        T.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225]),
    ])

    print("\n📂 Loading Dataset from CSV...")
    if not CSV_PATH.exists():
        print(f"❌ Metadata file not found at {CSV_PATH}")
        sys.exit(1)
        
    df = pd.read_csv(CSV_PATH)
    
    dataset = ConceptDataset(df, transform=transform, dropout_p=0.5)
    
    n_train = int(len(dataset) * 0.8)
    n_val = len(dataset) - n_train
    
    train_ds, val_ds = random_split(dataset, [n_train, n_val], generator=torch.Generator().manual_seed(42))
    
    train_loader = DataLoader(train_ds, batch_size=batch_size, shuffle=True, num_workers=2, drop_last=True)
    val_loader   = DataLoader(val_ds,   batch_size=batch_size, shuffle=False, num_workers=2)

    backbone_model, concept_head, embed_dim = build_model(backbone, len(SYMPTOM_COLS))
    backbone_model = backbone_model.to(device)
    concept_head = concept_head.to(device)
    
    params = list(backbone_model.parameters()) + list(concept_head.parameters())
    optimizer = optim.AdamW(params, lr=lr, weight_decay=1e-4)
    scheduler = optim.lr_scheduler.CosineAnnealingLR(optimizer, T_max=epochs)
    
    criterion = nn.BCEWithLogitsLoss()

    best_val_loss = float("inf")
    t0 = time.perf_counter()

    print("\n🚀 Starting Training...")
    
    for epoch in range(1, epochs + 1):
        backbone_model.train(); concept_head.train()
        train_loss = 0.0
        
        for imgs, labels, _ in train_loader:
            imgs, labels = imgs.to(device), labels.to(device)
            optimizer.zero_grad()
            
            feats = backbone_model(imgs)
            logits = concept_head(feats)
            
            loss = criterion(logits, labels)
            loss.backward()
            optimizer.step()
            train_loss += loss.item()
            
        scheduler.step()
        train_loss /= len(train_loader)
        
        # Validation
        backbone_model.eval(); concept_head.eval()
        val_loss = 0.0
        with torch.no_grad():
            for imgs, labels, _ in val_loader:
                feats = backbone_model(imgs.to(device))
                logits = concept_head(feats)
                val_loss += criterion(logits, labels.to(device)).item()

        val_loss /= len(val_loader)

        print(f"  Epoch {epoch:3d}/{epochs} | Train Loss: {train_loss:.4f} | Val Loss: {val_loss:.4f}")

        if val_loss < best_val_loss:
            best_val_loss = val_loss
            # Save the best model state securely in memory, then serialize below
            best_backbone_sd = backbone_model.state_dict()
            best_concept_sd = concept_head.state_dict()

    elapsed = time.perf_counter() - t0
    print(f"\n✅ Training complete in {elapsed:.1f}s")
    print(f"   Best Val Loss: {best_val_loss:.4f}")
    
    print("\n⚠️  FREEZING image branch now (PRD §5.4 — do not unfreeze until Step 1.4)")
    for p in list(backbone_model.parameters()) + list(concept_head.parameters()):
        p.requires_grad = False

    # Save frozen artifact
    frozen_path = ARTIFACTS / "frozen_image_branch.pt"
    
    torch.save({
        "backbone":       best_backbone_sd,
        "concept_head":   best_concept_sd,
        "concept_names":  SYMPTOM_COLS,
        "backbone_name":  backbone,
        "embed_dim":      embed_dim,
        "frozen":         True,
    }, frozen_path)
    print(f"   Frozen checkpoint saved: {frozen_path}")

    # MLflow
    try:
        import mlflow
        mlflow.set_tracking_uri(MLFLOW_URI)
        mlflow.set_experiment(MLFLOW_EXP)
        with mlflow.start_run(run_name=f"image_branch_concept_{backbone}"):
            mlflow.log_params({"backbone": backbone, "epochs": epochs,
                               "lr": lr, "batch_size": batch_size,
                               "n_concepts": len(SYMPTOM_COLS),
                               "modality_dropout_p": 0.5})
            mlflow.log_metrics({"best_val_loss": best_val_loss, "train_time_s": elapsed})
            mlflow.set_tags({"phase": "1.2_image_branch", "frozen": "true",
                             "hardware": "RTX5070-12GB",
                             "dataset": "concept_bottleneck_v1"})
            mlflow.log_artifact(str(frozen_path))
        print(f"   MLflow run logged ✅")
    except Exception as e:
        print(f"   MLflow error: {e}")

if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument("--backbone", default="efficientnet_b0", choices=["efficientnet_b0", "convnext_tiny"])
    parser.add_argument("--epochs",     type=int, default=10)
    parser.add_argument("--batch-size", type=int, default=32)
    parser.add_argument("--lr",         type=float, default=1e-3)
    parser.add_argument("--device",     default=None, help="cuda|cpu (auto-detected if omitted)")
    args = parser.parse_args()

    print("=" * 60)
    print("M2 Image Branch Training (Concept Bottleneck) — Phase 1, Step 1.2")
    print("=" * 60)

    train_image_branch(
        backbone=args.backbone,
        epochs=args.epochs,
        batch_size=args.batch_size,
        lr=args.lr,
        device=args.device,
    )
