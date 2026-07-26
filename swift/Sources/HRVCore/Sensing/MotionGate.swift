import Foundation

// Motion gating for the continuous (strap) path.
//
// The detector's whole premise is separating genuine arousal from ordinary
// life. In Apple Watch mode that works because HealthKit supplies workouts and
// sleep, and ContextClassifier excludes non-restful samples. A Bluetooth strap
// has NO such context -- so without this, an HRV drop caused by standing up or
// walking to the kitchen is indistinguishable from a stress event, and live
// triggers would fire on movement.
//
// Pure and value-typed: the gating rule is unit-tested without any sensor.

public enum MotionState: String, Sendable, Equatable {
    /// No reading available (permission denied, or the source is off). Treated
    /// as restful on purpose -- missing motion data must not silently discard
    /// every sample, which would disable detection entirely.
    case unknown
    case stationary
    case walking
    case running
    case cycling
    case automotive

    /// Whether this state, on its own, counts as at rest.
    public var isAtRest: Bool {
        switch self {
        case .stationary, .unknown: return true
        case .walking, .running, .cycling, .automotive: return false
        }
    }
}

/// Tracks recent movement and answers "was this moment restful?".
///
/// Movement doesn't only corrupt the window it happens in: heart-rate
/// variability stays suppressed for a while afterwards, so a recovery buffer
/// follows every active period -- the same idea as
/// `ContextClassifier.postWorkoutRecovery` on the HealthKit path.
public struct MotionGate: Sendable {
    /// How long after movement stops a sample is still considered non-restful.
    public var recoverySeconds: Double
    /// The window each sample covers; movement anywhere inside it disqualifies
    /// the sample, since the statistic is computed over the whole span.
    public var windowSeconds: Double

    private var lastActiveAt: Date?
    private(set) public var current: MotionState = .unknown

    public init(recoverySeconds: Double = 120, windowSeconds: Double = 120) {
        self.recoverySeconds = recoverySeconds
        self.windowSeconds = windowSeconds
    }

    public mutating func record(_ state: MotionState, at time: Date) {
        current = state
        if !state.isAtRest { lastActiveAt = time }
    }

    /// True when neither the window ending at `time` nor the recovery buffer
    /// before it contained movement.
    public func isRestful(at time: Date) -> Bool {
        guard let lastActiveAt else { return true }
        return time.timeIntervalSince(lastActiveAt) > (recoverySeconds + windowSeconds)
    }

    /// Convenience for feeding the detector.
    public func sampleContext(at time: Date) -> SampleContext {
        SampleContext(isRestful: isRestful(at: time), isSleep: false)
    }

    public mutating func reset() {
        lastActiveAt = nil
        current = .unknown
    }
}
