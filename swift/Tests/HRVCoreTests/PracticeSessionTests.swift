import XCTest
@testable import HRVCore

final class PracticeSessionTests: XCTestCase {
    func testInterruptedSessionRetainsElapsedTime() {
        var session = PracticeSessionState(protocolID: "long-release", goal: .calming)
        session.start()
        session.tick(seconds: 42)
        session.interrupt()
        XCTAssertEqual(session.status, .interrupted)
        XCTAssertEqual(session.elapsedSeconds, 42)
    }

    func testDiscomfortStopsSessionAndRetainsReason() {
        var session = PracticeSessionState(protocolID: "long-release", goal: .calming)
        session.start()
        session.markUncomfortable(reason: "air hunger")
        session.tick(seconds: 10)
        XCTAssertEqual(session.status, .uncomfortable)
        XCTAssertEqual(session.elapsedSeconds, 0)
        XCTAssertEqual(session.discomfortReason, "air hunger")
    }

    func testSlowDownIsBounded() {
        var session = PracticeSessionState(protocolID: "long-release", goal: .calming)
        session.start()
        for _ in 0..<20 { session.slowDown() }
        XCTAssertEqual(session.paceScale, 1.5, accuracy: 0.001)
    }

    func testWatchCannotCreateRRorCoherenceMetric() {
        XCTAssertNil(LiveMetric(kind: .trueRRMilliseconds, value: 850,
                                sensorMode: .watchEstimatedRhythm))
        XCTAssertNil(LiveMetric(kind: .coherence, value: 72,
                                sensorMode: .watchEstimatedRhythm))
        XCTAssertNotNil(LiveMetric(kind: .estimatedRhythm, value: 72,
                                   sensorMode: .watchEstimatedRhythm))
    }

    func testPolarCanCreateTrueRRAndCoherence() {
        XCTAssertNotNil(LiveMetric(kind: .trueRRMilliseconds, value: 850,
                                   sensorMode: .polarRR))
        XCTAssertNotNil(LiveMetric(kind: .coherence, value: 72,
                                   sensorMode: .polarRR))
    }
}
