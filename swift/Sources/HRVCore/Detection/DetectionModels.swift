import Foundation

// Detection layer models (Deep Dive B.7 / B.8). Port of hrv_core/detection/models.py.

/// 1.4826 makes the MAD a consistent estimator of sigma for a normal distribution.
public let madToSigma: Double = 1.4826

public enum DetectorState: String, Sendable {
    case learning   // no reliable baseline yet -- collect only, never alert
    case normal
    case watching   // an anomaly was seen, waiting to see if it persists
    case alert      // transient state on the tick an alert fires
    case cooldown   // suppress further alerts for the cooldown period
}

/// Personal baseline on the ln(RMSSD) scale (Deep Dive B.4).
public struct Baseline: Sendable, Equatable {
    public let median: Double
    public let mad: Double
    public let sampleCount: Int
    public let windowStart: Date
    public var k: Double

    public init(median: Double, mad: Double, sampleCount: Int,
                windowStart: Date, k: Double = 2.0) {
        self.median = median
        self.mad = mad
        self.sampleCount = sampleCount
        self.windowStart = windowStart
        self.k = k
    }

    public var scaledMad: Double { madToSigma * mad }
    public var lowerBound: Double { median - k * scaledMad }
    public var upperBound: Double { median + k * scaledMad }
}

/// Calibration parameters -- the heart of the product (Deep Dive B.7).
/// Starting values, not final; tuned via the simulation harness (Q-B).
public struct DetectorConfig: Sendable {
    public var k: Double                 // sensitivity in scaled-MAD units (1.5-2.0)
    public var persistenceWindow: Int    // consecutive anomalies required before Alert
    public var cooldown: TimeInterval    // minimum gap between alerts (seconds)
    public var alertOnDropOnly: Bool     // v1: only alert on an HRV decrease

    public init(k: Double = 2.0, persistenceWindow: Int = 3,
                cooldown: TimeInterval = 8 * 3600, alertOnDropOnly: Bool = true) {
        self.k = k
        self.persistenceWindow = persistenceWindow
        self.cooldown = cooldown
        self.alertOnDropOnly = alertOnDropOnly
    }
}

/// Contextual tags used for stratification (Deep Dive B.5).
public struct SampleContext: Sendable {
    public var isRestful: Bool   // false when taken near exertion -> excluded entirely
    public var isSleep: Bool

    public init(isRestful: Bool = true, isSleep: Bool = false) {
        self.isRestful = isRestful
        self.isSleep = isSleep
    }
}

public struct AlertEvent: Sendable, Equatable {
    public let firedAt: Date
    public let robustZ: Double
    public let rawValueMs: Double
    public let reason: String

    public init(firedAt: Date, robustZ: Double, rawValueMs: Double, reason: String) {
        self.firedAt = firedAt
        self.robustZ = robustZ
        self.rawValueMs = rawValueMs
        self.reason = reason
    }
}
