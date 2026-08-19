"""
M2 Multimodal Engine — runs the PyTorch Concept Bottleneck + GMU Fusion.
"""

from __future__ import annotations

import json
import pickle
from dataclasses import dataclass
from pathlib import Path
from typing import Any
import numpy as np
from datetime import datetime
from PIL import Image

import torch
import torchvision.transforms as T

# Reuse the existing sys.path patch from M3 so we can import from `ml.`
from app.ml_inference.numeric.m3_engine import _ensure_engine_dir_on_path
_ensure_engine_dir_on_path()

# Re-import the exact model architectures we trained
from ml.training.m2_health.train_fusion import AquaVerseMultimodal
from app.ml_inference.numeric import m2_risk_engine

from app.config import get_settings

@dataclass(frozen=True)
class MultimodalRiskResult:
    calibrated_risk_score: float
    gate_vision: float
    gate_temporal: float
    concept_activations: dict[str, float]
    stress_hours: float
    stocking_density: float | None

class M2MultimodalBundle:
    def __init__(self):
        settings = get_settings()
        self.repo_root = Path(settings.m3_engine_dir).resolve().parents[2]
        
        self.artifacts_dir = self.repo_root / "ml" / "artifacts" / "m2_health"
        self.image_branch_pt = self.artifacts_dir / "image_branch" / "frozen_image_branch.pt"
        self.fusion_pt = self.artifacts_dir / "fusion" / "fusion_stage2_best.pt"
        self.temporal_metrics = self.artifacts_dir / "temporal" / "metrics.json"
        self.calibrator_pkl = self.artifacts_dir / "calibrator.pkl"

        self.device = "cuda" if torch.cuda.is_available() else "cpu"

        # Load Temporal Metadata
        with open(self.temporal_metrics) as f:
            temp_meta = json.load(f)
        self.n_features = len(temp_meta["feature_cols"])
        self.temporal_feature_cols = temp_meta["feature_cols"]

        # Load Fusion Model
        self.model = AquaVerseMultimodal(n_temporal_features=self.n_features, image_branch_pt=self.image_branch_pt)
        self.model.load_state_dict(torch.load(self.fusion_pt, map_location=self.device, weights_only=True))
        self.model.to(self.device)
        self.model.eval()

        # Load Calibrator
        with open(self.calibrator_pkl, "rb") as f:
            self.calibrator = pickle.load(f)

        # Vision Transforms
        self.transform = T.Compose([
            T.Resize((224, 224)),
            T.ToTensor(),
            T.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225]),
        ])

_bundle_instance: M2MultimodalBundle | None = None

def get_multimodal_bundle() -> M2MultimodalBundle:
    global _bundle_instance
    if _bundle_instance is None:
        _bundle_instance = M2MultimodalBundle()
    return _bundle_instance

def extract_temporal_vector(points: list[m2_risk_engine.RawLogPoint], doc_value: int | None, stocking_count: int | None, now: datetime) -> tuple[torch.Tensor, float]:
    """Extract the exact temporal features the fusion model expects."""
    bundle = get_multimodal_bundle()
    
    # We use m2_risk_engine's _build_raw_frame to get the raw df, then sim.features
    effective_doc = doc_value if doc_value is not None else m2_risk_engine.DEFAULT_DOC
    effective_stocking_count = stocking_count if (stocking_count is not None and stocking_count > 0) else m2_risk_engine.STOCKING_COUNT_PLACEHOLDER

    sorted_points = sorted(points, key=lambda p: p.recorded_at)
    if sorted_points:
        raw_df = m2_risk_engine._build_raw_frame(sorted_points, effective_doc)
    else:
        raw_df = m2_risk_engine._build_raw_frame(
            [m2_risk_engine.RawLogPoint(recorded_at=now, do_mg_l=None, tan_mg_l=None, ph=None, water_temp_c=None, alkalinity_mg_l=None, no2_mg_l=None, no3_mg_l=None, salinity_ppt=None)],
            effective_doc,
        )

    from sim.features import compute_features
    from sim.species import get_species
    # using vannamei as fallback
    sp = get_species("vannamei")
    feat_df = compute_features(raw_df, stocking_weight_g=sp.stocking_weight_g, stocking_count=effective_stocking_count)
    last = feat_df.iloc[-1]

    # Build the 1D tensor ordered exactly by temporal_feature_cols
    vec = []
    for col in bundle.temporal_feature_cols:
        val = last.get(col, 0.0)
        vec.append(float(val) if not np.isnan(val) else 0.0)
        
    stress_hours = float(last.get("stress_hours_lt3_24h", 0.0))
    if np.isnan(stress_hours):
        stress_hours = 0.0

    return torch.tensor([vec], dtype=torch.float32), stress_hours

def score_multimodal(
    points: list[m2_risk_engine.RawLogPoint],
    doc_value: int | None,
    stocking_count: int | None,
    now: datetime,
    image: Image.Image | None,
    image_age_hours: float
) -> MultimodalRiskResult:
    bundle = get_multimodal_bundle()
    
    # 1. Temporal
    x_t, stress_hours = extract_temporal_vector(points, doc_value, stocking_count, now)
    x_t = x_t.to(bundle.device)

    # 2. Image
    if image is not None:
        img_t = bundle.transform(image.convert("RGB")).unsqueeze(0).to(bundle.device)
        mask = torch.tensor([[1.0]], device=bundle.device)
    else:
        img_t = torch.zeros((1, 3, 224, 224), device=bundle.device)
        mask = torch.tensor([[0.0]], device=bundle.device)
        
    age_t = torch.tensor([[image_age_hours]], device=bundle.device, dtype=torch.float32)

    # 3. Model Forward
    with torch.no_grad():
        # Get concept activations directly from image branch if image is present
        concept_dict = {}
        if image is not None:
            feats = bundle.model.backbone(img_t)
            concept_logits = bundle.model.concept_head(feats)
            concept_probs = torch.sigmoid(concept_logits).squeeze().cpu().numpy()
            for i, name in enumerate(bundle.model.concept_names):
                concept_dict[name] = round(float(concept_probs[i]), 4)
        else:
            for name in bundle.model.concept_names:
                concept_dict[name] = 0.0

        logits, gates = bundle.model(x_t, img_t, mask, age_t)
        
        raw_prob = torch.sigmoid(logits.squeeze()).cpu().numpy()
        
        # 4. Calibrate
        import sklearn.linear_model
        # Check if calibrator is LogisticRegression or Isotonic
        if hasattr(bundle.calibrator, "predict_proba"):
            calibrated_prob = bundle.calibrator.predict_proba(np.array([[raw_prob]]))[:, 1][0]
        else:
            calibrated_prob = bundle.calibrator.predict(np.array([raw_prob]))[0]

        gate_t = float(gates[0, 0].cpu())
        gate_v = float(gates[0, 1].cpu())

    return MultimodalRiskResult(
        calibrated_risk_score=round(float(calibrated_prob), 4),
        gate_temporal=round(gate_t, 4),
        gate_vision=round(gate_v, 4),
        concept_activations=concept_dict,
        stress_hours=round(stress_hours, 2),
        stocking_density=None
    )
