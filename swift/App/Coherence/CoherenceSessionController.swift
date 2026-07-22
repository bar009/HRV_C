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
    private(set) var score: Int = 0
    private(set) var band: CoherenceBand = .low
    private(set) var elapsed: TimeInterval = 0
    private(set) var lastSaved: CoherenceSummary?
    private(set) var history: [CoherenceSummary] = []
    /// True once a real coherence score has come in this session. On an iPhone
    /// with no paired watch feeding beats, this stays false and the UI runs as
    /// a plain breathing exercise (no score).
    private(set) var hasCoherence = false

    /// Full breath cycle in seconds -- 10s ≈ the ~0.1 Hz resonance HeartMath
    /// targets, so pacing the user here nudges them toward the coherent peak.
    let breathingPace: Double = 10

    // ---- internals ----
    private let source: HeartRateSource
    private var samples: [IBISample] = []
    private var scores: [Int] = []
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
        samples = []; scores = []; score = 0; band = .low; elapsed = 0; hasCoherence = false
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
        let avg = scores.isEmpty ? 0 : Int((Double(scores.reduce(0, +)) / Double(scores.count)).rounded())
        let peak = scores.max() ?? 0
        let summary = CoherenceSummary(startedAt: startDate, durationSec: elapsed,
                                       avgScore: avg, peakScore: peak, breathingPace: breathingPace)
        lastSaved = summary
        persist(summary)
        reloadHistory()
    }

    func reset() { phase = .idle; lastSaved = nil }

    // MARK: pipeline
    private func ingest(_ sample: IBISample) {
        samples.append(sample)
        // Keep only the sliding analysis window.
        let cutoff = sample.t - CoherenceEngine.windowSeconds
        samples.removeAll { $0.t < cutoff }
    }

    private func tick() {
        elapsed = Date().timeIntervalSince(startDate)
        if let result = CoherenceEngine.analyze(samples) {
            score = result.score
            band = result.band
            scores.append(result.score)
            hasCoherence = true
        }
    }

    #if DEBUG
    /// QA hooks (simulator can't tap through a full session): seed history and
    /// jump straight to the results screen for screenshots.
    func debugSeedHistory() {
        guard history.isEmpty else { return }   // onAppear can fire twice
        let now = Date()
        let demo = [(min: 4, avg: 72, peak: 88), (min: 3, avg: 55, peak: 71), (min: 5, avg: 61, peak: 80)]
        for (i, d) in demo.enumerated() {
            persist(CoherenceSummary(startedAt: now.addingTimeInterval(-Double(i + 1) * 86_400),
                                     durationSec: Double(d.min * 60),
                                     avgScore: d.avg, peakScore: d.peak, breathingPace: breathingPace))
        }
        reloadHistory()
    }

    func debugShowResults() {
        debugSeedHistory()
        lastSaved = CoherenceSummary(startedAt: Date(), durationSec: 240,
                                     avgScore: 68, peakScore: 84, breathingPace: breathingPace)
        phase = .finished
    }
    #endif

    // MARK: persistence
    private func persist(_ s: CoherenceSummary) {
        #if canImport(SwiftData)
        context.insert(CoherenceSession(startedAt: s.startedAt, durationSec: s.durationSec,
                                        avgScore: s.avgScore, peakScore: s.peakScore,
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
    let avgScore: Int
    let peakScore: Int
    let breathingPace: Double

    init(id: UUID = UUID(), startedAt: Date, durationSec: TimeInterval,
         avgScore: Int, peakScore: Int, breathingPace: Double) {
        self.id = id; self.startedAt = startedAt; self.durationSec = durationSec
        self.avgScore = avgScore; self.peakScore = peakScore; self.breathingPace = breathingPace
    }

    #if canImport(SwiftData)
    init(_ m: CoherenceSession) {
        id = m.id; startedAt = m.startedAt; durationSec = m.durationSec
        avgScore = m.avgScore; peakScore = m.peakScore; breathingPace = m.breathingPace
    }
    #endif
}
