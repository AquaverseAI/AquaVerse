"""Advisory — routers for /v1/reason (internal) and /v1/ask and /v1/advisories."""

from __future__ import annotations

from typing import TYPE_CHECKING
from uuid import uuid4

from fastapi import APIRouter, Query, status, HTTPException
import httpx

from app.advisory.number_validator import validate_llm_output
from app.advisory.schemas import (
    AdvisoryOut,
    AskIn,
    AskOut,
    BroadcastIn,
    ReasonIn,
    ReasonOut,
    M3PondSnapshotRequest,
    M3ReasonResponse,
)
from app.core import rbac
from app.core.errors import NumberMismatchError
from app.core.pagination import CursorPage
from app.core.timezones import utcnow
from app.deps import CurrentStaff, CurrentUser, InternalOnly

if TYPE_CHECKING:
    pass


router = APIRouter(tags=["Advisory"])

# Language → health phrasing template (never confident diagnosis)
_HEALTH_PHRASING = (
    "Observations are consistent with {condition}. "
    "Please confirm by {confirmation_method} before taking action."
)


# ---------------------------------------------------------------------------
# POST /v1/reason  — internal only
# ---------------------------------------------------------------------------
@router.post(
    "/reason",
    response_model=ReasonOut,
    status_code=status.HTTP_200_OK,
    summary="[INTERNAL] Generate a reasoned advisory from the LLM layer",
    description=(
        "Internal-only endpoint (requires X-Internal-Token header). "
        "The LLM output is validated by number_validator.py before being returned. "
        "Any numeral in the LLM response that was not present in the tool_call_payload "
        "causes rejection and regeneration (server-side, in the request path)."
    ),
)
async def reason(
    body: ReasonIn,
    _: InternalOnly,
) -> ReasonOut:
    """
    Phase 1: stub that demonstrates the validator is wired.
    Phase 4: replace stub LLM call with real vLLM multi-LoRA request.
    """
    now = utcnow()
    rejected_this_request = 0

    # Phase 1 stub: construct a safe explanation using ONLY values from tool_call_payload
    payload = body.tool_call_payload
    stub_explanation = (
        f"The pond risk score is {payload.risk_score:.2f} ({payload.risk_level} risk). "
        f"Chemistry component: {payload.components.get('chemistry', 0.0):.2f}. "
        f"This is consistent with early EMS/AHPND indicators — "
        f"confirm by water sample lab analysis before treatment."
    )

    # Validate: even the stub must pass the guardrail
    # (Phase 4: validate actual vLLM output here)
    try:
        validate_llm_output(
            stub_explanation,
            body.tool_call_payload.model_dump(),
        )
    except NumberMismatchError:
        rejected_this_request += 1
        raise

    return ReasonOut(
        pond_id=body.pond_id,
        adapter=body.adapter,
        explanation=stub_explanation,
        rejected_attempts_this_request=rejected_this_request,
        model_version="qwen3-8b-stub-v0.1",
        generated_at=now,
    )


# ---------------------------------------------------------------------------
# POST /v1/ask  — farmer-facing
# ---------------------------------------------------------------------------
@router.post(
    "/ask",
    response_model=AskOut,
    status_code=status.HTTP_200_OK,
    summary="Ask a question about your pond (farmer-facing)",
    description=(
        "Farmer-facing conversational Q&A. Routes through the full two-layer pipeline: "
        "quantitative scores are fetched first, then the reasoning layer generates an explanation "
        "using only those numbers. Rate-limited to 30 requests/minute."
    ),
)
async def ask(body: AskIn, user: CurrentUser) -> AskOut:
    """
    Phase 4: Call the external M3 serving engine with the static payload.
    """
    if user.role not in ("staff", "admin"):
        rbac.require_pond_scope(user.pond_ids, body.pond_id)
    now = utcnow()
    
    # Construct static 28-field payload for the specific pond_id 
    # to test integration before full DB aggregation is implemented
    m3_request = M3PondSnapshotRequest(
        pond_id=str(body.pond_id),
        species_key="vannamei",
        doc=52,
        biomass_est_kg=12.3,
        alive_count=180,
        do_mg_l=2.74,
        tan_mg_l=0.15,
        ph=7.9,
        alkalinity_mg_l=140.0,
        water_temp_c=29.5,
        salinity_ppt=15.0,
        wind_mean_24h=3.2,
        solar_rad_24h=450.0,
        rain_48h_mm=0.0,
        night_do_min_3d_trend=-0.1,
        do_amplitude=2.1,
        stress_hours_lt3_24h=6.0,
        stress_hours_lt3_7d=14.0,
        tan_slope_3d=0.02,
        alkalinity_trend_7d=-1.5,
        feed_kg_7d_cum=8.4,
        fcr_running=1.3,
        management_quality=0.75,
        aerator_on=True,
        data_health_score=1.0,
        nh3_un_ionised=0.01,
        cum_feed_kg=8.4,
        feed_cost_per_kg_rs=90.0,
        market_price_per_kg_rs=350.0
    )

    try:
        async with httpx.AsyncClient(timeout=15.0) as client:
            response = await client.post(
                "http://172.17.0.1:8001/v1/reason/m3",
                json=m3_request.model_dump()
            )
            response.raise_for_status()
            
            # Parse the response back into our M3ReasonResponse schema
            m3_response = M3ReasonResponse.model_validate(response.json())
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail=f"M3 reasoning engine failed: {str(e)}"
        ) from e

    return AskOut(
        pond_id=body.pond_id,
        question=body.question,
        answer=m3_response.narration,
        language=body.language,
        tts_url=None,
        generated_at=now,
        rejected_attempts_this_request=m3_response.regeneration_attempts,
    )


# ---------------------------------------------------------------------------
# GET /v1/advisories
# ---------------------------------------------------------------------------
@router.get(
    "/advisories",
    response_model=CursorPage[AdvisoryOut],
    summary="List published advisories",
)
async def list_advisories(
    user: CurrentUser,
    district: str | None = Query(default=None),
    cursor: str | None = Query(default=None),
    limit: int = Query(default=50, ge=1, le=200),
) -> CursorPage[AdvisoryOut]:
    from datetime import timedelta

    if district is not None and user.role in ("staff", "admin"):
        rbac.require_district(user.district, district)

    now = utcnow()
    stub = AdvisoryOut(
        id=uuid4(),
        title="Weekly Water Quality Advisory — Nagapattinam District",
        body="Monitor dissolved oxygen levels closely this week due to algal bloom conditions.",
        language="ta",
        target_district="Nagapattinam",
        target_species="Litopenaeus vannamei",
        severity="warning",
        issued_at=now,
        expires_at=now + timedelta(days=7),
    )
    return CursorPage[AdvisoryOut](items=[stub], next_cursor=None)


# ---------------------------------------------------------------------------
# POST /v1/advisories/broadcast
# ---------------------------------------------------------------------------
@router.post(
    "/advisories/broadcast",
    response_model=AdvisoryOut,
    status_code=status.HTTP_201_CREATED,
    summary="Broadcast an advisory to farmers (staff only)",
)
async def broadcast_advisory(body: BroadcastIn, user: CurrentStaff) -> AdvisoryOut:
    now = utcnow()
    return AdvisoryOut(
        id=uuid4(),
        title=body.title,
        body=body.body,
        language=body.language,
        target_district=body.target_district,
        target_species=body.target_species,
        severity=body.severity,
        issued_at=now,
        expires_at=body.expires_at,
    )
