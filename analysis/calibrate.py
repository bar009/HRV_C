"""Run hrv_core on an Apple Health export: density (Q-A) + calibration (Q-B).

On an export that contains HRV SDNN, this builds the personal baseline, runs the
detector, and sweeps k / persistence / cooldown. It is the Track H calibration
tool and is Mac-independent. Validate the pipeline now on a synthetic export
(``analysis.make_sample_export``); run it on a real Apple Watch export later.
"""
from __future__ import annotations

import argparse
import math
import sys
from collections import Counter
from datetime import timedelta
from typing import List

from hrv_core.detection.baseline import BaselineEngine
from hrv_core.detection.detector import AnomalyDetector
from hrv_core.detection.models import AlertEvent, DetectorConfig, SampleContext
from analysis.apple_health import HRVReading, parse_hrv_sdnn


def summarize_density(readings: List[HRVReading]) -> None:
    per_day = Counter(r.timestamp.date() for r in readings)
    days = len(per_day)
    counts = list(per_day.values())
    vals = sorted(r.sdnn_ms for r in readings)
    print(f"  samples     : {len(readings)} over {days} days "
          f"({readings[0].timestamp.date()} -> {readings[-1].timestamp.date()})")
    print(f"  samples/day : mean {len(readings) / days:.1f}, min {min(counts)}, max {max(counts)}")
    print(f"  SDNN ms     : min {vals[0]:.0f}, median {vals[len(vals) // 2]:.0f}, max {vals[-1]:.0f}")


def run_detector(readings: List[HRVReading], config: DetectorConfig) -> List[AlertEvent]:
    engine = BaselineEngine(window_days=60, min_baseline_days=7, k=config.k)
    det = AnomalyDetector(engine, config)
    alerts: List[AlertEvent] = []
    for r in readings:
        evt = det.evaluate(r.timestamp, r.sdnn_ms, SampleContext(is_restful=True))
        if evt:
            alerts.append(evt)
    return alerts


def main() -> int:
    p = argparse.ArgumentParser(description="Calibrate hrv_core on an Apple Health export")
    p.add_argument("export")
    p.add_argument("--k", type=float, default=2.0)
    p.add_argument("--persistence", type=int, default=3)
    p.add_argument("--cooldown-hours", type=float, default=8.0)
    p.add_argument("--plot", action="store_true")
    p.add_argument("--out", default="my_hrv.png")
    args = p.parse_args()

    print(f"Parsing {args.export} ...")
    readings = parse_hrv_sdnn(args.export)

    print("\n=== Data density (Q-A: passive SDNN availability) ===")
    if not readings:
        print("  NO HRV SDNN records found — cannot calibrate.")
        print("  (Apple Watch writes SDNN mainly from Breathe/sleep; a Huawei export has none.)")
        return 0
    summarize_density(readings)
    if len(readings) < 30:
        print("\n  Not enough data to calibrate yet — keep collecting.")
        return 0

    cfg = DetectorConfig(k=args.k, persistence_window=args.persistence,
                         cooldown=timedelta(hours=args.cooldown_hours))
    print(f"\n=== Detector (k={cfg.k}, persistence={cfg.persistence_window}, cooldown={cfg.cooldown}) ===")
    alerts = run_detector(readings, cfg)
    print(f"  alerts fired: {len(alerts)}")
    for a in alerts[:10]:
        print(f"    {a.fired_at:%Y-%m-%d %H:%M}  robust_z={a.robust_z:.2f}  sdnn={a.raw_value_ms:.0f}ms")
    if len(alerts) > 10:
        print(f"    ... (+{len(alerts) - 10} more)")

    print("\n=== Sensitivity sweep (Q-B) ===")
    print(f"  {'k':>5} {'persist':>7} | {'alerts':>6}")
    for k in (1.5, 1.75, 2.0, 2.25, 2.5):
        for pw in (2, 3):
            c = DetectorConfig(k=k, persistence_window=pw, cooldown=cfg.cooldown)
            print(f"  {k:>5} {pw:>7} | {len(run_detector(readings, c)):>6}")

    if args.plot:
        _plot(readings, cfg, args.out)
    return 0


def _plot(readings: List[HRVReading], config: DetectorConfig, out: str) -> None:
    try:
        import matplotlib
        matplotlib.use("Agg")
        import matplotlib.pyplot as plt
    except ImportError:
        print("  (matplotlib not installed — skipping plot)")
        return
    engine = BaselineEngine(window_days=60, min_baseline_days=7, k=config.k)
    det = AnomalyDetector(engine, config)
    ts, ln, med, low, alert_ts, alert_ln = [], [], [], [], [], []
    for r in readings:
        evt = det.evaluate(r.timestamp, r.sdnn_ms, SampleContext(is_restful=True))
        b = engine.current_baseline(asof=r.timestamp)
        ts.append(r.timestamp)
        ln.append(math.log(r.sdnn_ms))
        med.append(b.median if b else None)
        low.append(b.lower_bound if b else None)
        if evt:
            alert_ts.append(r.timestamp)
            alert_ln.append(math.log(r.sdnn_ms))
    fig, ax = plt.subplots(figsize=(11, 5))
    ax.plot(ts, ln, ".", ms=4, alpha=0.5, label="ln(SDNN) samples")
    ax.plot(ts, med, "-", lw=1.5, label="baseline median")
    ax.plot(ts, low, "--", lw=1.0, label="lower bound")
    ax.plot(alert_ts, alert_ln, "v", ms=12, color="red", label="ALERT")
    ax.set_title("HRV calibration — your data")
    ax.set_ylabel("ln(SDNN)")
    ax.legend(loc="lower left", fontsize=8)
    fig.autofmt_xdate()
    fig.tight_layout()
    fig.savefig(out, dpi=110)
    print(f"  wrote plot -> {out}")


if __name__ == "__main__":
    sys.exit(main())
