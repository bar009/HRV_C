// Event context assembly (pure logic; no HealthKit, no SwiftData).
import XCTest
@testable import HRV_Phone

final class EventContextTests: XCTestCase {
    private var cal = Calendar(identifier: .gregorian)
    private let noonUTC = Date(timeIntervalSince1970: 1_699_963_200)  // 2023-11-14 12:00 UTC

    override func setUp() {
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
    }

    private func night(endingHoursBeforeNoon h: Double, lengthHours len: Double) -> DateInterval {
        let end = noonUTC.addingTimeInterval(-h * 3600)
        return DateInterval(start: end.addingTimeInterval(-len * 3600), end: end)
    }

    // MARK: sleep

    func testSleepSumsTheNightsFragmentsForTheEventsDay() {
        let fragments = [night(endingHoursBeforeNoon: 5, lengthHours: 3),
                         night(endingHoursBeforeNoon: 8, lengthHours: 1.5)]
        let hours = EventContextBuilder.sleepHours(before: noonUTC, in: fragments, calendar: cal)
        XCTAssertEqual(hours ?? 0, 4.5, accuracy: 0.01)
    }

    func testSleepIgnoresNightsFromOtherDays() {
        let lastNight = night(endingHoursBeforeNoon: 5, lengthHours: 7)
        let weekAgo = DateInterval(start: noonUTC.addingTimeInterval(-7 * 86_400),
                                   end: noonUTC.addingTimeInterval(-7 * 86_400 + 3600))
        let hours = EventContextBuilder.sleepHours(before: noonUTC, in: [lastNight, weekAgo], calendar: cal)
        XCTAssertEqual(hours ?? 0, 7, accuracy: 0.01)
    }

    func testUsualSleepIsMedianAcrossNightsAndNeedsAtLeastTwo() {
        let nights = (1...3).map { d in
            DateInterval(start: noonUTC.addingTimeInterval(-Double(d) * 86_400 - 6 * 3600),
                         end: noonUTC.addingTimeInterval(-Double(d) * 86_400))
        }
        XCTAssertEqual(EventContextBuilder.usualSleepHours(from: nights, calendar: cal) ?? 0, 6, accuracy: 0.01)
        XCTAssertNil(EventContextBuilder.usualSleepHours(from: [nights[0]], calendar: cal),
                     "one night isn't enough to call something 'usual'")
    }

    // MARK: workout

    func testMostRecentWorkoutWithinLookbackWins() {
        let recent = DateInterval(start: noonUTC.addingTimeInterval(-3 * 3600),
                                  end: noonUTC.addingTimeInterval(-2 * 3600))   // ended 2h before
        let older = DateInterval(start: noonUTC.addingTimeInterval(-9 * 3600),
                                 end: noonUTC.addingTimeInterval(-8 * 3600))
        let since = EventContextBuilder.hoursSinceWorkout(before: noonUTC, in: [older, recent])
        XCTAssertEqual(since ?? 0, 2, accuracy: 0.01)
    }

    func testWorkoutsBeyondLookbackAreIgnored() {
        let old = DateInterval(start: noonUTC.addingTimeInterval(-14 * 3600),
                               end: noonUTC.addingTimeInterval(-13 * 3600))    // 13h before > 12h window
        XCTAssertNil(EventContextBuilder.hoursSinceWorkout(before: noonUTC, in: [old]))
    }

    func testWorkoutsAfterTheEventAreIgnored() {
        let later = DateInterval(start: noonUTC.addingTimeInterval(3600),
                                 end: noonUTC.addingTimeInterval(2 * 3600))
        XCTAssertNil(EventContextBuilder.hoursSinceWorkout(before: noonUTC, in: [later]))
    }

    // MARK: highlighting (emphasis only, never causal)

    func testBelowUsualSleepAndAboveUsualRestingHRAreFlagged() {
        let ctx = EventContext(sleepHours: 4.5, usualSleepHours: 7,
                               hoursSinceWorkout: nil,
                               restingHeartRate: 62, usualRestingHeartRate: 55)
        XCTAssertTrue(ctx.sleepIsBelowUsual)
        XCTAssertTrue(ctx.restingHeartRateIsAboveUsual)
        XCTAssertFalse(ctx.isEmpty)
    }

    func testNormalValuesAreNotFlagged() {
        let ctx = EventContext(sleepHours: 7, usualSleepHours: 7,
                               hoursSinceWorkout: nil,
                               restingHeartRate: 55, usualRestingHeartRate: 55)
        XCTAssertFalse(ctx.sleepIsBelowUsual)
        XCTAssertFalse(ctx.restingHeartRateIsAboveUsual)
    }

    func testEmptyContextIsEmpty() {
        XCTAssertTrue(EventContext().isEmpty)
    }
}
