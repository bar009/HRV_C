import Foundation

/// Offsets a beat contributes on top of the breath.
public struct BeatOffsets: Sendable, Equatable {
    public var rootScaleX: Double = 0
    public var rootScaleY: Double = 0
    public var rootTranslateY: Double = 0
    public var rootRotate: Double = 0
    public var earTranslateY: Double = 0
    public var tailTranslateX: Double = 0

    public init() {}
}

/// A one-shot: a short piece of character played *around* a session rather than
/// inside it, so the breath itself stays calm and the character lives at the
/// edges. Port of `INTRO` and `COMPLETE` in
/// `breathing-poc/src/motion-beats.js`.
public struct OneShot: Sendable {
    public let name: String
    public let duration: Double
    public let scaleX: [TrackPoint]
    public let scaleY: [TrackPoint]
    public let translateY: [TrackPoint]
    public let rotate: [TrackPoint]
    public let earLag: [TrackPoint]
    public let tailLag: [TrackPoint]

    /// The instant the body is moving fastest, where a pose swap is least
    /// visible. A cut is hidden when it is smaller than its surroundings, and
    /// this is where the surroundings are largest.
    public let swapAt: Double

    public func offsets(at t: Double, intensity: Double = 1) -> BeatOffsets {
        var out = BeatOffsets()
        out.rootScaleX = IdleBehaviour.sample(scaleX, t) * intensity
        out.rootScaleY = IdleBehaviour.sample(scaleY, t) * intensity
        out.rootTranslateY = IdleBehaviour.sample(translateY, t) / ArtSpace.k * intensity
        out.rootRotate = IdleBehaviour.sample(rotate, t) * intensity
        out.earTranslateY = IdleBehaviour.sample(earLag, t) * BeatAmplitude.earLag / ArtSpace.k * intensity
        out.tailTranslateX = IdleBehaviour.sample(tailLag, t) * BeatAmplitude.tailLag / ArtSpace.k * intensity
        return out
    }
}

public enum Beats {

    // MARK: - The idle bob

    /// How many rise-and-falls fit in a cycle. One per four seconds, and never
    /// fewer than one — a breath shorter than that still has to move.
    public static func bobPeriods(cycleSeconds: Double) -> Int {
        max(1, Int((cycleSeconds / 4).rounded()))
    }

    /// The bob as a track: up, middle, down, middle, repeating.
    public static func bobTrack(cycleSeconds: Double) -> [TrackPoint] {
        let n = bobPeriods(cycleSeconds: cycleSeconds)
        let steps = n * 4
        let values: [Double] = [0, -1, 0, 1]
        var points: [TrackPoint] = []
        for k in 0...steps {
            points.append(TrackPoint(Double(k) / Double(steps) * cycleSeconds,
                                     values[k % 4],
                                     k == steps ? nil : Easing.smooth))
        }
        return points
    }

    /// The whole-body rise and fall that runs for the entire loop.
    ///
    /// A stretch about the ground, not a lift: a lift would take the feet with
    /// it. During an inhale it is swamped by the body's own travel; during a
    /// hold it is the only thing moving, which is what stops a four-second hold
    /// reading as a stalled player.
    ///
    /// Damped by the **cycle**, not the phase — the bob spans the loop, so what
    /// matters is how fast the whole breath is going.
    public static func loop(cycleTime: Double,
                            cycleSeconds: Double,
                            intensity: Double = 1) -> BeatOffsets {
        var out = BeatOffsets()
        if intensity == 0 { return out }
        let damp = Tempo.damping(cycleSeconds)
        let bob = IdleBehaviour.sample(bobTrack(cycleSeconds: cycleSeconds), cycleTime)
        out.rootScaleY = bob * BeatAmplitude.bob * intensity * damp
        return out
    }

    // MARK: - The one-shots

    /// Anticipate, rise, settle. "Here we go."
    public static let intro = OneShot(
        name: "intro",
        duration: 1.2,
        scaleX: [TrackPoint(0, 0, Easing.smooth), TrackPoint(0.18, 0.030, Easing.breathIn),
                 TrackPoint(0.52, -0.025, Easing.settle), TrackPoint(0.80, 0.004, Easing.settle),
                 TrackPoint(1.2, 0, nil)],
        scaleY: [TrackPoint(0, 0, Easing.smooth), TrackPoint(0.18, -0.040, Easing.breathIn),
                 TrackPoint(0.52, 0.050, Easing.settle), TrackPoint(0.80, -0.005, Easing.settle),
                 TrackPoint(1.2, 0, nil)],
        translateY: [TrackPoint(0, 0, Easing.smooth), TrackPoint(0.18, 2, Easing.breathIn),
                     TrackPoint(0.52, -6, Easing.settle), TrackPoint(0.80, 0.5, Easing.settle),
                     TrackPoint(1.2, 0, nil)],
        rotate: [TrackPoint(0, 0, Easing.smooth), TrackPoint(0.30, -1.1, Easing.smooth),
                 TrackPoint(0.70, 0.5, Easing.settle), TrackPoint(1.2, 0, nil)],
        earLag: [TrackPoint(0, 0, Easing.smooth), TrackPoint(0.26, 1.6, Easing.smooth),
                 TrackPoint(0.62, -1.1, Easing.settle), TrackPoint(0.92, 0.35, Easing.settle),
                 TrackPoint(1.2, 0, nil)],
        tailLag: [TrackPoint(0, 0, Easing.smooth), TrackPoint(0.32, 1.2, Easing.smooth),
                  TrackPoint(0.70, -0.8, Easing.settle), TrackPoint(1.2, 0, nil)],
        // **Measured, not chosen.** The first version of this said "the peak
        // squash" and used 0.18 — a control-point position, not a velocity peak.
        // Sweeping the beat at 2000 steps puts the fastest instant at 0.301 s;
        // the largest *displacement* is elsewhere again, at 0.52. Those are three
        // different questions and only the middle one hides a cut.
        swapAt: 0.301)

    /// Two small hops, ears bouncing, landing soft. "Done."
    public static let complete = OneShot(
        name: "complete",
        duration: 1.6,
        scaleX: [TrackPoint(0, 0, Easing.smooth), TrackPoint(0.12, 0.032, Easing.breathIn),
                 TrackPoint(0.34, -0.020, Easing.smooth), TrackPoint(0.52, 0.036, Easing.smooth),
                 TrackPoint(0.72, -0.014, Easing.smooth), TrackPoint(0.88, 0.022, Easing.smooth),
                 TrackPoint(1.10, -0.004, Easing.settle), TrackPoint(1.6, 0, nil)],
        scaleY: [TrackPoint(0, 0, Easing.smooth), TrackPoint(0.12, -0.042, Easing.breathIn),
                 TrackPoint(0.34, 0.038, Easing.smooth), TrackPoint(0.52, -0.046, Easing.smooth),
                 TrackPoint(0.72, 0.028, Easing.smooth), TrackPoint(0.88, -0.028, Easing.smooth),
                 TrackPoint(1.10, 0.006, Easing.settle), TrackPoint(1.6, 0, nil)],
        translateY: [TrackPoint(0, 0, Easing.smooth), TrackPoint(0.12, 2.5, Easing.breathIn),
                     TrackPoint(0.34, -22, Easing.smooth), TrackPoint(0.52, 0, Easing.smooth),
                     TrackPoint(0.72, -12, Easing.smooth), TrackPoint(0.88, 0, Easing.smooth),
                     TrackPoint(1.10, -1, Easing.settle), TrackPoint(1.6, 0, nil)],
        rotate: [TrackPoint(0, 0, Easing.smooth), TrackPoint(0.34, 1.4, Easing.smooth),
                 TrackPoint(0.72, -1.0, Easing.smooth), TrackPoint(1.10, 0.3, Easing.settle),
                 TrackPoint(1.6, 0, nil)],
        earLag: [TrackPoint(0, 0, Easing.smooth), TrackPoint(0.18, 1.8, Easing.smooth),
                 TrackPoint(0.40, -2.0, Easing.smooth), TrackPoint(0.60, 1.3, Easing.smooth),
                 TrackPoint(0.80, -1.0, Easing.smooth), TrackPoint(1.05, 0.4, Easing.settle),
                 TrackPoint(1.6, 0, nil)],
        tailLag: [TrackPoint(0, 0, Easing.smooth), TrackPoint(0.22, 1.4, Easing.smooth),
                  TrackPoint(0.48, -1.2, Easing.smooth), TrackPoint(0.78, 0.8, Easing.smooth),
                  TrackPoint(1.6, 0, nil)],
        // Measured the same way: 0.198 s, not the 0.34 first written here,
        // which is where this beat's displacement peaks rather than its speed.
        swapAt: 0.198)

    public static let oneShots = [intro, complete]
}
