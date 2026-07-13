"""Detector -> presentation mapping (parity with PresentationMapperTests.swift)."""
from hrv_core.detection.models import DetectorState
from hrv_core.presentation import PresentationKind as K
from hrv_core.presentation import map_presentation


def _m(s, setup=True, recent=True):
    return map_presentation(s, has_completed_setup=setup, has_reliable_recent_sample=recent)


def test_not_set_up_is_always_setup_required():
    for s in DetectorState:
        assert _m(s, setup=False) is K.SETUP_REQUIRED


def test_stale_is_always_unavailable():
    for s in [DetectorState.NORMAL, DetectorState.WATCHING, DetectorState.ALERT, DetectorState.COOLDOWN]:
        assert _m(s, recent=False) is K.UNAVAILABLE


def test_detector_state_mapping():
    assert _m(DetectorState.LEARNING) is K.LEARNING
    assert _m(DetectorState.NORMAL) is K.STABLE
    assert _m(DetectorState.WATCHING) is K.STABLE   # internal, hidden
    assert _m(DetectorState.COOLDOWN) is K.STABLE   # internal, hidden
    assert _m(DetectorState.ALERT) is K.ATTENTION
