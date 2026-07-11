"""BaselineEngine rolling window + median/MAD on ln (Deep Dive B.2-B.4)."""
import math
import statistics
from datetime import datetime, timedelta

import pytest

from hrv_core.detection.baseline import BaselineEngine, mad


def test_median_and_mad_on_ln_scale():
    engine = BaselineEngine(window_days=60, min_baseline_days=1)
    start = datetime(2026, 1, 1)
    vals = [40.0, 45.0, 50.0, 45.0, 40.0, 50.0, 45.0]
    for i, v in enumerate(vals):
        engine.ingest(start + timedelta(days=i), v)

    b = engine.current_baseline(asof=start + timedelta(days=len(vals)))
    xs = [math.log(v) for v in vals]
    assert b is not None
    assert b.median == pytest.approx(statistics.median(xs))
    assert b.mad == pytest.approx(mad(xs))
    assert b.sample_count == len(vals)


def test_learning_until_min_days():
    engine = BaselineEngine(min_baseline_days=7)
    start = datetime(2026, 1, 1)
    for i in range(5):  # only 5 distinct days
        engine.ingest(start + timedelta(days=i), 45.0)
    assert engine.current_baseline(asof=start + timedelta(days=5)) is None
    assert not engine.has_min_baseline()


def test_window_evicts_old_samples():
    engine = BaselineEngine(window_days=10, min_baseline_days=1)
    start = datetime(2026, 1, 1)
    engine.ingest(start, 40.0)
    engine.ingest(start + timedelta(days=20), 50.0)
    b = engine.current_baseline(asof=start + timedelta(days=20))
    assert b is not None
    assert b.sample_count == 1  # the day-0 sample fell outside the 10-day window
    assert b.median == pytest.approx(math.log(50.0))


def test_non_positive_value_ignored():
    engine = BaselineEngine(min_baseline_days=1)
    start = datetime(2026, 1, 1)
    engine.ingest(start, 0.0)
    engine.ingest(start, -5.0)
    assert engine.distinct_days() == 0


def test_lower_bound_uses_scaled_mad():
    engine = BaselineEngine(min_baseline_days=1, k=2.0)
    start = datetime(2026, 1, 1)
    for i, v in enumerate([40.0, 45.0, 50.0]):
        engine.ingest(start + timedelta(days=i), v)
    b = engine.current_baseline()
    assert b.lower_bound == pytest.approx(b.median - 2.0 * 1.4826 * b.mad)
