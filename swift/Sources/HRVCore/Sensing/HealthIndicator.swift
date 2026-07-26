import Foundation

// The registry of every indicator/method the product surfaces, and the rules
// that decide whether the currently-connected sensor can actually produce it.
//
// This is the single place new features register: rather than hardcoding a
// `nil` check per screen, a feature asks `IndicatorResolver` and gets back one
// of available / approximate / unavailable — so adding a device only means
// declaring its SensorCapabilities.

public enum HealthIndicator: String, CaseIterable, Sendable {
    case liveBPM
    case sdnn                 // Apple's passive SDNN
    case rmssd
    case pnn50
    case sdsd
    case coherence
    case restingHeartRate
    case sleepContext
    case workoutContext
    case sustainedDetection   // the slow "silent" change
    case liveTriggers         // catching a change within minutes
}

/// Why an indicator is degraded or missing. Structured (not prose) so the app
/// layer owns the user-facing wording and localization.
public enum IndicatorLimitation: String, Sendable, Equatable {
    /// The sensor reports heart rate only — no inter-beat intervals.
    case needsBeatToBeat
    /// Timing is reconstructed from heart-rate samples, not measured per beat.
    case rrDerivedFromHeartRate
    /// Needs all-day coverage; this sensor only samples occasionally.
    case needsContinuousCoverage
    /// Comes from Apple Health, which isn't available/authorized here.
    case needsHealthKit
    /// No sensor is connected at all.
    case noSensor
}

public enum IndicatorAvailability: Sendable, Equatable {
    case available
    /// Works, but degraded — the UI **must** label it rather than present it as exact.
    case approximate(IndicatorLimitation)
    case unavailable(IndicatorLimitation)

    public var isAvailable: Bool { self == .available }
    public var isUsable: Bool {
        switch self {
        case .available, .approximate: return true
        case .unavailable:             return false
        }
    }
    public var limitation: IndicatorLimitation? {
        switch self {
        case .available:                   return nil
        case .approximate(let l):          return l
        case .unavailable(let l):          return l
        }
    }
}

public enum IndicatorResolver {
    public static func availability(of indicator: HealthIndicator,
                                    given caps: SensorCapabilities) -> IndicatorAvailability {
        switch indicator {
        case .liveBPM:
            // Any live heart-rate stream can show BPM; a purely passive
            // HealthKit feed cannot (it delivers summaries, not a stream).
            return caps.rrFidelity > .none || caps.continuousCoverage
                ? .available : .unavailable(.needsContinuousCoverage)

        case .sdnn:
            return caps.passiveSDNN ? .available : .unavailable(.needsHealthKit)

        case .rmssd, .pnn50, .sdsd:
            return timeDomainAvailability(caps)

        case .coherence:
            // Frequency-domain math over the tachogram: genuinely needs
            // beat-to-beat timing; HR-derived timing gives only a rough signal.
            return timeDomainAvailability(caps)

        case .restingHeartRate:
            return caps.restingHeartRate ? .available : .unavailable(.needsHealthKit)

        case .sleepContext:
            return caps.sleepContext ? .available : .unavailable(.needsHealthKit)

        case .workoutContext:
            return caps.workoutContext ? .available : .unavailable(.needsHealthKit)

        case .sustainedDetection:
            // Either Apple's passive SDNN over days, or continuous beat-to-beat
            // windows of our own.
            if caps.passiveSDNN { return .available }
            if caps.rrFidelity == .beatToBeat && caps.continuousCoverage { return .available }
            if caps.rrFidelity == .derivedFromHR { return .approximate(.rrDerivedFromHeartRate) }
            return .unavailable(caps.rrFidelity == .none ? .needsBeatToBeat : .needsContinuousCoverage)

        case .liveTriggers:
            // The memo's "catch it live": impossible without continuous,
            // true beat-to-beat data.
            switch caps.rrFidelity {
            case .none:          return .unavailable(.needsBeatToBeat)
            case .derivedFromHR: return .unavailable(.needsBeatToBeat)
            case .beatToBeat:    return caps.continuousCoverage
                                    ? .available : .unavailable(.needsContinuousCoverage)
            }
        }
    }

    /// Shared rule for everything computed from the NN series.
    private static func timeDomainAvailability(_ caps: SensorCapabilities) -> IndicatorAvailability {
        switch caps.rrFidelity {
        case .none:          return .unavailable(.needsBeatToBeat)
        case .derivedFromHR: return .approximate(.rrDerivedFromHeartRate)
        case .beatToBeat:    return .available
        }
    }

    /// Every indicator resolved at once — for the "what this mode gives you" list.
    public static func all(given caps: SensorCapabilities) -> [(HealthIndicator, IndicatorAvailability)] {
        HealthIndicator.allCases.map { ($0, availability(of: $0, given: caps)) }
    }
}

public extension SensorCapabilities {
    /// Combine two sources — e.g. a chest strap for live RR *plus* HealthKit
    /// context when the user also wears a watch and granted access. Takes the
    /// better of each field.
    func merging(_ other: SensorCapabilities) -> SensorCapabilities {
        SensorCapabilities(
            rrFidelity: max(rrFidelity, other.rrFidelity),
            continuousCoverage: continuousCoverage || other.continuousCoverage,
            passiveSDNN: passiveSDNN || other.passiveSDNN,
            restingHeartRate: restingHeartRate || other.restingHeartRate,
            sleepContext: sleepContext || other.sleepContext,
            workoutContext: workoutContext || other.workoutContext,
            batteryReadout: batteryReadout || other.batteryReadout)
    }
}
