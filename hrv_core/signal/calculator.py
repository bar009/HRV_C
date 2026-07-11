"""Time-domain HRV metrics (Deep Dive A.3). Pure functions, stdlib only.

These mirror the Swift ``HRVCalculator`` enum (A.6.3) 1:1. Keeping them pure and
dependency-free is what makes the port mechanical and lets the unit tests act as
the numeric oracle for the eventual XCTest suite.

All inputs are sequences of NN (Normal-to-Normal) intervals in milliseconds,
i.e. RR intervals that already passed artifact rejection. Each function returns
``None`` when there is not enough data, mirroring Swift's ``Double?``.
"""
from __future__ import annotations

import math
from typing import List, Optional, Sequence


def _successive_diffs(nn: Sequence[float]) -> List[float]:
    """NN[i+1] - NN[i]; there are len(nn) - 1 of them."""
    return [nn[i + 1] - nn[i] for i in range(len(nn) - 1)]


def rmssd(nn: Sequence[float]) -> Optional[float]:
    """Root mean square of successive differences — the primary metric (A.3.1).

    Most stable over short windows and most responsive to fast changes, which is
    exactly what "extreme change" detection needs.
    """
    if len(nn) < 2:
        return None
    diffs = _successive_diffs(nn)
    mean_sq = sum(d * d for d in diffs) / len(diffs)
    return math.sqrt(mean_sq)


def sdnn(nn: Sequence[float]) -> Optional[float]:
    """Sample standard deviation of NN intervals (A.3, divide by N-1).

    Secondary metric, kept for consistency with the value Apple reports.
    """
    if len(nn) < 2:
        return None
    mean = sum(nn) / len(nn)
    variance = sum((x - mean) ** 2 for x in nn) / (len(nn) - 1)
    return math.sqrt(variance)


def pnn50(nn: Sequence[float]) -> Optional[float]:
    """Percentage of successive differences greater than 50 ms (A.3)."""
    if len(nn) < 2:
        return None
    diffs = _successive_diffs(nn)
    nn50 = sum(1 for d in diffs if abs(d) > 50.0)
    return (nn50 / len(diffs)) * 100.0


def sdsd(nn: Sequence[float]) -> Optional[float]:
    """Standard deviation of successive differences (A.3)."""
    if len(nn) < 3:  # need >= 2 diffs for a sample std of the diffs
        return None
    diffs = _successive_diffs(nn)
    mean = sum(diffs) / len(diffs)
    variance = sum((d - mean) ** 2 for d in diffs) / (len(diffs) - 1)
    return math.sqrt(variance)
