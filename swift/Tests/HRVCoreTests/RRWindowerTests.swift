import XCTest
@testable import HRVCore

final class RRWindowerTests: XCTestCase {
    private let t0 = Date(timeIntervalSince1970: 1_700_000_000)

    /// Feed `count` beats at ~1 s apart starting at `from`, returning every
    /// window the windower emitted along the way.
    private func feed(_ w: inout RRWindower, beats: Int, from: Date, rrMs: Double = 1000) -> [[Double]] {
        var windows: [[Double]] = []
        for i in 0..<beats {
            let t = from.addingTimeInterval(Double(i) * (rrMs / 1000))
            if let win = w.add([rrMs], at: t) { windows.append(win) }
        }
        return windows
    }

    func testNoWindowBeforeMinBeats() {
        var w = RRWindower(windowSeconds: 120, stepSeconds: 30, minBeats: 60)
        let windows = feed(&w, beats: 59, from: t0)
        XCTAssertTrue(windows.isEmpty)
        XCTAssertEqual(w.bufferedBeats, 59)
    }

    func testFirstWindowEmitsAtMinBeats() {
        var w = RRWindower(windowSeconds: 120, stepSeconds: 30, minBeats: 60)
        let windows = feed(&w, beats: 60, from: t0)
        XCTAssertEqual(windows.count, 1)
        XCTAssertEqual(windows.first?.count, 60)
    }

    func testSubsequentWindowsRespectTheStep() {
        var w = RRWindower(windowSeconds: 120, stepSeconds: 30, minBeats: 60)
        // 150 beats at 1/s = 150 s. First window at 60 s, then every 30 s:
        // 90 s, 120 s, 150 s -> 4 windows total.
        let windows = feed(&w, beats: 150, from: t0)
        XCTAssertEqual(windows.count, 4)
    }

    func testWindowNeverExceedsWindowSeconds() {
        var w = RRWindower(windowSeconds: 120, stepSeconds: 30, minBeats: 60)
        let windows = feed(&w, beats: 300, from: t0)
        // At 1 beat/s a 120 s window holds ~120 beats, never the full 300.
        for win in windows { XCTAssertLessThanOrEqual(win.count, 121) }
    }

    func testResetClearsBufferAndCadence() {
        var w = RRWindower(windowSeconds: 120, stepSeconds: 30, minBeats: 60)
        _ = feed(&w, beats: 60, from: t0)
        w.reset()
        XCTAssertEqual(w.bufferedBeats, 0)
        // After a disconnect the next window must rebuild from scratch, so a
        // handful of beats is not enough.
        let windows = feed(&w, beats: 10, from: t0.addingTimeInterval(600))
        XCTAssertTrue(windows.isEmpty)
    }

    func testNonPositiveIntervalsAreDropped() {
        var w = RRWindower(minBeats: 2)
        XCTAssertNil(w.add([0, -5], at: t0))
        XCTAssertEqual(w.bufferedBeats, 0)
    }
}
