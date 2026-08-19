"""Alert rule evaluation engine.

Evaluates a freshly-ingested `Log` row against real, species-parameterized
chemistry thresholds (`ml/serving/m3/sim/species.py` — the same source of
truth `m2_risk_engine.py` uses for risk scoring) and returns a list of
alert candidates for anything breached. Hooked into `POST /v1/logs` in
`app/ingest/router.py`: every log write is evaluated the moment it lands,
not on a separate poll/cron.

This intentionally checks raw chemistry thresholds, not the M2 risk score
itself — an alert answers "is DO critically low right now", the risk score
(`GET /v1/ponds/{id}/risk`) answers "what's the 24h mortality-risk outlook".
They're complementary signals, not the same computation twice.
"""

from __future__ import annotations

from dataclasses import dataclass

from app.db.models.log import Log
from app.ml_inference.numeric.m2_risk_engine import resolve_species_key
from app.ml_inference.numeric.m3_engine import _ensure_engine_dir_on_path

# pH band outside which stress is considered severe enough to alert on.
# Not species-parameterized in sim/species.py (no ph_min/ph_max field
# there) — this is a widely-cited generic brackish/freshwater aquaculture
# safe band, not a per-species literature value like the DO thresholds
# below. Documented here rather than silently treated as equally precise.
PH_SAFE_LOW = 6.5
PH_SAFE_HIGH = 9.0

# TAN (total ammonia nitrogen) alert threshold. Toxicity depends heavily on
# pH/temperature (un-ionized fraction), which sim/species.py does not model
# per-species either — this is a single conservative literature threshold
# (unionized-ammonia-toxicity onset for most warmwater aquaculture species
# at typical pond pH), same honesty tier as the pH band above.
TAN_ALERT_MG_L = 1.0


@dataclass(frozen=True)
class AlertCandidate:
    alert_type: str
    severity: str  # critical | high | medium | low
    title: str
    message: str
    parameter: str
    measured_value: float
    threshold_value: float


def evaluate_thresholds(log: Log, species_text: str | None) -> list[AlertCandidate]:
    """Check one `Log` row's chemistry against species thresholds.

    Pure function of the log row + the pond's species string — no DB access,
    so it's cheap to call inline from the ingest path and easy to unit test.
    """
    _ensure_engine_dir_on_path()
    from sim.species import get_species  # type: ignore[import-not-found]

    species_key = resolve_species_key(species_text)
    sp = get_species(species_key)
    candidates: list[AlertCandidate] = []

    if log.dissolved_oxygen_mgl is not None:
        do = log.dissolved_oxygen_mgl
        if do < sp.do_lethal_mg_l:
            candidates.append(
                AlertCandidate(
                    alert_type="low_dissolved_oxygen",
                    severity="critical",
                    title="Dissolved oxygen at lethal level",
                    message=(
                        f"Dissolved oxygen has dropped to {do:.2f} mg/L — below the "
                        f"{sp.name} lethal threshold of {sp.do_lethal_mg_l:.2f} mg/L. "
                        "Mortality risk is acute; aerate immediately."
                    ),
                    parameter="dissolved_oxygen_mgl",
                    measured_value=do,
                    threshold_value=sp.do_lethal_mg_l,
                )
            )
        elif do < sp.do_stress_threshold_mg_l:
            candidates.append(
                AlertCandidate(
                    alert_type="low_dissolved_oxygen",
                    severity="high",
                    title="Dissolved oxygen critically low",
                    message=(
                        f"Dissolved oxygen has dropped to {do:.2f} mg/L — below the "
                        f"{sp.name} stress threshold of {sp.do_stress_threshold_mg_l:.2f} mg/L."
                    ),
                    parameter="dissolved_oxygen_mgl",
                    measured_value=do,
                    threshold_value=sp.do_stress_threshold_mg_l,
                )
            )

    if log.ammonia_nh3_mgl is not None and log.ammonia_nh3_mgl > TAN_ALERT_MG_L:
        candidates.append(
            AlertCandidate(
                alert_type="high_ammonia",
                severity="high",
                title="Ammonia (TAN) elevated",
                message=(
                    f"Total ammonia nitrogen is {log.ammonia_nh3_mgl:.2f} mg/L — above "
                    f"the {TAN_ALERT_MG_L:.2f} mg/L alert threshold."
                ),
                parameter="ammonia_nh3_mgl",
                measured_value=log.ammonia_nh3_mgl,
                threshold_value=TAN_ALERT_MG_L,
            )
        )

    if log.ph is not None and (log.ph < PH_SAFE_LOW or log.ph > PH_SAFE_HIGH):
        threshold = PH_SAFE_LOW if log.ph < PH_SAFE_LOW else PH_SAFE_HIGH
        candidates.append(
            AlertCandidate(
                alert_type="ph_out_of_range",
                severity="medium",
                title="pH out of safe range",
                message=(
                    f"pH is {log.ph:.2f} — outside the safe band of "
                    f"{PH_SAFE_LOW:.1f}–{PH_SAFE_HIGH:.1f}."
                ),
                parameter="ph",
                measured_value=log.ph,
                threshold_value=threshold,
            )
        )

    return candidates
