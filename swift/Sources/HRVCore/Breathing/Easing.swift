import Foundation

/// Easing curves for the breathing mascot. Port of `breathing-poc/src/easing.js`.
///
/// Every curve leaves 0 and arrives at 1 with zero velocity. That is what makes
/// the phase joins invisible: the turn at the top of an inhale, the entry and
/// exit of a hold, and the loop boundary are all places where two curves meet,
/// and a non-zero slope on either side reads as a flinch.
///
/// ## Why this is a bisection and not Newton–Raphson
///
/// The reference implementation solves `x` by **24 steps of bisection**, and a
/// port is only correct if it reproduces the reference's *output*, not the
/// mathematically ideal curve. Newton converges faster and lands on slightly
/// different values in the last decimals; so does bisection at 20 or 30 steps.
/// Those differences are far below a pixel on their own, but they compound
/// through the region profiles and the layer products, and a port that is
/// "obviously equivalent" is exactly how a rig drifts.
///
/// Note also *which* `t` is used for the final evaluation: the loop assigns the
/// midpoint first and narrows afterwards, so the value returned is the curve at
/// the **24th midpoint**, not at the midpoint of the interval left when the loop
/// ends. Reproduced deliberately.
public struct CubicBezier: Sendable, Equatable {
    public let x1: Double
    public let y1: Double
    public let x2: Double
    public let y2: Double

    public init(_ x1: Double, _ y1: Double, _ x2: Double, _ y2: Double) {
        self.x1 = x1
        self.y1 = y1
        self.x2 = x2
        self.y2 = y2
    }

    /// One axis of the curve at parameter `t`, with the endpoints pinned at 0
    /// and 1 — the standard CSS/Lottie form.
    @inline(__always)
    private func axis(_ t: Double, _ a: Double, _ b: Double) -> Double {
        let u = 1.0 - t
        return 3.0 * a * t * u * u + 3.0 * b * t * t * u + t * t * t
    }

    /// Output for a normalised input, both in 0...1.
    public func callAsFunction(_ x: Double) -> Double {
        if x <= 0 { return 0 }
        if x >= 1 { return 1 }
        var lo = 0.0
        var hi = 1.0
        var t = x
        for _ in 0..<24 {
            t = (lo + hi) / 2.0
            if axis(t, x1, x2) < x { lo = t } else { hi = t }
        }
        return axis(t, y1, y2)
    }
}

/// The five curves the engine uses, by the names the reference gives them.
public enum Easing {
    /// Gentle start, most of the travel mid-phase, settles softly into the top.
    public static let breathIn = CubicBezier(0.42, 0, 0.30, 1)

    /// The same shape with a longer tail — the release should feel slower.
    public static let breathOut = CubicBezier(0.38, 0, 0.20, 1)

    /// Neither half favoured; for exercises whose two sides carry equal weight.
    public static let breathEven = CubicBezier(0.40, 0, 0.25, 1)

    public static let smooth = CubicBezier(0.42, 0, 0.58, 1)

    /// Leaves quickly, lands slowly. Used for the tail of an overshoot.
    public static let settle = CubicBezier(0.25, 0, 0.20, 1)
}
