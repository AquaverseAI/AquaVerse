"""Digital Twin — Pydantic v2 schemas.

RULE: The twin endpoint NEVER reveals whether data came from the simulator or a real sensor.
Same schema either way.
"""

from __future__ import annotations

from datetime import datetime
from typing import TYPE_CHECKING
from uuid import UUID

from pydantic import BaseModel, Field

if TYPE_CHECKING:
    pass


class StateVector(BaseModel):
    """
    Current state of the digital twin for a pond.
    Schema is identical whether backed by real sensors or the simulator.
    """

    pond_id: UUID
    as_of: datetime
    temperature_c: float | None = None
    dissolved_oxygen_mgl: float | None = None
    ph: float | None = None
    salinity_ppt: float | None = None
    ammonia_nh3_mgl: float | None = None
    turbidity_ntu: float | None = None
    biomass_kg_estimated: float | None = None
    fcr_estimated: float | None = None  # feed conversion ratio
    # Suppression — always visible
    suppressed: bool = Field(
        ...,
        description=("True if the state vector is in blind state. Always surfaced — never hidden."),
    )
    suppression_reason: str | None = None


class WhatIfScenario(BaseModel):
    """What-if simulation inputs."""

    delta_temperature_c: float | None = Field(default=None, ge=-10, le=10)
    delta_dissolved_oxygen_mgl: float | None = Field(default=None, ge=-10, le=10)
    delta_salinity_ppt: float | None = Field(default=None, ge=-20, le=20)
    delta_feed_rate_pct: float | None = Field(default=None, ge=-100, le=200)
    horizon_hours: int = Field(default=24, ge=1, le=168)


class WhatIfOut(BaseModel):
    """Simulated state after applying the scenario."""

    pond_id: UUID
    scenario: WhatIfScenario
    simulated_state: StateVector
    risk_delta: float = Field(
        ...,
        description="Change in risk score relative to current baseline (positive = more risk)",
    )
    generated_at: datetime
