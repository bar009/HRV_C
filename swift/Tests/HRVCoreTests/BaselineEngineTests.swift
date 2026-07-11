import XCTest
@testable import HRVCore

// Parity with tests/test_baseline.py.
final class BaselineEngineTests: XCTestCase {

    func testMedianAndMadOnLnScale() {
        let engine = BaselineEngine(windowDays: 60, minBaselineDays: 1)
        let vals: [Double] = [40, 45, 50, 45, 40, 50, 45]
        for (i, v) in vals.enumerated() { engine.ingest(timestamp: day(i), rmssdValue: v) }
        let b = engine.currentBaseline(asOf: day(vals.count))!
        let xs = vals.map { log($0) }
        XCTAssertEqual(b.median, Statistics.median(xs), accuracy: 1e-12)
        XCTAssertEqual(b.mad, Statistics.mad(xs), accuracy: 1e-12)
        XCTAssertEqual(b.sampleCount, vals.count)
    }

    func testLearningUntilMinDays() {
        let engine = BaselineEngine(minBaselineDays: 7)
        for i in 0..<5 { engine.ingest(timestamp: day(i), rmssdValue: 45) }
        XCTAssertNil(engine.currentBaseline(asOf: day(5)))
        XCTAssertFalse(engine.hasMinBaseline())
    }

    func testWindowEvictsOldSamples() {
        let engine = BaselineEngine(windowDays: 10, minBaselineDays: 1)
        engine.ingest(timestamp: day(0), rmssdValue: 40)
        engine.ingest(timestamp: day(20), rmssdValue: 50)
        let b = engine.currentBaseline(asOf: day(20))!
        XCTAssertEqual(b.sampleCount, 1)  // day-0 sample fell outside the 10-day window
        XCTAssertEqual(b.median, log(50), accuracy: 1e-12)
    }

    func testNonPositiveValueIgnored() {
        let engine = BaselineEngine(minBaselineDays: 1)
        engine.ingest(timestamp: day(0), rmssdValue: 0)
        engine.ingest(timestamp: day(0), rmssdValue: -5)
        XCTAssertEqual(engine.distinctDays(), 0)
    }

    func testLowerBoundUsesScaledMad() {
        let engine = BaselineEngine(minBaselineDays: 1, k: 2.0)
        for (i, v) in [40.0, 45.0, 50.0].enumerated() { engine.ingest(timestamp: day(i), rmssdValue: v) }
        let b = engine.currentBaseline()!
        XCTAssertEqual(b.lowerBound, b.median - 2.0 * 1.4826 * b.mad, accuracy: 1e-12)
    }
}
