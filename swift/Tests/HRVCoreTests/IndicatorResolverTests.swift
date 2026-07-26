import XCTest
@testable import HRVCore

/// The truth table that keeps the product honest: what each class of sensor can
/// and cannot actually produce.
final class IndicatorResolverTests: XCTestCase {

    private func avail(_ i: HealthIndicator, _ c: SensorCapabilities) -> IndicatorAvailability {
        IndicatorResolver.availability(of: i, given: c)
    }

    // MARK: chest strap -- the reference case

    func testChestStrapDoesAllHRVAndLiveTriggers() {
        let c = SensorCapabilities.bleChestStrap
        for i in [HealthIndicator.rmssd, .pnn50, .sdsd, .coherence, .liveBPM,
                  .sustainedDetection] {
            XCTAssertEqual(avail(i, c), .available, "\(i) should be available on a chest strap")
        }
        // Live triggers work, but a strap alone has no movement signal, so they
        // will misfire on walking until motion gating is on.
        XCTAssertEqual(avail(.liveTriggers, c), .approximate(.needsMotionAccess))
        var gated = c
        gated.motionContext = true
        XCTAssertEqual(avail(.liveTriggers, gated), .available)
    }

    func testChestStrapHasNoHealthKitContext() {
        let c = SensorCapabilities.bleChestStrap
        for i in [HealthIndicator.sdnn, .restingHeartRate, .sleepContext, .workoutContext] {
            XCTAssertEqual(avail(i, c), .unavailable(.needsHealthKit))
        }
    }

    // MARK: passive Apple Watch

    func testPassiveWatchDoesSustainedButNotLive() {
        let c = SensorCapabilities.appleWatchPassive
        XCTAssertEqual(avail(.sdnn, c), .available)
        XCTAssertEqual(avail(.sustainedDetection, c), .available)
        XCTAssertEqual(avail(.restingHeartRate, c), .available)
        // The whole reason the strap exists:
        XCTAssertEqual(avail(.liveTriggers, c), .unavailable(.needsBeatToBeat))
        XCTAssertEqual(avail(.coherence, c), .unavailable(.needsBeatToBeat))
        XCTAssertEqual(avail(.rmssd, c), .unavailable(.needsBeatToBeat))
    }

    // MARK: watch workout -- the honesty case

    func testWatchWorkoutCoherenceIsApproximateNotExact() {
        let c = SensorCapabilities.appleWatchWorkout
        XCTAssertEqual(avail(.coherence, c), .approximate(.rrDerivedFromHeartRate))
        XCTAssertEqual(avail(.rmssd, c), .approximate(.rrDerivedFromHeartRate))
        XCTAssertTrue(avail(.coherence, c).isUsable)
        XCTAssertFalse(avail(.coherence, c).isAvailable)
        // Derived timing is still not good enough to alert on.
        XCTAssertEqual(avail(.liveTriggers, c), .unavailable(.needsBeatToBeat))
    }

    // MARK: BPM-only strap

    func testBpmOnlyStrapDisablesEveryHRVIndicator() {
        let c = SensorCapabilities.bleBpmOnly
        for i in [HealthIndicator.rmssd, .pnn50, .sdsd, .coherence, .liveTriggers] {
            XCTAssertEqual(avail(i, c), .unavailable(.needsBeatToBeat), "\(i) must be off")
        }
        // It can still show a pulse.
        XCTAssertEqual(avail(.liveBPM, c), .available)
        XCTAssertFalse(avail(.rmssd, c).isUsable)
    }

    // MARK: nothing connected

    func testNoSensorHasNothingUsable() {
        let c = SensorCapabilities.none
        for (_, a) in IndicatorResolver.all(given: c) {
            XCTAssertFalse(a.isUsable)
        }
    }

    // MARK: merging -- strap + watch together

    func testMergingGivesStrapLiveDataPlusHealthKitContext() {
        let merged = SensorCapabilities.bleChestStrap.merging(.appleWatchPassive)
        // From the strap -- usable, though still ungated without motion access.
        XCTAssertTrue(avail(.liveTriggers, merged).isUsable)
        XCTAssertEqual(avail(.sleepContext, merged), .available)   // from the watch
        XCTAssertEqual(avail(.sdnn, merged), .available)
        XCTAssertEqual(merged.rrFidelity, .beatToBeat)
    }

    func testMergingTakesTheBetterFidelity() {
        let merged = SensorCapabilities.appleWatchWorkout.merging(.bleChestStrap)
        XCTAssertEqual(merged.rrFidelity, .beatToBeat)
        XCTAssertEqual(avail(.coherence, merged), .available)
    }

    func testAllCoversEveryIndicator() {
        XCTAssertEqual(IndicatorResolver.all(given: .demo).count, HealthIndicator.allCases.count)
    }
}
