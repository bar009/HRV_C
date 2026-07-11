// Track C -- SwiftData implementation of HRVRepository (Deep Dive C.6/C.7).
// Mac-only. Same protocol as InMemoryHRVRepository, so nothing above it changes.
#if canImport(SwiftData)
import Foundation
import SwiftData
import HRVCore

@Model final class StoredSample {
    @Attribute(.unique) var id: UUID
    var timestamp: Date
    var lnRmssd: Double
    var rawValueMs: Double
    var metric: String
    var quality: String
    var context: String
    var source: String

    init(from s: ProcessedHRVSample) {
        id = s.id; timestamp = s.timestamp; lnRmssd = s.lnRmssd; rawValueMs = s.rawValueMs
        metric = s.metric; quality = s.quality; context = s.context; source = s.source
    }
    var value: ProcessedHRVSample {
        ProcessedHRVSample(id: id, timestamp: timestamp, lnRmssd: lnRmssd, rawValueMs: rawValueMs,
                           metric: metric, quality: quality, context: context, source: source)
    }
}

@Model final class StoredBaseline {
    @Attribute(.unique) var id: UUID
    var computedAt: Date
    var median: Double
    var mad: Double
    var sampleCount: Int
    var windowStart: Date
    init(from b: BaselineState) {
        id = b.id; computedAt = b.computedAt; median = b.median; mad = b.mad
        sampleCount = b.sampleCount; windowStart = b.windowStart
    }
    var value: BaselineState {
        BaselineState(id: id, computedAt: computedAt, median: median, mad: mad,
                      sampleCount: sampleCount, windowStart: windowStart)
    }
}

@Model final class StoredAlert {
    @Attribute(.unique) var id: UUID
    var firedAt: Date
    var robustZ: Double
    var rawValueMs: Double
    var reason: String
    init(from a: AlertRecord) {
        id = a.id; firedAt = a.firedAt; robustZ = a.robustZ; rawValueMs = a.rawValueMs; reason = a.reason
    }
    var value: AlertRecord {
        AlertRecord(id: id, firedAt: firedAt, robustZ: robustZ, rawValueMs: rawValueMs, reason: reason)
    }
}

@Model final class StoredAnchor {
    @Attribute(.unique) var dataType: String
    var anchorData: Data
    init(dataType: String, anchorData: Data) { self.dataType = dataType; self.anchorData = anchorData }
}

/// HealthKit stays the raw store (C.1); we persist only processed samples,
/// baseline, alerts, and anchors.
final class SwiftDataRepository: HRVRepository {
    private let context: ModelContext
    init(context: ModelContext) { self.context = context }

    func save(_ sample: ProcessedHRVSample) {
        context.insert(StoredSample(from: sample))
        try? context.save()
    }

    func samples(from start: Date, to end: Date) -> [ProcessedHRVSample] {
        let d = FetchDescriptor<StoredSample>(
            predicate: #Predicate { $0.timestamp >= start && $0.timestamp <= end },
            sortBy: [SortDescriptor(\.timestamp)]
        )
        return ((try? context.fetch(d)) ?? []).map(\.value)
    }

    func latestBaseline() -> BaselineState? {
        var d = FetchDescriptor<StoredBaseline>(sortBy: [SortDescriptor(\.computedAt, order: .reverse)])
        d.fetchLimit = 1
        return (try? context.fetch(d))?.first?.value
    }

    func upsertBaseline(_ baseline: BaselineState) {
        // Single logical row: clear and re-insert.
        if let existing = try? context.fetch(FetchDescriptor<StoredBaseline>()) {
            existing.forEach(context.delete)
        }
        context.insert(StoredBaseline(from: baseline))
        try? context.save()
    }

    func record(_ alert: AlertRecord) {
        context.insert(StoredAlert(from: alert))
        try? context.save()
    }

    func recentAlerts(since: Date) -> [AlertRecord] {
        let d = FetchDescriptor<StoredAlert>(
            predicate: #Predicate { $0.firedAt >= since },
            sortBy: [SortDescriptor(\.firedAt, order: .reverse)]
        )
        return ((try? context.fetch(d)) ?? []).map(\.value)
    }

    func anchor(for dataType: String) -> Data? {
        let d = FetchDescriptor<StoredAnchor>(predicate: #Predicate { $0.dataType == dataType })
        return (try? context.fetch(d))?.first?.anchorData
    }

    func saveAnchor(_ anchor: Data, for dataType: String) {
        if let existing = try? context.fetch(
            FetchDescriptor<StoredAnchor>(predicate: #Predicate { $0.dataType == dataType })
        ) {
            existing.forEach(context.delete)
        }
        context.insert(StoredAnchor(dataType: dataType, anchorData: anchor))
        try? context.save()
    }
}
#endif
