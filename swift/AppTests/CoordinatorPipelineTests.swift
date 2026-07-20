// App-layer pipeline tests: demo gate, stratification, episode grouping,
// event resolution, attention derivation, relevance persistence. Everything
// runs through the real seam (`ingest(_:classifier:)`) over an in-memory store.
import XCTest
import SwiftData
import HRVCore
@testable import HRV_Phone

final class CoordinatorPipelineTests: XCTestCase {
    private var container: ModelContainer!
    private var coordinator: MonitoringCoordinator!

    override func setUpWithError() throws {
        UserDefaults.standard.removeObject(forKey: "demoMode")
        UserDefaults.standard.removeObject(forKey: "didOnboard")
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(for: Schema(PrivacyStore.models), configurations: config)
        let context = ModelContext(container)
        coordinator = MonitoringCoordinator(repository: SwiftDataRepository(context: context),
                                            context: context)
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: "demoMode")
        UserDefaults.standard.removeObject(forKey: "didOnboard")
        coordinator = nil
        container = nil
    }

    private func loadDemo() { coordinator.loadDemoData() }

    // MARK: Demo gate

    func testDemoModeCompletesSetupWithoutHealthKit() {
        XCTAssertFalse(coordinator.hasCompletedSetup)
        loadDemo()
        XCTAssertTrue(coordinator.isDemoMode)
        XCTAssertTrue(coordinator.hasCompletedSetup)
        if case .setupRequired = coordinator.presentation {
            XCTFail("Demo data loaded but presentation is still setupRequired")
        }
    }

    // MARK: Stratification + grouping + resolution

    func testEpisodesAreGroupedAndWorkoutDipFiresNoEvent() {
        loadDemo()
        // One resolved historical episode + one open live episode. The workout
        // dip (day 10, deep enough to alert) must be excluded by the classifier.
        XCTAssertEqual(coordinator.events.count, 2,
                       "expected exactly 2 grouped episodes, got \(coordinator.events.count)")
    }

    func testHistoricalEpisodeResolvedWithDuration() {
        loadDemo()
        let resolved = coordinator.events.filter { $0.durationHours != nil }
        XCTAssertEqual(resolved.count, 1)
        // Alert fires on the 3rd anomalous slot of day 20 (+6h); recovery is the
        // first slot of day 24 -> 96h - 6h = 90h.
        XCTAssertEqual(resolved.first?.durationHours ?? 0, 90, accuracy: 1.5)
    }

    func testLiveEpisodeStaysOpenAndPresentsAttention() {
        loadDemo()
        let open = coordinator.events.filter { $0.durationHours == nil }
        XCTAssertEqual(open.count, 1)
        guard case let .attention(alertID, _) = coordinator.presentation else {
            return XCTFail("expected .attention, got \(coordinator.presentation)")
        }
        XCTAssertEqual(alertID, open.first?.id)
    }

    func testMarkSeenExitsAttention() {
        loadDemo()
        guard case let .attention(alertID?, _) = coordinator.presentation else {
            return XCTFail("expected .attention with an alert id")
        }
        coordinator.markEventSeen(alertID)
        guard case .stable = coordinator.presentation else {
            return XCTFail("expected .stable after acknowledging, got \(coordinator.presentation)")
        }
    }

    // MARK: Today tab data

    func testTodayEventsExcludesOlderEpisodes() {
        loadDemo()
        // DemoData seeds one live episode (today) + one historical (~11 days ago).
        XCTAssertEqual(coordinator.events.count, 2)
        XCTAssertEqual(coordinator.todayEvents.count, 1)
        let fired = try? XCTUnwrap(coordinator.todayEvents.first).firedAt
        XCTAssertTrue(Calendar.current.isDateInToday(fired ?? .distantPast))
    }

    func testSamplesSinceNarrowsToTheRequestedWindow() {
        loadDemo()
        let all = coordinator.samples(since: TrendRange.all.cutoff())
        let day = coordinator.samples(since: TrendRange.day.cutoff())
        XCTAssertFalse(all.isEmpty)
        XCTAssertLessThan(day.count, all.count, "a one-day window must be narrower than all history")
        XCTAssertTrue(day.allSatisfy { $0.timestamp >= TrendRange.day.cutoff().addingTimeInterval(-60) })
    }

    // MARK: QA state preview knobs (checklist §A)

    func testQALearningStateFewerThanSevenDays() {
        coordinator.loadDemoData(days: 3)
        guard case .learning = coordinator.presentation else {
            return XCTFail("expected .learning, got \(coordinator.presentation)")
        }
    }

    func testQAStaleStateBeyondStalenessWindow() {
        coordinator.loadDemoData(ageOffset: 20 * 3600)
        guard case .unavailable = coordinator.presentation else {
            return XCTFail("expected .unavailable, got \(coordinator.presentation)")
        }
    }

    // MARK: Relevance feedback

    func testRelevanceRoundTripAndUpdateWithoutDuplication() throws {
        loadDemo()
        let event = try XCTUnwrap(coordinator.events.first)
        XCTAssertNil(coordinator.savedRelevance(for: event.id))

        coordinator.saveRelevance("timely", for: event.id)
        XCTAssertEqual(coordinator.savedRelevance(for: event.id), "timely")

        coordinator.saveRelevance("notRelevant", for: event.id)
        XCTAssertEqual(coordinator.savedRelevance(for: event.id), "notRelevant")

        let context = ModelContext(container)
        let all = try context.fetch(FetchDescriptor<GuidedResponse>())
        XCTAssertEqual(all.count, 1, "re-answering must update, not duplicate")
    }
}
