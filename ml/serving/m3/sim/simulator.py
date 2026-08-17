"""
AquaVerse pond simulator v1.

This is the "trick that solves the data problem" from the MVP spec: the same
engine (a) generates mock data for the digital twin, (b) generates training
data for M1/M2/M3, and (c) becomes the residual-based anomaly detector once
real sensors arrive. Get this right once, it pays three times.

Hourly timestep. DO mass balance + N-cycle + growth, species-parameterized.
"""

from __future__ import annotations
import numpy as np
import pandas as pd

from . import constants as C
from .species import SpeciesParams, get_species
from .weather import WeatherGenerator


class PondSimulator:
    def __init__(
        self,
        species_key: str,
        pond_radius_m: float = 3.0,
        pond_depth_m: float = 0.6,
        stocking_count: int = 20,
        salinity_ppt: float | None = None,
        management_quality: float = 0.7,   # 0-1, farmer diligence dial
        aeration_available: bool = True,
        season: str = "mixed",
        seed: int | None = None,
    ):
        self.species: SpeciesParams = get_species(species_key)
        self.species_key = species_key
        self.rng = np.random.default_rng(seed)

        self.pond_area_m2 = np.pi * pond_radius_m ** 2
        self.pond_depth_m = pond_depth_m
        self.pond_volume_l = self.pond_area_m2 * pond_depth_m * 1000.0

        self.stocking_count = stocking_count
        self.salinity_ppt = (
            salinity_ppt
            if salinity_ppt is not None
            else float(np.mean(self.species.salinity_range_ppt))
        )
        self.management_quality = np.clip(management_quality, 0.0, 1.0)
        self.aeration_available = aeration_available
        self.weather_gen = WeatherGenerator(season=season, seed=seed)

    # ------------------------------------------------------------------
    def run(self, days: int | None = None) -> pd.DataFrame:
        sp = self.species
        days = days or sp.culture_days_typical
        hours = days * 24
        weather = self.weather_gen.generate(days)

        # --- state arrays ---
        water_temp_c = np.zeros(hours)
        do_mg_l = np.zeros(hours)
        tan_mg_l = np.zeros(hours)
        no2_mg_l = np.zeros(hours)
        no3_mg_l = np.zeros(hours)
        ph = np.zeros(hours)
        alkalinity_mg_l = np.zeros(hours)
        biomass_kg = np.zeros(hours)
        feed_kg_hourly = np.zeros(hours)
        aerator_on = np.zeros(hours, dtype=bool)
        mortality_count = np.zeros(hours, dtype=int)
        secchi_cm = np.zeros(hours)
        sod_load = np.zeros(hours)  # organic buildup driving sediment O2 demand

        # --- initial conditions ---
        water_temp_c[0] = weather["air_temp_c"][0]
        do_mg_l[0] = C.do_saturation_mg_l(water_temp_c[0], self.salinity_ppt) * 0.9
        tan_mg_l[0] = 0.05
        no2_mg_l[0] = 0.01
        no3_mg_l[0] = 1.0
        ph[0] = 7.8 if sp.water_type == "freshwater" else 8.1
        alkalinity_mg_l[0] = 120.0 if sp.water_type == "freshwater" else 150.0
        biomass_kg[0] = sp.stocking_weight_g * self.stocking_count / 1000.0
        secchi_cm[0] = 35.0
        sod_load[0] = 0.5

        alive_count = self.stocking_count
        cum_feed_kg = 0.0
        thermal_time_constant = 0.15 + 0.05 * self.pond_depth_m  # deeper pond = slower to equilibrate

        for h in range(1, hours):
            day = h // 24
            hour_of_day = h % 24

            # ---- water temperature (lags air temp) ----
            water_temp_c[h] = water_temp_c[h - 1] + thermal_time_constant * (
                weather["air_temp_c"][h] - water_temp_c[h - 1]
            )

            # ---- nitrifier maturation ramp (0 -> 1 over first N days) ----
            nitrifier_capacity = min(1.0, day / C.NITRIFIER_MATURATION_DAYS)

            # ---- feeding schedule: 3x/day at 08:00, 13:00, 18:00 ----
            # feeding rate as % of biomass/day, tapering as biomass grows (typical practice)
            biomass_prev = biomass_kg[h - 1]
            pct_bw_per_day = np.interp(
                biomass_prev, [0.1, 5, 50, 500], [8.0, 5.0, 3.0, 1.8]
            )
            daily_feed_kg = biomass_prev * pct_bw_per_day / 100.0
            # management noise: less diligent farmers over/under-feed
            daily_feed_kg *= 1.0 + self.rng.normal(0, 0.15 * (1.1 - self.management_quality))

            feed_now = 0.0
            if hour_of_day in (8, 13, 18):
                feed_now = daily_feed_kg / 3.0
                # occasional missed feed for low-management ponds
                if self.rng.random() < 0.1 * (1 - self.management_quality):
                    feed_now = 0.0
            feed_kg_hourly[h] = feed_now
            cum_feed_kg += feed_now

            # ---- nitrogen loading from feed (spread excretion over ~6h lag) ----
            feed_n_kg = feed_now * C.FEED_N_CONTENT_FRACTION
            tan_input_kg = feed_n_kg * C.FEED_N_TO_WATER_FRACTION
            tan_input_mg_l = (tan_input_kg * 1e6) / self.pond_volume_l

            # ---- sediment organic loading (drives SOD), decays slowly, builds with uneaten feed ----
            uneaten_frac = 0.05 + 0.15 * (1 - self.management_quality)
            sod_load[h] = sod_load[h - 1] * 0.999 + feed_now * uneaten_frac * 0.4
            sod_demand = 0.15 + 0.02 * sod_load[h]  # mg/L/hr equivalent baseline

            # ---- nitrification: TAN -> NO2 -> NO3, temp & DO & maturity dependent ----
            temp_factor = np.clip((water_temp_c[h - 1] - 15) / 15, 0.05, 1.3)
            do_limit = np.clip(do_mg_l[h - 1] / 2.0, 0.05, 1.0)
            k1 = 0.06 * nitrifier_capacity * temp_factor * do_limit   # TAN -> NO2
            k2_nitrite = 0.10 * nitrifier_capacity * temp_factor * do_limit  # NO2 -> NO3 (usually faster)

            tan_prev = tan_mg_l[h - 1] + tan_input_mg_l
            tan_oxidised = k1 * tan_prev
            no2_produced = tan_oxidised
            no2_prev = no2_mg_l[h - 1] + no2_produced
            no2_oxidised = k2_nitrite * no2_prev

            tan_mg_l[h] = max(tan_prev - tan_oxidised, 0.0)
            no2_mg_l[h] = max(no2_prev - no2_oxidised, 0.0)
            no3_mg_l[h] = no3_mg_l[h - 1] + no2_oxidised

            # O2 and alkalinity consumed by nitrification (Ebeling stoichiometry, ref 4)
            o2_demand_nitrification = tan_oxidised * C.O2_PER_G_TAN_NITRIFIED
            alk_demand_nitrification = tan_oxidised * C.ALKALINITY_PER_G_TAN_NITRIFIED

            # ---- alkalinity balance ----
            rain_dilution = weather["rain_mm"][h] * 0.15
            alkalinity_mg_l[h] = max(
                alkalinity_mg_l[h - 1] - alk_demand_nitrification - rain_dilution + 0.05,
                5.0,
            )

            # ---- pH: diurnal CO2 swing + alkalinity buffering + nitrification acidity ----
            daylight = max(np.sin((hour_of_day - 6) / 12 * np.pi), 0)
            ph_diurnal = 0.35 * daylight - 0.15  # up during day (CO2 uptake), down at night
            ph_buffer_drift = (alkalinity_mg_l[h] - 100) * 0.002
            ph_acidification = -tan_oxidised * 0.02
            base_ph = 7.8 if sp.water_type == "freshwater" else 8.1
            ph[h] = np.clip(
                base_ph + ph_diurnal + ph_buffer_drift + ph_acidification
                + self.rng.normal(0, 0.03),
                6.0, 9.5,
            )

            # ---- DO mass balance ----
            do_sat = C.do_saturation_mg_l(water_temp_c[h], self.salinity_ppt)
            k2_reaer = C.reaeration_coeff_per_day(weather["wind_speed_ms"][h], water_temp_c[h]) / 24.0

            productivity = 0.5 + 0.5 * self.management_quality  # nutrient-driven plankton density
            photosynthesis = daylight * (2.5 * productivity) * (1 - 0.4 * weather["cloud_cover_frac"][h])

            plankton_respiration = 0.4 * productivity  # constant background, causes night draw-down
            fish_respiration = (
                sp.respiration_coeff * biomass_prev * 0.02
                * temp_factor / max(self.pond_volume_l / 1000.0, 1.0)
            )
            respiration_total = plankton_respiration + fish_respiration + sod_demand

            reaeration = k2_reaer * (do_sat - do_mg_l[h - 1])

            # aerator control policy: turn on overnight if DO trending toward stress threshold
            forecast_risk = do_mg_l[h - 1] < (sp.do_stress_threshold_mg_l + 1.0) and hour_of_day in range(20, 24)
            forecast_risk |= do_mg_l[h - 1] < sp.do_stress_threshold_mg_l and hour_of_day in list(range(0, 6))
            responsive = self.rng.random() < (0.3 + 0.65 * self.management_quality)
            aerator_now = self.aeration_available and forecast_risk and responsive
            aerator_on[h] = aerator_now
            aerator_boost = 0.9 if aerator_now else 0.0

            do_next = (
                do_mg_l[h - 1]
                + photosynthesis
                - respiration_total
                - o2_demand_nitrification
                + reaeration
                + aerator_boost
                + self.rng.normal(0, 0.05)
            )
            do_mg_l[h] = np.clip(do_next, 0.05, do_sat * 1.4)

            # ---- growth ----
            do_stress_factor = np.clip(
                (do_mg_l[h] - sp.do_lethal_mg_l)
                / max(sp.do_stress_threshold_mg_l - sp.do_lethal_mg_l, 0.1)
                * sp.do_tolerance_factor,
                0.0, 1.0,
            )
            temp_growth_factor = np.clip(
                1.0 - abs(water_temp_c[h] - np.mean(sp.temp_optimum_c)) / 12.0, 0.1, 1.0
            )
            sgr_hourly = (sp.max_sgr_pct_day / 100.0 / 24.0) * do_stress_factor * temp_growth_factor
            biomass_kg[h] = biomass_prev * (1 + sgr_hourly) if alive_count > 0 else biomass_prev

            # ---- mortality ----
            mort_p = 0.00002  # baseline hourly mortality probability per animal
            if do_mg_l[h] < sp.do_lethal_mg_l:
                mort_p += 0.02
            elif do_mg_l[h] < sp.do_stress_threshold_mg_l:
                mort_p += 0.001
            new_deaths = self.rng.binomial(max(alive_count, 0), min(mort_p, 0.5))
            mortality_count[h] = new_deaths

            # Dead animals must stop contributing to pond biomass. Without this,
            # total biomass keeps compounding independent of population count,
            # and avg-weight-per-individual (biomass / alive_count) blows up
            # whenever a die-off shrinks the population faster than biomass
            # "notices". Remove each death's share of biomass at the average
            # weight *before* this hour's growth increment.
            if alive_count > 0 and new_deaths > 0:
                avg_weight_kg_prev = biomass_kg[h] / alive_count
                biomass_kg[h] = max(biomass_kg[h] - avg_weight_kg_prev * new_deaths, 0.0)

            alive_count = max(alive_count - new_deaths, 0)
            if alive_count == 0:
                biomass_kg[h] = 0.0

            # ---- turbidity / secchi (organic load + plankton density) ----
            secchi_cm[h] = np.clip(
                45 - 15 * productivity - 0.05 * sod_load[h] + self.rng.normal(0, 1.5),
                8, 60,
            )

        idx = pd.date_range("2026-01-01", periods=hours, freq="h")
        df = pd.DataFrame({
            "timestamp": idx,
            "day_of_culture": (np.arange(hours) // 24),
            "species": self.species_key,
            "air_temp_c": weather["air_temp_c"],
            "solar_rad_wm2": weather["solar_rad_wm2"],
            "wind_speed_ms": weather["wind_speed_ms"],
            "rain_mm": weather["rain_mm"],
            "water_temp_c": water_temp_c,
            "do_mg_l": do_mg_l,
            "tan_mg_l": tan_mg_l,
            "nh3_un_ionised_mg_l": tan_mg_l * np.array([
                C.unionised_nh3_fraction(p, t) for p, t in zip(ph, water_temp_c)
            ]),
            "no2_mg_l": no2_mg_l,
            "no3_mg_l": no3_mg_l,
            "ph": ph,
            "alkalinity_mg_l": alkalinity_mg_l,
            "salinity_ppt": self.salinity_ppt,
            "biomass_kg": biomass_kg,
            "alive_count": np.concatenate([[self.stocking_count],
                                            np.cumsum(mortality_count[1:]) * -1 + self.stocking_count]),
            "feed_kg": feed_kg_hourly,
            "cum_feed_kg": np.cumsum(feed_kg_hourly),
            "mortality_count": mortality_count,
            "aerator_on": aerator_on,
            "secchi_cm": secchi_cm,
            "management_quality": self.management_quality,
        })
        return df


def compute_running_fcr(df: pd.DataFrame, stocking_weight_g: float, stocking_count: int) -> pd.Series:
    stocked_biomass_kg = stocking_weight_g * stocking_count / 1000.0
    biomass_gain = (df["biomass_kg"] - stocked_biomass_kg).clip(lower=0.01)
    return df["cum_feed_kg"] / biomass_gain
