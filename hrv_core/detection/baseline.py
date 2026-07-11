"""Rolling baseline on ln(RMSSD) using median + MAD (Deep Dive B.2-B.4). Stdlib only.

RMSSD is approximately log-normal, so every statistic is computed on
``x = ln(value)``. Median + MAD are used instead of mean + SD because they are
robust to the right-skew and to single noisy samples that would otherwise poison
the very threshold we compare against. Mirrors the Swift ``BaselineEngine`` (B.8.1).
"""
from __future__ import annotations

import math
from dataclasses import dataclass
from datetime import datetime, timedelta
from statistics import median as _median
from typing import List, Optional

from .models import Baseline


def mad(values: List[float], center: Optional[float] = None) -> float:
    """Median Absolute Deviation of ``values``."""
    if not values:
        return 0.0
    med = center if center is not None else _median(values)
    return _median([abs(v - med) for v in values])


@dataclass
class _WindowSample:
    timestamp: datetime
    ln_value: float


class BaselineEngine:
    """Maintains the rolling window and derives the current baseline on demand."""

    def __init__(self, window_days: int = 60, min_baseline_days: int = 7, k: float = 2.0):
        self.window_days = window_days
        self.min_baseline_days = min_baseline_days
        self.k = k
        self._samples: List[_WindowSample] = []

    def ingest(self, timestamp: datetime, rmssd_value: float) -> None:
        """Add one high-quality, restful RMSSD sample to the rolling window."""
        if rmssd_value <= 0:
            return  # ln undefined; treat as "no measurement"
        self._samples.append(_WindowSample(timestamp, math.log(rmssd_value)))
        self._evict_old(asof=timestamp)

    def _evict_old(self, asof: datetime) -> None:
        cutoff = asof - timedelta(days=self.window_days)
        self._samples = [s for s in self._samples if s.timestamp >= cutoff]

    def distinct_days(self) -> int:
        return len({s.timestamp.date() for s in self._samples})

    def has_min_baseline(self) -> bool:
        return self.distinct_days() >= self.min_baseline_days

    def current_baseline(self, asof: Optional[datetime] = None) -> Optional[Baseline]:
        """Return the baseline over the current window, or None while Learning."""
        if asof is not None:
            self._evict_old(asof)
        if not self.has_min_baseline():
            return None
        xs = [s.ln_value for s in self._samples]
        med = _median(xs)
        return Baseline(
            median=med,
            mad=mad(xs, center=med),
            sample_count=len(xs),
            window_start=min(s.timestamp for s in self._samples),
            k=self.k,
        )
