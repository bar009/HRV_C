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
    private var engine: BaselineEngine
    private var detector: AnomalyDetector
    private let config: DetectorConfig
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
    /// Demo Mode (launch checklist #10): synthetic data stands in for HealthKit,
    /// so the setup gate must not require a real authorization. Persisted so the
    /// stored demo samples still render after a relaunch.
    private(set) var isDemoMode = UserDefaults.standard.bool(forKey: "demoMode")

    var learningDay: Int { engine.distinctDays() }
    var learningTotalDays: Int { 7 }
    var hasCompletedSetup: Bool { (isHealthAuthorized || isDemoMode) && hasAnySample }

    // ---- internal ----
    private var lastSampleAt: Date?
    private var hasAnySample = false
    private var lastAlertID: UUID?

    #if canImport(SwiftData)
    init(repository: HRVRepository, context: ModelContext, config: DetectorConfig = DetectorConfig()) {
        let engine = BaselineEngine()

        self.repository = repository
        self.context = context
        self.config = config
        self.engine = engine
        self.detector = AnomalyDetector(engine: engine, config: config)
        reloadStored()
        restorePipelineState()
        refresh()
    }
    #endif

    // MARK: lifecycle
    func start() async {
        // Demo Mode replaces the HealthKit feed entirely -- don't prompt for
        // authorization or observe samples on top of the synthetic data.
        guard !isDemoMode else { refresh(); return }
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

    /// Relevance feedback from the event detail screen. Updates the event's
    /// existing GuidedResponse if there is one, so re-answering never
    /// duplicates records (the success metric counts events, not taps).
    func saveRelevance(_ value: String, for eventID: UUID) {
        #if canImport(SwiftData)
        var d = FetchDescriptor<GuidedResponse>(predicate: #Predicate { $0.eventID == eventID })
        d.sortBy = [SortDescriptor(\.createdAt, order: .reverse)]
        if let existing = try? context.fetch(d).first {
            existing.relevance = value
        } else {
            context.insert(GuidedResponse(eventID: eventID, relevance: value))
        }
        try? context.save()
        #endif
    }

    /// The stored relevance answer for an event, if the user already gave one.
    func savedRelevance(for eventID: UUID) -> String? {
        #if canImport(SwiftData)
        var d = FetchDescriptor<GuidedResponse>(predicate: #Predicate { $0.eventID == eventID })
        d.sortBy = [SortDescriptor(\.createdAt, order: .reverse)]
        let stored = (try? context.fetch(d).first?.relevance) ?? ""
        return stored.isEmpty ? nil : stored
        #else
        return nil
        #endif
    }

    func markEventSeen(_ id: UUID) {
        if let e = events.first(where: { $0.id == id }) {
            e.seen = true
            #if canImport(SwiftData)
            try? context.save()
            #endif
            // Full refresh (not just reload): seeing the live event is one of the
            // Attention exits, so the presentation must be recomputed.
            refresh()
        }
    }

    /// Launch checklist #7 -- wipe every stored trace and reset to first-run.
    func deleteAllData() {
        #if canImport(SwiftData)
        try? context.delete(model: StoredSample.self)
        try? context.delete(model: StoredBaseline.self)
        try? context.delete(model: StoredAlert.self)
        try? context.delete(model: StoredAnchor.self)
        try? context.delete(model: EventRecord.self)
        try? context.delete(model: GuidedResponse.self)
        try? context.save()
        #endif
        // Fresh detection state: drop the in-memory baseline window + detector state.
        engine = BaselineEngine()
        detector = AnomalyDetector(engine: engine, config: config)
        baseline = nil
        recentSamples = []
        events = []
        hasAnySample = false
        lastSampleAt = nil
        lastAlertID = nil
        isDemoMode = false
        UserDefaults.standard.removeObject(forKey: "demoMode")
        UserDefaults.standard.removeObject(forKey: "didOnboard")
        refresh()
    }

    /// Launch checklist #10 -- Demo Mode: feed synthetic samples so a reviewer sees
    /// the app work without an Apple Watch. Runs through the real (tested) pipeline.
    func loadDemoData() {
        isDemoMode = true
        UserDefaults.standard.set(true, forKey: "demoMode")
        ingest(DemoData.generate())
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
        let from = Date().addingTimeInterval(-Double(engine.windowDays) * 86_400)
        recentSamples = repository.samples(from: from, to: Date())
    }

    /// Rehydrate the rolling baseline and alert cooldown without replaying
    /// notifications or writing duplicate samples after an app restart.
    private func restorePipelineState() {
        for sample in recentSamples
            where sample.quality == SampleQuality.high.rawValue && sample.context != "active" {
            engine.ingest(timestamp: sample.timestamp, rmssdValue: sample.rawValueMs)
        }

        let latestSample = recentSamples.max { $0.timestamp < $1.timestamp }
        hasAnySample = latestSample != nil
        lastSampleAt = latestSample?.timestamp

        let cooldownStart = Date().addingTimeInterval(-config.cooldown)
        let latestAlert = repository.recentAlerts(since: cooldownStart)
            .max { $0.firedAt < $1.firedAt }
        lastAlertID = latestAlert?.id
        detector = AnomalyDetector(engine: engine, config: config,
                                   lastAlertAt: latestAlert?.firedAt)
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
        // PRODUCT_STATE_MODEL: Attention persists after a confirmed alert until
        // the Guided Moment is completed/skipped or the data returns to range.
        // The detector's .alert state is transient (it moves to .cooldown on the
        // same tick), so the ongoing-attention window is derived here.
        if case .stable = presentation, let e = activeAttentionEvent {
            presentation = .attention(alertID: e.id, lastUpdated: lastSampleAt)
        }
    }

    /// The newest event, while it is still "live": not yet acted on by the user
    /// and fired within one cooldown period of the newest sample.
    private var activeAttentionEvent: EventRecord? {
        guard let e = events.first, !e.seen,
              let last = lastSampleAt,
              last.timeIntervalSince(e.firedAt) <= config.cooldown else { return nil }
        return e
    }

    private func isRecent(_ date: Date?) -> Bool {
        guard let date else { return false }
        return Date().timeIntervalSince(date) <= stalenessInterval
    }
}
