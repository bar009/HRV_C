"""Artifact rejection pipeline (Deep Dive A.4). Pure, stdlib only.

Most false-positive alerts originate from noisy intervals, so this stage is
deliberately conservative: it prefers returning ``LOW_QUALITY`` over emitting a
noisy value. Mirrors the Swift ``ArtifactCorrector`` struct (A.6.2).

Pipeline order on a raw RR sequence (ms):
  1. physiological range filter          [300, 2000] ms  (~30-200 bpm)
  2. adaptive successive-delta (Malik)    reject beat if >20% from last ACCEPTED
  3. deletion (default; no interpolation)
  4. window quality gate                  < min_valid_beats OR > max_reject_ratio
"""
from __future__ import annotations

from dataclasses import dataclass
from typing import List, Optional, Sequence

from .models import SampleQuality


@dataclass(frozen=True)
class CleanResult:
    nn: List[float]        # accepted Normal-to-Normal intervals (ms)
    rejected: int          # number of raw beats dropped
    quality: SampleQuality


@dataclass(frozen=True)
class ArtifactCorrector:
    physiological_min_ms: float = 300.0
    physiological_max_ms: float = 2000.0
    max_successive_delta: float = 0.20   # Malik 20%
    min_valid_beats: int = 30
    max_reject_ratio: float = 0.20

    def clean(self, rr: Sequence[float]) -> CleanResult:
        total = len(rr)

        # Step 1 — physiological range filter
        in_range = [
            x for x in rr
            if self.physiological_min_ms <= x <= self.physiological_max_ms
        ]

        # Step 2/3 — Malik successive-delta filter against the last ACCEPTED beat.
        # Comparing to the last accepted (not the immediate previous) prevents a
        # single artifact from poisoning the rest of the chain.
        nn: List[float] = []
        last_accepted: Optional[float] = None
        for x in in_range:
            if last_accepted is None:
                nn.append(x)
                last_accepted = x
                continue
            if abs(x - last_accepted) / last_accepted > self.max_successive_delta:
                continue  # ectopic beat -> delete, do NOT update last_accepted
            nn.append(x)
            last_accepted = x

        rejected = total - len(nn)

        # Step 4 — minimum window quality gate
        reject_ratio = (rejected / total) if total > 0 else 1.0
        quality = SampleQuality.HIGH
        if len(nn) < self.min_valid_beats or reject_ratio > self.max_reject_ratio:
            quality = SampleQuality.LOW

        return CleanResult(nn=nn, rejected=rejected, quality=quality)
