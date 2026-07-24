// Track J -- drives an active coherence practice session (D-COH). Phone-led:
// the breathing pacer + live score run here; the beat stream comes from a
// HeartRateSource (real watch workout on device, simulated otherwise).
import Foundation
import Observation
import HRVCore
#if canImport(SwiftData)
import SwiftData
#endif

@Observable
@MainActor
final class CoherenceSessionController {
    enum Phase: Equatable { case idle, running, finished }

    // ---- UI-facing ----
    private(set) var phase: Phase = .idle
    private(set) var level: Int = 0            // live coherence level, 0-10
    private(set) var band: CoherenceBand = .low
    private(set) var elapsed: TimeInterval = 0
    private(set) var lastSaved: CoherenceSummary?
    private(set) var history: [CoherenceSummary] = []
    /// True once a real coherence level has come in this session. On an iPhone
    /// with no paired watch feeding beats, this stays false and the UI runs as
    /// a plain breathing exercise (no score).
    private(set) var hasCoherence = false

    // ---- live "collecting data" surface (distinct from hasCoherence: beats
    // arrive ~immediately, but the first level needs ~half a window) ----
    /// True once any beat has been ingested this session.
    private(set) var isReceivingBeats = false
    /// Instantaneous heart rate from the latest inter-beat interval, bpm.
    private(set) var currentBPM: Int = 0
    /// Beats ingested this session (a visible sign data is flowing).
    private(set) var beatCount = 0
    /// Rolling recent bpm values for the live mini-waveform (newest last).
    private(set) var recentBPM: [Double] = []
    /// 0…1 progress toward the first coherence reading (needs ~half a window).
    var firstReadingProgress: Double {
        hasCoherence ? 1 : min(elapsed, CoherenceEngine.windowSeconds / 2) / (CoherenceEngine.windowSeconds / 2)
    }

    private let recentBPMCap = 40

    /// Full breath cycle in seconds -- 10s ≈ the ~0.1 Hz resonance HeartMath
    /// targets, so pacing the user here nudges them toward the coherent peak.
    let breathingPace: Double = 10

    // ---- internals ----
    private let source: HeartRateSource
    private var samples: [IBISample] = []
    private var levels: [Int] = []              // one per reading, for peak level
    private var inCoherenceCount = 0            // readings in medium+high
    private var readingCount = 0                // total readings (for the %)
    private var startDate = Date()
    private var ticker: Timer?

    #if canImport(SwiftData)
    private let context: ModelContext
    init(source: HeartRateSource, context: ModelContext) {
        self.source = source
        self.context = context
        reloadHistory()
        source.onBeat = { [weak self] sample in
            Task { @MainActor in self?.ingest(sample) }
        }
    }
    #else
    init(source: HeartRateSource) {
        self.source = source
        source.onBeat = { [weak self] sample in
            Task { @MainActor in self?.ingest(sample) }
        }
    }
    #endif

    // MARK: session lifecycle
    func start() {
        samples = []; levels = []; inCoherenceCount = 0; readingCount = 0
        level = 0; band = .low; elapsed = 0; hasCoherence = false
        isReceivingBeats = false; currentBPM = 0; beatCount = 0; recentBPM = []
        startDate = Date()
        phase = .running
        source.start()
        ticker = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
    }

    func finish() {
        guard phase == .running else { return }
        source.stop()
        ticker?.invalidate(); ticker = nil
        phase = .finished
        // Honest, reachable session metric: share of readings that were in
        // coherence (medium+high). Peak = best 0-10 level reached.
        let pct = readingCount == 0 ? 0
            : Int((Double(inCoherenceCount) / Double(readingCount) * 100).rounded())
        let peak = levels.max() ?? 0
        let summary = CoherenceSummary(startedAt: startDate, durationSec: elapsed,
                                       coherencePct: pct, peakLevel: peak, breathingPace: breathingPace)
        lastSaved = summary
        persist(summary)
        reloadHistory()
    }

    func reset() { phase = .idle; lastSaved = nil }

    // MARK: pipeline
    private func ingest(_ sample: IBISample) {
        isReceivingBeats = true
        beatCount += 1
        if sample.ibiMs > 0 {
            currentBPM = Int((60_000 / sample.ibiMs).rounded())
            recentBPM.append(60_000 / sample.ibiMs)
            if recentBPM.count > recentBPMCap { recentBPM.removeFirst(recentBPM.count - recentBPMCap) }
        }
        samples.append(sample)
        // Keep only the sliding analysis window.
        let cutoff = sample.t - CoherenceEngine.windowSeconds
        samples.removeAll { $0.t < cutoff }
    }

    private func tick() {
        elapsed = Date().timeIntervalSince(startDate)
        if let result = CoherenceEngine.analyze(samples) {
            level = result.level
            band = result.band
            levels.append(result.level)
            readingCount += 1
            if result.band != .low { inCoherenceCount += 1 }
            hasCoherence = true
        }
    }

    #if DEBUG
    /// QA hooks (simulator can't tap through a full session): seed history and
    /// jump straight to the results screen for screenshots.
    func debugSeedHistory() {
        guard history.isEmpty else { return }   // onAppear can fire twice
        let now = Date()
        let demo = [(min: 4, pct: 72, peak: 9), (min: 3, pct: 48, peak: 6), (min: 5, pct: 61, peak: 8)]
        for (i, d) in demo.enumerated() {
            persist(CoherenceSummary(startedAt: now.addingTimeInterval(-Double(i + 1) * 86_400),
                                     durationSec: Double(d.min * 60),
                                     coherencePct: d.pct, peakLevel: d.peak, breathingPace: breathingPace))
        }
        reloadHistory()
    }

    func debugShowResults() {
        debugSeedHistory()
        lastSaved = CoherenceSummary(startedAt: Date(), durationSec: 240,
                                     coherencePct: 64, peakLevel: 8, breathingPace: breathingPace)
        phase = .finished
    }
    #endif

    // MARK: persistence
    private func persist(_ s: CoherenceSummary) {
        #if canImport(SwiftData)
        context.insert(CoherenceSession(startedAt: s.startedAt, durationSec: s.durationSec,
                                        coherencePct: s.coherencePct, peakLevel: s.peakLevel,
                                        breathingPace: s.breathingPace))
        try? context.save()
        #endif
    }

    private func reloadHistory() {
        #if canImport(SwiftData)
        let d = FetchDescriptor<CoherenceSession>(sortBy: [SortDescriptor(\.startedAt, order: .reverse)])
        history = ((try? context.fetch(d)) ?? []).map(CoherenceSummary.init)
        #endif
    }
}

/// View-facing value type, so the UI never holds a SwiftData model directly.
struct CoherenceSummary: Identifiable, Equatable {
    let id: UUID
    let startedAt: Date
    let durationSec: TimeInterval
    let coherencePct: Int   // % time in coherence, 0-100
    let peakLevel: Int      // best level reached, 0-10
    let breathingPace: Double

    init(id: UUID = UUID(), startedAt: Date, durationSec: TimeInterval,
         coherencePct: Int, peakLevel: Int, breathingPace: Double) {
        self.id = id; self.startedAt = startedAt; self.durationSec = durationSec
        self.coherencePct = coherencePct; self.peakLevel = peakLevel; self.breathingPace = breathingPace
    }

    #if canImport(SwiftData)
    init(_ m: CoherenceSession) {
        id = m.id; startedAt = m.startedAt; durationSec = m.durationSec
        coherencePct = m.coherencePct; peakLevel = m.peakLevel; breathingPace = m.breathingPace
    }
    #endif
}
