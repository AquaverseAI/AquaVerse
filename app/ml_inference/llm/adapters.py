"""LoRA adapter definitions: m1_chemistry | m2_health | m3_production. Phase 4."""

from __future__ import annotations

from enum import StrEnum


class Adapter(StrEnum):
    M1_CHEMISTRY = "m1_chemistry"
    M2_HEALTH = "m2_health"
    M3_PRODUCTION = "m3_production"
