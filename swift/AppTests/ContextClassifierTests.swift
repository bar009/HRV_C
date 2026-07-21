// Track H -- unit tests for the rest/sleep/active classifier.
import XCTest
@testable import HRV_Phone

final class ContextClassifierTests: XCTestCase {
    private let base = Date(timeIntervalSince1970: 1_700_000_000)

    func testDefaultIsRest() {
        let c = ContextClassifier()
        XCTAssertEqual(c.label(at: base), "rest")
        XCTAssertTrue(c.context(at: base).isRestful)
        XCTAssertFalse(c.context(at: base).isSleep)
    }

    func testWorkoutTagsActiveIncludingRecoveryBuffer() {
        let workout = DateInterval(start: base, end: base.addingTimeInterval(30 * 60))
        let c = ContextClassifier(workouts: [workout])

        // During the workout.
        XCTAssertEqual(c.label(at: base.addingTimeInterval(10 * 60)), "active")
        XCTAssertFalse(c.context(at: base.addingTimeInterval(10 * 60)).isRestful)
        // Inside the 45-minute recovery buffer after it ends.
        XCTAssertEqual(c.label(at: workout.end.addingTimeInterval(44 * 60)), "active")
        // After the buffer expires.
        XCTAssertEqual(c.label(at: workout.end.addingTimeInterval(46 * 60)), "rest")
    }

    func testSleepTagsSleepButStaysRestful() {
        let night = DateInterval(start: base, end: base.addingTimeInterval(7 * 3600))
        let c = ContextClassifier(sleep: [night])
        let during = base.addingTimeInterval(3600)
        XCTAssertEqual(c.label(at: during), "sleep")
        XCTAssertTrue(c.context(at: during).isRestful)
        XCTAssertTrue(c.context(at: during).isSleep)
    }

    func testActiveWinsOverSleepOverlap() {
        let interval = DateInterval(start: base, end: base.addingTimeInterval(3600))
        let c = ContextClassifier(workouts: [interval], sleep: [interval])
        XCTAssertEqual(c.label(at: base.addingTimeInterval(60)), "active")
    }
}
