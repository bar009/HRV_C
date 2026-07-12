"""Parser + end-to-end pipeline on a synthetic Apple Health export."""
from datetime import timedelta

from analysis.apple_health import parse_hrv_sdnn

SAMPLE = """<?xml version="1.0" encoding="UTF-8"?>
<HealthData locale="en_US">
  <Record type="HKQuantityTypeIdentifierHeartRateVariabilitySDNN" sourceName="Apple Watch" unit="ms" creationDate="2026-01-01 08:00:00 +0000" startDate="2026-01-01 07:59:00 +0000" endDate="2026-01-01 08:00:00 +0000" value="45.2"/>
  <Record type="HKQuantityTypeIdentifierHeartRate" sourceName="Apple Watch" unit="count/min" creationDate="2026-01-01 08:00:00 +0000" startDate="2026-01-01 08:00:00 +0000" endDate="2026-01-01 08:00:00 +0000" value="62"/>
  <Record type="HKQuantityTypeIdentifierHeartRateVariabilitySDNN" sourceName="Apple Watch" unit="ms" creationDate="2026-01-02 09:00:00 +0000" startDate="2026-01-02 08:59:00 +0000" endDate="2026-01-02 09:00:00 +0000" value="52.0"/>
</HealthData>
"""


def test_parse_filters_and_sorts(tmp_path):
    p = tmp_path / "export.xml"
    p.write_text(SAMPLE, encoding="utf-8")
    r = parse_hrv_sdnn(str(p))
    assert len(r) == 2                      # the HeartRate record is ignored
    assert r[0].sdnn_ms == 45.2
    assert r[1].sdnn_ms == 52.0
    assert r[0].timestamp < r[1].timestamp  # sorted


def test_end_to_end_detects_injected_drop(tmp_path):
    from analysis.make_sample_export import write_sample
    from analysis.calibrate import run_detector
    from hrv_core.detection.models import DetectorConfig

    p = tmp_path / "sample.xml"
    write_sample(str(p), days=40, event_start=28, event_len=7, drop=0.45, seed=7)
    readings = parse_hrv_sdnn(str(p))
    assert len(readings) > 200

    alerts = run_detector(readings, DetectorConfig(k=2.0, persistence_window=3,
                                                   cooldown=timedelta(hours=8)))
    assert len(alerts) >= 1  # the sustained suppression is detected on realistic-shaped data


def test_empty_export_yields_no_readings(tmp_path):
    p = tmp_path / "empty.xml"
    p.write_text('<?xml version="1.0"?>\n<HealthData locale="en_US"></HealthData>\n', encoding="utf-8")
    assert parse_hrv_sdnn(str(p)) == []
