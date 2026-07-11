import Foundation

/// Rolling baseline on ln(RMSSD) using median + MAD (Deep Dive B.2-B.4).
/// Port of hrv_core/detection/baseline.py.
///
/// RMSSD is ~log-normal, so every statistic is computed on x = ln(value).
/// Days are bucketed by UTC day index for deterministic "distinct days" counting.
public final class BaselineEngine {
    public let windowDays: Int
    public let minBaselineDays: Int
    public let k: Double

    private struct WindowSample {
        let timestamp: Date
        let lnValue: Double
    }
    private var samples: [WindowSample] = []

    public init(windowDays: Int = 60, minBaselineDays: Int = 7, k: Double = 2.0) {
        self.windowDays = windowDays
        self.minBaselineDays = minBaselineDays
        self.k = k
    }

    /// Add one high-quality, restful RMSSD sample to the rolling window.
    public func ingest(timestamp: Date, rmssdValue: Double) {
        guard rmssdValue > 0 else { return }  // ln undefined -> "no measurement"
        samples.append(WindowSample(timestamp: timestamp, lnValue: log(rmssdValue)))
        evictOld(asOf: timestamp)
    }

    private func evictOld(asOf: Date) {
        let cutoff = asOf.addingTimeInterval(-Double(windowDays) * 86_400)
        samples.removeAll { $0.timestamp < cutoff }
    }

    private func dayIndex(_ date: Date) -> Int {
        Int((date.timeIntervalSince1970 / 86_400).rounded(.down))
    }

    public func distinctDays() -> Int {
        Set(samples.map { dayIndex($0.timestamp) }).count
    }

    public func hasMinBaseline() -> Bool {
        distinctDays() >= minBaselineDays
    }

    public var sampleCount: Int { samples.count }

    public func currentBaseline(asOf: Date? = nil) -> Baseline? {
        if let asOf { evictOld(asOf: asOf) }
        guard hasMinBaseline() else { return nil }
        let xs = samples.map { $0.lnValue }
        let med = Statistics.median(xs)
        let windowStart = samples.map { $0.timestamp }.min() ?? Date()
        return Baseline(median: med, mad: Statistics.mad(xs, center: med),
                        sampleCount: xs.count, windowStart: windowStart, k: k)
    }
}
