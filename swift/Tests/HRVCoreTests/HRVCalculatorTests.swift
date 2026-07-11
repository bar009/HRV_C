import XCTest
@testable import HRVCore

// Parity with tests/test_calculator.py.
final class HRVCalculatorTests: XCTestCase {
    let nn: [Double] = [800, 850, 800, 820, 810]  // diffs: 50, -50, 20, -10

    func testRmssdKnown() {
        // squares 2500,2500,400,100 -> mean 1375
        XCTAssertEqual(HRVCalculator.rmssd(nn)!, (1375.0).squareRoot(), accuracy: 1e-9)
    }

    func testSdnnSampleStdev() {
        // mean 816; variance = 1720 / (5-1) = 430
        XCTAssertEqual(HRVCalculator.sdnn(nn)!, (430.0).squareRoot(), accuracy: 1e-9)
    }

    func testPnn50Known() {
        let v: [Double] = [800, 900, 820, 870]  // diffs 100,-80,50 -> two are > 50ms
        XCTAssertEqual(HRVCalculator.pnn50(v)!, 200.0 / 3.0, accuracy: 1e-9)
    }

    func testSdsdSampleStdevOfDiffs() {
        let diffs: [Double] = [50, -50, 20, -10]
        let mean = diffs.reduce(0, +) / Double(diffs.count)
        let variance = diffs.map { ($0 - mean) * ($0 - mean) }.reduce(0, +) / Double(diffs.count - 1)
        XCTAssertEqual(HRVCalculator.sdsd(nn)!, variance.squareRoot(), accuracy: 1e-9)
    }

    func testShortInputReturnsNil() {
        XCTAssertNil(HRVCalculator.rmssd([800]))
        XCTAssertNil(HRVCalculator.sdnn([]))
        XCTAssertNil(HRVCalculator.pnn50([800]))
    }

    func testSdsdNeedsThreeIntervals() {
        XCTAssertNil(HRVCalculator.sdsd([800, 810]))
    }
}
