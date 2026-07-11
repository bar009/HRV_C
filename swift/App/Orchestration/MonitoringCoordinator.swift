// Track B -- end-to-end wiring (Deep Dive D.2). Mac-only.
// The Swift analog of sim/run_scenario.py: HealthKit -> Signal/Detection (HRVCore)
// -> Persistence -> Notification. All decisions happen on-device.
import Foundation
import Observation
import HRVCore

@Observable
final class MonitoringCoordinator {
    private let repository: HRVRepository
    private let engine: BaselineEngine
    private let detector: AnomalyDetector
    private let alerts = AlertService()
    #if canImport(HealthKit)
    private let health = HealthKitService()
    #endif

    // UI-facing state.
    private(set) var state: DetectorState = .learning
    private(set) var latestBaseline: Baseline?
    private(set) var recentAlerts: [AlertRecord] = []

    init(repository: HRVRepository, config: DetectorConfig = DetectorConfig()) {
        self.repository = repository
        self.engine = BaselineEngine()
        self.detector = AnomalyDetector(engine: engine, config: config)
    }

    func start() async {
        #if canImport(HealthKit)
        guard HealthKitService.isAvailable else { return }
        try? await health.requestAuthorization()
        await alerts.requestAuthorization()
        health.startObservingSDNN(
            anchorProvider: { [weak self] key in self?.repository.anchor(for: key) },
            anchorSink: { [weak self] data, key in self?.repository.saveAnchor(data, for: key) },
            onSamples: { [weak self] samples in self?.ingest(samples) }
        )
        #endif
        refreshState()
    }

    /// Core pipeline for a batch of new samples (also the unit-testable seam).
    func ingest(_ samples: [HRVSample]) {
        for s in samples where s.quality == .high {
            // TODO(Track H): derive real context (HR/sleep). Assume restful for now.
            let context = SampleContext(isRestful: true)
            if let event = detector.evaluate(timestamp: s.timestamp, rmssdValue: s.valueMs, context: context) {
                let record = AlertRecord(firedAt: event.firedAt, robustZ: event.robustZ,
                                         rawValueMs: event.rawValueMs, reason: event.reason)
                repository.record(record)
                alerts.fireHRVDrop(event)
            }
            persist(s, context: context)
        }
        refreshState()
    }

    private func persist(_ s: HRVSample, context: SampleContext) {
        let processed = ProcessedHRVSample(
            timestamp: s.timestamp, lnRmssd: log(s.valueMs), rawValueMs: s.valueMs,
            metric: s.metric.rawValue, quality: s.quality.rawValue,
            context: context.isRestful ? "rest" : "active", source: s.source.rawValue)
        repository.save(processed)
    }

    private func refreshState() {
        state = detector.state
        latestBaseline = engine.currentBaseline()
        recentAlerts = repository.recentAlerts(since: Date().addingTimeInterval(-30 * 86_400))
    }
}
