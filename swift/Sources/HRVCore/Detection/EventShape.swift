import Foundation

// The shape of a detected drop (strategy memo — distinguish an acute "visible"
// change from a low-grade sustained one). Kept factual: this describes the
// SIGNAL (how deep the drop went below the personal range), never a cause or an
// emotional state. Pure + value-typed, so it's unit-testable and platform-free.

public enum EventShape: String, Sendable, Equatable {
    /// A sharp, pronounced drop — well below the personal range.
    case acute
    /// A shallow drop that only just crosses the personal threshold, the kind
    /// that persists quietly and is easy to miss.
    case sustained
}

public enum EventShapeClassifier {
    /// Depth (in scaled-MAD units below the personal median) at/above which a
    /// drop reads as acute rather than a low-grade sustained dip. The detector
    /// only fires past `k` (≈2), so this sits above that. Starting value —
    /// real tuning is Q-B (the calibration study).
    public static let acuteDepth: Double = 3.0

    /// `robustZ` is negative on a drop; classify by its magnitude (depth).
    public static func classify(robustZ: Double, acuteDepth: Double = acuteDepth) -> EventShape {
        abs(robustZ) >= acuteDepth ? .acute : .sustained
    }
}
