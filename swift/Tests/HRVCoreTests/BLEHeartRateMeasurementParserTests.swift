import XCTest
@testable import HRVCore

final class BLEHeartRateMeasurementParserTests: XCTestCase {
    func testParsesEightBitHeartRateAndRR() {
        // Flags: RR present. HR=60. RR=1024 units => 1000 ms.
        let value = BLEHeartRateMeasurementParser.parse([0x10, 60, 0x00, 0x04])
        XCTAssertEqual(value?.bpm, 60)
        XCTAssertEqual(value?.rrMilliseconds.first ?? 0, 1000, accuracy: 0.001)
    }

    func testParsesMultipleRRIntervals() {
        let value = BLEHeartRateMeasurementParser.parse([
            0x10, 75,
            0x33, 0x03, // 819 units
            0x66, 0x03  // 870 units
        ])
        XCTAssertEqual(value?.rrMilliseconds.count, 2)
        XCTAssertEqual(value?.rrMilliseconds[0] ?? 0, 799.805, accuracy: 0.001)
        XCTAssertEqual(value?.rrMilliseconds[1] ?? 0, 849.609, accuracy: 0.001)
    }

    func testParsesSixteenBitHeartRateWithEnergyAndRR() {
        // Flags: uint16 HR + energy + RR.
        let value = BLEHeartRateMeasurementParser.parse([
            0x19, 0x2C, 0x01, 0x10, 0x00, 0x00, 0x04
        ])
        XCTAssertEqual(value?.bpm, 300)
        XCTAssertEqual(value?.rrMilliseconds, [1000])
    }

    func testRejectsTruncatedPayload() {
        XCTAssertNil(BLEHeartRateMeasurementParser.parse([]))
        XCTAssertNil(BLEHeartRateMeasurementParser.parse([0x01, 60]))
        XCTAssertNil(BLEHeartRateMeasurementParser.parse([0x08, 60, 0x01]))
    }
}
