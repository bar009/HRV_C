// Continuous monitoring from a Bluetooth strap: RR stream -> rolling windows ->
// time-domain metrics -> its OWN baseline + detector.
//
// HARD RULE: this never shares a baseline with the passive HealthKit path.
// Apple's SDNN (a handful of resting snapshots a day) and our RMSSD (a 2-minute
// window every 30 s) are different metrics measured under different conditions;
// pooling them would corrupt both distributions. Hence a private
// BaselineEngine + AnomalyDetector(.live) here.
import Foundation
import Observation
import HRVCore

@Observable
@MainActor
final class StrapMonitor {
    // ---- UI-facing ----
    private(set) var state: ProviderState = .idle
    private(set) var capabilities: SensorCapabilities = .none
    private(set) var batteryPercent: Int?
    private(set) var currentBPM: Int = 0
    private(set) var bufferedBeats: Int = 0
    private(set) var lastWindowAt: Date?
    private(set) var discovered: [DiscoveredDevice] = []
    /// Latest window's metrics, for the live readout.
    private(set) var latestMetrics: BeatSeriesMetrics?

    var isConnected: Bool { state.isConnected }
    var pairedDeviceID: UUID? { provider.pairedDeviceID }

    /// Emitted when a window produces a usable sample; the app persists it and
    /// charts it. Kept as a callback so this type stays independent of storage.
    var onSample: ((HRVSample) -> Void)?
    /// Emitted when the live detector confirms a sustained drop.
    var onLiveEvent: ((AlertEvent) -> Void)?
    /// Raw beats, for the live coherence session.
    var onBeat: ((Double) -> Void)?

    // ---- internals ----
    private let provider: HeartRateProviding
    private var windower = RRWindower()
    private let engine: BaselineEngine
    private var detector: AnomalyDetector

    init(provider: HeartRateProviding) {
        self.provider = provider
        // A continuous feed builds a usable distribution within hours, so the
        // live baseline needs a much shorter warm-up than the passive one.
        let engine = BaselineEngine(windowDays: 14, minBaselineDays: 1, k: DetectorConfig.live.k)
        self.engine = engine
        self.detector = AnomalyDetector(engine: engine, config: .live)

        provider.onState = { [weak self] s in
            Task { @MainActor in self?.handleState(s) }
        }
        provider.onDiscover = { [weak self] d in
            Task { @MainActor in self?.handleDiscovery(d) }
        }
        provider.onMeasurement = { [weak self] m, at in
            Task { @MainActor in self?.handle(m, at: at) }
        }
    }

    // MARK: control

    func startScan() { discovered = []; provider.startScan() }
    func stopScan() { provider.stopScan() }
    func connect(_ id: UUID) { provider.connect(id) }
    func disconnect() { provider.disconnect() }
    func forget() { provider.forget(); windower.reset(); reset() }

    /// Reconnect to a remembered strap on launch when the mode is active.
    func resumeIfPaired() {
        if let id = provider.pairedDeviceID, !state.isConnected { provider.connect(id) }
    }

    // MARK: pipeline

    private func handleState(_ s: ProviderState) {
        state = s
        capabilities = provider.capabilities
        batteryPercent = provider.batteryPercent
        // A window must never straddle a coverage gap.
        if !s.isConnected { windower.reset(); bufferedBeats = 0 }
    }

    private func handleDiscovery(_ d: DiscoveredDevice) {
        guard !discovered.contains(where: { $0.id == d.id }) else { return }
        discovered.append(d)
    }

    private func handle(_ m: HeartRateMeasurement, at time: Date) {
        currentBPM = m.bpm
        batteryPercent = provider.batteryPercent
        capabilities = provider.capabilities
        guard m.hasRR else { return }   // BPM-only device: nothing to compute

        for ibi in m.rrIntervalsMs { onBeat?(ibi) }

        guard let window = windower.add(m.rrIntervalsMs, at: time) else {
            bufferedBeats = windower.bufferedBeats
            return
        }
        bufferedBeats = windower.bufferedBeats
        lastWindowAt = time

        let metrics = RRExtractor.metrics(fromRR: window)
        latestMetrics = metrics
        // A zero RMSSD (a perfectly flat series -- a stuck sensor, or padded
        // data) is not a real measurement: ln(0) is undefined and the baseline
        // would reject it anyway, so drop it here rather than store a bad row.
        guard metrics.isUsable, let rmssd = metrics.rmssd, rmssd > 0 else { return }

        onSample?(HRVSample(timestamp: time, valueMs: rmssd, metric: .rmssdComputed,
                            quality: metrics.quality, source: .bleStrap,
                            sampleCount: metrics.beatCount))

        // Live detection on our own baseline only.
        if let event = detector.evaluate(timestamp: time, rmssdValue: rmssd) {
            onLiveEvent?(event)
        }
    }

    private func reset() {
        state = .idle
        capabilities = .none
        currentBPM = 0
        bufferedBeats = 0
        lastWindowAt = nil
        latestMetrics = nil
        discovered = []
    }
}
