"""Factual report of what an Apple Health export contains (memory-light).

Streams the file, counts records per HealthKit type, and reports the date span
and whether HRV SDNN is present. Use it to characterize a real export before
calibration (e.g. the Huawei-sourced export that lacks HRV entirely).
"""
from __future__ import annotations

import argparse
import sys
import xml.etree.ElementTree as ET
from collections import Counter
from datetime import datetime
from typing import Optional, Tuple

from analysis.apple_health import HRV_SDNN, parse_date


def scan(path: str) -> Tuple[Counter, Optional[datetime], Optional[datetime]]:
    counts: Counter = Counter()
    first: Optional[datetime] = None
    last: Optional[datetime] = None
    context = ET.iterparse(path, events=("start", "end"))
    _, root = next(context)
    for event, elem in context:
        if event != "end" or elem.tag != "Record":
            continue
        t = elem.get("type")
        if t:
            counts[t] += 1
        end = elem.get("endDate")
        if end:
            try:
                d = parse_date(end)
                if first is None or d < first:
                    first = d
                if last is None or d > last:
                    last = d
            except ValueError:
                pass
        root.clear()
    return counts, first, last


def main() -> int:
    p = argparse.ArgumentParser(description="Report the contents of an Apple Health export")
    p.add_argument("export")
    args = p.parse_args()

    print(f"Scanning {args.export} ...")
    counts, first, last = scan(args.export)
    total = sum(counts.values())
    print(f"\nRecords : {total:,}")
    if first and last:
        print(f"Span    : {first.date()} -> {last.date()} ({(last - first).days} days)")

    hrv = counts.get(HRV_SDNN, 0)
    print(f"\nHRV SDNN present : {'YES (' + str(hrv) + ')' if hrv else 'NO — 0 records'}")
    if not hrv:
        print("  (Apple Watch writes SDNN mainly from Breathe/sleep; a Huawei export has none.)")

    print("\nTop data types:")
    for t, c in counts.most_common(20):
        short = t.replace("HKQuantityTypeIdentifier", "").replace("HKCategoryTypeIdentifier", "")
        print(f"  {c:>10,}  {short}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
