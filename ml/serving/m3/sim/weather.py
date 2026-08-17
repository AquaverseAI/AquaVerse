"""
Synthetic weather generator for Tamil Nadu coastal/inland climate.

This is a placeholder for the real Open-Meteo Historical Forecast API pull
(dataset register ref [38] / feature `rain_48h_mm`, `wind_mean_24h`,
`solar_rad_24h`). The sandbox has no network access to open-meteo.com, and
training must eventually run on the Historical Forecast API, not this
generator — the PRD's risk register flags train/serve skew as the exact bug
this would cause if used at serving time. This module exists ONLY to make the
simulator runnable standalone for dataset generation / architecture
validation. Swap `WeatherGenerator` for a real Open-Meteo puller before
producing the final training corpus.
"""

import numpy as np


class WeatherGenerator:
    def __init__(self, season: str = "mixed", seed: int | None = None):
        """
        season: "southwest_monsoon" (Jun-Sep), "northeast_monsoon" (Oct-Dec),
                "dry" (Jan-May), or "mixed" (randomly draws a season per cycle)
        """
        self.rng = np.random.default_rng(seed)
        self.season = season

    def _season_params(self):
        if self.season == "mixed":
            season = self.rng.choice(
                ["southwest_monsoon", "northeast_monsoon", "dry"]
            )
        else:
            season = self.season

        # (mean_air_temp_c, temp_amplitude, rain_prob_per_day, mean_wind_ms, cloud_base)
        table = {
            "southwest_monsoon": (28.0, 4.0, 0.35, 4.5, 0.55),
            "northeast_monsoon": (27.0, 4.5, 0.45, 3.5, 0.60),
            "dry": (31.0, 5.5, 0.05, 2.5, 0.20),
        }
        return season, table[season]

    def generate(self, days: int) -> dict:
        """
        Returns hourly arrays (length = days*24) for:
        air_temp_c, solar_rad_wm2, wind_speed_ms, rain_mm, cloud_cover_frac
        """
        season, (mean_t, amp_t, rain_prob, mean_wind, cloud_base) = self._season_params()
        hours = days * 24
        t = np.arange(hours)
        hour_of_day = t % 24
        day_of_run = t // 24

        # diurnal temperature cycle, trough ~05:00, peak ~15:00
        diurnal = -np.cos((hour_of_day - 5) / 24 * 2 * np.pi)
        air_temp_c = mean_t + amp_t * 0.5 * diurnal + self.rng.normal(0, 0.4, hours)

        # solar radiation: daytime bell curve, zero at night, modulated by cloud
        daylight = np.clip(np.sin((hour_of_day - 6) / 12 * np.pi), 0, None)
        cloud_cover_frac = np.clip(
            cloud_base + self.rng.normal(0, 0.15, hours), 0.0, 0.95
        )
        solar_rad_wm2 = 850 * daylight * (1 - 0.75 * cloud_cover_frac)

        # wind: diurnal (afternoon sea breeze) + noise
        wind_speed_ms = np.clip(
            mean_wind + 1.5 * np.clip(np.sin((hour_of_day - 9) / 14 * np.pi), 0, None)
            + self.rng.normal(0, 0.6, hours),
            0.2, None,
        )

        # rain: bernoulli per day, concentrated in a few afternoon/evening hours
        rain_days = self.rng.random(days) < rain_prob
        rain_mm = np.zeros(hours)
        for d in range(days):
            if rain_days[d]:
                n_wet_hours = self.rng.integers(1, 4)
                wet_hours = self.rng.choice(range(13, 21), size=n_wet_hours, replace=False)
                intensity = self.rng.exponential(8.0, n_wet_hours)
                for h, mm in zip(wet_hours, intensity):
                    rain_mm[d * 24 + h] = mm

        return {
            "season": season,
            "air_temp_c": air_temp_c,
            "solar_rad_wm2": solar_rad_wm2,
            "wind_speed_ms": wind_speed_ms,
            "rain_mm": rain_mm,
            "cloud_cover_frac": cloud_cover_frac,
        }
