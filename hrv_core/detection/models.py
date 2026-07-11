"""Detection layer models (Deep Dive B.7 / B.8). Stdlib only."""
from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime, timedelta
from enum import Enum


# 1.4826 makes the MAD a consistent estimator of sigma for a normal distribution.
MAD_TO_SIGMA = 1.4826


class DetectorState(str, Enum):
    LEARNING = "learning"    # no reliable baseline yet — collect only, never alert
    NORMAL = "normal"
    WATCHING = "watching"    # an anomaly was seen, waiting to see if it persists
    ALERT = "alert"          # transient state on the tick an alert fires
    COOLDOWN = "cooldown"    # suppress further alerts for cooldown period


@dataclass(frozen=True)
class Baseline:
    """Personal baseline on the ln(RMSSD) scale (Deep Dive B.4)."""

    median: float
    mad: float
    sample_count: int
    window_start: datetime
    k: float = 2.0

    @property
    def scaled_mad(self) -> float:
        return MAD_TO_SIGMA * self.mad

    @property
    def lower_bound(self) -> float:
        return self.median - self.k * self.scaled_mad

    @property
    def upper_bound(self) -> float:
        return self.median + self.k * self.scaled_mad


@dataclass(frozen=True)
class DetectorConfig:
    """Calibration parameters — the heart of the product (Deep Dive B.7).

    These are *starting* values, not final. The simulation harness
    (sim/run_scenario.py) is how they get tuned before real-device data (Q-B).
    """

    k: float = 2.0                               # sensitivity in scaled-MAD units (1.5-2.0)
    persistence_window: int = 3                  # consecutive anomalies required before Alert
    cooldown: timedelta = timedelta(hours=8)     # minimum gap between alerts
    alert_on_drop_only: bool = True              # v1: only alert on an HRV *decrease*


@dataclass(frozen=True)
class SampleContext:
    """Contextual tags used for stratification (Deep Dive B.5)."""

    is_restful: bool = True   # False when taken near exertion (high HR) -> excluded entirely
    is_sleep: bool = False


@dataclass(frozen=True)
class AlertEvent:
    fired_at: datetime
    robust_z: float
    raw_value_ms: float
    reason: str
