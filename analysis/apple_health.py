"""Parse an Apple Health export (export.xml) into HRV samples.

Streams the file with ``iterparse`` and clears processed nodes, so a
multi-hundred-MB export does not blow up memory. Extracts HRV SDNN — Apple's
passive primary source (Deep Dive D-OP4). Unknown record types are skipped
silently, so exports whose structure is not 100% Apple-native (e.g. a Huawei
watch synced into Apple Health) parse without error — they simply yield no HRV.
"""
from __future__ import annotations

import xml.etree.ElementTree as ET
from dataclasses import dataclass
from datetime import datetime
from typing import List

HRV_SDNN = "HKQuantityTypeIdentifierHeartRateVariabilitySDNN"


@dataclass
class HRVReading:
    timestamp: datetime
    sdnn_ms: float
    source: str


def parse_date(s: str) -> datetime:
    """Apple Health date, e.g. '2026-01-01 08:00:00 +0000'."""
    return datetime.strptime(s, "%Y-%m-%d %H:%M:%S %z")


def parse_hrv_sdnn(path: str) -> List[HRVReading]:
    """Return all HRV SDNN readings (ms), sorted by time. Memory-light."""
    out: List[HRVReading] = []
    context = ET.iterparse(path, events=("start", "end"))
    _, root = next(context)  # the <HealthData> root
    for event, elem in context:
        if event != "end" or elem.tag != "Record":
            continue
        if elem.get("type") == HRV_SDNN:
            try:
                out.append(HRVReading(
                    timestamp=parse_date(elem.get("endDate")),
                    sdnn_ms=float(elem.get("value")),
                    source=elem.get("sourceName", ""),
                ))
            except (TypeError, ValueError):
                pass
        root.clear()  # drop processed records so memory stays flat
    out.sort(key=lambda r: r.timestamp)
    return out
