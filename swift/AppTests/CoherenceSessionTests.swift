// Track J -- session controller over the real engine + in-memory store.
import XCTest
import SwiftData
import HRVCore
@testable import HRV_Phone

@MainActor
final class CoherenceSessionTests: XCTestCase {
    private var container: ModelContainer!

    override func setUpWithError() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(for: Schema(PrivacyStore.models), configurations: config)
    }
    override func tearDown() { container = nil }

    /// Feed a coherent stream straight through the controller's engine path and
    /// confirm it scores high -- the same pipeline the live UI uses.
    private func coherentSamples(seconds: Double = 64, hz: Double = 4) -> [IBISample] {
        let step = 1.0 / hz
        var out: [IBISample] = []
        var t = 0.0
        while t <= seconds { out.append(IBISample(t: t, ibiMs: 900 + 40 * sin(2 * .pi * 0.1 * t))); t += step }
        return out
    }

    func testCoherentWindowScoresHighThroughEngine() {
        let result = CoherenceEngine.analyze(coherentSamples())
        XCTAssertGreaterThan(result?.score ?? 0, 70)
        XCTAssertEqual(result?.band, .high)
    }

    func testFinishPersistsAndReloadsHistory() {
        let controller = CoherenceSessionController(source: SimulatedHeartRateSource(coherent: true),
                                                    context: ModelContext(container))
        XCTAssertTrue(controller.history.isEmpty)
        controller.start()
        controller.finish()
        XCTAssertEqual(controller.phase, .finished)
        XCTAssertNotNil(controller.lastSaved)
        // A fresh controller over the same store must see the saved session.
        let reopened = CoherenceSessionController(source: SimulatedHeartRateSource(),
                                                  context: ModelContext(container))
        XCTAssertEqual(reopened.history.count, 1)
    }

    func testBandThresholds() {
        XCTAssertEqual(CoherenceEngine.band(forScore: 10), .low)
        XCTAssertEqual(CoherenceEngine.band(forScore: 55), .medium)
        XCTAssertEqual(CoherenceEngine.band(forScore: 85), .high)
    }
}
