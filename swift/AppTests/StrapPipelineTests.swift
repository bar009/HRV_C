// The chest-strap path end to end, driven by a controllable provider so it runs
// without hardware (CoreBluetooth has none in the Simulator).
import XCTest
import SwiftData
import HRVCore
@testable import HRV_Phone

/// A provider the test drives by hand.
private final class MockProvider: HeartRateProviding {
    var onMeasurement: ((HeartRateMeasurement, Date) -> Void)?
    var onState: ((ProviderState) -> Void)?
    var onDiscover: ((DiscoveredDevice) -> Void)?
    var state: ProviderState = .idle
    var capabilities: SensorCapabilities = .bleChestStrap
    var batteryPercent: Int? = 90
    var pairedDeviceID: UUID? = UUID()

    func startScan() {}
    func stopScan() {}
    func connect(_ id: UUID) { state = .connected(name: "Mock"); onState?(state) }
    func disconnect() { state = .disconnected; onState?(state) }
    func forget() { state = .idle; onState?(state) }

    /// Emit `count` beats ~one second apart, with a small respiratory wobble so
    /// the series has real variability (a perfectly flat series has RMSSD 0).
    func emitBeats(_ count: Int, ibiMs: Double = 1000, wobble: Double = 30, from: Date) {
        var elapsed: TimeInterval = 0
        for i in 0..<count {
            let value = ibiMs + wobble * sin(2 * .pi * 0.1 * Double(i))
            let t = from.addingTimeInterval(elapsed)
            elapsed += value / 1000
            onMeasurement?(HeartRateMeasurement(bpm: Int(60_000 / value),
                                                rrIntervalsMs: [value]), t)
        }
    }
}

@MainActor
final class StrapPipelineTests: XCTestCase {
    private var container: ModelContainer!

    override func setUpWithError() throws {
        UserDefaults.standard.removeObject(forKey: SensorMode.storageKey)
        UserDefaults.standard.removeObject(forKey: "demoMode")
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(for: Schema(PrivacyStore.models), configurations: config)
    }
    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: SensorMode.storageKey)
        container = nil
    }

    private func settle() async {
        // StrapMonitor hops to the main actor via Task; let those drain.
        for _ in 0..<5 { await Task.yield() }
    }

    // MARK: capability gating

    func testBpmOnlyProviderDisablesEveryHRVIndicator() {
        let provider = SimulatedHeartRateProvider(sendsRR: false)
        XCTAssertEqual(provider.capabilities, .bleBpmOnly)
        for i in [HealthIndicator.rmssd, .coherence, .liveTriggers] {
            XCTAssertFalse(IndicatorResolver.availability(of: i, given: provider.capabilities).isUsable,
                           "\(i) must be off for a heart-rate-only strap")
        }
    }

    func testBpmOnlyMeasurementsProduceNoSamples() async {
        let provider = MockProvider()
        provider.capabilities = .bleBpmOnly
        let monitor = StrapMonitor(provider: provider)
        var samples: [HRVSample] = []
        monitor.onSample = { samples.append($0) }

        // RR-less packets: plenty of beats, but nothing to compute from.
        for i in 0..<120 {
            provider.onMeasurement?(HeartRateMeasurement(bpm: 60, rrIntervalsMs: []),
                                    Date().addingTimeInterval(Double(i)))
        }
        await settle()
        XCTAssertTrue(samples.isEmpty)
    }

    // MARK: windowing

    func testWindowsProduceStrapSamples() async {
        let provider = MockProvider()
        let monitor = StrapMonitor(provider: provider)
        var samples: [HRVSample] = []
        monitor.onSample = { samples.append($0) }

        // 120 beats at ~1 s apart crosses the 60-beat minimum and the 30 s step.
        provider.emitBeats(120, ibiMs: 1000, from: Date(timeIntervalSince1970: 1_700_000_000))
        await settle()

        XCTAssertFalse(samples.isEmpty, "a continuous RR stream should yield windows")
        XCTAssertEqual(samples.first?.source, .bleStrap)
        XCTAssertEqual(samples.first?.metric, .rmssdComputed)
        XCTAssertGreaterThan(samples.first?.valueMs ?? 0, 0)
    }

    func testDisconnectResetsTheWindowSoItNeverStraddlesAGap() async {
        let provider = MockProvider()
        let monitor = StrapMonitor(provider: provider)
        var samples: [HRVSample] = []
        monitor.onSample = { samples.append($0) }

        let t0 = Date(timeIntervalSince1970: 1_700_000_000)
        provider.emitBeats(50, from: t0)          // below the minimum
        await settle()
        provider.disconnect()
        await settle()
        provider.emitBeats(50, from: t0.addingTimeInterval(86_400))  // a day later
        await settle()

        XCTAssertTrue(samples.isEmpty, "buffered beats must be dropped on disconnect")
    }

    // MARK: isolation from the passive baseline

    func testStrapSamplesNeverEnterThePassiveSDNNBaseline() {
        let context = ModelContext(container)
        let coordinator = MonitoringCoordinator(repository: SwiftDataRepository(context: context),
                                                context: context)
        // Enough strap windows to build a baseline, if they were pooled.
        let t0 = Date().addingTimeInterval(-3600)
        for i in 0..<40 {
            coordinator.recordStrapSample(HRVSample(
                timestamp: t0.addingTimeInterval(Double(i) * 30), valueMs: 42,
                metric: .rmssdComputed, quality: .high, source: .bleStrap, sampleCount: 90))
        }
        // The passive path must be untouched: still awaiting setup, no events.
        guard case .setupRequired = coordinator.presentation else {
            return XCTFail("strap samples leaked into the passive detector: \(coordinator.presentation)")
        }
        XCTAssertTrue(coordinator.events.isEmpty)
        // But they are stored and chartable.
        XCTAssertEqual(coordinator.rmssdSamples(since: .distantPast).count, 40)
    }

    // MARK: mode

    func testSensorModeDefaultsToAppleWatchAndPersists() {
        XCTAssertEqual(SensorMode.current, .appleWatch)
        SensorMode.current = .bleStrap
        XCTAssertEqual(SensorMode.current, .bleStrap)
        XCTAssertEqual(SensorMode.current.baseCapabilities.rrFidelity, .beatToBeat)
    }
}
