import XCTest
@testable import HRVCore

final class EventShapeTests: XCTestCase {
    func testDeepDropIsAcute() {
        XCTAssertEqual(EventShapeClassifier.classify(robustZ: -3.0), .acute)
        XCTAssertEqual(EventShapeClassifier.classify(robustZ: -5.2), .acute)
    }

    func testShallowDropIsSustained() {
        // Past the ~2.0 detection threshold but not deep -> low-grade/sustained.
        XCTAssertEqual(EventShapeClassifier.classify(robustZ: -2.1), .sustained)
        XCTAssertEqual(EventShapeClassifier.classify(robustZ: -2.9), .sustained)
    }

    func testSignAgnostic() {
        // Magnitude drives it; a positive z of the same depth reads the same.
        XCTAssertEqual(EventShapeClassifier.classify(robustZ: 3.0), .acute)
    }
}
