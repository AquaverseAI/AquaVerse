"""Digital Twin — router for /v1/twin."""

from __future__ import annotations

from typing import TYPE_CHECKING
from uuid import UUID

from fastapi import APIRouter, status
from fastapi.responses import HTMLResponse

from app.config import get_settings
from app.core import rbac
from app.core.timezones import utcnow
from app.db.models.pond import Pond
from app.db.models.log import Log
from app.deps import CurrentUser, DbSession
from app.twin.schemas import StateVector, WhatIfOut, WhatIfScenario
from app.twin.simulator_adapter import create_current_state, simulate_whatif
from app.alerts.suppression import is_suppressed
from app.ml_inference.router import _compute_pond_risk
from app.ml_inference.numeric.m2_risk_engine import score_pond, RawLogPoint
from sqlalchemy import select

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
async def get_twin_state(pond_id: UUID, user: CurrentUser, session: DbSession) -> StateVector:
    if user.role not in ("staff", "admin"):
        rbac.require_pond_scope(user.pond_ids, pond_id)
        
    pond = (await session.execute(select(Pond).where(Pond.id == pond_id))).scalar_one_or_none()
    if not pond:
        from fastapi import HTTPException
        raise HTTPException(status_code=404, detail="Pond not found")

    recent_log = (
        await session.execute(
            select(Log).where(Log.pond_id == pond_id).order_by(Log.recorded_at.desc()).limit(1)
        )
    ).scalar_one_or_none()
    
    suppressed, suppression_reason = is_suppressed(pond_id, recent_log)

    return create_current_state(pond, recent_log, suppressed, suppression_reason)


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
            {visualise_button}
        </div>

        <div class="dashboard">
            <div class="metric-card" style="animation: fadeInUp 0.5s ease-out 0.1s both;">
                <div class="status-indicator"></div>
                <div class="metric-label">Temperature</div>
                <div class="metric-value">{state.temperature_c}<span class="metric-unit">°C</span></div>
            </div>

            <div class="metric-card" style="animation: fadeInUp 0.5s ease-out 0.2s both;">
                <!-- Slightly lower DO could be warning, let's assume >4 is healthy but let's just make it look cool -->
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
        "Applies the given scenario deltas to the current twin state and returns the simulated outcome. "
        "Risk delta indicates how much the risk score would change."
    ),
)
async def whatif(pond_id: UUID, scenario: WhatIfScenario, user: CurrentUser, session: DbSession) -> WhatIfOut:
    if user.role not in ("staff", "admin"):
        rbac.require_pond_scope(user.pond_ids, pond_id)
        
    pond = (await session.execute(select(Pond).where(Pond.id == pond_id))).scalar_one_or_none()
    if not pond:
        from fastapi import HTTPException
        raise HTTPException(status_code=404, detail="Pond not found")

    now = utcnow()
    
    # Get current state for simulation
    current_state = await get_twin_state(pond_id, user, session)
    
    # Simulate what-if scenario
    simulated = simulate_whatif(current_state, scenario)
    
    # Compute baseline risk
    baseline_computation = await _compute_pond_risk(session, pond, now)
    baseline_risk = baseline_computation.risk_out.risk_score
    
    # Fetch recent logs + active crop to calculate new risk
    from app.ml_inference.router import _fetch_recent_logs, _fetch_active_crop
    from datetime import timedelta
    
    since = now - timedelta(days=30)
    logs = await _fetch_recent_logs(session, pond.id, since)
    crop = await _fetch_active_crop(session, pond.id)
    
    if crop is not None:
        doc_value: int | None = max((now.date() - crop.stocking_date).days, 0)
        stocking_count: int | None = crop.post_larvae_count
    else:
        doc_value = None
        stocking_count = None
        
    points = [
        RawLogPoint(
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
    
    # Append the simulated future point
    simulated_point = RawLogPoint(
        recorded_at=now + timedelta(hours=scenario.horizon_hours),
        do_mg_l=simulated.dissolved_oxygen_mgl,
        tan_mg_l=simulated.ammonia_nh3_mgl,
        ph=simulated.ph,
        water_temp_c=simulated.temperature_c,
        alkalinity_mg_l=None,
        no2_mg_l=None,
        no3_mg_l=None,
        salinity_ppt=simulated.salinity_ppt,
    )
    points.append(simulated_point)
    
    # Score with the new point
    simulated_risk_out = score_pond(points, doc_value, stocking_count, now + timedelta(hours=scenario.horizon_hours))
    simulated_risk = simulated_risk_out.risk_score
    risk_delta = simulated_risk - baseline_risk

    return WhatIfOut(
        pond_id=pond_id,
        scenario=scenario,
        simulated_state=simulated,
        risk_delta=risk_delta,
        generated_at=now,
    )
