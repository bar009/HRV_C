"""AnomalyDetector state machine: persistence, cooldown, context gating (Deep Dive B.6)."""
from datetime import datetime, timedelta

from hrv_core.detection.baseline import BaselineEngine
from hrv_core.detection.detector import AnomalyDetector
from hrv_core.detection.models import DetectorConfig, DetectorState, SampleContext

START = datetime(2026, 1, 1)
HEALTHY = [43.0, 45.0, 47.0]  # small spread -> MAD > 0 (a constant baseline is degenerate)
DROP = 18.0                   # ~60% below baseline -> deeply anomalous
RESTFUL = SampleContext(is_restful=True)


def _config():
    return DetectorConfig(k=1.75, persistence_window=2, cooldown=timedelta(hours=8))


def _build_seeded_detector(days=10, per_day=6):
    engine = BaselineEngine(window_days=60, min_baseline_days=7)
    det = AnomalyDetector(engine, _config())
    last = START
    n = 0
    for d in range(days):
        for s in range(per_day):
            last = START + timedelta(days=d, hours=3 * s)
            det.evaluate(last, HEALTHY[n % len(HEALTHY)], RESTFUL)
            n += 1
    return det, engine, last


def test_baseline_established_leaves_learning():
    det, _, _ = _build_seeded_detector()
    assert det.state == DetectorState.NORMAL


def test_sustained_drop_fires_exactly_one_alert():
    det, _, last = _build_seeded_detector()
    alerts = []
    for i in range(5):  # five consecutive drops, 1h apart (inside the 8h cooldown)
        evt = det.evaluate(last + timedelta(hours=i + 1), DROP, RESTFUL)
        if evt:
            alerts.append(evt)
    assert len(alerts) == 1                       # persistence -> one alert, cooldown mutes the rest
    assert alerts[0].robust_z < -1.75
    assert det.state == DetectorState.COOLDOWN


def test_single_dip_does_not_alert():
    det, _, last = _build_seeded_detector()
    e1 = det.evaluate(last + timedelta(hours=1), DROP, RESTFUL)     # WATCHING
    e2 = det.evaluate(last + timedelta(hours=2), 45.0, RESTFUL)     # back to normal
    assert e1 is None and e2 is None
    assert det.state == DetectorState.NORMAL


def test_exertion_sample_is_ignored():
    det, engine, last = _build_seeded_detector()
    before = engine.distinct_days()
    count_before = len(engine._samples)
    evt = det.evaluate(last + timedelta(hours=1), DROP, SampleContext(is_restful=False))
    assert evt is None
    assert det.state == DetectorState.NORMAL          # unchanged
    assert len(engine._samples) == count_before       # not ingested into baseline
    assert engine.distinct_days() == before


def test_alert_fires_again_after_cooldown_elapses():
    det, _, last = _build_seeded_detector()
    alerts = []
    # first sustained drop -> alert #1 at +2h
    for i in (1, 2):
        evt = det.evaluate(last + timedelta(hours=i), DROP, RESTFUL)
        if evt:
            alerts.append(evt)
    # cooldown is 8h; resume drops well after it -> alert #2
    for i in (11, 12):
        evt = det.evaluate(last + timedelta(hours=i), DROP, RESTFUL)
        if evt:
            alerts.append(evt)
    assert len(alerts) == 2
