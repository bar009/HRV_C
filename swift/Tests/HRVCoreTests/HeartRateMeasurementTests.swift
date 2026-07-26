import XCTest
@testable import HRVCore

/// The BLE payload parser is the one place unknown third-party hardware can
/// hand us arbitrary bytes, so malformed input must return nil rather than trap.
final class HeartRateMeasurementTests: XCTestCase {

    private func rrBytes(_ ms: Double) -> [UInt8] {
        let raw = UInt16((ms / HeartRateMeasurement.rrTickMs).rounded())
        return [UInt8(raw & 0xFF), UInt8(raw >> 8)]
    }

    func testEightBitHeartRateNoRR() {
        // flags 0x00 -> 8-bit HR, no energy, no RR
        let m = HeartRateMeasurement.parse([0x00, 60])
        XCTAssertEqual(m?.bpm, 60)
        XCTAssertEqual(m?.rrIntervalsMs, [])
        XCTAssertEqual(m?.hasRR, false)
    }

    func testSixteenBitHeartRate() {
        // flags 0x01 -> 16-bit HR, little-endian 300
        let m = HeartRateMeasurement.parse([0x01, 0x2C, 0x01])
        XCTAssertEqual(m?.bpm, 300)
    }

    func testSingleRRInterval() {
        // flags 0x10 -> RR present
        let m = HeartRateMeasurement.parse([0x10, 60] + rrBytes(1000))
        XCTAssertEqual(m?.bpm, 60)
        XCTAssertEqual(m?.rrIntervalsMs.count, 1)
        XCTAssertEqual(m?.rrIntervalsMs.first ?? 0, 1000, accuracy: 1.0)
        XCTAssertEqual(m?.hasRR, true)
    }

    func testMultipleRRIntervalsInOnePacket() {
        // A strap often batches 2-3 beats into a single notification.
        let m = HeartRateMeasurement.parse([0x10, 62] + rrBytes(800) + rrBytes(820) + rrBytes(790))
        XCTAssertEqual(m?.rrIntervalsMs.count, 3)
        XCTAssertEqual(m?.rrIntervalsMs[1] ?? 0, 820, accuracy: 1.0)
    }

    func testEnergyExpendedOffsetIsSkippedBeforeRR() {
        // flags 0x18 -> energy expended (2 bytes) + RR. If the offset were
        // mishandled the RR value would be garbage.
        let m = HeartRateMeasurement.parse([0x18, 60, 0xFF, 0x00] + rrBytes(900))
        XCTAssertEqual(m?.bpm, 60)
        XCTAssertEqual(m?.rrIntervalsMs.count, 1)
        XCTAssertEqual(m?.rrIntervalsMs.first ?? 0, 900, accuracy: 1.0)
    }

    func testWideHeartRateWithEnergyAndRR() {
        let m = HeartRateMeasurement.parse([0x19, 0x2C, 0x01, 0x10, 0x00] + rrBytes(700))
        XCTAssertEqual(m?.bpm, 300)
        XCTAssertEqual(m?.rrIntervalsMs.first ?? 0, 700, accuracy: 1.0)
    }

    // MARK: malformed input

    func testEmptyPayloadReturnsNil() {
        XCTAssertNil(HeartRateMeasurement.parse([]))
    }

    func testFlagsOnlyReturnsNil() {
        XCTAssertNil(HeartRateMeasurement.parse([0x00]))
    }

    func testTruncatedWideHeartRateReturnsNil() {
        XCTAssertNil(HeartRateMeasurement.parse([0x01, 0x2C]))
    }

    func testTruncatedEnergyFieldReturnsNil() {
        // Claims energy expended but only one byte of it -> offsets untrustworthy.
        XCTAssertNil(HeartRateMeasurement.parse([0x18, 60, 0xFF]))
    }

    func testOddTrailingByteIsIgnoredNotFatal() {
        let m = HeartRateMeasurement.parse([0x10, 60] + rrBytes(1000) + [0x07])
        XCTAssertEqual(m?.rrIntervalsMs.count, 1)
    }

    func testRRFlagSetButNoDataYieldsEmpty() {
        let m = HeartRateMeasurement.parse([0x10, 60])
        XCTAssertEqual(m?.bpm, 60)
        XCTAssertEqual(m?.rrIntervalsMs, [])
    }
}
