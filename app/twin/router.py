"""Digital Twin — router for /v1/twin."""

from __future__ import annotations

from typing import TYPE_CHECKING
from uuid import UUID

from fastapi import APIRouter, status

from app.core.timezones import utcnow
from app.twin.schemas import StateVector, WhatIfOut, WhatIfScenario

if TYPE_CHECKING:
    pass


router = APIRouter(prefix="/twin", tags=["Digital Twin"])


@router.get(
    "/{pond_id}/state",
    response_model=StateVector,
    summary="Get the current digital twin state for a pond",
    description=(
        "Returns the current state vector. "
        "RULE: The response is identical whether backed by real sensors or the simulator. "
        "The source is never revealed in the response schema."
    ),
)
async def get_twin_state(pond_id: UUID) -> StateVector:
    now = utcnow()
    return StateVector(
        pond_id=pond_id,
        as_of=now,
        temperature_c=28.5,
        dissolved_oxygen_mgl=6.2,
        ph=7.8,
        salinity_ppt=15.0,
        ammonia_nh3_mgl=0.3,
        turbidity_ntu=12.0,
        biomass_kg_estimated=450.0,
        fcr_estimated=1.4,
        suppressed=False,
    )


@router.post(
    "/{pond_id}/whatif",
    response_model=WhatIfOut,
    status_code=status.HTTP_200_OK,
    summary="Run a what-if simulation",
    description=(
        "Applies the given scenario deltas to the current twin state and returns the simulated outcome. "
        "Risk delta indicates how much the risk score would change."
    ),
)
async def whatif(pond_id: UUID, scenario: WhatIfScenario) -> WhatIfOut:
    now = utcnow()
    # Stub: apply simple delta arithmetic (Phase 4: call simulator_adapter)
    simulated = StateVector(
        pond_id=pond_id,
        as_of=now,
        temperature_c=28.5 + (scenario.delta_temperature_c or 0.0),
        dissolved_oxygen_mgl=6.2 + (scenario.delta_dissolved_oxygen_mgl or 0.0),
        ph=7.8,
        salinity_ppt=15.0 + (scenario.delta_salinity_ppt or 0.0),
        ammonia_nh3_mgl=0.3,
        turbidity_ntu=12.0,
        suppressed=False,
    )
    return WhatIfOut(
        pond_id=pond_id,
        scenario=scenario,
        simulated_state=simulated,
        risk_delta=0.05 if (scenario.delta_dissolved_oxygen_mgl or 0) < 0 else -0.02,
        generated_at=now,
    )
