"""Anomaly detector: robust-z + alert state machine (Deep Dive B.3 / B.6). Stdlib only.

Mirrors the Swift ``AnomalyDetector`` (B.8.2). Every false-positive protection is
built into the state machine rather than bolted on:

  * Learning gate  — no alerts until a reliable baseline exists.
  * persistence    — an anomaly must last ``persistence_window`` samples before Alert.
  * cooldown       — no second alert until ``cooldown`` has elapsed.
  * context gating — samples taken near exertion never enter the baseline or alert.

Guiding rule (B.4/A.4): an over-eager alert makes the user turn the app off, so
we would rather miss than flood.
"""
from __future__ import annotations

import math
from datetime import datetime
from typing import Optional

from .baseline import BaselineEngine
from .models import (
    AlertEvent,
    Baseline,
    DetectorConfig,
    DetectorState,
    SampleContext,
)


def robust_z(x: float, baseline: Baseline) -> float:
    """(x - median) / (1.4826 * MAD). Returns 0 when MAD is 0 (degenerate baseline)."""
    denom = baseline.scaled_mad
    if denom == 0:
        return 0.0
    return (x - baseline.median) / denom


class AnomalyDetector:
    def __init__(self, baseline_engine: BaselineEngine, config: Optional[DetectorConfig] = None):
        self.engine = baseline_engine
        self.config = config or DetectorConfig()
        self.state: DetectorState = DetectorState.LEARNING
        self._consecutive_anomalies = 0
        self._last_alert_at: Optional[datetime] = None

    def _is_anomaly(self, z: float) -> bool:
        if self.config.alert_on_drop_only:
            return z < -self.config.k
        return abs(z) > self.config.k

    def evaluate(
        self,
        timestamp: datetime,
        rmssd_value: float,
        context: Optional[SampleContext] = None,
    ) -> Optional[AlertEvent]:
        """Feed one restful RMSSD sample; return an AlertEvent iff one should fire."""
        context = context or SampleContext()

        # Context gating (B.5): near exertion -> neither baseline nor alert.
        if not context.is_restful:
            return None

        # Roll the baseline forward, then read it back.
        self.engine.ingest(timestamp, rmssd_value)
        baseline = self.engine.current_baseline(asof=timestamp)

        if baseline is None:
            self.state = DetectorState.LEARNING
            return None

        if self.state == DetectorState.LEARNING:
            self.state = DetectorState.NORMAL

        z = robust_z(math.log(rmssd_value), baseline)
        anomalous = self._is_anomaly(z)

        # Cooldown: suppress everything until the period elapses.
        if self.state == DetectorState.COOLDOWN:
            if self._last_alert_at is not None and (timestamp - self._last_alert_at) >= self.config.cooldown:
                self.state = DetectorState.NORMAL  # fall through to normal handling
            else:
                if not anomalous:
                    self._consecutive_anomalies = 0
                return None

        if anomalous:
            self._consecutive_anomalies += 1
            if self.state == DetectorState.NORMAL:
                self.state = DetectorState.WATCHING
            if self._consecutive_anomalies >= self.config.persistence_window:
                self.state = DetectorState.COOLDOWN
                self._last_alert_at = timestamp
                self._consecutive_anomalies = 0
                return AlertEvent(
                    fired_at=timestamp,
                    robust_z=z,
                    raw_value_ms=rmssd_value,
                    reason=f"robust_z={z:.2f} < -k={self.config.k}",
                )
            return None

        # Returned to range.
        self._consecutive_anomalies = 0
        if self.state == DetectorState.WATCHING:
            self.state = DetectorState.NORMAL
        return None
