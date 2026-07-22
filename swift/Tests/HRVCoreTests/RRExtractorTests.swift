import XCTest
@testable import HRVCore

// Beat-series pipeline (A.6.1). Deterministic synthetic RR arrays.
final class RRExtractorTests: XCTestCase {

    func testRRIntervalsFromBeatTimes() {
        // Beat times in seconds -> RR in ms.
        let rr = RRExtractor.rrIntervals(fromBeatTimes: [0, 0.8, 1.6, 2.4])
        XCTAssertEqual(rr.count, 3)
        for v in rr { XCTAssertEqual(v, 800, accuracy: 1e-6) }
    }

    func testRRIntervalsSortAndNeedTwoBeats() {
        let rr = RRExtractor.rrIntervals(fromBeatTimes: [1.6, 0, 0.8])
        XCTAssertEqual(rr.count, 2)
        for v in rr { XCTAssertEqual(v, 800, accuracy: 1e-6) }
        XCTAssertTrue(RRExtractor.rrIntervals(fromBeatTimes: [0.8]).isEmpty)
    }

    /// A clean 40-beat window (all in range, within Malik 20%) -> high quality
    /// and metrics equal to HRVCalculator over the same intervals.
    func testCleanWindowComputesAllMetrics() {
        let pattern: [Double] = [800, 820, 810, 790, 805]
        let rr = (0..<8).flatMap { _ in pattern }   // 40 intervals
        let m = RRExtractor.metrics(fromRR: rr)
        XCTAssertEqual(m.quality, .high)
        XCTAssertEqual(m.beatCount, 40)
        XCTAssertEqual(m.rmssd!, HRVCalculator.rmssd(rr)!, accuracy: 1e-9)
        XCTAssertEqual(m.sdnn!, HRVCalculator.sdnn(rr)!, accuracy: 1e-9)
        XCTAssertEqual(m.pnn50!, HRVCalculator.pnn50(rr)!, accuracy: 1e-9)
        XCTAssertEqual(m.sdsd!, HRVCalculator.sdsd(rr)!, accuracy: 1e-9)
        XCTAssertTrue(m.isUsable)
    }

    /// Too few beats -> low quality, nil metrics (never emit a noisy value).
    func testShortWindowIsLowQualityWithNilMetrics() {
        let m = RRExtractor.metrics(fromRR: [800, 810, 805])
        XCTAssertEqual(m.quality, .low)
        XCTAssertNil(m.rmssd)
        XCTAssertNil(m.sdnn)
        XCTAssertFalse(m.isUsable)
    }

    /// Out-of-range beats are dropped before the math.
    func testPhysiologicalOutliersAreRejected() {
        var rr = Array(repeating: 800.0, count: 40)
        rr.insert(4000, at: 10)   // impossible RR -> filtered
        let m = RRExtractor.metrics(fromRR: rr)
        XCTAssertEqual(m.quality, .high)
        XCTAssertEqual(m.beatCount, 40, "the 4000ms outlier should not survive")
    }
}
