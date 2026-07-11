"""Synthetic data generators for exercising the HRV core.

Two levels:
  * micro  — realistic RR interval series (with injectable artifacts) to drive
    the Signal layer (ArtifactCorrector + HRVCalculator).
  * macro  — a multi-day timeline of resting RMSSD samples (healthy baseline +
    circadian variation + an injected multi-day suppression event) to drive the
    Detection layer (BaselineEngine + AnomalyDetector).

numpy is used purely for convenient random draws — it stays out of hrv_core.
"""
from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime, timedelta
from typing import List, Optional

import numpy as np

# --------------------------------------------------------------------------- #
# micro — RR interval series for the Signal layer
# --------------------------------------------------------------------------- #

def make_rr_series(
    mean_hr_bpm: float = 60.0,
    rmssd_ms: float = 40.0,
    n_beats: int = 120,
    n_ectopic: int = 0,
    n_out_of_range: int = 0,
    seed: Optional[int] = None,
) -> List[float]:
    """Return a raw RR series (ms) with optional injected artifacts."""
    rng = np.random.default_rng(seed)
    mean_rr = 60000.0 / mean_hr_bpm
    rr = rng.normal(mean_rr, rmssd_ms, size=n_beats).tolist()

    if n_ectopic:
        for i in rng.choice(len(rr), size=min(n_ectopic, len(rr)), replace=False):
            rr[int(i)] *= 1.5  # +50% jump -> ectopic (> Malik 20%)
    if n_out_of_range:
        for i in rng.choice(len(rr), size=min(n_out_of_range, len(rr)), replace=False):
            rr[int(i)] = 120.0  # below physiological minimum
    return rr


# --------------------------------------------------------------------------- #
# macro — multi-day resting RMSSD timeline for the Detection layer
# --------------------------------------------------------------------------- #

@dataclass
class DailySample:
    timestamp: datetime
    rmssd_ms: float
    is_restful: bool


def make_multiday_timeline(
    days: int = 40,
    samples_per_day: int = 8,
    baseline_rmssd: float = 45.0,
    circadian_amp: float = 0.10,
    noise_frac: float = 0.08,
    event_start_day: Optional[int] = None,
    event_len_days: int = 0,
    event_drop_frac: float = 0.45,
    seed: Optional[int] = None,
    start: Optional[datetime] = None,
) -> List[DailySample]:
    """Generate a resting RMSSD timeline.

    A healthy log-normal baseline with mild circadian variation, optionally with a
    sustained multi-day suppression (``event_*``) representing the "extreme change"
    the product exists to catch.
    """
    rng = np.random.default_rng(seed)
    start = start or datetime(2026, 1, 1)
    out: List[DailySample] = []
    for d in range(days):
        for s in range(samples_per_day):
            frac = s / max(1, samples_per_day - 1)
            hour = 6.0 + frac * 17.0  # spread across waking hours 06:00-23:00
            ts = start + timedelta(days=d, hours=hour)

            circ = 1.0 + circadian_amp * np.sin(2 * np.pi * (hour / 24.0))
            val = baseline_rmssd * circ * float(np.exp(rng.normal(0.0, noise_frac)))

            if event_start_day is not None and event_start_day <= d < event_start_day + event_len_days:
                val *= (1.0 - event_drop_frac)

            out.append(DailySample(ts, float(val), True))
    return out
