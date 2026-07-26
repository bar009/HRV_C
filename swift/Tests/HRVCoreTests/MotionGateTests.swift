import XCTest
@testable import HRVCore

final class MotionGateTests: XCTestCase {
    private let t0 = Date(timeIntervalSince1970: 1_700_000_000)

    func testStatesClassifyRestCorrectly() {
        XCTAssertTrue(MotionState.stationary.isAtRest)
        XCTAssertFalse(MotionState.walking.isAtRest)
        XCTAssertFalse(MotionState.running.isAtRest)
        XCTAssertFalse(MotionState.cycling.isAtRest)
        XCTAssertFalse(MotionState.automotive.isAtRest)
    }

    /// Missing motion data must not disable detection outright.
    func testUnknownIsTreatedAsRestful() {
        var gate = MotionGate()
        XCTAssertTrue(MotionState.unknown.isAtRest)
        gate.record(.unknown, at: t0)
        XCTAssertTrue(gate.isRestful(at: t0))
    }

    func testNoMotionEverRecordedIsRestful() {
        let gate = MotionGate()
        XCTAssertTrue(gate.isRestful(at: t0))
    }

    func testStationaryStaysRestful() {
        var gate = MotionGate()
        gate.record(.stationary, at: t0)
        XCTAssertTrue(gate.isRestful(at: t0.addingTimeInterval(10)))
    }

    func testWalkingBlocksTheWindowAndTheRecoveryBuffer() {
        var gate = MotionGate(recoverySeconds: 120, windowSeconds: 120)
        gate.record(.walking, at: t0)
        // Immediately after, and through the window + recovery span (240 s).
        XCTAssertFalse(gate.isRestful(at: t0))
        XCTAssertFalse(gate.isRestful(at: t0.addingTimeInterval(120)))
        XCTAssertFalse(gate.isRestful(at: t0.addingTimeInterval(239)))
        // Past it, rest resumes.
        XCTAssertTrue(gate.isRestful(at: t0.addingTimeInterval(241)))
    }

    func testReturningToStationaryDoesNotClearTheBufferEarly() {
        var gate = MotionGate(recoverySeconds: 120, windowSeconds: 120)
        gate.record(.walking, at: t0)
        gate.record(.stationary, at: t0.addingTimeInterval(5))
        // HRV is still suppressed right after movement.
        XCTAssertFalse(gate.isRestful(at: t0.addingTimeInterval(60)))
    }

    func testSampleContextMirrorsTheGate() {
        var gate = MotionGate()
        gate.record(.running, at: t0)
        XCTAssertFalse(gate.sampleContext(at: t0).isRestful)
        XCTAssertTrue(gate.sampleContext(at: t0.addingTimeInterval(1000)).isRestful)
    }

    func testResetClearsMovementHistory() {
        var gate = MotionGate()
        gate.record(.walking, at: t0)
        gate.reset()
        XCTAssertTrue(gate.isRestful(at: t0))
        XCTAssertEqual(gate.current, .unknown)
    }

    // MARK: capability wiring

    func testLiveTriggersAreApproximateWithoutMotionGating() {
        // A strap with no motion source still detects, but will misfire on
        // movement -- the UI must say so rather than imply precision.
        let ungated = SensorCapabilities.bleChestStrap
        XCTAssertEqual(IndicatorResolver.availability(of: .liveTriggers, given: ungated),
                       .approximate(.needsMotionAccess))

        var gated = ungated
        gated.motionContext = true
        XCTAssertEqual(IndicatorResolver.availability(of: .liveTriggers, given: gated), .available)
    }
}
