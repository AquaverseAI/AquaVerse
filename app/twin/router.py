"""Digital Twin — router for /v1/twin (P2.2)."""

from __future__ import annotations

from datetime import timedelta
from typing import TYPE_CHECKING
from uuid import UUID

from fastapi import APIRouter, HTTPException, status
from fastapi.responses import HTMLResponse

from app.alerts import suppression
from app.config import get_settings
from app.core import rbac
from app.core.timezones import utcnow
from app.db.models.pond import Pond
from app.deps import CurrentUser, DbSession
from app.ml_inference.numeric import m2_risk_engine
from app.ml_inference.router import _RISK_LOOKBACK_DAYS, _fetch_active_crop, _fetch_recent_logs
from app.twin import simulator_adapter
from app.twin.schemas import StateVector, WhatIfOut, WhatIfScenario

if TYPE_CHECKING:
    from app.db.models.log import Log

router = APIRouter(prefix="/twin", tags=["Digital Twin"])


async def _get_pond_or_404(session: DbSession, pond_id: UUID) -> Pond:
    pond = await session.get(Pond, pond_id)
    if pond is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Pond not found")
    return pond


async def _build_state_vector(
    session: DbSession, pond: Pond, logs: list[Log] | None = None
) -> StateVector:
    """Build the twin's state vector — real sensor data when the pond has
    a recent reading, a species-parameterized simulated baseline
    (`simulator_adapter.py`) otherwise. Per the schema's own rule, the
    caller can never tell which branch produced the response other than
    via the always-visible `suppressed`/`suppression_reason` fields.

    Biomass/FCR are always simulator-estimated (see
    `simulator_adapter.py`'s honesty notes) — there is no real biomass
    telemetry or feed-log pipeline anywhere in this repo, real sensor data
    or not.
    """
    now = utcnow()
    blind = await suppression.check_blind_state(session, pond.id, now)
    species_key = m2_risk_engine.resolve_species_key(pond.species)

    crop = await _fetch_active_crop(session, pond.id)
    if crop is not None:
        doc = max((now.date() - crop.stocking_date).days, 0)
        stocking_count = crop.post_larvae_count or m2_risk_engine.STOCKING_COUNT_PLACEHOLDER
    else:
        doc = m2_risk_engine.DEFAULT_DOC
        stocking_count = m2_risk_engine.STOCKING_COUNT_PLACEHOLDER

    sim = simulator_adapter.simulate_state(pond.id, species_key, doc, stocking_count)

    if not blind.suppressed:
        if logs is None:
            since = now - timedelta(days=_RISK_LOOKBACK_DAYS)
            logs = await _fetch_recent_logs(session, pond.id, since)
        latest = logs[-1] if logs else None
        if latest is not None:
            return StateVector(
                pond_id=pond.id,
                as_of=now,
                temperature_c=latest.temperature_c,
                dissolved_oxygen_mgl=latest.dissolved_oxygen_mgl,
                ph=latest.ph,
                salinity_ppt=latest.salinity_ppt,
                ammonia_nh3_mgl=latest.ammonia_nh3_mgl,
                turbidity_ntu=latest.turbidity_ntu,
                biomass_kg_estimated=sim.biomass_kg_estimated,
                fcr_estimated=sim.fcr_estimated,
                suppressed=False,
            )

    return StateVector(
        pond_id=pond.id,
        as_of=now,
        temperature_c=sim.temperature_c,
        dissolved_oxygen_mgl=sim.dissolved_oxygen_mgl,
        ph=sim.ph,
        salinity_ppt=sim.salinity_ppt,
        ammonia_nh3_mgl=sim.ammonia_nh3_mgl,
        turbidity_ntu=sim.turbidity_ntu,
        biomass_kg_estimated=sim.biomass_kg_estimated,
        fcr_estimated=sim.fcr_estimated,
        suppressed=True,
        suppression_reason=blind.suppression_reason,
    )


@router.get(
    "/{pond_id}/state",
    response_model=StateVector,
    summary="Get the current digital twin state for a pond",
    description=(
        "Returns the current state vector. "
        "RULE: The response is identical whether backed by real sensors or the simulator. "
        "The source is never revealed in the response schema — only suppressed/suppression_reason "
        "hint at data quality, and are always populated when the pond is blind-state."
    ),
)
async def get_twin_state(pond_id: UUID, user: CurrentUser, session: DbSession) -> StateVector:
    if user.role not in ("staff", "admin"):
        rbac.require_pond_scope(user.pond_ids, pond_id)
    pond = await _get_pond_or_404(session, pond_id)
    return await _build_state_vector(session, pond)


@router.get(
    "/{pond_id}/view",
    response_class=HTMLResponse,
    summary="Get a visual dashboard of the digital twin state",
)
async def get_twin_view(pond_id: UUID, user: CurrentUser, session: DbSession) -> str:
    state = await get_twin_state(pond_id, user, session)

    visualizer_url = get_settings().twin_visualizer_url
    visualise_button = (
        f'<a href="{visualizer_url}" class="visualise-btn">Visualize in 3D Twin</a>'
        if visualizer_url
        else ""
    )
    badge_class = "badge-suppressed" if state.suppressed else "badge-live"
    badge_text = f"Blind state: {state.suppression_reason}" if state.suppressed else "Live data"

    html_content = f"""
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Digital Twin | Pond {state.pond_id}</title>
        <link href="https://fonts.googleapis.com/css2?family=Outfit:wght@300;400;500;600;700&display=swap" rel="stylesheet">
        <style>
            :root {{
                --bg-gradient: linear-gradient(135deg, #020617 0%, #0f172a 50%, #1e3a8a 100%);
                --card-bg: rgba(255, 255, 255, 0.03);
                --card-border: rgba(255, 255, 255, 0.08);
                --text-main: #f8fafc;
                --text-muted: #94a3b8;
                --accent: #38bdf8;
                --accent-glow: rgba(56, 189, 248, 0.4);
            }}

            * {{ margin: 0; padding: 0; box-sizing: border-box; }}

            body {{
                font-family: 'Outfit', sans-serif;
                background: var(--bg-gradient);
                color: var(--text-main);
                min-height: 100vh;
                display: flex;
                flex-direction: column;
                align-items: center;
                padding: 3rem 1rem;
                overflow-x: hidden;
            }}

            .header {{
                text-align: center;
                margin-bottom: 3rem;
                animation: fadeInDown 0.8s ease-out;
            }}

            .header h1 {{
                font-size: 2.5rem;
                font-weight: 700;
                background: linear-gradient(to right, #38bdf8, #818cf8);
                -webkit-background-clip: text;
                -webkit-text-fill-color: transparent;
                margin-bottom: 0.5rem;
            }}

            .header p {{
                color: var(--text-muted);
                font-size: 1.1rem;
            }}

            .badge {{
                display: inline-block;
                margin-top: 0.5rem;
                padding: 0.3rem 0.9rem;
                border-radius: 9999px;
                font-size: 0.85rem;
                font-weight: 600;
                letter-spacing: 0.03em;
            }}
            .badge-live {{ background: rgba(16, 185, 129, 0.15); color: #10b981; }}
            .badge-suppressed {{ background: rgba(245, 158, 11, 0.15); color: #f59e0b; }}

            .dashboard {{
                display: grid;
                grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
                gap: 1.5rem;
                width: 100%;
                max-width: 1200px;
                animation: fadeInUp 0.8s ease-out forwards;
                opacity: 0;
            }}

            .metric-card {{
                background: var(--card-bg);
                border: 1px solid var(--card-border);
                backdrop-filter: blur(12px);
                -webkit-backdrop-filter: blur(12px);
                border-radius: 16px;
                padding: 1.5rem;
                display: flex;
                flex-direction: column;
                position: relative;
                overflow: hidden;
                transition: transform 0.3s ease, box-shadow 0.3s ease, border-color 0.3s ease;
            }}

            .metric-card::before {{
                content: '';
                position: absolute;
                top: 0; left: 0; right: 0; height: 2px;
                background: linear-gradient(90deg, transparent, var(--accent), transparent);
                opacity: 0;
                transition: opacity 0.3s ease;
            }}

            .metric-card:hover {{
                transform: translateY(-5px);
                box-shadow: 0 10px 30px -10px rgba(0, 0, 0, 0.5), 0 0 20px -5px var(--accent-glow);
                border-color: rgba(255, 255, 255, 0.15);
            }}

            .metric-card:hover::before {{
                opacity: 1;
            }}

            .metric-label {{
                font-size: 0.95rem;
                color: var(--text-muted);
                font-weight: 500;
                text-transform: uppercase;
                letter-spacing: 0.05em;
                margin-bottom: 0.75rem;
            }}

            .metric-value {{
                font-size: 2.5rem;
                font-weight: 700;
                color: var(--text-main);
                display: flex;
                align-items: baseline;
                gap: 0.25rem;
            }}

            .metric-unit {{
                font-size: 1.1rem;
                font-weight: 400;
                color: var(--text-muted);
            }}

            .status-indicator {{
                position: absolute;
                top: 1.5rem;
                right: 1.5rem;
                width: 10px;
                height: 10px;
                border-radius: 50%;
                background-color: #10b981; /* Default healthy green */
                box-shadow: 0 0 10px #10b981;
            }}

            .status-warning {{ background-color: #f59e0b; box-shadow: 0 0 10px #f59e0b; }}
            .status-danger {{ background-color: #ef4444; box-shadow: 0 0 10px #ef4444; }}

            @keyframes fadeInUp {{
                from {{ opacity: 0; transform: translateY(30px); }}
                to {{ opacity: 1; transform: translateY(0); }}
            }}

            @keyframes fadeInDown {{
                from {{ opacity: 0; transform: translateY(-30px); }}
                to {{ opacity: 1; transform: translateY(0); }}
            }}

            /* Responsive delays for stagger effect */
            .metric-card:nth-child(1) {{ animation-delay: 0.1s; }}
            .metric-card:nth-child(2) {{ animation-delay: 0.2s; }}
            .metric-card:nth-child(3) {{ animation-delay: 0.3s; }}
            .metric-card:nth-child(4) {{ animation-delay: 0.4s; }}
            .metric-card:nth-child(5) {{ animation-delay: 0.5s; }}
            .metric-card:nth-child(6) {{ animation-delay: 0.6s; }}
            .metric-card:nth-child(7) {{ animation-delay: 0.7s; }}
            .metric-card:nth-child(8) {{ animation-delay: 0.8s; }}

            .visualise-btn {{
                display: inline-block;
                margin-top: 1.5rem;
                padding: 0.85rem 2.5rem;
                background: linear-gradient(135deg, #38bdf8, #818cf8);
                color: #ffffff;
                text-decoration: none;
                font-weight: 600;
                font-size: 1.1rem;
                border-radius: 9999px;
                box-shadow: 0 4px 15px rgba(56, 189, 248, 0.4);
                transition: transform 0.2s ease, box-shadow 0.2s ease;
                letter-spacing: 0.05em;
                animation: fadeInUp 0.8s ease-out 0.4s both;
            }}
            .visualise-btn:hover {{
                transform: translateY(-2px) scale(1.03);
                box-shadow: 0 8px 25px rgba(56, 189, 248, 0.6);
            }}
        </style>
    </head>
    <body>
        <div class="header">
            <h1>Digital Twin Active</h1>
            <p>Pond ID: {state.pond_id}</p>
            <span class="badge {badge_class}">
                {badge_text}
            </span>
            {visualise_button}
        </div>

        <div class="dashboard">
            <div class="metric-card" style="animation: fadeInUp 0.5s ease-out 0.1s both;">
                <div class="status-indicator"></div>
                <div class="metric-label">Temperature</div>
                <div class="metric-value">{state.temperature_c}<span class="metric-unit">°C</span></div>
            </div>

            <div class="metric-card" style="animation: fadeInUp 0.5s ease-out 0.2s both;">
                <div class="status-indicator"></div>
                <div class="metric-label">Dissolved Oxygen</div>
                <div class="metric-value">{state.dissolved_oxygen_mgl}<span class="metric-unit">mg/L</span></div>
            </div>

            <div class="metric-card" style="animation: fadeInUp 0.5s ease-out 0.3s both;">
                <div class="status-indicator"></div>
                <div class="metric-label">pH Level</div>
                <div class="metric-value">{state.ph}</div>
            </div>

            <div class="metric-card" style="animation: fadeInUp 0.5s ease-out 0.4s both;">
                <div class="status-indicator"></div>
                <div class="metric-label">Salinity</div>
                <div class="metric-value">{state.salinity_ppt}<span class="metric-unit">ppt</span></div>
            </div>

            <div class="metric-card" style="animation: fadeInUp 0.5s ease-out 0.5s both;">
                <div class="status-indicator status-warning"></div>
                <div class="metric-label">Ammonia (NH3)</div>
                <div class="metric-value">{state.ammonia_nh3_mgl}<span class="metric-unit">mg/L</span></div>
            </div>

            <div class="metric-card" style="animation: fadeInUp 0.5s ease-out 0.6s both;">
                <div class="status-indicator"></div>
                <div class="metric-label">Turbidity</div>
                <div class="metric-value">{state.turbidity_ntu}<span class="metric-unit">NTU</span></div>
            </div>

            <div class="metric-card" style="animation: fadeInUp 0.5s ease-out 0.7s both;">
                <div class="status-indicator"></div>
                <div class="metric-label">Est. Biomass</div>
                <div class="metric-value">{state.biomass_kg_estimated}<span class="metric-unit">kg</span></div>
            </div>

            <div class="metric-card" style="animation: fadeInUp 0.5s ease-out 0.8s both;">
                <div class="status-indicator"></div>
                <div class="metric-label">Est. FCR</div>
                <div class="metric-value">{state.fcr_estimated}</div>
            </div>
        </div>
    </body>
    </html>
    """
    return html_content


@router.post(
    "/{pond_id}/whatif",
    response_model=WhatIfOut,
    status_code=status.HTTP_200_OK,
    summary="Run a what-if simulation",
    description=(
        "Applies the given scenario deltas to the current twin state and returns the simulated "
        "outcome. risk_delta is computed by re-running the real M2 risk-scoring model "
        "(app/ml_inference/numeric/m2_risk_engine.py) against the pond's actual recent chemistry "
        "with the scenario's deltas applied — not a hardcoded estimate. "
        "delta_feed_rate_pct currently has no effect: no feed-log ingestion pipeline exists to "
        "translate a feed-rate change into a chemistry or risk effect."
    ),
)
async def whatif(
    pond_id: UUID, scenario: WhatIfScenario, user: CurrentUser, session: DbSession
) -> WhatIfOut:
    if user.role not in ("staff", "admin"):
        rbac.require_pond_scope(user.pond_ids, pond_id)
    pond = await _get_pond_or_404(session, pond_id)
    now = utcnow()

    since = now - timedelta(days=_RISK_LOOKBACK_DAYS)
    logs = await _fetch_recent_logs(session, pond.id, since)
    crop = await _fetch_active_crop(session, pond.id)
    doc = max((now.date() - crop.stocking_date).days, 0) if crop else None
    stocking_count = crop.post_larvae_count if crop else None

    current_state = await _build_state_vector(session, pond, logs=logs)

    sim_current = simulator_adapter.SimulatedState(
        temperature_c=current_state.temperature_c or 0.0,
        dissolved_oxygen_mgl=current_state.dissolved_oxygen_mgl or 0.0,
        ph=current_state.ph or 0.0,
        salinity_ppt=current_state.salinity_ppt or 0.0,
        ammonia_nh3_mgl=current_state.ammonia_nh3_mgl or 0.0,
        turbidity_ntu=current_state.turbidity_ntu or 0.0,
        biomass_kg_estimated=current_state.biomass_kg_estimated or 0.0,
        fcr_estimated=current_state.fcr_estimated or 0.0,
    )
    sim_scenario = simulator_adapter.apply_scenario_deltas(
        sim_current,
        delta_temperature_c=scenario.delta_temperature_c,
        delta_dissolved_oxygen_mgl=scenario.delta_dissolved_oxygen_mgl,
        delta_salinity_ppt=scenario.delta_salinity_ppt,
    )
    simulated = StateVector(
        pond_id=pond_id,
        as_of=now,
        temperature_c=sim_scenario.temperature_c,
        dissolved_oxygen_mgl=sim_scenario.dissolved_oxygen_mgl,
        ph=sim_scenario.ph,
        salinity_ppt=sim_scenario.salinity_ppt,
        ammonia_nh3_mgl=sim_scenario.ammonia_nh3_mgl,
        turbidity_ntu=sim_scenario.turbidity_ntu,
        biomass_kg_estimated=current_state.biomass_kg_estimated,
        fcr_estimated=current_state.fcr_estimated,
        suppressed=current_state.suppressed,
        suppression_reason=current_state.suppression_reason,
    )

    baseline_points = _points_from_logs(logs) or [
        m2_risk_engine.RawLogPoint(
            recorded_at=now,
            do_mg_l=sim_current.dissolved_oxygen_mgl,
            tan_mg_l=sim_current.ammonia_nh3_mgl,
            ph=sim_current.ph,
            water_temp_c=sim_current.temperature_c,
            alkalinity_mg_l=None,
            no2_mg_l=None,
            no3_mg_l=None,
            salinity_ppt=sim_current.salinity_ppt,
        )
    ]
    last_baseline_point = baseline_points[-1]
    scenario_points = [
        *baseline_points[:-1],
        m2_risk_engine.RawLogPoint(
            recorded_at=last_baseline_point.recorded_at,
            do_mg_l=sim_scenario.dissolved_oxygen_mgl,
            tan_mg_l=last_baseline_point.tan_mg_l,
            ph=sim_scenario.ph,
            water_temp_c=sim_scenario.temperature_c,
            alkalinity_mg_l=last_baseline_point.alkalinity_mg_l,
            no2_mg_l=last_baseline_point.no2_mg_l,
            no3_mg_l=last_baseline_point.no3_mg_l,
            salinity_ppt=sim_scenario.salinity_ppt,
        ),
    ]

    baseline_result = m2_risk_engine.score_pond(
        points=baseline_points,
        species_text=pond.species,
        doc_value=doc,
        stocking_count=stocking_count,
        now=now,
    )
    scenario_result = m2_risk_engine.score_pond(
        points=scenario_points,
        species_text=pond.species,
        doc_value=doc,
        stocking_count=stocking_count,
        now=now,
    )
    risk_delta = round(scenario_result.risk_score - baseline_result.risk_score, 4)

    return WhatIfOut(
        pond_id=pond_id,
        scenario=scenario,
        simulated_state=simulated,
        risk_delta=risk_delta,
        generated_at=now,
    )


def _points_from_logs(logs: list[Log]) -> list[m2_risk_engine.RawLogPoint]:
    return [
        m2_risk_engine.RawLogPoint(
            recorded_at=log.recorded_at,
            do_mg_l=log.dissolved_oxygen_mgl,
            tan_mg_l=log.ammonia_nh3_mgl,
            ph=log.ph,
            water_temp_c=log.temperature_c,
            alkalinity_mg_l=log.alkalinity_mgl,
            no2_mg_l=log.nitrite_mgl,
            no3_mg_l=log.nitrate_mgl,
            salinity_ppt=log.salinity_ppt,
        )
        for log in logs
    ]
