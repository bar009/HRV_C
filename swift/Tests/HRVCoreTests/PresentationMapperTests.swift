import XCTest
@testable import HRVCore

// Detector -> presentation mapping. Parity with tests/test_presentation.py.
final class PresentationMapperTests: XCTestCase {

    private func input(_ s: DetectorState, setup: Bool = true, recent: Bool = true) -> PresentationInput {
        PresentationInput(detectorState: s, hasCompletedSetup: setup, hasReliableRecentSample: recent)
    }

    func testNotSetUpIsAlwaysSetupRequired() {
        for s in [DetectorState.learning, .normal, .watching, .alert, .cooldown] {
            XCTAssertEqual(PresentationMapper.map(input(s, setup: false)).kind, .setupRequired)
        }
    }

    func testStaleIsAlwaysUnavailable() {
        for s in [DetectorState.normal, .watching, .alert, .cooldown] {
            XCTAssertEqual(PresentationMapper.map(input(s, recent: false)).kind, .unavailable)
        }
    }

    func testLearningMapsToLearning() {
        XCTAssertEqual(PresentationMapper.map(input(.learning)).kind, .learning)
    }

    func testNormalMapsToStable() {
        XCTAssertEqual(PresentationMapper.map(input(.normal)).kind, .stable)
    }

    func testWatchingIsHiddenAsStable() {
        XCTAssertEqual(PresentationMapper.map(input(.watching)).kind, .stable)
    }

    func testCooldownIsHiddenAsStable() {
        XCTAssertEqual(PresentationMapper.map(input(.cooldown)).kind, .stable)
    }

    func testAlertMapsToAttention() {
        XCTAssertEqual(PresentationMapper.map(input(.alert)).kind, .attention)
    }

    func testLearningCarriesProgress() {
        let state = PresentationMapper.map(PresentationInput(
            detectorState: .learning, hasCompletedSetup: true, hasReliableRecentSample: true,
            learningDay: 4, learningTotalDays: 7))
        guard case let .learning(day, total) = state else { return XCTFail("expected learning") }
        XCTAssertEqual(day, 4)
        XCTAssertEqual(total, 7)
    }
}
