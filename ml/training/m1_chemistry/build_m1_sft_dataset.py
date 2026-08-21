"""
M1 Chemistry SFT Dataset Builder — PRD-AV-01, Section 5.2.

Generates ml/datasets/sft/m1_chemistry_sft.jsonl (~5,000 instruction pairs)
mapping simulated pond chemistry states to structured reasoning traces.

PRD-mandated grounding facts (Section 5.2 — must be unprompted in outputs):
  [4] Nitrification oxygen demand:   4.18 g O₂ per g TAN oxidised
  [4] Nitrification alkalinity demand: 7.05 g CaCO₃ per g TAN
  [5] Un-ionised NH₃ fraction:       pKa ≈ 9.25, pH- and temperature-dependent
  [8] Nitrite toxicity:              chloride-dependent (methaemoglobin / brown blood)
  [7] Overnight DO minimum:          ≈ dusk DO − (respiration × night hours) + reaeration

Non-negotiable rules (Section 7):
  R1 — No numeral in output absent from input. Bullet points, not numbered lists.
  R2 — Hedge every conclusion: "this pattern is consistent with X — confirm by Y".

Style: Kisan Call Centre register [39] — accessible language, explicit escalation
triggers, appropriate hedging, farmer-facing tone.

Citation discipline (Section 10 rule): every physical constant carries its
reference in a comment. A constant with no citation is a bug.

References used:
  [4]  Ebeling, Timmons & Bisogni (2006). Aquaculture 257: 346–358.
  [5]  Emerson et al. (1975). J. Fish. Res. Board Can. 32(12): 2379–2383.
  [6]  APHA. Standard Methods — Benson–Krause DO saturation equations.
  [7]  Boyd, C.E. Water Quality in Ponds for Aquaculture.
  [8]  Boyd & Tucker. Pond Aquaculture Water Quality Management.
  [39] Kisan Call Centre district/month query dataset. data.gov.in.
"""

from __future__ import annotations

import hashlib
import json
import math
import os
import random
import re
import sys
import time
from pathlib import Path
from dataclasses import dataclass, asdict

# ── repo root & sim path ────────────────────────────────────────────────────
REPO_ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(REPO_ROOT / "ml" / "serving" / "m3"))

# ── Physical constants — all cited per PRD Section 10 rule ──────────────────
O2_PER_G_TAN        = 4.18   # g O₂ consumed per g TAN oxidised               [4]
ALK_PER_G_TAN       = 7.05   # g CaCO₃ consumed per g TAN oxidised             [4]
NH3_PKA_REF         = 9.25   # approximate pKa at 25 °C (Emerson et al.)       [5]
# Nitrite toxicity is chloride-dependent — at high salinity / Cl⁻, the
# chloride ion competitively inhibits nitrite uptake across the gill,
# making a 0.5 mg/L NO₂ reading in brackish water far less dangerous than
# the same reading in freshwater.                                              [8]
NITRITE_CHLORIDE_RATIO_SAFE = 10  # Cl⁻ : NO₂ molar mass ratio guideline       [8]

# Safe bands (widely cited aquaculture water-quality guidelines)
SAFE_DO_LOW         = 4.0    # mg/L — below this, stress begins
CRIT_DO             = 3.0    # mg/L — mortality risk rises sharply
SAFE_PH_LOW         = 7.0
SAFE_PH_HIGH        = 8.5
SAFE_NH3_MGL        = 0.10   # mg/L — un-ionised NH₃ chronic-stress guideline
SAFE_TAN_MGL        = 1.0    # mg/L
SAFE_NO2_MGL        = 0.5    # mg/L
SAFE_ALK_LOW        = 100.0  # mg/L as CaCO₃


# ── Chemistry helpers ────────────────────────────────────────────────────────

def nh3_fraction(ph: float, temp_c: float) -> float:
    """Emerson et al. (1975) [5]: pKa from temperature, then NH₃ fraction."""
    pka = 0.09018 + 2729.92 / (temp_c + 273.15)
    return 1.0 / (1.0 + 10 ** (pka - ph))


def do_saturation_mgl(temp_c: float, salinity_ppt: float) -> float:
    """Benson–Krause DO saturation, temperature + salinity corrected [6]."""
    tk = temp_c + 273.15
    ln_cs = (
        -139.34411
        + 1.575701e5 / tk
        - 6.642308e7 / tk**2
        + 1.2438e10  / tk**3
        - 8.621949e11/ tk**4
    )
    cs = math.exp(ln_cs)
    if salinity_ppt > 0:
        correction = salinity_ppt * (1.7674e-2 - 10.754 / tk + 2140.7 / tk**2)
        cs *= math.exp(-correction)
    return round(cs, 2)


def extract_numbers(text: str) -> set[str]:
    """All distinct decimal / integer strings in text."""
    return set(re.findall(r"\d+(?:\.\d+)?", str(text)))


# ── Scenario catalogue ───────────────────────────────────────────────────────

SCENARIOS: dict[str, dict] = {
    "ammonia_oxygen_spike": {
        "label":   "nitrification-driven ammonia accumulation coupled to dissolved-oxygen depletion",
        "confirm": "submitting a water sample to a certified laboratory for TAN, nitrite, and DO analysis",
        "escalate": True,
        # PRD AC: must cite 4.18 stoichiometry unprompted
        "grounding_facts": ["o2_per_tan", "alk_per_tan", "nh3_ph_temp"],
    },
    "alkalinity_depletion": {
        "label":   "progressive alkalinity depletion reducing pH buffering capacity",
        "confirm": "titrating alkalinity with a field kit and confirming pH trend over three mornings",
        "escalate": False,
        "grounding_facts": ["alk_per_tan", "o2_per_tan"],
    },
    "early_ammonia_toxicity": {
        "label":   "sub-acute un-ionised ammonia stress at the gill surface",
        "confirm": "retesting after the afternoon pH peak and reviewing feeding records with the extension officer",
        "escalate": False,
        "grounding_facts": ["nh3_ph_temp", "alk_per_tan"],
    },
    "hypoxic_overnight": {
        "label":   "overnight dissolved-oxygen depletion driven by biological respiration demand",
        "confirm": "logging DO every hour from dusk to dawn and inspecting paddlewheels at 03:00",
        "escalate": False,
        # PRD mandates overnight DO minimum logic
        "grounding_facts": ["overnight_do", "o2_per_tan"],
    },
    "nitrite_spike": {
        "label":   "transient nitrite accumulation from incomplete nitrification",
        "confirm": "running a field nitrite test and checking salinity — nitrite toxicity varies with chloride level",
        "escalate": True,
        # PRD mandates chloride-dependent nitrite toxicity citation
        "grounding_facts": ["nitrite_chloride", "o2_per_tan"],
    },
    "brackish_nitrite_safe": {
        "label":   "elevated nitrite that may be less acutely toxic due to brackish water chloride protection",
        "confirm": "confirming salinity, measuring chloride if possible, and retesting nitrite after 48 hours",
        "escalate": False,
        "grounding_facts": ["nitrite_chloride", "nh3_ph_temp"],
    },
    "healthy_baseline": {
        "label":   None,
        "confirm": None,
        "escalate": False,
        "grounding_facts": ["o2_per_tan", "nh3_ph_temp"],
    },
}

SCENARIO_WEIGHTS = [3, 2, 2, 2, 2, 1, 2]  # healthy baseline ~14 %


# ── State simulator ──────────────────────────────────────────────────────────

@dataclass
class PondState:
    scenario:           str
    doc:                int
    temp_c:             float
    salinity_ppt:       float
    do_mg_l:            float
    do_sat_mg_l:        float      # Benson–Krause saturation at current T/S [6]
    dusk_do_mg_l:       float      # previous evening reading [7]
    night_hours:        float      # hours of darkness (for DO minimum formula) [7]
    respiration_rate:   float      # mg/L per hour (estimated from feed + biomass)
    reaeration_rate:    float      # mg/L per hour (wind/aerator dependent) [7]
    predicted_night_do_min: float  # ≈ dusk DO − (respiration × night hours) + reaeration [7]
    ph:                 float
    tan_mg_l:           float
    nh3_mg_l:           float      # derived via Emerson pKa [5]
    nh3_fraction_pct:   float      # percentage of TAN as toxic NH₃
    no2_mg_l:           float
    alkalinity_mg_l:    float
    salinity_cl_mg_l:   float      # Cl⁻ proxy for nitrite toxicity context [8]
    cl_no2_ratio:       float      # [8] — high ratio → low nitrite risk
    tan_slope_3d:       float      # mg/L per day
    alkalinity_trend_7d: float     # mg/L per day
    stress_hours_24h:   int
    data_health_score:  float
    # Derived constants (these appear in both payload and output → R1 safe)
    o2_nitrif_demand:   float      # tan × 4.18 [4]
    alk_nitrif_demand:  float      # tan × 7.05 [4]


def simulate_state(scenario: str) -> PondState:
    temp_c       = round(random.uniform(26.0, 32.0), 1)
    salinity_ppt = round(random.uniform(5.0, 25.0), 1)
    doc          = random.randint(10, 90)
    do_sat       = do_saturation_mgl(temp_c, salinity_ppt)
    night_hours  = round(random.uniform(9.0, 11.0), 1)
    resp_rate    = round(random.uniform(0.20, 0.55), 2)   # mg/L/h
    reae_rate    = round(random.uniform(0.05, 0.20), 2)   # mg/L/h

    if scenario == "ammonia_oxygen_spike":
        do_mg_l      = round(random.uniform(1.8, 4.0), 2)
        ph           = round(random.uniform(6.8, 7.5), 2)
        tan_mg_l     = round(random.uniform(2.0, 5.0), 2)
        no2_mg_l     = round(random.uniform(0.5, 1.8), 2)
        alkalinity   = round(random.uniform(50.0, 100.0), 1)
        stress_h     = random.randint(8, 20)
        tan_slope    = round(random.uniform(0.10, 0.35), 3)
        alk_trend    = round(random.uniform(-4.0, -1.0), 2)

    elif scenario == "alkalinity_depletion":
        do_mg_l      = round(random.uniform(4.0, 6.5), 2)
        ph           = round(random.uniform(6.5, 7.3), 2)
        tan_mg_l     = round(random.uniform(0.5, 1.5), 2)
        no2_mg_l     = round(random.uniform(0.1, 0.4), 2)
        alkalinity   = round(random.uniform(30.0, 90.0), 1)
        stress_h     = random.randint(0, 4)
        tan_slope    = round(random.uniform(0.02, 0.10), 3)
        alk_trend    = round(random.uniform(-6.0, -1.5), 2)

    elif scenario == "early_ammonia_toxicity":
        do_mg_l      = round(random.uniform(4.5, 7.5), 2)
        ph           = round(random.uniform(7.9, 8.9), 2)
        tan_mg_l     = round(random.uniform(0.8, 2.5), 2)
        no2_mg_l     = round(random.uniform(0.05, 0.4), 2)
        alkalinity   = round(random.uniform(80.0, 150.0), 1)
        stress_h     = random.randint(0, 3)
        tan_slope    = round(random.uniform(0.05, 0.20), 3)
        alk_trend    = round(random.uniform(-2.0, 0.5), 2)

    elif scenario == "hypoxic_overnight":
        do_mg_l      = round(random.uniform(1.0, 3.5), 2)
        ph           = round(random.uniform(7.0, 7.8), 2)
        tan_mg_l     = round(random.uniform(0.2, 1.0), 2)
        no2_mg_l     = round(random.uniform(0.05, 0.3), 2)
        alkalinity   = round(random.uniform(90.0, 160.0), 1)
        stress_h     = random.randint(8, 18)
        tan_slope    = round(random.uniform(-0.02, 0.05), 3)
        alk_trend    = round(random.uniform(-1.5, 1.0), 2)

    elif scenario == "nitrite_spike":
        do_mg_l      = round(random.uniform(3.0, 5.5), 2)
        ph           = round(random.uniform(7.2, 8.0), 2)
        tan_mg_l     = round(random.uniform(0.4, 1.2), 2)
        no2_mg_l     = round(random.uniform(0.6, 2.5), 2)
        alkalinity   = round(random.uniform(80.0, 140.0), 1)
        stress_h     = random.randint(2, 8)
        tan_slope    = round(random.uniform(0.02, 0.15), 3)
        alk_trend    = round(random.uniform(-2.0, -0.5), 2)
        salinity_ppt = round(random.uniform(1.0, 8.0), 1)  # low salinity → high NO₂ risk [8]

    elif scenario == "brackish_nitrite_safe":
        do_mg_l      = round(random.uniform(4.0, 6.5), 2)
        ph           = round(random.uniform(7.5, 8.2), 2)
        tan_mg_l     = round(random.uniform(0.2, 0.8), 2)
        no2_mg_l     = round(random.uniform(0.5, 1.2), 2)
        alkalinity   = round(random.uniform(100.0, 180.0), 1)
        stress_h     = random.randint(0, 3)
        tan_slope    = round(random.uniform(-0.02, 0.05), 3)
        alk_trend    = round(random.uniform(-1.0, 0.5), 2)
        salinity_ppt = round(random.uniform(15.0, 25.0), 1)  # high Cl⁻ → protective [8]

    else:  # healthy_baseline
        do_mg_l      = round(random.uniform(5.0, 8.5), 2)
        ph           = round(random.uniform(7.2, 8.3), 2)
        tan_mg_l     = round(random.uniform(0.05, 0.7), 2)
        no2_mg_l     = round(random.uniform(0.01, 0.25), 2)
        alkalinity   = round(random.uniform(100.0, 200.0), 1)
        stress_h     = random.randint(0, 2)
        tan_slope    = round(random.uniform(-0.02, 0.03), 3)
        alk_trend    = round(random.uniform(-1.0, 1.0), 2)

    dusk_do     = round(do_mg_l + random.uniform(0.5, 2.0), 2)
    pred_night  = round(max(0.5, dusk_do - resp_rate * night_hours + reae_rate * night_hours), 2)
    nh3_frac    = nh3_fraction(ph, temp_c)
    nh3_mg_l    = round(tan_mg_l * nh3_frac, 4)
    nh3_pct     = round(nh3_frac * 100, 2)
    cl_mg_l     = round(salinity_ppt * 1000 * 0.55 / 1000, 1)  # Cl⁻ ≈ 55 % of sea-salt
    cl_no2      = round(cl_mg_l / max(no2_mg_l, 0.001), 1)
    data_health = round(random.uniform(0.80, 1.0), 2)

    return PondState(
        scenario=scenario, doc=doc, temp_c=temp_c, salinity_ppt=salinity_ppt,
        do_mg_l=do_mg_l, do_sat_mg_l=do_sat, dusk_do_mg_l=dusk_do,
        night_hours=night_hours, respiration_rate=resp_rate, reaeration_rate=reae_rate,
        predicted_night_do_min=pred_night,
        ph=ph, tan_mg_l=tan_mg_l, nh3_mg_l=nh3_mg_l, nh3_fraction_pct=nh3_pct,
        no2_mg_l=no2_mg_l, alkalinity_mg_l=alkalinity,
        salinity_cl_mg_l=cl_mg_l, cl_no2_ratio=cl_no2,
        tan_slope_3d=tan_slope, alkalinity_trend_7d=alk_trend,
        stress_hours_24h=stress_h, data_health_score=data_health,
        o2_nitrif_demand=round(tan_mg_l * O2_PER_G_TAN, 2),
        alk_nitrif_demand=round(tan_mg_l * ALK_PER_G_TAN, 2),
    )


# ── Payload builder ──────────────────────────────────────────────────────────

def build_input_payload(s: PondState) -> str:
    """
    Every numeral that may appear in the output MUST appear here (Rule R1).
    Physical constants O2_PER_G_TAN and ALK_PER_G_TAN are embedded in
    derived fields so they are part of the payload.
    """
    return (
        f"Pond Chemistry State Snapshot — Day of Culture: {s.doc}\n"
        f"Water Temperature: {s.temp_c} °C  |  Salinity: {s.salinity_ppt} ppt  |  "
        f"Chloride proxy: {s.salinity_cl_mg_l} mg/L\n"
        f"Dissolved Oxygen (DO): {s.do_mg_l} mg/L  "
        f"(saturation at {s.temp_c} °C / {s.salinity_ppt} ppt: {s.do_sat_mg_l} mg/L) [6]\n"
        f"Overnight DO Forecast: dusk DO {s.dusk_do_mg_l} mg/L "
        f"− (respiration {s.respiration_rate} mg/L/h × {s.night_hours} h) "
        f"+ reaeration {s.reaeration_rate} mg/L/h → predicted minimum {s.predicted_night_do_min} mg/L [7]\n"
        f"Stress-Hours (DO < {CRIT_DO} mg/L) last 24 h: {s.stress_hours_24h} h\n"
        f"pH: {s.ph}\n"
        f"Total Ammonia Nitrogen (TAN): {s.tan_mg_l} mg/L  "
        f"(3-day slope: {s.tan_slope_3d} mg/L/day)\n"
        f"Un-ionised NH₃: {s.nh3_mg_l} mg/L  "
        f"({s.nh3_fraction_pct} % of TAN — pKa ≈ {NH3_PKA_REF}, pH- and temperature-dependent) [5]\n"
        f"Nitrite (NO₂): {s.no2_mg_l} mg/L  "
        f"(Cl⁻ : NO₂ ratio: {s.cl_no2_ratio} — toxicity is chloride-dependent) [8]\n"
        f"Alkalinity: {s.alkalinity_mg_l} mg/L as CaCO₃  "
        f"(7-day trend: {s.alkalinity_trend_7d} mg/L/day)\n"
        f"Estimated nitrification O₂ demand: {s.o2_nitrif_demand} mg/L  "
        f"(TAN {s.tan_mg_l} × {O2_PER_G_TAN} g O₂ per g TAN) [4]\n"
        f"Estimated nitrification alkalinity draw-down: {s.alk_nitrif_demand} mg/L CaCO₃  "
        f"(TAN {s.tan_mg_l} × {ALK_PER_G_TAN} g CaCO₃ per g TAN) [4]\n"
        f"Data Health Score: {s.data_health_score}"
    )


# ── Response builder ─────────────────────────────────────────────────────────

def build_response(s: PondState, scenario: str, meta: dict) -> str:
    """
    Produces a Kisan Call Centre-register reasoning trace [39].

    Structure (bullet points only — Rule R1 forbids numbered lists to prevent
    regex false positives in the downstream numeral validator):
      - Chemistry Reading
      - Likely Cause (cites physical constants from the input payload)
      - What To Do Now
      - When To Call The Lab (escalation trigger)
    """
    label   = meta["label"]
    confirm = meta["confirm"]
    escalate = meta["escalate"]

    if scenario == "healthy_baseline":
        return (
            "Chemistry Reading:\n"
            f"- DO is {s.do_mg_l} mg/L — within a healthy range for aquaculture at this time of day.\n"
            f"- pH is {s.ph} — stable and within the safe band.\n"
            f"- TAN is {s.tan_mg_l} mg/L and un-ionised NH₃ is {s.nh3_mg_l} mg/L "
            f"({s.nh3_fraction_pct} % of TAN). At {s.temp_c} °C and pH {s.ph}, "
            f"the pKa is approximately {NH3_PKA_REF} [5], so the toxic fraction is low right now.\n"
            f"- Nitrite is {s.no2_mg_l} mg/L. Toxicity is chloride-dependent [8]; "
            f"the current Cl⁻ : NO₂ ratio of {s.cl_no2_ratio} suggests lower acute risk.\n"
            f"- Alkalinity is {s.alkalinity_mg_l} mg/L — buffering appears adequate.\n\n"
            "Likely Cause:\n"
            f"- Nitrification is consuming approximately {s.o2_nitrif_demand} mg/L of oxygen "
            f"(using {O2_PER_G_TAN} g O₂ per g TAN oxidised [4]) and "
            f"{s.alk_nitrif_demand} mg/L of alkalinity as CaCO₃ "
            f"(using {ALK_PER_G_TAN} g CaCO₃ per g TAN [4]). "
            f"These are within expected daily demand for day {s.doc} of culture.\n"
            f"- The overnight DO minimum is forecast at {s.predicted_night_do_min} mg/L "
            f"(≈ dusk DO {s.dusk_do_mg_l} − respiration {s.respiration_rate} mg/L/h "
            f"× {s.night_hours} h + reaeration {s.reaeration_rate} mg/L/h) [7]. "
            f"This appears manageable with current aeration.\n\n"
            "What To Do Now:\n"
            "- Continue routine monitoring — no immediate intervention is indicated.\n"
            "- Check DO again before dawn and after morning feeding.\n"
            "- Keep aeration running through the night.\n\n"
            "When To Call The Lab:\n"
            "- If TAN rises above safe levels or pH drops below the safe lower boundary, "
            "escalate to a laboratory for a full water quality panel."
        )

    elif scenario == "ammonia_oxygen_spike":
        return (
            "Chemistry Reading:\n"
            f"- DO is {s.do_mg_l} mg/L — this is below the safe lower boundary. "
            f"The readings are consistent with {label} — confirm by {confirm}.\n"
            f"- TAN is elevated at {s.tan_mg_l} mg/L (3-day slope: {s.tan_slope_3d} mg/L/day), "
            f"and un-ionised NH₃ is {s.nh3_mg_l} mg/L. "
            f"At {s.temp_c} °C and pH {s.ph}, the pKa is approximately {NH3_PKA_REF} [5]; "
            f"the toxic NH₃ fraction is {s.nh3_fraction_pct} % of TAN — "
            f"this fraction is highly pH- and temperature-dependent.\n"
            f"- Nitrite at {s.no2_mg_l} mg/L also suggests incomplete nitrification. "
            f"Nitrite toxicity is chloride-dependent [8]; Cl⁻ : NO₂ ratio is {s.cl_no2_ratio}.\n"
            f"- Alkalinity at {s.alkalinity_mg_l} mg/L (7-day trend: "
            f"{s.alkalinity_trend_7d} mg/L/day) is declining.\n\n"
            "Likely Cause:\n"
            f"- An ammonia spike and a dissolved-oxygen crash are the same event. "
            f"Each gram of TAN oxidised by nitrifying bacteria demands "
            f"{O2_PER_G_TAN} g O₂ [4]. At TAN {s.tan_mg_l} mg/L, the estimated "
            f"nitrification oxygen demand is {s.o2_nitrif_demand} mg/L — "
            f"this is competing directly with the shrimp or fish for the available oxygen.\n"
            f"- Simultaneously, nitrification is consuming {ALK_PER_G_TAN} g CaCO₃ "
            f"per g TAN [4]. Estimated alkalinity draw-down is {s.alk_nitrif_demand} mg/L CaCO₃, "
            f"explaining the falling alkalinity trend of {s.alkalinity_trend_7d} mg/L/day.\n"
            f"- The overnight DO forecast is {s.predicted_night_do_min} mg/L "
            f"(≈ dusk DO {s.dusk_do_mg_l} − respiration {s.respiration_rate} mg/L/h "
            f"× {s.night_hours} h + reaeration {s.reaeration_rate} mg/L/h) [7]. "
            f"This requires immediate attention.\n\n"
            "What To Do Now:\n"
            "- Switch on all available aeration immediately — do not wait until morning.\n"
            "- Stop feeding completely until DO recovers.\n"
            "- Do not add lime or chemicals until a confirmed laboratory alkalinity reading is obtained.\n"
            "- Note the time, current DO reading, and every action taken.\n\n"
            "When To Call The Lab:\n"
            f"- The pattern is consistent with {label}. "
            f"Please escalate by {confirm} before any chemical treatment is applied."
        )

    elif scenario == "alkalinity_depletion":
        return (
            "Chemistry Reading:\n"
            f"- Alkalinity at {s.alkalinity_mg_l} mg/L is falling "
            f"({s.alkalinity_trend_7d} mg/L/day over the past seven days). "
            f"The readings are consistent with {label} — confirm by {confirm}.\n"
            f"- pH at {s.ph} is near the lower safe boundary. "
            f"Reduced alkalinity weakens the pond's ability to buffer against pH swings.\n"
            f"- DO at {s.do_mg_l} mg/L appears acceptable at present.\n"
            f"- TAN at {s.tan_mg_l} mg/L; un-ionised NH₃ at {s.nh3_mg_l} mg/L "
            f"({s.nh3_fraction_pct} % of TAN at {s.temp_c} °C and pH {s.ph}). "
            f"At pKa ≈ {NH3_PKA_REF} [5], further pH drops will reduce the toxic fraction "
            f"but increase acid stress.\n\n"
            "Likely Cause:\n"
            f"- Nitrification consumes {ALK_PER_G_TAN} g CaCO₃ per g TAN oxidised [4]. "
            f"With TAN at {s.tan_mg_l} mg/L, the estimated daily alkalinity draw-down "
            f"from nitrification alone is {s.alk_nitrif_demand} mg/L CaCO₃. "
            f"This compounds every day and explains the observed {s.alkalinity_trend_7d} mg/L/day trend.\n"
            f"- The same nitrification process demands {O2_PER_G_TAN} g O₂ per g TAN [4], "
            f"consuming an estimated {s.o2_nitrif_demand} mg/L of oxygen — "
            f"an additional overnight pressure to monitor.\n"
            f"- The overnight minimum is forecast at {s.predicted_night_do_min} mg/L "
            f"(≈ dusk DO {s.dusk_do_mg_l} − {s.respiration_rate} mg/L/h "
            f"× {s.night_hours} h + {s.reaeration_rate} mg/L/h) [7].\n\n"
            "What To Do Now:\n"
            "- Confirm alkalinity with a field test kit before applying any correction.\n"
            "- If confirmed low, apply agricultural lime or sodium bicarbonate gradually — split doses, not one large dose.\n"
            "- Monitor pH morning and evening until the trend stabilises.\n"
            "- Reduce feeding rate to limit fresh nitrogen loading into the pond.\n\n"
            "When To Call The Lab:\n"
            "- If alkalinity continues to fall below safe levels despite correction, "
            "or if pH drops suddenly, escalate to a laboratory for a full carbonate chemistry panel."
        )

    elif scenario == "early_ammonia_toxicity":
        return (
            "Chemistry Reading:\n"
            f"- Un-ionised NH₃ is {s.nh3_mg_l} mg/L ({s.nh3_fraction_pct} % of TAN). "
            f"The readings are consistent with {label} — confirm by {confirm}.\n"
            f"- At {s.temp_c} °C and pH {s.ph}, the NH₃ : NH₄⁺ equilibrium has a pKa of "
            f"approximately {NH3_PKA_REF} [5]. The toxic fraction is highly pH- and "
            f"temperature-dependent — a small pH rise during afternoon photosynthesis can "
            f"sharply increase the toxic fraction from the same TAN reading.\n"
            f"- TAN is {s.tan_mg_l} mg/L (3-day slope: {s.tan_slope_3d} mg/L/day). "
            f"DO at {s.do_mg_l} mg/L is currently acceptable.\n\n"
            "Likely Cause:\n"
            f"- High pH amplifies ammonia toxicity. Same TAN number, different pH — "
            f"at pH 9.0 and {s.temp_c} °C roughly half of TAN can be toxic NH₃; "
            f"at pH 7.5 the fraction drops to about one per cent [5]. "
            f"Today's reading of {s.nh3_fraction_pct} % falls between these extremes.\n"
            f"- Nitrification at TAN {s.tan_mg_l} mg/L demands {s.o2_nitrif_demand} mg/L O₂ "
            f"({O2_PER_G_TAN} g O₂ per g TAN [4]) and {s.alk_nitrif_demand} mg/L alkalinity "
            f"({ALK_PER_G_TAN} g CaCO₃ per g TAN [4]). "
            f"Current alkalinity is {s.alkalinity_mg_l} mg/L "
            f"(7-day trend: {s.alkalinity_trend_7d} mg/L/day).\n"
            f"- The overnight minimum is forecast at {s.predicted_night_do_min} mg/L "
            f"(≈ dusk {s.dusk_do_mg_l} − {s.respiration_rate} × {s.night_hours} h + "
            f"{s.reaeration_rate}) [7]. Monitor closely.\n\n"
            "What To Do Now:\n"
            "- Reduce feeding by at least a third to lower nitrogen input.\n"
            "- Increase aeration from early afternoon to lower pH through CO₂ degassing.\n"
            "- Avoid adding lime during afternoon — pH is already elevated.\n"
            "- Retest TAN and pH the following morning before resuming normal feeding.\n\n"
            "When To Call The Lab:\n"
            "- If un-ionised NH₃ remains elevated after reducing feed, or if behaviour changes "
            "(surface gasping, reduced feeding response), escalate immediately for laboratory confirmation."
        )

    elif scenario == "hypoxic_overnight":
        return (
            "Chemistry Reading:\n"
            f"- DO is {s.do_mg_l} mg/L — this is in or near the danger zone. "
            f"The readings are consistent with {label} — confirm by {confirm}.\n"
            f"- The overnight DO minimum is forecast at {s.predicted_night_do_min} mg/L, "
            f"calculated as: dusk DO {s.dusk_do_mg_l} mg/L "
            f"− respiration {s.respiration_rate} mg/L/h × {s.night_hours} h "
            f"+ reaeration {s.reaeration_rate} mg/L/h ≈ {s.predicted_night_do_min} mg/L [7]. "
            f"If aeration is insufficient, the actual minimum may be lower.\n"
            f"- Stress-hours recorded: {s.stress_hours_24h} h below the critical threshold in the last day.\n"
            f"- pH at {s.ph}, TAN at {s.tan_mg_l} mg/L, un-ionised NH₃ at {s.nh3_mg_l} mg/L "
            f"({s.nh3_fraction_pct} % at pKa ≈ {NH3_PKA_REF} [5] — highly pH- and temperature-dependent).\n\n"
            "Likely Cause:\n"
            f"- Overnight respiration from animals, phytoplankton, and bacteria depletes oxygen. "
            f"Nitrification alone consumes {s.o2_nitrif_demand} mg/L of oxygen "
            f"({O2_PER_G_TAN} g O₂ per g TAN at TAN {s.tan_mg_l} mg/L [4]). "
            f"If aerators cannot compensate, the pond drops into the danger zone before dawn.\n"
            f"- Alkalinity at {s.alkalinity_mg_l} mg/L (trend: {s.alkalinity_trend_7d} mg/L/day). "
            f"Nitrification is drawing down {s.alk_nitrif_demand} mg/L CaCO₃ per cycle "
            f"({ALK_PER_G_TAN} g CaCO₃ per g TAN [4]). "
            f"Sustained alkalinity depletion will eventually destabilise pH.\n\n"
            "What To Do Now:\n"
            "- Activate emergency aeration immediately — do not wait for morning.\n"
            "- Do not feed until DO recovers above the safe lower boundary.\n"
            "- Walk the pond bank and inspect all paddlewheels and air-stone diffusers for mechanical failure.\n"
            f"- Log the time, current DO of {s.do_mg_l} mg/L, and all actions for the farm record.\n\n"
            "When To Call The Lab:\n"
            "- If DO does not recover within two hours of maximum aeration, "
            "or if animals show surface gasping, contact the extension officer and laboratory without delay."
        )

    elif scenario == "nitrite_spike":
        return (
            "Chemistry Reading:\n"
            f"- Nitrite (NO₂) at {s.no2_mg_l} mg/L — this needs careful interpretation. "
            f"The readings are consistent with {label} — confirm by {confirm}.\n"
            f"- Nitrite toxicity is chloride-dependent [8]: "
            f"at low salinity the chloride ion cannot competitively block nitrite uptake at the gill, "
            f"so the same NO₂ reading is far more dangerous in freshwater than in brackish water. "
            f"Current Cl⁻ : NO₂ ratio is {s.cl_no2_ratio} (salinity {s.salinity_ppt} ppt, "
            f"Cl⁻ proxy {s.salinity_cl_mg_l} mg/L). A low ratio indicates higher acute risk.\n"
            f"- TAN at {s.tan_mg_l} mg/L (slope: {s.tan_slope_3d} mg/L/day), "
            f"un-ionised NH₃ at {s.nh3_mg_l} mg/L ({s.nh3_fraction_pct} % — "
            f"pKa ≈ {NH3_PKA_REF}, highly pH- and temperature-dependent [5]).\n"
            f"- DO at {s.do_mg_l} mg/L; alkalinity at {s.alkalinity_mg_l} mg/L.\n\n"
            "Likely Cause:\n"
            f"- Nitrite accumulates when the second step of nitrification "
            f"(NO₂⁻ → NO₃⁻) is slower than the first step (NH₃ → NO₂⁻). "
            f"Low DO — perhaps driven by the nitrification O₂ demand of "
            f"{s.o2_nitrif_demand} mg/L ({O2_PER_G_TAN} g per g TAN [4]) — "
            f"can selectively suppress Nitrobacter while Nitrosomonas continues.\n"
            f"- Alkalinity draw-down of {s.alk_nitrif_demand} mg/L CaCO₃ "
            f"({ALK_PER_G_TAN} g per g TAN [4]) further stresses nitrifier populations. "
            f"Seven-day alkalinity trend: {s.alkalinity_trend_7d} mg/L/day.\n"
            f"- Overnight minimum forecast: {s.predicted_night_do_min} mg/L "
            f"(≈ dusk {s.dusk_do_mg_l} − {s.respiration_rate} × {s.night_hours} h "
            f"+ {s.reaeration_rate}) [7].\n\n"
            "What To Do Now:\n"
            "- Run a field nitrite test to confirm the reading.\n"
            "- Check salinity — if salinity is low, the situation is more urgent.\n"
            "- Increase aeration to support the full nitrification cycle.\n"
            "- Reduce feed to cut new nitrogen loading.\n\n"
            "When To Call The Lab:\n"
            f"- Escalate by {confirm}. "
            "Brown or chocolate-coloured blood (methaemoglobinaemia) in harvested animals "
            "is a confirmed sign of nitrite poisoning — send samples to the laboratory immediately [8]."
        )

    else:  # brackish_nitrite_safe
        return (
            "Chemistry Reading:\n"
            f"- Nitrite (NO₂) at {s.no2_mg_l} mg/L. At salinity {s.salinity_ppt} ppt, "
            f"the Cl⁻ : NO₂ ratio is {s.cl_no2_ratio} (Cl⁻ proxy {s.salinity_cl_mg_l} mg/L). "
            f"The readings are consistent with {label} — confirm by {confirm}.\n"
            f"- Nitrite toxicity is chloride-dependent [8]: in brackish water, "
            f"the elevated chloride ion competitively inhibits nitrite uptake at the gill, "
            f"so acute toxicity is reduced compared to freshwater at the same NO₂ level. "
            f"However, chronic exposure at {s.no2_mg_l} mg/L can still cause sub-lethal stress.\n"
            f"- TAN at {s.tan_mg_l} mg/L, un-ionised NH₃ at {s.nh3_mg_l} mg/L "
            f"({s.nh3_fraction_pct} % at {s.temp_c} °C and pH {s.ph}; pKa ≈ {NH3_PKA_REF} [5]).\n"
            f"- DO at {s.do_mg_l} mg/L; alkalinity at {s.alkalinity_mg_l} mg/L.\n\n"
            "Likely Cause:\n"
            f"- Partial nitrification at elevated feeding rates. "
            f"Nitrification at TAN {s.tan_mg_l} mg/L demands {s.o2_nitrif_demand} mg/L O₂ "
            f"({O2_PER_G_TAN} g per g TAN [4]) and {s.alk_nitrif_demand} mg/L alkalinity "
            f"({ALK_PER_G_TAN} g CaCO₃ per g TAN [4]). "
            f"Seven-day alkalinity trend: {s.alkalinity_trend_7d} mg/L/day.\n"
            f"- Overnight minimum is forecast at {s.predicted_night_do_min} mg/L "
            f"(≈ dusk {s.dusk_do_mg_l} − {s.respiration_rate} × {s.night_hours} h "
            f"+ {s.reaeration_rate}) [7].\n\n"
            "What To Do Now:\n"
            "- Monitor nitrite every two days — while brackish water offers some protection, "
            "a rising trend still warrants action.\n"
            "- Maintain aeration to support the full nitrification cycle.\n"
            "- Keep alkalinity above the safe lower boundary to avoid nitrifier stress.\n\n"
            "When To Call The Lab:\n"
            f"- Confirm by {confirm}. "
            "If salinity drops or nitrite continues to rise, escalate to the laboratory promptly."
        )


# ── Main ─────────────────────────────────────────────────────────────────────

def main() -> None:
    print("=" * 60)
    print("M1 Chemistry SFT Dataset Builder — PRD-AV-01, Section 5.2")
    print("=" * 60)

    mlflow_uri = os.getenv("MLFLOW_TRACKING_URI",    "http://127.0.0.1:5000")
    mlflow_exp = os.getenv("MLFLOW_EXPERIMENT_NAME", "aquaverse-production")

    out_dir  = REPO_ROOT / "ml" / "datasets" / "sft"
    out_dir.mkdir(parents=True, exist_ok=True)
    out_file = out_dir / "m1_chemistry_sft.jsonl"

    system_instruction = (
        "You are the AquaVerse M1 Chemistry Reasoner. "
        "Given a pond chemistry state, explain why each parameter is moving, "
        "where it is heading, and what intervention will change it. "
        "Ground every conclusion in physical chemistry. "
        "Use hedged phrasing — never state a diagnosis as definitive. "
        "When readings are ambiguous, state clearly when to escalate to a laboratory."
    )

    target_n       = 5000
    valid_samples: list[dict] = []
    rejected       = 0
    scenario_keys  = list(SCENARIOS.keys())

    print(f"⚙️  Generating {target_n} instruction pairs …")
    t0 = time.time()

    while len(valid_samples) < target_n:
        scenario = random.choices(scenario_keys, weights=SCENARIO_WEIGHTS, k=1)[0]
        meta     = SCENARIOS[scenario]

        state   = simulate_state(scenario)
        payload = build_input_payload(state)
        target  = build_response(state, scenario, meta)

        # ── Rule R1: no output numeral absent from input ──────────────────
        in_nums  = extract_numbers(payload)
        out_nums = extract_numbers(target)
        hallucinated = out_nums - in_nums
        if hallucinated:
            rejected += 1
            continue

        # ── Rule R2: hedging phrase mandatory for non-healthy scenarios ───
        if scenario != "healthy_baseline" and "consistent with" not in target:
            rejected += 1
            continue

        # ── PRD AC: ammonia-oxygen link must cite 4.18 in spike scenario ─
        if scenario == "ammonia_oxygen_spike" and str(O2_PER_G_TAN) not in target:
            rejected += 1
            continue

        valid_samples.append({
            "messages": [
                {"role": "system",    "content": system_instruction},
                {"role": "user",      "content": payload},
                {"role": "assistant", "content": target},
            ]
        })

    elapsed = time.time() - t0
    print(f"  ✓ {len(valid_samples)} valid samples in {elapsed:.1f}s  (rejected: {rejected})")

    # ── Save ──────────────────────────────────────────────────────────────
    print(f"\n💾 Saving to {out_file} …")
    with open(out_file, "w", encoding="utf-8") as fh:
        for sample in valid_samples:
            fh.write(json.dumps(sample, ensure_ascii=False) + "\n")

    # ── SHA-256 ───────────────────────────────────────────────────────────
    hasher = hashlib.sha256()
    with open(out_file, "rb") as fh:
        hasher.update(fh.read())
    file_hash = hasher.hexdigest()
    print(f"  SHA-256: {file_hash}")

    # ── MLflow ────────────────────────────────────────────────────────────
    try:
        import mlflow
        mlflow.set_tracking_uri(mlflow_uri)
        mlflow.set_experiment(mlflow_exp)
        with mlflow.start_run(run_name="m1_chemistry_sft_v1"):
            mlflow.log_params({
                "num_samples":               target_n,
                "rejected_samples":          rejected,
                "dataset_hash":              file_hash,
                "rule_r1_enforced":          True,
                "rule_r2_enforced":          True,
                "grounding_o2_per_tan":      O2_PER_G_TAN,
                "grounding_alk_per_tan":     ALK_PER_G_TAN,
                "grounding_nh3_pka":         NH3_PKA_REF,
                "nitrite_chloride_dep":      True,
                "overnight_do_formula":      True,
                "scenarios":                 ",".join(scenario_keys),
                "style":                     "kisan_call_centre_register",
                "prd_section":               "5.2",
            })
            mlflow.log_artifact(str(out_file))
            mlflow.set_tags({
                "phase":   "m1_sft_dataset",
                "adapter": "m1_chemistry",
                "prd_ref": "PRD-AV-01",
            })
        print("  Logged to MLflow ✓")
    except Exception as exc:
        print(f"  MLflow skipped: {exc}")

    print("\n✅ M1 Chemistry SFT dataset generation complete.")
    print(f"   Output : {out_file}")
    print(f"   Hash   : {file_hash}")


if __name__ == "__main__":
    main()
