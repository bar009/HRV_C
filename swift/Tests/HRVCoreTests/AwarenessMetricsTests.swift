import XCTest
@testable import HRVCore

final class AwarenessMetricsTests: XCTestCase {
    func testAverageIgnoresNegativesAndEmpties() {
        XCTAssertNil(AwarenessMetrics.average([]))
        XCTAssertNil(AwarenessMetrics.average([-10, -1]))
        XCTAssertEqual(AwarenessMetrics.average([3600, 7200]) ?? 0, 5400, accuracy: 0.001)
    }

    func testImprovingNeedsEnoughHistory() {
        XCTAssertNil(AwarenessMetrics.isImproving(chronological: [100, 200, 300]))
    }

    func testImprovingWhenRecentGapsAreShorter() {
        // Older half slow (long gaps), recent half quick -> improving.
        XCTAssertEqual(AwarenessMetrics.isImproving(chronological: [10_000, 9_000, 1_000, 800]), true)
    }

    func testNotImprovingWhenRecentGapsAreLonger() {
        XCTAssertEqual(AwarenessMetrics.isImproving(chronological: [800, 1_000, 9_000, 10_000]), false)
    }
}
