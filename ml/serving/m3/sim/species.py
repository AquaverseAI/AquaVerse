"""
Species parameter sets. Add a species by adding a SpeciesParams entry —
nothing else in the simulator should need to change (species-parameterized
by design, per your call to scope v1 for both freshwater and brackish species).
"""

from dataclasses import dataclass


@dataclass(frozen=True)
class SpeciesParams:
    name: str
    water_type: str            # "freshwater" | "brackish"
    salinity_range_ppt: tuple  # (min, max) tolerated
    temp_optimum_c: tuple      # (low, high) optimal growth band
    stocking_weight_g: float   # typical stocking size
    harvest_weight_g: float    # typical target harvest size
    max_sgr_pct_day: float     # specific growth rate ceiling, %/day, at optimum conditions
    fcr_target: float          # target feed conversion ratio under good management
    do_stress_threshold_mg_l: float   # below this, growth/feeding suppressed
    do_lethal_mg_l: float             # below this, mortality risk rises sharply
    do_tolerance_factor: float        # 1.0 = baseline; >1 = more tolerant of low DO (air-breathers)
    respiration_coeff: float          # relative metabolic O2 demand per kg biomass
    feed_protein_pct: float           # typical feed protein %, used for N loading
    culture_days_typical: int         # typical days of culture to harvest


SPECIES = {
    "gift_tilapia": SpeciesParams(
        name="GIFT Tilapia (Oreochromis niloticus)",
        water_type="freshwater",
        salinity_range_ppt=(0, 5),
        temp_optimum_c=(27, 30),
        stocking_weight_g=15.0,
        harvest_weight_g=500.0,
        max_sgr_pct_day=2.8,
        fcr_target=1.6,
        do_stress_threshold_mg_l=3.0,
        do_lethal_mg_l=1.0,
        do_tolerance_factor=1.2,   # moderately tolerant
        respiration_coeff=1.0,
        feed_protein_pct=28.0,
        culture_days_typical=180,
    ),
    "magur_catfish": SpeciesParams(
        name="Magur Catfish (Clarias magur)",
        water_type="freshwater",
        salinity_range_ppt=(0, 2),
        temp_optimum_c=(25, 31),
        stocking_weight_g=10.0,
        harvest_weight_g=120.0,
        max_sgr_pct_day=3.2,
        fcr_target=1.3,
        do_stress_threshold_mg_l=1.5,   # air-breathing, tolerant
        do_lethal_mg_l=0.3,
        do_tolerance_factor=2.5,        # accessory air-breathing organ
        respiration_coeff=0.8,
        feed_protein_pct=32.0,
        culture_days_typical=150,
    ),
    "vannamei": SpeciesParams(
        name="Litopenaeus vannamei",
        water_type="brackish",
        salinity_range_ppt=(5, 25),
        temp_optimum_c=(28, 32),
        stocking_weight_g=0.01,   # post-larvae
        harvest_weight_g=18.0,
        max_sgr_pct_day=8.0,      # PL grow fast early, SGR% is deceptive but kept simple here
        fcr_target=1.25,          # ref [36]: 1.20-1.30 baseline
        do_stress_threshold_mg_l=4.0,
        do_lethal_mg_l=1.5,
        do_tolerance_factor=0.8,  # least tolerant of the three
        respiration_coeff=1.1,
        feed_protein_pct=35.0,
        culture_days_typical=100,
    ),
}


def get_species(key: str) -> SpeciesParams:
    if key not in SPECIES:
        raise KeyError(f"Unknown species '{key}'. Options: {list(SPECIES)}")
    return SPECIES[key]
