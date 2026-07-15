import Foundation

/// (x - median) / (1.4826 * MAD). Returns 0 when MAD is 0 (degenerate baseline).
public func robustZ(_ x: Double, baseline: Baseline) -> Double {
    let denom = baseline.scaledMad
    if denom == 0 { return 0.0 }
    return (x - baseline.median) / denom
}

/// Anomaly detector: robust-z + alert state machine (Deep Dive B.3 / B.6).
/// Port of hrv_core/detection/detector.py.
///
/// Every false-positive protection is built into the state machine: Learning
/// gate, persistence window, cooldown, and context gating.
public final class AnomalyDetector {
    public let engine: BaselineEngine
    public let config: DetectorConfig
    public private(set) var state: DetectorState = .learning

    private var consecutiveAnomalies = 0
    private var lastAlertAt: Date?

    public init(engine: BaselineEngine, config: DetectorConfig = DetectorConfig(),
                lastAlertAt: Date? = nil) {
        self.engine = engine
        self.config = config
        self.lastAlertAt = lastAlertAt
        if lastAlertAt != nil {
            state = .cooldown
        } else if engine.hasMinBaseline() {
            state = .normal
        }
    }

    private func isAnomaly(_ z: Double) -> Bool {
        config.alertOnDropOnly ? (z < -config.k) : (abs(z) > config.k)
    }

    /// Feed one restful RMSSD sample; returns an AlertEvent iff one should fire.
    @discardableResult
    public func evaluate(timestamp: Date, rmssdValue: Double,
                         context: SampleContext = SampleContext()) -> AlertEvent? {
        // Context gating (B.5): near exertion -> neither baseline nor alert.
        guard context.isRestful else { return nil }

        engine.ingest(timestamp: timestamp, rmssdValue: rmssdValue)
        guard let baseline = engine.currentBaseline(asOf: timestamp) else {
            state = .learning
            return nil
        }
        if state == .learning { state = .normal }

        let z = robustZ(log(rmssdValue), baseline: baseline)
        let anomalous = isAnomaly(z)

        // Cooldown: suppress everything until the period elapses.
        if state == .cooldown {
            if let last = lastAlertAt, timestamp.timeIntervalSince(last) >= config.cooldown {
                state = .normal  // fall through to normal handling
            } else {
                if !anomalous { consecutiveAnomalies = 0 }
                return nil
            }
        }

        if anomalous {
            consecutiveAnomalies += 1
            if state == .normal { state = .watching }
            if consecutiveAnomalies >= config.persistenceWindow {
                state = .cooldown
                lastAlertAt = timestamp
                consecutiveAnomalies = 0
                let reason = "robust_z=\(String(format: "%.2f", z)) < -k=\(config.k)"
                return AlertEvent(firedAt: timestamp, robustZ: z,
                                  rawValueMs: rmssdValue, reason: reason)
            }
            return nil
        }

        // Returned to range.
        consecutiveAnomalies = 0
        if state == .watching { state = .normal }
        return nil
    }
}
