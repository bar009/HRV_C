import Foundation

// Beat-to-beat pipeline (Deep Dive A.6.1). Turns a beat series into RR
// intervals and computes the time-domain metrics via the existing
// ArtifactCorrector + HRVCalculator. HealthKit-free so HRVCore stays
// platform-independent and Windows-verifiable: the HealthKit layer extracts
// the raw beat times, this layer does the math.
//
// Q-A: passive HKHeartbeatSeriesSample availability is unproven (mostly around
// ECG/workouts) -- this pipeline is fully unit-testable, but real data needs a
// device field test before it's trusted.

/// The full set of time-domain HRV metrics computed from one beat window (ms),
/// or nil fields when the window was too noisy/short to trust.
public struct BeatSeriesMetrics: Sendable, Equatable {
    public let rmssd: Double?
    public let sdnn: Double?
    public let pnn50: Double?
    public let sdsd: Double?
    public let quality: SampleQuality
    public let beatCount: Int

    public init(rmssd: Double?, sdnn: Double?, pnn50: Double?, sdsd: Double?,
                quality: SampleQuality, beatCount: Int) {
        self.rmssd = rmssd; self.sdnn = sdnn; self.pnn50 = pnn50; self.sdsd = sdsd
        self.quality = quality; self.beatCount = beatCount
    }

    public var isUsable: Bool { quality == .high && rmssd != nil }
}

public enum RRExtractor {
    /// RR intervals (ms) from beat times. Input is `timeSinceSeriesStart`
    /// seconds (as `HKHeartbeatSeriesQuery` provides), sorted ascending.
    public static func rrIntervals(fromBeatTimes beatTimes: [TimeInterval]) -> [Double] {
        let t = beatTimes.sorted()
        guard t.count >= 2 else { return [] }
        return (0..<(t.count - 1)).map { (t[$0 + 1] - t[$0]) * 1000.0 }
    }

    /// Clean the RR series (Malik/physiological, A.4) then compute the metrics.
    /// A low-quality window yields nil metrics but still reports its quality.
    public static func metrics(fromRR rr: [Double],
                               corrector: ArtifactCorrector = ArtifactCorrector()) -> BeatSeriesMetrics {
        let cleaned = corrector.clean(rr)
        guard cleaned.quality == .high else {
            return BeatSeriesMetrics(rmssd: nil, sdnn: nil, pnn50: nil, sdsd: nil,
                                     quality: cleaned.quality, beatCount: cleaned.nn.count)
        }
        return BeatSeriesMetrics(
            rmssd: HRVCalculator.rmssd(cleaned.nn),
            sdnn: HRVCalculator.sdnn(cleaned.nn),
            pnn50: HRVCalculator.pnn50(cleaned.nn),
            sdsd: HRVCalculator.sdsd(cleaned.nn),
            quality: .high,
            beatCount: cleaned.nn.count)
    }

    /// Convenience: straight from beat times to metrics.
    public static func metrics(fromBeatTimes beatTimes: [TimeInterval],
                               corrector: ArtifactCorrector = ArtifactCorrector()) -> BeatSeriesMetrics {
        metrics(fromRR: rrIntervals(fromBeatTimes: beatTimes), corrector: corrector)
    }
}
