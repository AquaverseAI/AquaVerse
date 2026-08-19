"""Digital Twin — Simulator Adapter."""

from __future__ import annotations

from typing import TYPE_CHECKING
from uuid import UUID

from app.core.timezones import utcnow
from app.twin.schemas import StateVector, WhatIfScenario

if TYPE_CHECKING:
    from app.db.models.log import Log
    from app.db.models.pond import Pond


def create_current_state(pond: Pond, recent_log: Log | None, suppressed: bool, suppression_reason: str | None) -> StateVector:
    """Create a StateVector from the latest sensor data."""
    now = utcnow()
    if not recent_log:
        return StateVector(
            pond_id=pond.id,
            as_of=now,
            temperature_c=28.0,
            dissolved_oxygen_mgl=6.0,
            ph=7.8,
            salinity_ppt=15.0,
            ammonia_nh3_mgl=0.1,
            turbidity_ntu=12.0,
            biomass_kg_estimated=None,
            fcr_estimated=None,
            suppressed=suppressed,
            suppression_reason=suppression_reason,
        )

    return StateVector(
        pond_id=pond.id,
        as_of=now,
        temperature_c=recent_log.temperature_c,
        dissolved_oxygen_mgl=recent_log.dissolved_oxygen_mgl,
        ph=recent_log.ph,
        salinity_ppt=recent_log.salinity_ppt,
        ammonia_nh3_mgl=recent_log.ammonia_nh3_mgl,
        turbidity_ntu=recent_log.turbidity_ntu,
        biomass_kg_estimated=None,
        fcr_estimated=None,
        suppressed=suppressed,
        suppression_reason=suppression_reason,
    )


def simulate_whatif(current_state: StateVector, scenario: WhatIfScenario) -> StateVector:
    """Apply what-if scenario deltas to the current state."""
    # Simple linear arithmetic (Phase 4 stub/adapter).
    # Real mechanistic simulation would run PondSimulator from current boundary conditions.
    now = utcnow()
    
    simulated_temp = current_state.temperature_c
    if simulated_temp is not None and scenario.delta_temperature_c is not None:
        simulated_temp += scenario.delta_temperature_c
        
    simulated_do = current_state.dissolved_oxygen_mgl
    if simulated_do is not None and scenario.delta_dissolved_oxygen_mgl is not None:
        simulated_do += scenario.delta_dissolved_oxygen_mgl
        
    simulated_salinity = current_state.salinity_ppt
    if simulated_salinity is not None and scenario.delta_salinity_ppt is not None:
        simulated_salinity += scenario.delta_salinity_ppt

    return StateVector(
        pond_id=current_state.pond_id,
        as_of=now,
        temperature_c=simulated_temp,
        dissolved_oxygen_mgl=simulated_do,
        ph=current_state.ph,
        salinity_ppt=simulated_salinity,
        ammonia_nh3_mgl=current_state.ammonia_nh3_mgl,
        turbidity_ntu=current_state.turbidity_ntu,
        biomass_kg_estimated=current_state.biomass_kg_estimated,
        fcr_estimated=current_state.fcr_estimated,
        suppressed=current_state.suppressed,
        suppression_reason=current_state.suppression_reason,
    )
