import XCTest
@testable import HRVCore

// Parity with tests/test_detector.py.
final class AnomalyDetectorTests: XCTestCase {
    let healthy: [Double] = [43, 45, 47]  // small spread -> MAD > 0
    let drop = 18.0

    private func config() -> DetectorConfig {
        DetectorConfig(k: 1.75, persistenceWindow: 2, cooldown: 8 * 3600)
    }

    private func buildSeeded(days: Int = 10, perDay: Int = 6) -> (AnomalyDetector, BaselineEngine, Date) {
        let engine = BaselineEngine(windowDays: 60, minBaselineDays: 7)
        let det = AnomalyDetector(engine: engine, config: config())
        var last = day(0)
        var n = 0
        for d in 0..<days {
            for s in 0..<perDay {
                last = day(d, hours: Double(3 * s))
                det.evaluate(timestamp: last, rmssdValue: healthy[n % healthy.count])
                n += 1
            }
        }
        return (det, engine, last)
    }

    func testBaselineEstablishedLeavesLearning() {
        let (det, _, _) = buildSeeded()
        XCTAssertEqual(det.state, .normal)
    }

    func testSustainedDropFiresExactlyOneAlert() {
        let (det, _, last) = buildSeeded()
        var alerts: [AlertEvent] = []
        for i in 0..<5 {  // five drops 1h apart, inside the 8h cooldown
            if let e = det.evaluate(timestamp: last.addingTimeInterval(Double(i + 1) * 3600), rmssdValue: drop) {
                alerts.append(e)
            }
        }
        XCTAssertEqual(alerts.count, 1)
        XCTAssertLessThan(alerts[0].robustZ, -1.75)
        XCTAssertEqual(det.state, .cooldown)
    }

    func testSingleDipDoesNotAlert() {
        let (det, _, last) = buildSeeded()
        let e1 = det.evaluate(timestamp: last.addingTimeInterval(3600), rmssdValue: drop)
        let e2 = det.evaluate(timestamp: last.addingTimeInterval(7200), rmssdValue: 45)
        XCTAssertNil(e1)
        XCTAssertNil(e2)
        XCTAssertEqual(det.state, .normal)
    }

    func testExertionSampleIsIgnored() {
        let (det, engine, last) = buildSeeded()
        let before = engine.sampleCount
        let e = det.evaluate(timestamp: last.addingTimeInterval(3600), rmssdValue: drop,
                             context: SampleContext(isRestful: false))
        XCTAssertNil(e)
        XCTAssertEqual(det.state, .normal)
        XCTAssertEqual(engine.sampleCount, before)  // not ingested
    }

    func testAlertFiresAgainAfterCooldownElapses() {
        let (det, _, last) = buildSeeded()
        var alerts: [AlertEvent] = []
        for i in [1, 2] {  // alert #1 at +2h
            if let e = det.evaluate(timestamp: last.addingTimeInterval(Double(i) * 3600), rmssdValue: drop) {
                alerts.append(e)
            }
        }
        for i in [11, 12] {  // cooldown (8h) elapsed -> alert #2
            if let e = det.evaluate(timestamp: last.addingTimeInterval(Double(i) * 3600), rmssdValue: drop) {
                alerts.append(e)
            }
        }
        XCTAssertEqual(alerts.count, 2)
    }

    func testRestoredBaselineStartsInNormalState() {
        let engine = BaselineEngine(windowDays: 60, minBaselineDays: 7)
        for d in 0..<7 {
            engine.ingest(timestamp: day(d), rmssdValue: healthy[d % healthy.count])
        }

        let restored = AnomalyDetector(engine: engine, config: config())

        XCTAssertEqual(restored.state, .normal)
    }

    func testRestoredRecentAlertPreservesCooldown() {
        let engine = BaselineEngine(windowDays: 60, minBaselineDays: 7)
        for d in 0..<7 {
            engine.ingest(timestamp: day(d), rmssdValue: healthy[d % healthy.count])
        }
        let alertAt = day(7)
        let restored = AnomalyDetector(engine: engine, config: config(), lastAlertAt: alertAt)

        XCTAssertEqual(restored.state, .cooldown)
        XCTAssertNil(restored.evaluate(timestamp: day(7, hours: 1), rmssdValue: 45))
        XCTAssertEqual(restored.state, .cooldown)
        XCTAssertNil(restored.evaluate(timestamp: day(7, hours: 9), rmssdValue: 45))
        XCTAssertEqual(restored.state, .normal)
    }
}
