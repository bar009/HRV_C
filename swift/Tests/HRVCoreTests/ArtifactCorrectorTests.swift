import XCTest
@testable import HRVCore

// Parity with tests/test_artifact.py.
final class ArtifactCorrectorTests: XCTestCase {

    func testOutOfRangeRejected() {
        let ac = ArtifactCorrector(minValidBeats: 1, maxRejectRatio: 1.0)
        let res = ac.clean([100, 800, 3000, 810])
        XCTAssertEqual(res.nn, [800, 810])
        XCTAssertEqual(res.rejected, 2)
    }

    func testMalikRejectsEctopic() {
        let ac = ArtifactCorrector(minValidBeats: 1, maxRejectRatio: 1.0)
        let res = ac.clean([800, 810, 1300, 805])
        XCTAssertEqual(res.nn, [800, 810, 805])
        XCTAssertEqual(res.rejected, 1)
    }

    func testSingleArtifactDoesNotPoisonChain() {
        let ac = ArtifactCorrector(minValidBeats: 1, maxRejectRatio: 1.0)
        let res = ac.clean([800, 810, 1300, 820])
        XCTAssertEqual(res.nn, [800, 810, 820])
    }

    func testLowQualityWhenTooFewBeats() {
        let ac = ArtifactCorrector(minValidBeats: 30)
        XCTAssertEqual(ac.clean([800, 810, 805]).quality, .low)
    }

    func testLowQualityWhenRejectRatioHigh() {
        let ac = ArtifactCorrector(minValidBeats: 1, maxRejectRatio: 0.20)
        XCTAssertEqual(ac.clean([100, 3000, 800, 810]).quality, .low)  // 2/4 = 50% > 20%
    }

    func testHighQualityEnoughCleanBeats() {
        let ac = ArtifactCorrector(minValidBeats: 30)
        let rr = (0..<50).map { 800.0 + Double($0 % 5) }
        let res = ac.clean(rr)
        XCTAssertEqual(res.rejected, 0)
        XCTAssertEqual(res.quality, .high)
    }

    func testEmptyInputIsLowQuality() {
        let res = ArtifactCorrector().clean([])
        XCTAssertTrue(res.nn.isEmpty)
        XCTAssertEqual(res.quality, .low)
    }
}
