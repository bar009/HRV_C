"""HRVCalculator vs hand-computed values (Deep Dive A.3)."""
import math
import statistics

import pytest

from hrv_core.signal.calculator import pnn50, rmssd, sdnn, sdsd

NN = [800.0, 850.0, 800.0, 820.0, 810.0]  # diffs: 50, -50, 20, -10


def test_rmssd_known():
    # squares: 2500, 2500, 400, 100 -> mean 1375
    assert rmssd(NN) == pytest.approx(math.sqrt(1375.0))


def test_sdnn_matches_sample_stdev():
    assert sdnn(NN) == pytest.approx(statistics.stdev(NN))


def test_pnn50_known():
    nn = [800.0, 900.0, 820.0, 870.0]  # diffs 100, -80, 50 -> two are > 50ms
    assert pnn50(nn) == pytest.approx(200.0 / 3.0)


def test_sdsd_matches_sample_stdev_of_diffs():
    diffs = [NN[i + 1] - NN[i] for i in range(len(NN) - 1)]
    assert sdsd(NN) == pytest.approx(statistics.stdev(diffs))


@pytest.mark.parametrize("fn", [rmssd, sdnn, pnn50])
def test_short_input_returns_none(fn):
    assert fn([800.0]) is None
    assert fn([]) is None


def test_sdsd_needs_three_intervals():
    assert sdsd([800.0, 810.0]) is None
