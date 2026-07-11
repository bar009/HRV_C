import Foundation

// Logical storage schema (Deep Dive C.6) and the repository protocol (C.7).
// Port of hrv_core/persistence/repository.py. Foundation-only: the anchor is a
// Data blob here so HRVCore stays HealthKit-free; the SwiftData implementation
// on the Mac serializes HKQueryAnchor <-> Data behind this same protocol.

public struct ProcessedHRVSample: Sendable, Equatable {
    public let id: UUID
    public let timestamp: Date
    public let lnRmssd: Double
    public let rawValueMs: Double
    public let metric: String     // sdnnApple / rmssdComputed
    public let quality: String    // high / low
    public let context: String    // rest / sleep / active
    public let source: String

    public init(id: UUID = UUID(), timestamp: Date, lnRmssd: Double, rawValueMs: Double,
                metric: String, quality: String, context: String, source: String) {
        self.id = id
        self.timestamp = timestamp
        self.lnRmssd = lnRmssd
        self.rawValueMs = rawValueMs
        self.metric = metric
        self.quality = quality
        self.context = context
        self.source = source
    }
}

public struct BaselineState: Sendable, Equatable {
    public let id: UUID
    public let computedAt: Date
    public let median: Double
    public let mad: Double
    public let sampleCount: Int
    public let windowStart: Date

    public init(id: UUID = UUID(), computedAt: Date, median: Double, mad: Double,
                sampleCount: Int, windowStart: Date) {
        self.id = id
        self.computedAt = computedAt
        self.median = median
        self.mad = mad
        self.sampleCount = sampleCount
        self.windowStart = windowStart
    }
}

public struct AlertRecord: Sendable, Equatable {
    public let id: UUID
    public let firedAt: Date
    public let robustZ: Double
    public let rawValueMs: Double
    public let reason: String

    public init(id: UUID = UUID(), firedAt: Date, robustZ: Double,
                rawValueMs: Double, reason: String) {
        self.id = id
        self.firedAt = firedAt
        self.robustZ = robustZ
        self.rawValueMs = rawValueMs
        self.reason = reason
    }
}

/// Everything above the storage layer knows only this protocol (C.7), so the
/// engine (in-memory here, SwiftData on the Mac) can be swapped without touching
/// the detection logic.
public protocol HRVRepository: AnyObject {
    func save(_ sample: ProcessedHRVSample)
    func samples(from start: Date, to end: Date) -> [ProcessedHRVSample]

    func latestBaseline() -> BaselineState?
    func upsertBaseline(_ baseline: BaselineState)

    func record(_ alert: AlertRecord)
    func recentAlerts(since: Date) -> [AlertRecord]

    func anchor(for dataType: String) -> Data?
    func saveAnchor(_ anchor: Data, for dataType: String)
}
