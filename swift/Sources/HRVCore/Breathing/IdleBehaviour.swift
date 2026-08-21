import Foundation

/// The blink. Port of `breathing-poc/src/blink.js`.
///
/// It runs on its own clock, deliberately not tied to the start of an inhale,
/// the peak, or the loop boundary — so it must be driven by an independent timer
/// rather than baked into a breathing animation.
public enum Blink {
    public static let closeMs = 200.0
    public static let closedMs = 130.0
    public static let reopenMs = 240.0
    public static let totalMs = 570.0

    /// Three drawings rather than two. Two is the minimum a blink can be built
    /// from, but it steps straight from half-closed to closed, and at quarter
    /// speed that pop is visible. The 80% drawing sits where most of that step
    /// was. Reopening spends longer on each drawing than closing does, which is
    /// what makes the opening read as the slower half.
    public static let sequence: [(at: Double, lid: String?)] = [
        (0, nil),
        (70, "half"),
        (135, "mostly"),
        (200, "closed"),
        (330, "mostly"),
        (410, "half"),
        (510, nil),
    ]

    /// Which drawing is on screen `ms` into a blink.
    public static func lid(at ms: Double) -> String? {
        if ms < 0 || ms >= totalMs { return nil }
        var lid: String?
        for step in sequence {
            if ms >= step.at { lid = step.lid } else { break }
        }
        return lid
    }
}

/// One control point of a beat track: time in seconds, amount, and the easing
/// that leaves it.
public struct TrackPoint: Sendable {
    public let t: Double
    public let value: Double
    public let ease: CubicBezier?

    public init(_ t: Double, _ value: Double, _ ease: CubicBezier?) {
        self.t = t
        self.value = value
        self.ease = ease
    }
}

/// The unscheduled things a living animal does while nothing in particular is
/// happening. Port of `breathing-poc/src/idle.js`.
public struct IdleBehaviour: Sendable {
    public let name: String
    public let minGap: Double
    public let maxGap: Double
    public let duration: Double

    /// Exempt from the shared refractory period.
    public let ignoreRefractory: Bool

    /// Phases this behaviour would rather start in, and how long it will wait
    /// for one before going anyway.
    public let prefer: [BreathPhase]
    public let preferWindow: Double

    /// Now and then, twice — a perfectly regular blink reads as a metronome.
    public let doubleChance: Double
    public let doubleGap: Double

    public let earTrack: [TrackPoint]?
    public let tailTrack: [TrackPoint]?
    public let leanTrack: [TrackPoint]?

    public init(name: String, minGap: Double, maxGap: Double, duration: Double,
                ignoreRefractory: Bool = false,
                prefer: [BreathPhase] = [], preferWindow: Double = 0,
                doubleChance: Double = 0, doubleGap: Double = 0,
                earTrack: [TrackPoint]? = nil,
                tailTrack: [TrackPoint]? = nil,
                leanTrack: [TrackPoint]? = nil) {
        self.name = name
        self.minGap = minGap
        self.maxGap = maxGap
        self.duration = duration
        self.ignoreRefractory = ignoreRefractory
        self.prefer = prefer
        self.preferWindow = preferWindow
        self.doubleChance = doubleChance
        self.doubleGap = doubleGap
        self.earTrack = earTrack
        self.tailTrack = tailTrack
        self.leanTrack = leanTrack
    }

    /// Sample a track. Outside it the first and last values hold, so a track
    /// always starts and ends at rest.
    public static func sample(_ points: [TrackPoint], _ t: Double) -> Double {
        if t <= points[0].t { return points[0].value }
        guard let last = points.last else { return 0 }
        if t >= last.t { return last.value }
        var i = 0
        while i < points.count - 2 && points[i + 1].t <= t { i += 1 }
        let a = points[i]
        let b = points[i + 1]
        let ease = a.ease ?? Easing.smooth
        return a.value + (b.value - a.value) * ease((t - a.t) / (b.t - a.t))
    }
}

public enum IdleCatalogue {
    /// No two behaviours may start within this of each other.
    public static let refractory = 2.2

    /// Never in the first second of an exercise.
    public static let leadIn = 1.0

    /// A relaxed person blinks 15–20 times a minute. The first version of this
    /// used 8–14 seconds, chosen from an instinct about what "calm" ought to
    /// look like, and produced 4.4 a minute with the eyes shut 4% of the time —
    /// which reads, correctly, as a character that barely blinks.
    public static let blink = IdleBehaviour(
        name: "blink", minGap: 3.5, maxGap: 7, duration: Blink.totalMs / 1000,
        // Blinking while the ears twitch is what an animal does; at this
        // interval, deferring to every other behaviour would swallow a third of
        // them.
        ignoreRefractory: true,
        prefer: [.exhale, .holdAfterExhale], preferWindow: 1,
        doubleChance: 0.17, doubleGap: 0.3)

    public static let earTwitch = IdleBehaviour(
        name: "earTwitch", minGap: 11, maxGap: 21, duration: 0.45,
        earTrack: [TrackPoint(0, 0, Easing.smooth), TrackPoint(0.08, -1.5, Easing.smooth),
                   TrackPoint(0.20, 0.55, Easing.settle), TrackPoint(0.45, 0, nil)])

    public static let tailFlick = IdleBehaviour(
        name: "tailFlick", minGap: 15, maxGap: 27, duration: 0.85,
        tailTrack: [TrackPoint(0, 0, Easing.smooth), TrackPoint(0.15, 1.7, Easing.smooth),
                    TrackPoint(0.44, -0.9, Easing.settle), TrackPoint(0.85, 0, nil)])

    public static let weightShift = IdleBehaviour(
        name: "weightShift", minGap: 19, maxGap: 35, duration: 1.8,
        earTrack: [TrackPoint(0, 0, Easing.smooth), TrackPoint(0.70, 0.5, Easing.smooth),
                   TrackPoint(1.35, -0.2, Easing.settle), TrackPoint(1.8, 0, nil)],
        leanTrack: [TrackPoint(0, 0, Easing.smooth), TrackPoint(0.55, 0.75, Easing.smooth),
                    TrackPoint(1.20, -0.22, Easing.settle), TrackPoint(1.8, 0, nil)])

    /// In the order the reference declares them, because the controller steps
    /// through them in that order and the refractory check depends on it.
    public static let all = [blink, earTwitch, tailFlick, weightShift]
}

/// What the idle layer contributes at one instant.
public struct IdleOutput: Sendable, Equatable {
    public var lid: String?
    public var earTranslateY: Double
    public var tailTranslateX: Double
    public var rootRotate: Double
}

/// The scheduler. All the behaviours run on one clock, independent of the
/// breathing loop, and share a refractory period — which is what makes a set of
/// behaviours read as one creature rather than as several timers.
///
/// There used to be a second blink scheduler in the reference, with its own
/// 8–14 s interval. Nothing that shipped used it, but the verification imported
/// it — so for a whole pass the suite measured a blink rate no user could see
/// and reported it healthy while the real character blinked a third as often.
/// A port that adds its own convenience scheduler would recreate that exactly.
public final class IdleController {
    private struct State {
        var due: Double
        var startedAt: Double?
        var waiting: Double
        var count: Int
        var pendingDouble: Bool
    }

    private let behaviours: [IdleBehaviour]
    private let random: () -> Double
    private var state: [String: State] = [:]
    private var elapsed: Double = 0
    private var lastStart: Double = -.infinity

    /// `random` is injectable so a test can reproduce a run exactly. That is
    /// what makes this portable at all: with the same seeded generator, both
    /// implementations must produce the same timeline, which is a far stronger
    /// claim than agreeing on a blink rate.
    public init(behaviours: [IdleBehaviour] = IdleCatalogue.all,
                random: @escaping () -> Double) {
        self.behaviours = behaviours
        self.random = random
        reset()
    }

    public func reset() {
        elapsed = 0
        lastStart = -.infinity
        state = [:]
        for b in behaviours {
            state[b.name] = State(due: IdleCatalogue.leadIn + gap(for: b),
                                  startedAt: nil, waiting: 0, count: 0, pendingDouble: false)
        }
    }

    private func gap(for b: IdleBehaviour) -> Double {
        b.minGap + random() * (b.maxGap - b.minGap)
    }

    public var counts: [String: Int] {
        state.mapValues(\.count)
    }

    public func update(dt: Double, phase: BreathPhase?) -> IdleOutput {
        elapsed += dt
        var lid: String?
        var active: [(IdleBehaviour, Double)] = []

        for b in behaviours {
            guard var s = state[b.name] else { continue }
            defer { state[b.name] = s }

            if let started = s.startedAt {
                let local = elapsed - started
                if local >= b.duration {
                    s.startedAt = nil
                    // The gap is measured from the *end*, so two of the same
                    // behaviour never land on top of each other. The exception
                    // is a deliberate double: decided when the first of the pair
                    // finishes, cleared when the second does.
                    if s.pendingDouble {
                        s.pendingDouble = false
                        s.due = elapsed + gap(for: b)
                    } else if b.doubleChance > 0 && random() < b.doubleChance {
                        s.pendingDouble = true
                        s.due = elapsed + b.doubleGap
                    } else {
                        s.due = elapsed + gap(for: b)
                    }
                } else {
                    active.append((b, local))
                }
                continue
            }

            if elapsed < s.due { continue }
            // Something else is mid-move; wait rather than stack — unless this
            // is the blink, which has no reason to defer to an ear twitch.
            if !b.ignoreRefractory && elapsed - lastStart < IdleCatalogue.refractory { continue }

            let calm = b.prefer.isEmpty || phase == nil || b.prefer.contains(phase!)
            if calm || s.waiting > b.preferWindow {
                s.startedAt = elapsed
                s.count += 1
                lastStart = elapsed
                s.waiting = 0
                active.append((b, 0))
            } else {
                s.waiting += dt
            }
        }

        var out = IdleOutput(lid: nil, earTranslateY: 0, tailTranslateX: 0, rootRotate: 0)
        for (b, local) in active {
            if b.name == "blink" {
                lid = Blink.lid(at: local * 1000)
                continue
            }
            if let track = b.earTrack {
                out.earTranslateY += artPixels(IdleBehaviour.sample(track, local) * BeatAmplitude.earLag)
            }
            if let track = b.tailTrack {
                out.tailTranslateX += artPixels(IdleBehaviour.sample(track, local) * BeatAmplitude.tailLag)
            }
            if let track = b.leanTrack {
                out.rootRotate += IdleBehaviour.sample(track, local)
            }
        }
        out.lid = lid
        return out
    }

    /// Composition pixels to art units. Amplitudes are authored in the former.
    private func artPixels(_ outputPixels: Double) -> Double {
        outputPixels / ArtSpace.k
    }
}

public enum BeatAmplitude {
    /// The idle rise and fall is a *stretch about the ground*, not a lift. A
    /// lift would take the feet with it.
    public static let bob = 0.0026
    /// Composition pixels: how far the ears trail the body, and the tail.
    public static let earLag = 3.2
    public static let tailLag = 2.8
}

/// mulberry32 — small, fast, and good enough for scheduling jitter.
///
/// Ported so a run can be reproduced on both sides. The bit operations are
/// written to match JavaScript's, which is the whole point: `Math.imul` is a
/// 32-bit multiply, `>>>` is a logical shift on a 32-bit value, and a Swift
/// port using `Int` would agree for a while and then diverge.
public struct Mulberry32 {
    private var a: UInt32

    public init(seed: UInt32) {
        self.a = seed
    }

    public mutating func next() -> Double {
        a = a &+ 0x6D2B79F5
        var t = (a ^ (a >> 15)) &* (a | 1)
        t = (t &+ ((t ^ (t >> 7)) &* (t | 61))) ^ t
        return Double((t ^ (t >> 14))) / 4294967296.0
    }
}
