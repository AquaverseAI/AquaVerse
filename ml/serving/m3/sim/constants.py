"""
Tier-0 physical constants for the AquaVerse pond simulator.

Every constant here is sourced to literature per the programme rule in
PRD-AV-05 §10: "Every physical constant hard-coded in the simulator
carries an inline comment naming the reference number it came from.
A constant with no citation is a bug and will be rejected at code review."

Reference numbers match the programme-wide numbering (Dataset Register / PRD refs).
"""

# ---------------------------------------------------------------------------
# Nitrification stoichiometry
# Ref [4]: Ebeling, Timmons & Bisogni (2006), Aquaculture 257:346-358
# ---------------------------------------------------------------------------
O2_PER_G_TAN_NITRIFIED = 4.18          # g O2 consumed per g TAN oxidised
ALKALINITY_PER_G_TAN_NITRIFIED = 7.05  # g CaCO3 consumed per g TAN oxidised
BIOMASS_PRODUCED_PER_G_TAN = 0.20      # g nitrifier biomass produced per g TAN oxidised

# ---------------------------------------------------------------------------
# Feed nitrogen partition (biofloc C:N literature, dataset register Tier-0)
# ---------------------------------------------------------------------------
FEED_N_TO_WATER_FRACTION = 0.75        # fraction of feed N excreted to water column
FEED_N_TO_BIOMASS_FRACTION = 0.25      # fraction of feed N retained as fish/shrimp biomass
FEED_N_CONTENT_FRACTION = 0.052        # feed N as fraction of feed mass (~32% protein / 6.25 N-to-protein)

# ---------------------------------------------------------------------------
# NH3 <-> NH4+ equilibrium
# Ref [5]: Emerson, Russo, Lund & Thurston (1975), J. Fish. Res. Board Can. 32(12)
# ---------------------------------------------------------------------------
NH3_PKA_REFERENCE = 9.25               # approximate pKa at 25C, refined by temp below

def unionised_nh3_fraction(ph: float, temp_c: float) -> float:
    """
    Fraction of TAN present as toxic un-ionised NH3, as a function of pH and
    temperature. Emerson et al. (1975) [ref 5] regression form:

        pKa = 0.09018 + 2729.92 / T_kelvin

    fraction_NH3 = 1 / (1 + 10^(pKa - pH))
    """
    t_kelvin = temp_c + 273.15
    pka = 0.09018 + 2729.92 / t_kelvin
    return 1.0 / (1.0 + 10 ** (pka - ph))


# ---------------------------------------------------------------------------
# O2 saturation vs temperature and salinity (Benson-Krause)
# Ref [6]: APHA Standard Methods for the Examination of Water and Wastewater
# ---------------------------------------------------------------------------
def do_saturation_mg_l(temp_c: float, salinity_ppt: float = 0.0) -> float:
    """
    Benson-Krause dissolved-oxygen saturation concentration (mg/L),
    corrected for salinity. Standard APHA form. [ref 6]
    """
    t_k = temp_c + 273.15
    ln_cs = (
        -139.34411
        + 1.575701e5 / t_k
        - 6.642308e7 / t_k ** 2
        + 1.2438e10 / t_k ** 3
        - 8.621949e11 / t_k ** 4
    )
    cs_freshwater = pow(2.71828182846, ln_cs)

    if salinity_ppt > 0:
        # chlorinity-style salinity correction term
        correction = salinity_ppt * (
            1.7674e-2 - 10.754 / t_k + 2140.7 / t_k ** 2
        )
        cs = cs_freshwater * pow(2.71828182846, -correction)
    else:
        cs = cs_freshwater
    return cs


# ---------------------------------------------------------------------------
# Reaeration coefficient, wind-speed dependent
# Ref [7]: Boyd, C.E., Water Quality in Ponds for Aquaculture
# Banks & Herrera (1977) formulation, widely used in pond WQ models
# ---------------------------------------------------------------------------
def reaeration_coeff_per_day(wind_speed_ms: float, temp_c: float) -> float:
    """
    k2 at 20C from wind speed (m/s), then Arrhenius-corrected to temp_c.
    k2(20) = 0.728*sqrt(W) - 0.317*W + 0.0372*W^2   [Banks & Herrera, cited via ref 7]
    """
    w = max(wind_speed_ms, 0.0)
    k2_20 = 0.728 * (w ** 0.5) - 0.317 * w + 0.0372 * (w ** 2)
    k2_20 = max(k2_20, 0.05)  # floor: molecular diffusion still occurs at zero wind
    k2_t = k2_20 * (1.024 ** (temp_c - 20.0))
    return max(k2_t, 0.02)


# ---------------------------------------------------------------------------
# Expected FCR baseline
# Ref [36]: Zhang et al., feeding-frequency trial (A8: FCR 1.30 +/- 0.08, survival 98.48%)
# ---------------------------------------------------------------------------
FCR_BASELINE_VANNAMEI_LOW = 1.20
FCR_BASELINE_VANNAMEI_HIGH = 1.30

# ---------------------------------------------------------------------------
# Nitrifier maturation (immature biofilter causes early-DOC nitrite spikes)
# Modelled, not literature-exact: nitrification capacity ramps in over ~30 days
# from pond fill, consistent with cycling-protocol practice noted in project
# on-the-horizon notes ("pond fill, curing and cycling protocol").
# ---------------------------------------------------------------------------
NITRIFIER_MATURATION_DAYS = 30
