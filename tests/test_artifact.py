"""ArtifactCorrector pipeline (Deep Dive A.4)."""
from hrv_core.signal.artifact import ArtifactCorrector
from hrv_core.signal.models import SampleQuality


def test_out_of_range_rejected():
    ac = ArtifactCorrector(min_valid_beats=1, max_reject_ratio=1.0)
    res = ac.clean([100.0, 800.0, 3000.0, 810.0])  # 100 and 3000 are out of range
    assert 100.0 not in res.nn
    assert 3000.0 not in res.nn
    assert res.rejected == 2
    assert res.nn == [800.0, 810.0]


def test_malik_rejects_ectopic_beat():
    ac = ArtifactCorrector(min_valid_beats=1, max_reject_ratio=1.0)
    # last_accepted starts at 800; 1300 is +62% -> ectopic; 805 is fine vs 800
    res = ac.clean([800.0, 810.0, 1300.0, 805.0])
    assert 1300.0 not in res.nn
    assert res.nn == [800.0, 810.0, 805.0]
    assert res.rejected == 1


def test_single_artifact_does_not_poison_chain():
    # After rejecting 1300, the next beat is compared to 810 (last accepted), not 1300.
    ac = ArtifactCorrector(min_valid_beats=1, max_reject_ratio=1.0)
    res = ac.clean([800.0, 810.0, 1300.0, 820.0])
    assert res.nn == [800.0, 810.0, 820.0]


def test_low_quality_when_too_few_beats():
    ac = ArtifactCorrector(min_valid_beats=30)
    res = ac.clean([800.0, 810.0, 805.0])
    assert res.quality == SampleQuality.LOW


def test_low_quality_when_reject_ratio_high():
    ac = ArtifactCorrector(min_valid_beats=1, max_reject_ratio=0.20)
    res = ac.clean([100.0, 3000.0, 800.0, 810.0])  # 2 of 4 rejected -> 50% > 20%
    assert res.quality == SampleQuality.LOW


def test_high_quality_enough_clean_beats():
    ac = ArtifactCorrector(min_valid_beats=30)
    rr = [800.0 + (i % 5) for i in range(50)]  # all in range, tiny deltas
    res = ac.clean(rr)
    assert res.rejected == 0
    assert res.quality == SampleQuality.HIGH


def test_empty_input_is_low_quality():
    ac = ArtifactCorrector()
    res = ac.clean([])
    assert res.nn == []
    assert res.quality == SampleQuality.LOW
