import Foundation

// Unified sample models for the Signal layer (Deep Dive A.5).
// Port of hrv_core/signal/models.py.

public enum SampleQuality: String, Sendable {
    case high
    case low
}

public enum HRVMetric: String, Sendable {
    case sdnnApple        // Apple's built-in passive SDNN (primary source)
    case rmssdComputed    // computed by us from an RR/beat series
    case sdnnComputed
}

public enum HRVSource: String, Sendable {
    case healthKitDirect  // value read straight from HealthKit
    case beatSeries       // derived from HKHeartbeatSeriesSample
}

/// A single normalized HRV reading (Deep Dive A.5).
public struct HRVSample: Sendable, Equatable {
    public let timestamp: Date
    public let valueMs: Double
    public let metric: HRVMetric
    public let quality: SampleQuality
    public let source: HRVSource
    public let sampleCount: Int?   // how many NN intervals fed the value (computed path only)

    public init(timestamp: Date, valueMs: Double, metric: HRVMetric,
                quality: SampleQuality, source: HRVSource, sampleCount: Int? = nil) {
        self.timestamp = timestamp
        self.valueMs = valueMs
        self.metric = metric
        self.quality = quality
        self.source = source
        self.sampleCount = sampleCount
    }
}
