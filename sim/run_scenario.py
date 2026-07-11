"""End-to-end simulation of the passive HRV core (run from the repo root).

    python -m sim.run_scenario                # print scenarios A and B
    python -m sim.run_scenario --plot         # also write a PNG of scenario A

Scenario A: healthy learning period, then a sustained multi-day HRV suppression.
            Expectation -> the detector fires at least one alert during the event.
Scenario B: a healthy-but-noisy control with no event.
            Expectation -> the detector stays silent (no false positives).

This runner is also the living calibration tool for the DetectorConfig
parameters (k, persistence, cooldown) — Deep Dive B.7 / open question Q-B.
"""
from __future__ import annotations

import argparse
import math
import sys
from dataclasses import dataclass
from datetime import timedelta
from typing import List, Optional, Tuple

from hrv_core.detection.baseline import BaselineEngine
from hrv_core.detection.detector import AnomalyDetector
from hrv_core.detection.models import AlertEvent, DetectorConfig, DetectorState, SampleContext
from sim.synthetic import DailySample, make_multiday_timeline


@dataclass
class Step:
    ts: object
    ln_value: float
    baseline_median: Optional[float]
    lower_bound: Optional[float]
    state: str
    is_alert: bool


def run(timeline: List[DailySample], config: DetectorConfig) -> Tuple[List[AlertEvent], List[Step]]:
    engine = BaselineEngine(window_days=60, min_baseline_days=7, k=config.k)
    detector = AnomalyDetector(engine, config)
    alerts: List[AlertEvent] = []
    steps: List[Step] = []

    for smp in timeline:
        evt = detector.evaluate(smp.timestamp, smp.rmssd_ms, SampleContext(is_restful=smp.is_restful))
        if evt:
            alerts.append(evt)
        b = engine.current_baseline(asof=smp.timestamp)
        steps.append(
            Step(
                ts=smp.timestamp,
                ln_value=math.log(smp.rmssd_ms),
                baseline_median=(b.median if b else None),
                lower_bound=(b.lower_bound if b else None),
                state=detector.state.value,
                is_alert=bool(evt),
            )
        )
    return alerts, steps


def _print_transitions(steps: List[Step]) -> None:
    prev = None
    for s in steps:
        if s.state != prev:
            print(f"    {s.ts:%Y-%m-%d %H:%M}  ->  {s.state.upper()}")
            prev = s.state


def main() -> int:
    p = argparse.ArgumentParser(description="HRV passive-core simulation")
    p.add_argument("--days", type=int, default=45)
    p.add_argument("--event-start", type=int, default=28)
    p.add_argument("--event-len", type=int, default=7)
    p.add_argument("--drop", type=float, default=0.45, help="fractional HRV suppression during event")
    p.add_argument("--k", type=float, default=2.0)
    p.add_argument("--persistence", type=int, default=3)
    p.add_argument("--cooldown-hours", type=float, default=8.0)
    p.add_argument("--seed", type=int, default=7)
    p.add_argument("--seeds", type=int, default=20, help="how many seeds for the robustness summary")
    p.add_argument("--plot", action="store_true", help="write a PNG of scenario A")
    p.add_argument("--out", type=str, default="scenario_A.png")
    args = p.parse_args()

    config = DetectorConfig(
        k=args.k,
        persistence_window=args.persistence,
        cooldown=timedelta(hours=args.cooldown_hours),
    )

    # Scenario A — sustained suppression event.
    tl_a = make_multiday_timeline(
        days=args.days, event_start_day=args.event_start, event_len_days=args.event_len,
        event_drop_frac=args.drop, seed=args.seed,
    )
    alerts_a, steps_a = run(tl_a, config)

    # ---- Scenario A narrative (single seed, detailed) --------------------
    print("=" * 66)
    print("Scenario A - healthy learning, then a sustained HRV suppression")
    print("=" * 66)
    print(f"  config: k={config.k}  persistence={config.persistence_window}  "
          f"cooldown={config.cooldown}")
    print(f"  event: days {args.event_start}-{args.event_start + args.event_len - 1}, "
          f"drop={args.drop:.0%}  (seed={args.seed})")
    print("  state transitions:")
    _print_transitions(steps_a)
    print(f"  alerts fired: {len(alerts_a)}")
    for a in alerts_a[:5]:
        print(f"    {a.fired_at:%Y-%m-%d %H:%M}  robust_z={a.robust_z:.2f}  "
              f"value={a.raw_value_ms:.1f}ms")
    if len(alerts_a) > 5:
        print(f"    ... (+{len(alerts_a) - 5} more during the sustained event)")

    # ---- Robustness over many seeds (the honest result) ------------------
    detected, fp_seeds, total_fp = _robustness(args, config)
    n = args.seeds
    fp_tol = max(1, round(0.05 * n))  # tolerate <= 5% of control seeds
    a_ok = detected == n
    b_ok = fp_seeds <= fp_tol

    print()
    print("=" * 66)
    print(f"Robustness over {n} seeds")
    print("=" * 66)
    print(f"  event detected     : {detected}/{n} seeds")
    print(f"  control false-pos. : {fp_seeds}/{n} seeds fired (>=1 alert), "
          f"{total_fp} alerts total  [tolerance <= {fp_tol}]")

    print()
    print(f"RESULT:  detects event = {'PASS' if a_ok else 'FAIL'}   |   "
          f"false-positive rate = {'PASS' if b_ok else 'FAIL'}")
    print("  (final k/persistence/cooldown await real-device data - open question Q-B)")

    if args.plot:
        _plot(steps_a, args.out)

    return 0 if (a_ok and b_ok) else 1


def _robustness(args, config: DetectorConfig) -> Tuple[int, int, int]:
    """Run event + control across many seeds; return (detected, fp_seeds, total_fp)."""
    detected = fp_seeds = total_fp = 0
    for s in range(args.seeds):
        ev = make_multiday_timeline(
            days=args.days, event_start_day=args.event_start, event_len_days=args.event_len,
            event_drop_frac=args.drop, seed=1000 + s,
        )
        if len(run(ev, config)[0]) >= 1:
            detected += 1
        ctrl = make_multiday_timeline(days=args.days, noise_frac=0.08, seed=5000 + s)
        n_fp = len(run(ctrl, config)[0])
        if n_fp > 0:
            fp_seeds += 1
        total_fp += n_fp
    return detected, fp_seeds, total_fp


def _plot(steps: List[Step], out: str) -> None:
    try:
        import matplotlib
        matplotlib.use("Agg")
        import matplotlib.pyplot as plt
    except ImportError:
        print("  (matplotlib not installed — skipping plot)")
        return

    ts = [s.ts for s in steps]
    ln = [s.ln_value for s in steps]
    med = [s.baseline_median for s in steps]
    low = [s.lower_bound for s in steps]
    alert_ts = [s.ts for s in steps if s.is_alert]
    alert_ln = [s.ln_value for s in steps if s.is_alert]

    fig, ax = plt.subplots(figsize=(11, 5))
    ax.plot(ts, ln, ".", ms=4, alpha=0.6, label="ln(RMSSD) samples")
    ax.plot(ts, med, "-", lw=1.5, label="baseline median")
    ax.plot(ts, low, "--", lw=1.0, label="lower bound (median - k·MAD)")
    ax.plot(alert_ts, alert_ln, "v", ms=12, color="red", label="ALERT")
    ax.set_title("HRV passive core — scenario A (sustained suppression)")
    ax.set_ylabel("ln(RMSSD)")
    ax.legend(loc="lower left", fontsize=8)
    fig.autofmt_xdate()
    fig.tight_layout()
    fig.savefig(out, dpi=110)
    print(f"  wrote plot -> {out}")


if __name__ == "__main__":
    sys.exit(main())
