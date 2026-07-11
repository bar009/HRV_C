"""Unified sample models for the Signal layer (Deep Dive A.5).

Mirrors the Swift ``HRVSample`` struct so the baseline/detector downstream work
against a single type and never care where a value came from. Stdlib only.
"""
from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime
from enum import Enum
from typing import Optional


class SampleQuality(str, Enum):
    HIGH = "high"
    LOW = "low"


class HRVMetric(str, Enum):
    SDNN_APPLE = "sdnnApple"          # Apple's built-in passive SDNN (primary source)
    RMSSD_COMPUTED = "rmssdComputed"  # computed by us from an RR/beat series
    SDNN_COMPUTED = "sdnnComputed"


class HRVSource(str, Enum):
    HEALTHKIT_DIRECT = "healthKitDirect"  # value read straight from HealthKit
    BEAT_SERIES = "beatSeries"            # derived from HKHeartbeatSeriesSample


@dataclass(frozen=True)
class HRVSample:
    """A single normalized HRV reading (Deep Dive A.5)."""

    timestamp: datetime
    value_ms: float
    metric: HRVMetric
    quality: SampleQuality
    source: HRVSource
    sample_count: Optional[int] = None  # how many NN intervals fed the value (computed path only)
