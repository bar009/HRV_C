import XCTest
@testable import HRVCore

/// The pose director and the beat poses.
///
/// Hand-written rather than generated, because what is under test here is a
/// *decision* — which body is on screen and when it changes — rather than a
/// number the reference engine produces.
final class PoseDirectorTests: XCTestCase {

    // MARK: - The tables

    /// Every pose resolves to a stack and a set of images, and they agree.
    ///
    /// A pose whose layers and assets disagree does not throw: it draws the
    /// layers it can find and silently omits the rest, which looks like a design
    /// decision rather than a missing file.
    func testEveryPoseHasLayersAndAssetsThatAgree() {
        for pose in PoseName.allCases {
            let drawable = Set(pose.layers
                .filter { $0.kind == .mascot || $0.kind == .lid || $0.kind == .mouth }
                .map(\.id))
            let assets = Set(pose.assets.keys)
            XCTAssertFalse(drawable.isEmpty, "\(pose) has nothing to draw")
            XCTAssertEqual(drawable.subtracting(assets), [], "\(pose): layers with no image")
            XCTAssertEqual(assets.subtracting(drawable), [], "\(pose): images with no layer")
        }
    }

    /// Beat poses are tier two: one flat layer plus eyelids, and no masks or
    /// regions. If one of them started carrying a breathing stack, the tiering
    /// that makes eight poses affordable would have quietly collapsed.
    func testBeatPosesStayCheap() {
        for pose in PoseName.allCases where !pose.isBreathing {
            let mascotLayers = pose.layers.filter { $0.kind == .mascot }
            XCTAssertEqual(mascotLayers.count, 1,
                           "\(pose) draws \(mascotLayers.count) body layers, not 1")
            XCTAssertEqual(mascotLayers.first?.id, "base", "\(pose)")
            XCTAssertTrue(pose.layers.allSatisfy { $0.kind != .mouth },
                          "\(pose) has a face cue; beat poses do not speak")
        }
    }

    /// The breathing poses are the expensive ones, and both carry a full body.
    func testBreathingPosesCarryABody() {
        for pose in PoseName.allCases where pose.isBreathing {
            let ids = Set(pose.layers.map(\.id))
            for region in ["torso", "ribs", "bellyUpper", "bellyLower", "chest", "head", "ears"] {
                XCTAssertTrue(ids.contains(region), "\(pose) is missing \(region)")
            }
        }
    }

    /// Seated trades arms for folded legs one-for-one, so the two stacks are the
    /// same length and **a count can never tell them apart**. That has already
    /// hidden one failure in the reference, where every "seated" render was the
    /// standing rig drawn over the seated artwork.
    func testTheTwoBodiesDifferByIdNotCount() {
        XCTAssertEqual(PoseName.standing.layers.count, PoseName.seated.layers.count)
        XCTAssertTrue(Set(PoseName.standing.layers.map(\.id)).contains("arms"))
        XCTAssertTrue(Set(PoseName.seated.layers.map(\.id)).contains("legs"))
    }

    /// `sleep` is drawn with its eyes shut, so it has no eyelids and cannot
    /// blink. Every other pose can. Derived from the stack rather than declared
    /// a second time, so the two cannot disagree.
    func testOnlyTheSleepingPoseCannotBlink() {
        XCTAssertFalse(PoseName.sleep.canBlink, "a sleeping character should not blink")
        for pose in PoseName.allCases where pose != .sleep {
            XCTAssertTrue(pose.canBlink, "\(pose) has no eyelids")
        }
    }

    // MARK: - The swap

    func testTheCharacterBreathesOutsideABeat() {
        let director = PoseDirector(breathingPose: .seated)
        let frame = director.frame(at: 12, beat: nil, beatStartedAt: nil)
        XCTAssertEqual(frame.pose, .seated)
        XCTAssertNil(frame.beat)
    }

    /// The swap lands **inside** the beat, not at its start.
    ///
    /// A swap at t=0 is a cut against a still body, which is the one place it is
    /// most visible. The whole point of hiding it in a one-shot is that the body
    /// is already moving hard enough for a change of silhouette to read as part
    /// of the movement.
    func testTheSwapLandsInsideTheBeat() {
        let director = PoseDirector(breathingPose: .standing)
        let beat = Beats.intro

        let before = director.frame(at: 100 + beat.swapAt - 0.01, beat: beat, beatStartedAt: 100)
        XCTAssertEqual(before.pose, .standing, "swapped before the fastest instant")

        let after = director.frame(at: 100 + beat.swapAt + 0.01, beat: beat, beatStartedAt: 100)
        XCTAssertEqual(after.pose, .greet, "did not swap at the fastest instant")

        let atStart = director.frame(at: 100, beat: beat, beatStartedAt: 100)
        XCTAssertEqual(atStart.pose, .standing, "swapped at t=0, against a still body")
    }

    /// And it comes back afterwards. A beat that leaves the character in its
    /// greeting pose has not ended, it has changed the character.
    func testTheCharacterReturnsAfterTheBeat() {
        let director = PoseDirector(breathingPose: .seated)
        let beat = Beats.complete
        let after = director.frame(at: 100 + beat.duration + 0.001, beat: beat, beatStartedAt: 100)
        XCTAssertEqual(after.pose, .seated)
        XCTAssertNil(after.beat)
    }

    /// Both one-shots swap at their own measured instant, and the two differ —
    /// so a single hard-coded constant would be wrong for one of them.
    func testEachBeatHasItsOwnSwapInstant() {
        XCTAssertNotEqual(Beats.intro.swapAt, Beats.complete.swapAt)
        for beat in Beats.oneShots {
            XCTAssertGreaterThan(beat.swapAt, 0, "\(beat.name) swaps at the very start")
            XCTAssertLessThan(beat.swapAt, beat.duration, "\(beat.name) swaps after it ends")
        }
    }
}
