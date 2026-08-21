import Foundation

/// The regions the body moves in. Port of `SEQUENCE` and `EXTRA_REGIONS` in
/// `breathing-poc/src/mascot-layers.js`.
///
/// The first eight are layers. The rest are regions that drive something other
/// than a body part — an eyelid, a face drawing, a held brace — and exist so
/// those can be keyframed by the same machinery.
public enum BreathRegion: String, Sendable, CaseIterable {
    case root, bellyLower, bellyUpper, torso, ribs, chest, arms, head
    case tail, ears
    case release, hold, techniqueIn, techniqueOut, noseOut, lock

    /// Ears and tail do not track the breath: they drag behind the body and
    /// overshoot when it stops. During a hold there is no movement to lag
    /// behind, so they rest at zero rather than holding the phase's amount —
    /// getting that wrong parks the ears 3 px behind the head for four seconds.
    public var isDrag: Bool { self == .tail || self == .ears }
}

/// One control point of a profile: position, amount, and the easing that leaves
/// it. The last point of a profile has no easing.
public struct ProfilePoint: Sendable {
    public let u: Double
    public let value: Double
    public let ease: CubicBezier?

    public init(_ u: Double, _ value: Double, _ ease: CubicBezier?) {
        self.u = u
        self.value = value
        self.ease = ease
    }
}

public enum Tempo {
    /// At or above this many seconds, nothing is damped.
    public static let slow = 2.0
    /// At or below this, the character is at its quietest.
    public static let fast = 0.4
    /// And that quietest is about a fifth of the slow-breath size.
    public static let floorValue = 0.22

    /// Below this, an *event* is switched off rather than scaled. Letting go at
    /// the bottom of a breath is an event; one that happens twice a second is a
    /// flicker, and no amount of damping makes it read otherwise.
    public static let eventsOffBelow = 1.0

    /// 1 for an unhurried breath, falling toward `floorValue` for a fast one.
    public static func damping(_ phaseSeconds: Double) -> Double {
        if !(phaseSeconds > 0) || phaseSeconds >= slow { return 1 }
        if phaseSeconds <= fast { return floorValue }
        let u = (phaseSeconds - fast) / (slow - fast)
        return floorValue + (1 - floorValue) * u
    }
}

/// Where a region sits inside its phase, and what shape it takes there.
public struct RegionProfiles: Sendable {
    public let clock: BreathClock

    /// Which face the technique shows on a phase, if any. Supplied rather than
    /// derived so this type stays free of the technique table.
    public let hasFace: (BreathPhase) -> Bool

    /// Whether this exercise's exhale leaves through the nose. True for
    /// ordinary breathing — silence means the nose, not "unknown".
    public let exhalesThroughNose: Bool

    /// Whether the exercise asks for an abdominal lock on the empty hold.
    public let bandha: Bool

    public init(clock: BreathClock,
                exhalesThroughNose: Bool = true,
                bandha: Bool = false,
                hasFace: @escaping (BreathPhase) -> Bool = { _ in false }) {
        self.clock = clock
        self.exhalesThroughNose = exhalesThroughNose
        self.bandha = bandha
        self.hasFace = hasFace
    }

    private var easeIn: CubicBezier { clock.config.easeIn }
    private var easeOut: CubicBezier { clock.config.easeOut }

    private func seconds(of phase: BreathPhase) -> Double {
        clock.phases.first { $0.phase == phase }?.seconds ?? 0
    }

    private var flat: [ProfilePoint] {
        [ProfilePoint(0, 0, Easing.smooth), ProfilePoint(1, 0, nil)]
    }

    // MARK: - The window

    /// A region's start and end inside its phase, as fractions.
    ///
    /// **The delays are in seconds, not fractions**, chosen so the belly leads
    /// the chest by about 150 ms of a four-second breath. On a quarter-second
    /// kapalabhati pump the root's 0.18 s delay is 72% of the whole phase, so it
    /// sat still and then fell off a cliff. Damped by the same tempo factor as
    /// everything else that becomes 16%, and the sequence still reads. Above two
    /// seconds the damping is exactly 1, so nothing in the slow set moves by even
    /// a rounding error.
    public func window(_ region: BreathRegion, _ phase: BreathPhase, _ phaseSeconds: Double)
        -> (start: Double, end: Double) {
        guard let seq = Self.sequence[region]?[phase] else { return (0, 1) }
        let delay = seq.delay * Tempo.damping(phaseSeconds)
        let start = min(0.6, delay / max(0.001, phaseSeconds))
        let end = max(start + 0.25, 1 - seq.finishEarly)
        return (start, min(1, end))
    }

    // MARK: - The profile

    /// A region's shape inside its window.
    ///
    /// Returns `nil` where a region has no profile for a phase — a hold, for
    /// most regions — and the caller then uses the phase's own amount.
    public func profile(_ region: BreathRegion, _ phase: BreathPhase) -> [ProfilePoint]? {
        // The root overshoots: it passes its full height at 80% of the inhale
        // and settles back, which is what makes the body look like it arrives
        // and relaxes rather than stopping dead.
        if region == .root {
            if phase == .inhale {
                return [ProfilePoint(0, 0, easeIn), ProfilePoint(0.80, 1.10, Easing.settle),
                        ProfilePoint(1, 1, nil)]
            }
            if phase == .exhale {
                return [ProfilePoint(0, 1, easeOut), ProfilePoint(0.82, -0.05, Easing.settle),
                        ProfilePoint(1, 0, nil)]
            }
        }

        // The release: nothing for most of the breath, arriving only at the very
        // end of the exhale, held through the resting hold, let go early in the
        // next inhale. Every phase is given explicitly — including the holds,
        // which for every other region mean "no profile" — because the release
        // is the one thing that must *persist* through a hold rather than track
        // it.
        if region == .release {
            if seconds(of: .exhale) < Tempo.eventsOffBelow { return flat }
            switch phase {
            case .inhale:
                return [ProfilePoint(0, 1, easeOut), ProfilePoint(0.30, 0, Easing.smooth),
                        ProfilePoint(1, 0, nil)]
            case .exhale:
                return [ProfilePoint(0, 0, Easing.smooth), ProfilePoint(0.72, 0, easeIn),
                        ProfilePoint(1, 1, nil)]
            case .holdAfterInhale:
                return flat
            case .holdAfterExhale:
                return [ProfilePoint(0, 1, Easing.smooth), ProfilePoint(1, 1, nil)]
            }
        }

        // The brace, only while the breath is held in. It arrives quickly —
        // taking on a hold is a decision, not a fade — sits for the hold, and is
        // let go early in the exhale.
        //
        // Only an exercise that actually holds may let go of one. The exhale
        // profile starts at 1, so for a pattern with no held phase it asserted a
        // brace that never happened; both sighs showed it.
        if region == .hold {
            if seconds(of: .holdAfterInhale) < Tempo.eventsOffBelow { return flat }
            if !clock.phases.contains(where: { $0.phase == .holdAfterInhale }) { return flat }
            if phase == .holdAfterInhale {
                return [ProfilePoint(0, 0, easeIn), ProfilePoint(0.18, 1, Easing.smooth),
                        ProfilePoint(1, 1, nil)]
            }
            if phase == .exhale {
                return [ProfilePoint(0, 1, Easing.smooth), ProfilePoint(0.22, 0, Easing.smooth),
                        ProfilePoint(1, 0, nil)]
            }
            return flat
        }

        // The lock, only while the breath is held **out** and only where asked
        // for. Nothing asks yet, so this is flat everywhere — the capability is
        // built and measured before the exercises that need it.
        if region == .lock {
            if !bandha { return flat }
            if seconds(of: .holdAfterExhale) < Tempo.eventsOffBelow { return flat }
            if phase == .holdAfterExhale {
                return [ProfilePoint(0, 0, easeIn), ProfilePoint(0.16, 1, Easing.smooth),
                        ProfilePoint(1, 1, nil)]
            }
            if phase == .inhale {
                return [ProfilePoint(0, 1, easeOut), ProfilePoint(0.22, 0, Easing.smooth),
                        ProfilePoint(1, 0, nil)]
            }
            return flat
        }

        // The nostrils, for the whole of a nose exhale. The one face cue that is
        // not about technique: it answers "is air leaving right now", and it is
        // deliberately asymmetric so the two halves of a breath cannot be
        // confused for each other.
        if region == .noseOut {
            if seconds(of: .exhale) < Tempo.eventsOffBelow { return flat }
            if !exhalesThroughNose { return flat }
            if phase != .exhale { return flat }
            return [ProfilePoint(0, 0, easeIn), ProfilePoint(0.16, 1, Easing.smooth),
                    ProfilePoint(0.84, 1, Easing.smooth), ProfilePoint(1, 0, nil)]
        }

        // The technique: the mouth is shaped only during the phase it belongs
        // to, and only if the exercise has one. The same mistake the brace made
        // would purse the lips of every exercise in the set.
        if region == .techniqueIn || region == .techniqueOut {
            let own: BreathPhase = region == .techniqueIn ? .inhale : .exhale
            if seconds(of: own) < Tempo.eventsOffBelow { return flat }
            if phase != own || !hasFace(own) { return flat }
            return [ProfilePoint(0, 0, easeIn), ProfilePoint(0.20, 1, Easing.smooth),
                    ProfilePoint(0.82, 1, Easing.smooth), ProfilePoint(1, 0, nil)]
        }

        // Ears and tail drag behind the body and overshoot when it stops. Scaled
        // by tempo rather than clipped — the ears still trail a fast body, just
        // less far — and refined, because their exported position is a product
        // of two curves and long segments drift.
        if let lag = Self.lag[region]?[phase] {
            let damp = Tempo.damping(seconds(of: phase))
            let base = damp == 1 ? lag
                : lag.map { ProfilePoint($0.u, $0.value * damp, $0.ease) }
            return Self.refine(base)
        }

        if phase == .inhale {
            return [ProfilePoint(0, 0, easeIn), ProfilePoint(1, 1, nil)]
        }
        if phase == .exhale {
            return [ProfilePoint(0, 1, easeOut), ProfilePoint(1, 0, nil)]
        }
        return nil
    }

    // MARK: - Evaluation

    /// Evaluate a profile at a window-local position.
    public static func evaluate(_ profile: [ProfilePoint], _ u: Double) -> Double {
        let x = min(1, max(0, u))
        var i = 0
        while i < profile.count - 2 && profile[i + 1].u <= x { i += 1 }
        let a = profile[i]
        let b = profile[i + 1]
        if b.u == a.u { return b.value }
        guard let ease = a.ease else { return b.value }
        return a.value + (b.value - a.value) * ease((x - a.u) / (b.u - a.u))
    }

    /// The breath amount in every region at one instant.
    ///
    /// The root can exceed 1 while it overshoots. Every transform is linear in
    /// the amount, so that is simply more of the same pose.
    public func amounts(at state: BreathState) -> [BreathRegion: Double] {
        var out: [BreathRegion: Double] = [:]
        for region in BreathRegion.allCases {
            guard let p = profile(region, state.phase) else {
                // A holds has no profile. A breath-driven region carries the
                // phase's amount; a drag region rests at zero, because drag is a
                // response to movement and during a hold there is none.
                out[region] = region.isDrag ? 0 : state.progress
                continue
            }
            let w = window(region, state.phase, state.phaseSeconds)
            out[region] = Self.evaluate(p, (state.phaseProgress - w.start) / (w.end - w.start))
        }
        return out
    }

    // MARK: - Tables

    /// Split every segment in half, keeping the shape exactly.
    ///
    /// The inserted point is evaluated with the segment's own easing, so this
    /// adds keyframes without moving the curve by a rounding error. It exists
    /// because a layer's transform is the product of its own curve and its
    /// parent's, and the error between them grows with segment length.
    static func refine(_ profile: [ProfilePoint]) -> [ProfilePoint] {
        var out: [ProfilePoint] = []
        for i in 0..<(profile.count - 1) {
            let a = profile[i]
            let b = profile[i + 1]
            out.append(a)
            let um = (a.u + b.u) / 2
            if um > a.u, um < b.u, let ease = a.ease {
                out.append(ProfilePoint(um, a.value + (b.value - a.value) * ease(0.5), ease))
            }
        }
        out.append(profile[profile.count - 1])
        return out
    }

    /// Where each region sits inside its phase: a delay in **seconds**, and how
    /// early it finishes as a fraction.
    static let sequence: [BreathRegion: [BreathPhase: (delay: Double, finishEarly: Double)]] = [
        .root: [.inhale: (0.05, 0.00), .exhale: (0.18, 0.02)],
        .bellyLower: [.inhale: (0.00, 0.00), .exhale: (0.30, 0.00)],
        .bellyUpper: [.inhale: (0.06, 0.00), .exhale: (0.24, 0.04)],
        .torso: [.inhale: (0.10, 0.00), .exhale: (0.20, 0.06)],
        .ribs: [.inhale: (0.15, 0.00), .exhale: (0.16, 0.10)],
        .chest: [.inhale: (0.28, 0.00), .exhale: (0.00, 0.20)],
        .arms: [.inhale: (0.36, 0.00), .exhale: (0.06, 0.16)],
        .head: [.inhale: (0.42, 0.00), .exhale: (0.10, 0.14)],
        // Drag spans the whole phase: the delay is already in the shape of the
        // profile, so these must not be windowed on top of it.
        .tail: [.inhale: (0, 0), .exhale: (0, 0)],
        .ears: [.inhale: (0, 0), .exhale: (0, 0)],
        .release: [.inhale: (0, 0), .exhale: (0, 0)],
        .hold: [.inhale: (0, 0), .exhale: (0, 0)],
        .techniqueIn: [.inhale: (0, 0), .exhale: (0, 0)],
        .techniqueOut: [.inhale: (0, 0), .exhale: (0, 0)],
        .noseOut: [.inhale: (0, 0), .exhale: (0, 0)],
        .lock: [.inhale: (0, 0), .exhale: (0, 0)],
    ]

    static let lag: [BreathRegion: [BreathPhase: [ProfilePoint]]] = [
        .ears: [
            .inhale: [ProfilePoint(0, 0, Easing.smooth), ProfilePoint(0.34, -1, Easing.smooth),
                      ProfilePoint(0.86, 0.34, Easing.settle), ProfilePoint(1, 0, nil)],
            .exhale: [ProfilePoint(0, 0, Easing.smooth), ProfilePoint(0.28, 0.85, Easing.smooth),
                      ProfilePoint(0.78, -0.22, Easing.settle), ProfilePoint(1, 0, nil)],
        ],
        .tail: [
            .inhale: [ProfilePoint(0, 0, Easing.smooth), ProfilePoint(0.40, -0.9, Easing.smooth),
                      ProfilePoint(0.88, 0.30, Easing.settle), ProfilePoint(1, 0, nil)],
            .exhale: [ProfilePoint(0, 0, Easing.smooth), ProfilePoint(0.32, 0.75, Easing.smooth),
                      ProfilePoint(0.82, -0.20, Easing.settle), ProfilePoint(1, 0, nil)],
        ],
    ]
}
