"""Logical HRV repository (Deep Dive C.6 / C.7).

An in-memory implementation of the storage protocol, used to validate the
end-to-end data flow — this is deliberately NOT the real storage engine. On the
Mac this maps to a SwiftData/GRDB implementation behind the same protocol; every
layer above it stays unchanged (that is the whole point of C.7).

Key insight from C.1: HealthKit already *is* the raw database, so we never store
raw beats — only the processed samples, baseline state, alerts, and query
anchors that HealthKit does not hold for us.
"""
from __future__ import annotations

import json
from dataclasses import asdict, dataclass
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Optional


@dataclass
class ProcessedHRVSample:
    id: str
    timestamp: datetime
    ln_rmssd: float
    raw_value_ms: float
    metric: str        # sdnnApple / rmssdComputed
    quality: str       # high / low
    context: str       # rest / sleep / active
    source: str


@dataclass
class BaselineState:
    id: str
    computed_at: datetime
    median: float
    mad: float
    sample_count: int
    window_start: datetime


@dataclass
class AlertRecord:
    id: str
    fired_at: datetime
    robust_z: float
    raw_value_ms: float
    reason: str


class InMemoryHRVRepository:
    """Matches the ``HRVRepository`` protocol from C.7 (method names Pythonized)."""

    def __init__(self) -> None:
        self._samples: List[ProcessedHRVSample] = []
        self._baseline: Optional[BaselineState] = None
        self._alerts: List[AlertRecord] = []
        self._anchors: Dict[str, str] = {}

    # --- processed samples -------------------------------------------------
    def save(self, sample: ProcessedHRVSample) -> None:
        self._samples.append(sample)

    def samples(self, start: datetime, end: datetime) -> List[ProcessedHRVSample]:
        return [s for s in self._samples if start <= s.timestamp <= end]

    # --- baseline ----------------------------------------------------------
    def latest_baseline(self) -> Optional[BaselineState]:
        return self._baseline

    def upsert_baseline(self, baseline: BaselineState) -> None:
        self._baseline = baseline

    # --- alerts ------------------------------------------------------------
    def record_alert(self, alert: AlertRecord) -> None:
        self._alerts.append(alert)

    def recent_alerts(self, since: datetime) -> List[AlertRecord]:
        return [a for a in self._alerts if a.fired_at >= since]

    # --- HealthKit sync anchors -------------------------------------------
    def anchor(self, data_type: str) -> Optional[str]:
        return self._anchors.get(data_type)

    def save_anchor(self, data_type: str, anchor: str) -> None:
        self._anchors[data_type] = anchor

    # --- debug/export ------------------------------------------------------
    def snapshot(self) -> dict:
        return {
            "samples": [asdict(s) for s in self._samples],
            "baseline": asdict(self._baseline) if self._baseline else None,
            "alerts": [asdict(a) for a in self._alerts],
            "anchors": dict(self._anchors),
        }

    def dump_json(self, path: str | Path) -> None:
        Path(path).write_text(
            json.dumps(self.snapshot(), default=str, ensure_ascii=False, indent=2),
            encoding="utf-8",
        )
