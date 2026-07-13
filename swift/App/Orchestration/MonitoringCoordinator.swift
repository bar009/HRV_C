// P1 — end-to-end wiring + the single UI source (see docs/UI_WIRING.md). Mac-only.
// HealthKit -> Signal/Detection (HRVCore) -> PresentationMapper -> `presentation`,
// plus persistence (P2), events (P6) and permissions (P4). All on-device.
import Foundation
import Observation
import HRVCore
#if canImport(SwiftData)
import SwiftData
#endif

@Observable
final class MonitoringCoordinator {
    private let repository: HRVRepository
    #if canImport(SwiftData)
    private let context: ModelContext
    #endif
    private let engine: BaselineEngine
    private let detector: AnomalyDetector
    private let alerts = AlertService()
    #if canImport(HealthKit)
    private let health = HealthKitService()
    #endif

    /// Passive SDNN arrives a few times/day; older than this -> Unavailable.
    private let stalenessInterval: TimeInterval = 6 * 3600

    // ---- UI-facing surface (docs/UI_WIRING.md) ----
    private(set) var presentation: HRVPresentationState = .setupRequired
    private(set) var baseline: Baseline?
    private(set) var recentSamples: [ProcessedHRVSample] = []
    private(set) var events: [EventRecord] = []
    private(set) var isHealthAuthorized = false

    var learningDay: Int { engine.distinctDays() }
    var learningTotalDays: Int { 7 }
    var hasCompletedSetup: Bool { isHealthAuthorized && hasAnySample }

    // ---- internal ----
    private var lastSampleAt: Date?
    private var hasAnySample = false
    private var lastAlertID: UUID?

    #if canImport(SwiftData)
    init(repository: HRVRepository, context: ModelContext, config: DetectorConfig = DetectorConfig()) {
        self.repository = repository
        self.context = context
        self.engine = BaselineEngine()
        self.detector = AnomalyDetector(engine: engine, config: config)
        reloadStored()
        refresh()
    }
    #endif

    // MARK: lifecycle
    func start() async {
        #if canImport(HealthKit)
        guard HealthKitService.isAvailable else { return }
        await requestHealthAccess()
        health.startObservingSDNN(
            anchorProvider: { [weak self] key in self?.repository.anchor(for: key) },
            anchorSink: { [weak self] data, key in self?.repository.saveAnchor(data, for: key) },
            onSamples: { [weak self] samples in self?.ingest(samples) }
        )
        #endif
        refresh()
    }

    /// Core pipeline for a batch of new samples (also the unit-testable seam).
    func ingest(_ samples: [HRVSample]) {
        for s in samples where s.quality == .high {
            let ctx = SampleContext(isRestful: true)  // TODO(Track H): real stratification
            if let event = detector.evaluate(timestamp: s.timestamp, rmssdValue: s.valueMs, context: ctx) {
                recordEvent(event)
                alerts.fireHRVDrop(event)   // P3
            }
            persist(s)
            hasAnySample = true
            lastSampleAt = s.timestamp
        }
        refresh()
    }

    // MARK: actions (bound from screens per UI_WIRING.md)
    func requestHealthAccess() async {
        #if canImport(HealthKit)
        do { try await health.requestAuthorization(); isHealthAuthorized = true }
        catch { isHealthAuthorized = false }
        #endif
        refresh()
    }

    func requestNotifications() async { await alerts.requestAuthorization() }

    func saveGuidedResponse(_ response: GuidedResponse) {
        #if canImport(SwiftData)
        context.insert(response)
        try? context.save()
        #endif
    }

    func markEventSeen(_ id: UUID) {
        if let e = events.first(where: { $0.id == id }) {
            e.seen = true
            #if canImport(SwiftData)
            try? context.save()
            #endif
            reloadStored()
        }
    }

    // MARK: internals
    private func recordEvent(_ event: AlertEvent) {
        let rec = EventRecord(firedAt: event.firedAt, robustZ: event.robustZ,
                              rawValueMs: event.rawValueMs, reason: event.reason)
        lastAlertID = rec.id
        #if canImport(SwiftData)
        context.insert(rec)
        try? context.save()
        #endif
        repository.record(AlertRecord(id: rec.id, firedAt: event.firedAt, robustZ: event.robustZ,
                                      rawValueMs: event.rawValueMs, reason: event.reason))
    }

    private func persist(_ s: HRVSample) {
        let processed = ProcessedHRVSample(
            timestamp: s.timestamp, lnRmssd: log(s.valueMs), rawValueMs: s.valueMs,
            metric: s.metric.rawValue, quality: s.quality.rawValue,
            context: "rest", source: s.source.rawValue)
        repository.save(processed)
    }

    private func reloadStored() {
        #if canImport(SwiftData)
        let d = FetchDescriptor<EventRecord>(sortBy: [SortDescriptor(\.firedAt, order: .reverse)])
        events = (try? context.fetch(d)) ?? []
        #endif
        let from = Date().addingTimeInterval(-30 * 86_400)
        recentSamples = repository.samples(from: from, to: Date())
    }

    /// Recompute the user-visible presentation state from the current pipeline state.
    private func refresh() {
        baseline = engine.currentBaseline()
        let input = PresentationInput(
            detectorState: detector.state,
            hasCompletedSetup: hasCompletedSetup,
            hasReliableRecentSample: isRecent(lastSampleAt),
            learningDay: learningDay,
            learningTotalDays: learningTotalDays,
            lastUpdated: lastSampleAt,
            lastValidSample: lastSampleAt,
            alertID: lastAlertID
        )
        presentation = PresentationMapper.map(input)
        reloadStored()
    }

    private func isRecent(_ date: Date?) -> Bool {
        guard let date else { return false }
        return Date().timeIntervalSince(date) <= stalenessInterval
    }
}
