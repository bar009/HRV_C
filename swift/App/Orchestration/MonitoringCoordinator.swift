// P1 — end-to-end wiring + the single UI source (see docs/UI_WIRING.md). Mac-only.
// HealthKit -> Signal/Detection (HRVCore) -> PresentationMapper -> `presentation`,
// plus persistence (P2), events (P6) and permissions (P4). All on-device.
import Foundation
import Observation
import HRVCore
#if canImport(SwiftData)
import SwiftData
#endif
#if canImport(WatchConnectivity)
import WatchConnectivity
#endif

/// Result of the Settings connection/permissions self-test. HealthKit-free so the
/// diagnostics view stays decoupled -- the coordinator maps HealthKit's opaque
/// status into `prompt`, and `probe` reports what a real read actually returned.
struct HealthProbe: Sendable {
    let sdnnCount: Int
    let restingHRCount: Int
    let latestSDNN: Date?
    let latestRestingHR: Date?
    static let empty = HealthProbe(sdnnCount: 0, restingHRCount: 0, latestSDNN: nil, latestRestingHR: nil)
}

/// Whether tapping "allow" will still show the iOS permission sheet.
enum PermissionPromptState: Sendable {
    case canPrompt      // not asked yet -- requesting will show the sheet
    case alreadyAsked   // shown once already; iOS never re-prompts -> use Settings
    case unknown        // HealthKit unavailable / indeterminate
}

struct ConnectionDiagnostic: Sendable {
    let healthAvailable: Bool
    let prompt: PermissionPromptState
    let probe: HealthProbe
    let watchPaired: Bool
    let watchAppInstalled: Bool
    let watchReachable: Bool
}

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
    #if canImport(WatchConnectivity)
    private let watchSync = PhoneWatchSync.shared   // Track E: status mirror
    #endif

    /// Passive SDNN arrives a few times/day; older than this -> Unavailable.
    private let stalenessInterval: TimeInterval = 6 * 3600

    // ---- UI-facing surface (docs/UI_WIRING.md) ----
    private(set) var presentation: HRVPresentationState = .setupRequired
    private(set) var baseline: Baseline?
    private(set) var recentSamples: [ProcessedHRVSample] = []
    private(set) var events: [EventRecord] = []
    private(set) var isHealthAuthorized = false
    /// Set when the user taps an alert notification (UI_WIRING P3); RootView
    /// switches to Today and StatusScreen opens the Guided Moment, then clears it.
    var pendingGuidedAlertID: UUID?
    /// Demo Mode (launch checklist #10): synthetic data stands in for HealthKit,
    /// so the setup gate must not require a real authorization. Persisted so the
    /// stored demo samples still render after a relaunch.
    private(set) var isDemoMode = UserDefaults.standard.bool(forKey: "demoMode")

    var learningDay: Int { engine.distinctDays() }
    var learningTotalDays: Int { 7 }
    /// Events that fired today -- the Today tab answers "what happened today"
    /// without making the user scan dates in the Events tab. `events` is
    /// already newest-first.
    var todayEvents: [EventRecord] {
        events.filter { Calendar.current.isDateInToday($0.firedAt) }
    }
    var hasCompletedSetup: Bool { (isHealthAuthorized || isDemoMode) && hasAnySample }

    // ---- internal ----
    private var lastSampleAt: Date?
    private var hasAnySample = false
    private var lastAlertID: UUID?
    /// Latest resting HR and the personal usual, refreshed from HealthKit and
    /// snapshotted onto an event when it fires. Demo Mode sets them directly.
    private var restingHeartRate: Double?
    private var usualRestingHeartRate: Double?
    /// Latest beat-series metrics (RMSSD/pNN50/SDSD), when the advanced-metrics
    /// feature is on and a beat series is available. UI reads this.
    private(set) var beatMetrics: BeatSeriesMetrics?

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
        alerts.onOpenAlert = { [weak self] eventID in
            Task { @MainActor in self?.pendingGuidedAlertID = eventID }
        }
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
            onSamples: { [weak self] samples, classifier in
                // HealthKit delivers this on an arbitrary background queue;
                // ingest() mutates @Observable state that SwiftUI reads, so it
                // must run on the main actor like every other caller of it.
                Task { @MainActor in self?.ingest(samples, classifier: classifier) }
            }
        )
        refreshRestingHeartRate()
        refreshBeatMetrics()
        #endif
        refresh()
    }

    /// Keep the resting-HR snapshot current so an event fired later carries a
    /// value that was true around that time.
    private func refreshRestingHeartRate() {
        #if canImport(HealthKit)
        health.fetchRestingHeartRate { [weak self] latest, usual in
            Task { @MainActor in
                self?.restingHeartRate = latest
                self?.usualRestingHeartRate = usual
            }
        }
        #endif
    }

    /// Beat-series metrics (A.6.1), only when the feature is on. Device-only.
    private func refreshBeatMetrics() {
        #if canImport(HealthKit)
        guard FeatureFlags.advancedMetricsEnabled else { return }
        health.fetchLatestBeatMetrics { [weak self] metrics in
            Task { @MainActor in
                self?.beatMetrics = metrics
                if let rmssd = metrics?.rmssd { self?.persistRmssd(rmssd) }
                self?.refresh()
            }
        }
        #endif
    }

    /// Store a computed RMSSD as its own sample stream, so the Trends RMSSD
    /// view can chart it over time (kept separate from the sdnnApple detection
    /// samples).
    private func persistRmssd(_ value: Double, at date: Date = Date()) {
        repository.save(ProcessedHRVSample(
            timestamp: date, lnRmssd: log(value), rawValueMs: value,
            metric: HRVMetric.rmssdComputed.rawValue, quality: SampleQuality.high.rawValue,
            context: "rest", source: HRVSource.beatSeries.rawValue))
    }

    /// Computed-RMSSD samples in the window, for the Trends RMSSD chart.
    func rmssdSamples(since: Date) -> [ProcessedHRVSample] {
        repository.samples(from: since, to: Date())
            .filter { $0.metric == HRVMetric.rmssdComputed.rawValue }
    }

    /// Core pipeline for a batch of new samples (also the unit-testable seam).
    /// The classifier (Track H) tags each sample rest/sleep/active; active
    /// samples are excluded from both the baseline and alerting by the core.
    func ingest(_ samples: [HRVSample], classifier: ContextClassifier = ContextClassifier()) {
        for s in samples where s.quality == .high {
            let ctx = classifier.context(at: s.timestamp)
            if let event = detector.evaluate(timestamp: s.timestamp, rmssdValue: s.valueMs, context: ctx) {
                recordEvent(event, classifier: classifier)
            }
            if ctx.isRestful { resolveOpenEventIfRecovered(at: s.timestamp, valueMs: s.valueMs) }
            persist(s, label: classifier.label(at: s.timestamp))
            hasAnySample = true
            lastSampleAt = s.timestamp
        }
        refresh()
    }

    /// P6: an event stays "open" while readings remain below the personal range;
    /// the first restful in-range sample closes every open event (a long episode
    /// can spawn several alerts across cooldowns) and stamps their durations.
    private func resolveOpenEventIfRecovered(at timestamp: Date, valueMs: Double) {
        let open = events.filter { $0.durationHours == nil && timestamp > $0.firedAt }
        guard !open.isEmpty,
              let baseline = engine.currentBaseline(asOf: timestamp) else { return }
        let z = robustZ(log(valueMs), baseline: baseline)
        guard z >= -config.k else { return }
        for event in open {
            event.durationHours = max(0, timestamp.timeIntervalSince(event.firedAt) / 3600)
        }
        #if canImport(SwiftData)
        try? context.save()
        #endif
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

    /// The Settings "connection & permissions" self-test. Actually reads Health
    /// data (the only honest signal, since read-grant status is opaque) and
    /// reports the Apple Watch link, so the button always does something visible.
    func runConnectionDiagnostic() async -> ConnectionDiagnostic {
        let (paired, installed, reachable) = watchStatus()
        #if canImport(HealthKit)
        guard HealthKitService.isAvailable else {
            return ConnectionDiagnostic(healthAvailable: false, prompt: .unknown, probe: .empty,
                                        watchPaired: paired, watchAppInstalled: installed, watchReachable: reachable)
        }
        let prompt: PermissionPromptState
        switch await health.authorizationRequestStatus() {
        case .shouldRequest: prompt = .canPrompt
        case .unnecessary:   prompt = .alreadyAsked
        @unknown default:    prompt = .unknown
        }
        let probe = await health.probeRecentData()
        // A successful read is the closest thing to proof of read access.
        if probe.sdnnCount > 0 || probe.restingHRCount > 0 { isHealthAuthorized = true }
        return ConnectionDiagnostic(healthAvailable: true, prompt: prompt, probe: probe,
                                    watchPaired: paired, watchAppInstalled: installed, watchReachable: reachable)
        #else
        return ConnectionDiagnostic(healthAvailable: false, prompt: .unknown, probe: .empty,
                                    watchPaired: paired, watchAppInstalled: installed, watchReachable: reachable)
        #endif
    }

    private func watchStatus() -> (paired: Bool, installed: Bool, reachable: Bool) {
        #if canImport(WatchConnectivity)
        guard WCSession.isSupported() else { return (false, false, false) }
        let s = WCSession.default
        return (s.isPaired, s.isWatchAppInstalled, s.isReachable)
        #else
        return (false, false, false)
        #endif
    }

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

    /// Charting-only read path. Deliberately separate from `recentSamples`,
    /// which is detection-critical (restorePipelineState replays it into the
    /// BaselineEngine and it drives the learning-day count) and must keep its
    /// 60-day window. Samples are never pruned, so `.distantPast` really does
    /// return the full history.
    func samples(since: Date) -> [ProcessedHRVSample] {
        repository.samples(from: since, to: Date())
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
        try? context.delete(model: CoherenceSession.self)
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
    /// `days`/`ageOffset` let QA preview the `learning` and `unavailable`
    /// states (checklist §A) without waiting on real time; the Settings
    /// button always calls this with the defaults.
    func loadDemoData(days: Int = 30, ageOffset: TimeInterval = 0, liveEventSlots: Int = 3) {
        isDemoMode = true
        UserDefaults.standard.set(true, forKey: "demoMode")
        let batch = DemoData.generate(days: days,
                                      liveEventSlots: liveEventSlots,
                                      ageOffset: ageOffset)
        restingHeartRate = batch.restingHeartRate
        usualRestingHeartRate = batch.usualRestingHeartRate
        // Synthetic beat-series metrics so the detailed-metrics UI shows on the
        // simulator (real beat series need a device).
        if FeatureFlags.advancedMetricsEnabled {
            beatMetrics = BeatSeriesMetrics(rmssd: 42, sdnn: 48, pnn50: 18.5, sdsd: 39,
                                            quality: .high, beatCount: 92)
            // A sparse RMSSD history (beat series arrive occasionally) so the
            // Trends RMSSD view has something to draw.
            let wobble: [Double] = [40, 44, 38, 43, 41, 46, 39, 42]
            for d in stride(from: 28, through: 0, by: -3) {
                persistRmssd(wobble[(28 - d) / 3 % wobble.count],
                             at: Date().addingTimeInterval(-Double(d) * 86_400))
            }
        }
        ingest(batch.samples, classifier: batch.classifier)
    }

    // MARK: internals
    private func recordEvent(_ event: AlertEvent, classifier: ContextClassifier = ContextClassifier()) {
        // PRODUCT_STATE_MODEL: one sustained deviation == one event. The
        // detector re-alerts every cooldown while the drop persists; those
        // re-alerts extend the still-open episode instead of adding rows.
        if let open = events.first, open.durationHours == nil {
            if abs(event.robustZ) > abs(open.robustZ) {   // keep the worst depth
                open.robustZ = event.robustZ
                open.rawValueMs = event.rawValueMs
            }
            open.seen = false   // a fresh confirmed alert re-enters Attention
            lastAlertID = open.id
            #if canImport(SwiftData)
            try? context.save()
            #endif
            // Record this re-alert's own tick so restorePipelineState() can
            // still find a recent AlertRecord and restore cooldown correctly
            // if the app relaunches mid-episode, past the original firing's
            // cooldown window.
            repository.record(AlertRecord(firedAt: event.firedAt, robustZ: event.robustZ,
                                          rawValueMs: event.rawValueMs, reason: event.reason))
            alerts.fireHRVDrop(event, eventID: open.id)
            return
        }
        // Capture the co-occurring facts now, so the event's history keeps what
        // was true when it fired (facts only -- never a claimed cause).
        let eventContext = EventContextBuilder.build(
            eventDate: event.firedAt,
            sleepIntervals: classifier.sleepIntervals,
            workoutIntervals: classifier.workoutIntervals,
            restingHeartRate: restingHeartRate,
            usualRestingHeartRate: usualRestingHeartRate
        )
        let rec = EventRecord(firedAt: event.firedAt, robustZ: event.robustZ,
                              rawValueMs: event.rawValueMs, reason: event.reason,
                              context: eventContext)
        lastAlertID = rec.id
        // Keep the in-memory list current mid-batch so recovery inside the same
        // ingest pass (resolveOpenEventIfRecovered) can see and close this event.
        events.insert(rec, at: 0)
        #if canImport(SwiftData)
        context.insert(rec)
        try? context.save()
        #endif
        repository.record(AlertRecord(id: rec.id, firedAt: event.firedAt, robustZ: event.robustZ,
                                      rawValueMs: event.rawValueMs, reason: event.reason))
        // P3: the notification carries the event id so a tap can deep-link
        // straight into the Guided Moment for this event.
        alerts.fireHRVDrop(event, eventID: rec.id)
    }

    private func persist(_ s: HRVSample, label: String) {
        let processed = ProcessedHRVSample(
            timestamp: s.timestamp, lnRmssd: log(s.valueMs), rawValueMs: s.valueMs,
            metric: s.metric.rawValue, quality: s.quality.rawValue,
            context: label, source: s.source.rawValue)
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
        pushStateToWatch()
    }

    /// Track E: mirror the user-visible state to the watch after every refresh.
    private func pushStateToWatch() {
        #if canImport(WatchConnectivity)
        let stateName: String
        switch presentation {
        case .setupRequired: stateName = "setupRequired"
        case .learning:      stateName = "learning"
        case .stable:        stateName = "stable"
        case .attention:     stateName = "attention"
        case .unavailable:   stateName = "unavailable"
        }
        let latest = recentSamples.max { $0.timestamp < $1.timestamp }?.rawValueMs
        watchSync.push(state: stateName,
                       latestMs: latest,
                       rangeLoMs: baseline.map { exp($0.lowerBound) },
                       rangeHiMs: baseline.map { exp($0.upperBound) },
                       updatedAt: lastSampleAt)
        #endif
    }

    /// The newest event, while it is still "live": open (readings haven't
    /// returned to range -- resolution closes it) and not yet acknowledged
    /// (Guided Moment completion/skip marks it seen). Together these encode
    /// both PRODUCT_STATE_MODEL exits; data staleness is already handled by
    /// the mapper's unavailable precedence before this override applies.
    private var activeAttentionEvent: EventRecord? {
        guard let e = events.first, !e.seen, e.durationHours == nil else { return nil }
        return e
    }

    private func isRecent(_ date: Date?) -> Bool {
        guard let date else { return false }
        return Date().timeIntervalSince(date) <= stalenessInterval
    }
}
