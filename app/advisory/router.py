"""Advisory — routers for /v1/reason (internal) and /v1/ask and /v1/advisories."""

from __future__ import annotations

from typing import TYPE_CHECKING
from uuid import uuid4

from fastapi import APIRouter, Query, status

from app.advisory.number_validator import validate_llm_output
from app.advisory.schemas import (
    AdvisoryOut,
    AskIn,
    AskOut,
    BroadcastIn,
    ReasonIn,
    ReasonOut,
)
from app.core.errors import NumberMismatchError
from app.core.pagination import CursorPage
from app.core.timezones import utcnow
from app.deps import InternalOnly

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
async def ask(body: AskIn) -> AskOut:
    """
    Phase 1: return fixture answer.
    Phase 4: fetch quantitative scores → call /v1/reason internally → return.
    """
    now = utcnow()
    return AskOut(
        pond_id=body.pond_id,
        question=body.question,
        answer=(
            "Your pond's dissolved oxygen level of 4.2 mg/L is below the safe threshold of 5.0 mg/L. "
            "This is consistent with early oxygen depletion. "
            "Please aerate immediately and confirm by re-measuring in 30 minutes."
        ),
        language=body.language,
        tts_url=None,
        generated_at=now,
        rejected_attempts_this_request=0,
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
    district: str | None = Query(default=None),
    cursor: str | None = Query(default=None),
    limit: int = Query(default=50, ge=1, le=200),
) -> CursorPage[AdvisoryOut]:
    from datetime import timedelta

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
async def broadcast_advisory(body: BroadcastIn) -> AdvisoryOut:
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
