"""Model registry sync — real deployed-artifact metadata (P2.7).

`GET /v1/models` used to return one hardcoded fixture row; `ModelRegistry`
(app/db/models/model_registry.py) existed but nothing ever wrote to it —
there is no training/registration pipeline in this repo yet to populate
it. This module closes that gap the only honest way available without
one: it derives a real registry row from the M2 LightGBM bundle that is
actually loaded and actively serving `/v1/ponds/{id}/risk` (real
`model_version`, real `test_metrics` — both read off the real trained
artifact in `app/ml_inference/numeric/m2_risk_engine.py`), and upserts it
idempotently so the table always reflects whatever model is genuinely
running, not a snapshot frozen at some past registration step.

One field is a documented substitution rather than the real thing:
`dataset_hash` is meant to be a hash of the *training dataset* (per the
model's own docstring), but no training pipeline in this repo persists
that anywhere for the model actually loaded here. Using the real
artifact file's SHA-256 instead is a legitimate proxy for "which trained
object is this, exactly" — same kind of documented, real-not-fabricated
substitution as Geo's DBSCAN-for-Kulldorff — but it is not literally a
dataset hash, and is labelled as such in `notes` below.
"""

from __future__ import annotations

import hashlib
from pathlib import Path

from sqlalchemy import select, update
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import get_settings
from app.db.models.model_registry import ModelRegistry
from app.ml_inference.numeric.m2_risk_engine import get_m2_engine_bundle

_MODEL_NAME = "risk_lightgbm"


def _artifact_sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(65536), b""):
            digest.update(chunk)
    return digest.hexdigest()


async def ensure_active_model_registered(session: AsyncSession) -> ModelRegistry:
    """Idempotent get-or-create: one row per distinct `model_version` of
    the real M2 bundle. Every call — not just the one that inserts a new
    row — leaves exactly one `is_active=True` row for `_MODEL_NAME`, so a
    row left over `is_active=True` from a previous artifact version (or
    from any other unrelated write to this table) always gets corrected,
    not just skipped over because the current version's row already
    happened to exist. Returns that active row.

    Two real races this guards against, both only possible across
    process restarts picking up a different artifact (a single process
    only ever sees one `model_version`, cached by
    `get_m2_engine_bundle`'s `lru_cache`):
      * A new `model_version` shows up (the artifact was redeployed) —
        the previous row(s) for this name must flip to `is_active=False`.
      * Two requests race to insert the first row for a brand-new
        version — the DB's unique `(name, version)` constraint (see the
        matching migration) turns the loser's INSERT into an
        IntegrityError instead of a silent duplicate row; caught below
        and treated as "someone else just created it", re-reading rather
        than erroring the request.
    """
    bundle = get_m2_engine_bundle()

    existing = (
        await session.execute(
            select(ModelRegistry).where(
                ModelRegistry.name == _MODEL_NAME, ModelRegistry.version == bundle.model_version
            )
        )
    ).scalar_one_or_none()

    if existing is None:
        settings = get_settings()
        artifact_path = (
            Path(settings.m3_engine_dir).resolve() / "models" / "m2_mortality_risk_baseline.txt"
        )
        entry = ModelRegistry(
            name=_MODEL_NAME,
            model_type="lightgbm",
            version=bundle.model_version,
            artifact_path=str(artifact_path),
            # Real artifact hash, standing in for training-dataset lineage
            # this repo's model doesn't persist anywhere — see module
            # docstring.
            dataset_hash=_artifact_sha256(artifact_path),
            metrics=bundle.test_metrics,
            is_active=True,
            notes=(
                "Auto-registered from the loaded M2 engine bundle. dataset_hash is the "
                "artifact file's own SHA-256, not a training-dataset hash — no training "
                "pipeline in this repo records the latter for this model."
            ),
        )
        session.add(entry)
        try:
            await session.flush()
        except IntegrityError:
            # Another concurrent request already registered this exact
            # (name, version) — real DB-enforced dedup, not a made-up
            # "shouldn't happen" assumption. Re-read what it inserted.
            await session.rollback()
            existing = (
                await session.execute(
                    select(ModelRegistry).where(
                        ModelRegistry.name == _MODEL_NAME,
                        ModelRegistry.version == bundle.model_version,
                    )
                )
            ).scalar_one()
        else:
            existing = entry

    if not existing.is_active:
        existing.is_active = True

    # Deactivate every *other* row for this model name, regardless of
    # which branch above ran — the bug this fixes (found in code review)
    # was skipping this step whenever `existing` was already found on
    # the first SELECT, leaving a stale is_active=True row for a
    # different version untouched.
    await session.execute(
        update(ModelRegistry)
        .where(
            ModelRegistry.name == _MODEL_NAME,
            ModelRegistry.id != existing.id,
            ModelRegistry.is_active.is_(True),
        )
        .values(is_active=False)
    )

    await session.commit()
    await session.refresh(existing)
    return existing
