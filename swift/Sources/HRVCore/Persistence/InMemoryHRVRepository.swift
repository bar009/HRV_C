import Foundation

/// In-memory HRVRepository used for tests and for validating the end-to-end data
/// flow. NOT the real storage engine -- that is `SwiftDataRepository` on the Mac.
public final class InMemoryHRVRepository: HRVRepository {
    private var samplesStore: [ProcessedHRVSample] = []
    private var baseline: BaselineState?
    private var alerts: [AlertRecord] = []
    private var anchors: [String: Data] = [:]

    public init() {}

    public func save(_ sample: ProcessedHRVSample) {
        samplesStore.append(sample)
    }

    public func samples(from start: Date, to end: Date) -> [ProcessedHRVSample] {
        samplesStore.filter { $0.timestamp >= start && $0.timestamp <= end }
    }

    public func latestBaseline() -> BaselineState? { baseline }

    public func upsertBaseline(_ baseline: BaselineState) { self.baseline = baseline }

    public func record(_ alert: AlertRecord) { alerts.append(alert) }

    public func recentAlerts(since: Date) -> [AlertRecord] {
        alerts.filter { $0.firedAt >= since }
    }

    public func anchor(for dataType: String) -> Data? { anchors[dataType] }

    public func saveAnchor(_ anchor: Data, for dataType: String) {
        anchors[dataType] = anchor
    }
}
