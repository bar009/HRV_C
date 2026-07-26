import Foundation

// What a given sensor can actually produce. Devices differ: a chest ECG strap
// streams true beat-to-beat RR; an optical armband streams noisier RR; some
// budget straps expose BPM only (no HRV at all); Apple Watch gives sparse
// resting SDNN plus sleep/workout context no strap has. Features must resolve
// against this instead of assuming — see HealthIndicator.

/// How trustworthy the inter-beat timing is. Ordered: more is better.
public enum RRFidelity: Int, Comparable, Sendable {
    /// BPM only — no inter-beat timing, so no HRV math is possible.
    case none = 0
    /// Reconstructed from periodic heart-rate samples (e.g. an Apple Watch
    /// workout session). Usable as a rough signal, but it is NOT beat-to-beat:
    /// the values are smoothed averages, so HRV derived from it is approximate.
    case derivedFromHR = 1
    /// True RR intervals straight from the sensor (chest strap, ECG).
    case beatToBeat = 2

    public static func < (a: RRFidelity, b: RRFidelity) -> Bool { a.rawValue < b.rawValue }
}

public struct SensorCapabilities: Sendable, Equatable {
    public var rrFidelity: RRFidelity
    /// All-day coverage vs. sparse / at-rest-only snapshots.
    public var continuousCoverage: Bool
    /// Apple's own periodically-computed SDNN (HealthKit only).
    public var passiveSDNN: Bool
    public var restingHeartRate: Bool
    public var sleepContext: Bool
    public var workoutContext: Bool
    public var batteryReadout: Bool
    /// Live movement classification, used to exclude windows that were not
    /// taken at rest. Without it, continuous detection cannot tell a stress
    /// drop from "you stood up and walked".
    public var motionContext: Bool

    public init(rrFidelity: RRFidelity = .none,
                continuousCoverage: Bool = false,
                passiveSDNN: Bool = false,
                restingHeartRate: Bool = false,
                sleepContext: Bool = false,
                workoutContext: Bool = false,
                batteryReadout: Bool = false,
                motionContext: Bool = false) {
        self.rrFidelity = rrFidelity
        self.continuousCoverage = continuousCoverage
        self.passiveSDNN = passiveSDNN
        self.restingHeartRate = restingHeartRate
        self.sleepContext = sleepContext
        self.workoutContext = workoutContext
        self.batteryReadout = batteryReadout
        self.motionContext = motionContext
    }
}

public extension SensorCapabilities {
    /// Nothing connected.
    static let none = SensorCapabilities()

    /// Apple Watch, passive HealthKit only: sparse resting SDNN + context.
    static let appleWatchPassive = SensorCapabilities(
        rrFidelity: .none, continuousCoverage: false, passiveSDNN: true,
        restingHeartRate: true, sleepContext: true, workoutContext: true)

    /// Apple Watch during an active workout session — a live HR stream, so
    /// inter-beat timing is *derived*, not measured.
    static let appleWatchWorkout = SensorCapabilities(
        rrFidelity: .derivedFromHR, continuousCoverage: false, passiveSDNN: true,
        restingHeartRate: true, sleepContext: true, workoutContext: true)

    /// A BLE chest strap exposing the RR-Interval field (Polar H10, Garmin
    /// HRM, Wahoo TICKR, …) — the reference case.
    static let bleChestStrap = SensorCapabilities(
        rrFidelity: .beatToBeat, continuousCoverage: true, batteryReadout: true)

    /// An optical armband exposing RR (e.g. Polar Verity Sense): same math,
    /// more motion artefacts. The artefact corrector absorbs the difference,
    /// so capabilities match the chest strap.
    static let bleOpticalArmband = SensorCapabilities(
        rrFidelity: .beatToBeat, continuousCoverage: true, batteryReadout: true)

    /// A compliant strap that never sends the optional RR field — heart rate
    /// only, so every HRV feature stays off.
    static let bleBpmOnly = SensorCapabilities(
        rrFidelity: .none, continuousCoverage: true, batteryReadout: true)

    /// Synthetic source used in the Simulator and tests.
    static let simulated = SensorCapabilities(
        rrFidelity: .beatToBeat, continuousCoverage: true, batteryReadout: true)

    /// Demo Mode stands in for everything so reviewers see a full app.
    static let demo = SensorCapabilities(
        rrFidelity: .beatToBeat, continuousCoverage: true, passiveSDNN: true,
        restingHeartRate: true, sleepContext: true, workoutContext: true)
}
