import Foundation

/// Result of the artifact rejection pass.
public struct CleanResult: Sendable, Equatable {
    public let nn: [Double]         // accepted Normal-to-Normal intervals (ms)
    public let rejected: Int        // number of raw beats dropped
    public let quality: SampleQuality
}

/// Artifact rejection pipeline (Deep Dive A.4). Port of hrv_core/signal/artifact.py.
///
/// Deliberately conservative: prefers returning `.low` quality over emitting a
/// noisy value. Pipeline: physiological range -> Malik 20% successive-delta
/// (vs last ACCEPTED beat) -> deletion -> window quality gate.
public struct ArtifactCorrector: Sendable {
    public var physiologicalMinMs: Double
    public var physiologicalMaxMs: Double
    public var maxSuccessiveDelta: Double   // Malik 20%
    public var minValidBeats: Int
    public var maxRejectRatio: Double

    public init(physiologicalMinMs: Double = 300.0,
                physiologicalMaxMs: Double = 2000.0,
                maxSuccessiveDelta: Double = 0.20,
                minValidBeats: Int = 30,
                maxRejectRatio: Double = 0.20) {
        self.physiologicalMinMs = physiologicalMinMs
        self.physiologicalMaxMs = physiologicalMaxMs
        self.maxSuccessiveDelta = maxSuccessiveDelta
        self.minValidBeats = minValidBeats
        self.maxRejectRatio = maxRejectRatio
    }

    public func clean(_ rr: [Double]) -> CleanResult {
        let total = rr.count

        // Step 1 -- physiological range filter
        let inRange = rr.filter { $0 >= physiologicalMinMs && $0 <= physiologicalMaxMs }

        // Step 2/3 -- Malik filter against the last ACCEPTED beat (deletion).
        var nn: [Double] = []
        var lastAccepted: Double? = nil
        for x in inRange {
            guard let last = lastAccepted else {
                nn.append(x); lastAccepted = x; continue
            }
            if abs(x - last) / last > maxSuccessiveDelta {
                continue  // ectopic -> delete, do NOT update lastAccepted
            }
            nn.append(x); lastAccepted = x
        }

        let rejected = total - nn.count

        // Step 4 -- minimum window quality gate
        let rejectRatio = total > 0 ? Double(rejected) / Double(total) : 1.0
        let quality: SampleQuality =
            (nn.count < minValidBeats || rejectRatio > maxRejectRatio) ? .low : .high

        return CleanResult(nn: nn, rejected: rejected, quality: quality)
    }
}
