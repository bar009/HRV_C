"""Pure detector-state -> presentation-state mapping (PRODUCT_STATE_MODEL).

The single connection point between the compute pipeline and the UI. Watching and
Cooldown are internal and render as Stable; only a confirmed Alert becomes
Attention. Parallel to the Swift `PresentationMapper` (parity oracle).
"""
from __future__ import annotations

from enum import Enum

from hrv_core.detection.models import DetectorState


class PresentationKind(str, Enum):
    SETUP_REQUIRED = "setupRequired"
    LEARNING = "learning"
    STABLE = "stable"
    ATTENTION = "attention"
    UNAVAILABLE = "unavailable"


def map_presentation(detector_state: DetectorState, *,
                     has_completed_setup: bool,
                     has_reliable_recent_sample: bool) -> PresentationKind:
    # Precedence: setup gate, then data availability, then the detector state.
    if not has_completed_setup:
        return PresentationKind.SETUP_REQUIRED
    if not has_reliable_recent_sample:
        return PresentationKind.UNAVAILABLE
    if detector_state == DetectorState.LEARNING:
        return PresentationKind.LEARNING
    if detector_state in (DetectorState.NORMAL, DetectorState.WATCHING, DetectorState.COOLDOWN):
        return PresentationKind.STABLE  # Watching/Cooldown hidden as Stable
    if detector_state == DetectorState.ALERT:
        return PresentationKind.ATTENTION
    return PresentationKind.STABLE
