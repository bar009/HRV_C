import XCTest
@testable import HRVCore

final class CalibrationTests: XCTestCase {
    /// Today the config is intentionally identical for every sex (the personal
    /// baseline already self-normalizes). This guards against an accidental,
    /// unvalidated divergence sneaking in before the calibration study.
    func testConfigIsNeutralAcrossSexForNow() {
        let base = DetectorConfig(k: 2.0, persistenceWindow: 3)
        for sex in BiologicalSex.allCases {
            let c = CalibrationProfiles.config(for: CalibrationProfile(sex: sex), base: base)
            XCTAssertEqual(c.k, base.k)
            XCTAssertEqual(c.persistenceWindow, base.persistenceWindow)
            XCTAssertEqual(c.cooldown, base.cooldown)
        }
    }

    func testProfileRoundTripsThroughRawValue() {
        for sex in BiologicalSex.allCases {
            XCTAssertEqual(BiologicalSex(rawValue: sex.rawValue), sex)
        }
    }
}
