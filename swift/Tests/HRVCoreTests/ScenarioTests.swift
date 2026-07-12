import XCTest
@testable import HRVCore

// End-to-end detection flow -- the Swift analog of sim/run_scenario.py.
// Asserts the behavioral contract: a sustained drop fires an alert, and a
// healthy (noisy) stream stays silent. Numeric parity is covered by the unit
// tests; this is the integration seam.
final class ScenarioTests: XCTestCase {

    // Deterministic healthy wobble around 45 ms -> MAD > 0, |z| < k for all.
    private let wobble: [Double] = [-3, 0, 3, 1, -2, 2]
    private func healthy(_ i: Int) -> Double { 45.0 + wobble[i % wobble.count] }

    private func makeDetector() -> AnomalyDetector {
        // Defaults: k=2.0, persistence=3, cooldown=8h.
        AnomalyDetector(engine: BaselineEngine(windowDays: 60, minBaselineDays: 7),
                        config: DetectorConfig())
    }

    func testSustainedDropIsDetectedAndHealthyIsSilent() {
        let det = makeDetector()
        var alerts: [AlertEvent] = []
        var n = 0

        // 12 healthy days -> learning then normal, no alerts.
        for d in 0..<12 {
            for s in 0..<6 {
                if let e = det.evaluate(timestamp: day(d, hours: Double(3 * s)), rmssdValue: healthy(n)) {
                    alerts.append(e)
                }
                n += 1
            }
        }
        XCTAssertEqual(det.state, .normal)
        XCTAssertTrue(alerts.isEmpty, "no alerts during healthy learning/normal")

        // 5-day sustained ~50% suppression -> must fire.
        for d in 12..<17 {
            for s in 0..<6 {
                if let e = det.evaluate(timestamp: day(d, hours: Double(3 * s)), rmssdValue: 22.0) {
                    alerts.append(e)
                }
            }
        }
        XCTAssertGreaterThanOrEqual(alerts.count, 1, "sustained drop must fire at least one alert")
    }

    func testHealthyOnlyProducesNoAlerts() {
        let det = makeDetector()
        var alerts = 0
        var n = 0
        for d in 0..<25 {
            for s in 0..<6 {
                if det.evaluate(timestamp: day(d, hours: Double(3 * s)), rmssdValue: healthy(n)) != nil {
                    alerts += 1
                }
                n += 1
            }
        }
        XCTAssertEqual(alerts, 0, "healthy stream must not produce false positives")
    }
}
