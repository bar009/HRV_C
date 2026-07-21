// Trends windowing + series aggregation (pure logic, no view involved).
import XCTest
import HRVCore
@testable import HRV_Phone

final class TrendRangeTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 1_700_000_000)

    // MARK: cutoffs

    func testCutoffsMatchTheirWindows() {
        XCTAssertEqual(TrendRange.day.cutoff(from: now).timeIntervalSince(now), -86_400, accuracy: 1)
        XCTAssertEqual(TrendRange.week.cutoff(from: now).timeIntervalSince(now), -7 * 86_400, accuracy: 1)
        XCTAssertEqual(TrendRange.month.cutoff(from: now).timeIntervalSince(now), -30 * 86_400, accuracy: 1)
    }

    func testAllReachesBackPastAnyStoredSample() {
        XCTAssertEqual(TrendRange.all.cutoff(from: now), .distantPast)
    }

    func testOnlyDayIsIntraday() {
        XCTAssertTrue(TrendRange.day.isIntraday)
        for range in [TrendRange.week, .month, .all] {
            XCTAssertFalse(range.isIntraday, "\(range) should aggregate to daily medians")
        }
    }

    // MARK: series building

    private func sample(_ offsetHours: Double, _ ms: Double) -> ProcessedHRVSample {
        ProcessedHRVSample(timestamp: now.addingTimeInterval(offsetHours * 3600),
                           lnRmssd: log(ms), rawValueMs: ms,
                           metric: "sdnnApple", quality: "high",
                           context: "rest", source: "healthKitDirect")
    }

    func testIntradayKeepsEverySampleInTimeOrder() {
        let samples = [sample(2, 50), sample(0, 40), sample(1, 45)]
        let points = TrendSeries.points(for: samples, range: .day)
        XCTAssertEqual(points.count, 3, "a single day must not be collapsed to one point")
        XCTAssertEqual(points.map(\.valueMs), [40, 45, 50])
    }

    /// Day grouping is calendar-dependent, so this pins the calendar to UTC and
    /// anchors on a UTC midnight -- otherwise the result changes with the
    /// simulator's time zone.
    func testLongerRangesCollapseEachDayToItsMedian() {
        var utc = Calendar(identifier: .gregorian)
        utc.timeZone = TimeZone(secondsFromGMT: 0)!
        let midnightUTC = Date(timeIntervalSince1970: 1_699_920_000)  // 2023-11-14 00:00 UTC
        func at(_ hours: Double, _ ms: Double) -> ProcessedHRVSample {
            ProcessedHRVSample(timestamp: midnightUTC.addingTimeInterval(hours * 3600),
                               lnRmssd: log(ms), rawValueMs: ms,
                               metric: "sdnnApple", quality: "high",
                               context: "rest", source: "healthKitDirect")
        }
        // Three samples on one UTC day (median 45) + one the next UTC day.
        let samples = [at(1, 40), at(2, 45), at(3, 80), at(25, 30)]
        let points = TrendSeries.dailyMedians(samples, calendar: utc)
        XCTAssertEqual(points.count, 2)
        XCTAssertEqual(points.first?.valueMs, 45, "median, not mean -- 80 must not drag the day up")
        XCTAssertEqual(points.last?.valueMs, 30)
    }

    /// Routing check that doesn't depend on where day boundaries fall.
    func testNonIntradayRangesAggregate() {
        let samples = (0..<6).map { sample(Double($0), 40 + Double($0)) }
        let aggregated = TrendSeries.points(for: samples, range: .month)
        XCTAssertLessThan(aggregated.count, samples.count,
                          "longer ranges must group samples, not plot each one")
    }

    func testMedianOfEvenCountAveragesTheMiddlePair() {
        XCTAssertEqual(TrendSeries.median([10, 20, 30, 40]), 25)
    }

    func testEmptySamplesProduceNoPoints() {
        XCTAssertTrue(TrendSeries.points(for: [], range: .week).isEmpty)
        XCTAssertTrue(TrendSeries.points(for: [], range: .day).isEmpty)
    }
}
