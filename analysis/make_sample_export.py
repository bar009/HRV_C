"""Write a synthetic Apple Health export.xml (HRV SDNN) for testing the pipeline
and formulas before real Apple Watch data exists. Uses sim.synthetic for
realistic values (healthy baseline + an injected multi-day suppression event).
"""
from __future__ import annotations

import argparse
import sys

from sim.synthetic import make_multiday_timeline

_HEADER = '<?xml version="1.0" encoding="UTF-8"?>\n<HealthData locale="en_US">\n'
_FOOTER = "</HealthData>\n"
_REC = ('  <Record type="HKQuantityTypeIdentifierHeartRateVariabilitySDNN" '
        'sourceName="Apple Watch" unit="ms" '
        'creationDate="{d}" startDate="{d}" endDate="{d}" value="{v:.1f}"/>\n')


def write_sample(path: str, days: int = 40, samples_per_day: int = 8,
                 event_start: int = 28, event_len: int = 7, drop: float = 0.45,
                 seed: int = 7) -> int:
    timeline = make_multiday_timeline(
        days=days, samples_per_day=samples_per_day, event_start_day=event_start,
        event_len_days=event_len, event_drop_frac=drop, seed=seed,
    )
    with open(path, "w", encoding="utf-8") as f:
        f.write(_HEADER)
        for s in timeline:
            d = s.timestamp.strftime("%Y-%m-%d %H:%M:%S +0000")
            f.write(_REC.format(d=d, v=s.rmssd_ms))
        f.write(_FOOTER)
    return len(timeline)


def main() -> int:
    p = argparse.ArgumentParser(description="Write a synthetic Apple Health export.xml")
    p.add_argument("out")
    p.add_argument("--days", type=int, default=40)
    p.add_argument("--event-start", type=int, default=28)
    p.add_argument("--event-len", type=int, default=7)
    p.add_argument("--drop", type=float, default=0.45)
    p.add_argument("--seed", type=int, default=7)
    a = p.parse_args()
    n = write_sample(a.out, days=a.days, event_start=a.event_start,
                     event_len=a.event_len, drop=a.drop, seed=a.seed)
    print(f"wrote {n} synthetic HRV records -> {a.out}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
