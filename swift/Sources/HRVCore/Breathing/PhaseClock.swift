import Foundation

/// The four phases of a breath, always in this order.
///
/// A phase with a duration of zero is **dropped** rather than kept at length
/// zero: most exercises have no holds, and a zero-length phase that still exists
/// would take a keyframe and could be landed on.
public enum BreathPhase: String, Sendable, CaseIterable {
    case inhale
    case holdAfterInhale
    case exhale
    case holdAfterExhale

    public var isHold: Bool {
        self == .holdAfterInhale || self == .holdAfterExhale
    }
}

/// One exercise's timing. Port of a `breathing-configs.js` entry.
public struct BreathConfig: Sendable, Equatable {
    public let id: String
    public let inhale: Double
    public let holdAfterInhale: Double
    public let exhale: Double
    public let holdAfterExhale: Double
    public let cycles: Int
    public let easeIn: CubicBezier
    public let easeOut: CubicBezier

    public init(id: String,
                inhale: Double,
                holdAfterInhale: Double = 0,
                exhale: Double,
                holdAfterExhale: Double = 0,
                cycles: Int = 1,
                easeIn: CubicBezier = Easing.breathIn,
                easeOut: CubicBezier = Easing.breathOut) {
        self.id = id
        self.inhale = inhale
        self.holdAfterInhale = holdAfterInhale
        self.exhale = exhale
        self.holdAfterExhale = holdAfterExhale
        self.cycles = cycles
        self.easeIn = easeIn
        self.easeOut = easeOut
    }

    public func seconds(of phase: BreathPhase) -> Double {
        switch phase {
        case .inhale: return inhale
        case .holdAfterInhale: return holdAfterInhale
        case .exhale: return exhale
        case .holdAfterExhale: return holdAfterExhale
        }
    }
}

/// A phase with its place on the timeline.
public struct PhaseSpan: Sendable, Equatable {
    public let phase: BreathPhase
    public let seconds: Double
    public let start: Double
    public let end: Double
    public let startFrame: Int
    public let endFrame: Int
}

/// What the engine knows at one instant.
public struct BreathState: Sendable, Equatable {
    public let time: Double
    public let cycle: Int
    public let cycleTime: Double
    public let phase: BreathPhase
    public let phaseIndex: Int
    public let phaseSeconds: Double
    public let phaseStart: Double
    public let phaseProgress: Double

    /// The breath amount: 0 at rest, 1 at full.
    public let progress: Double

    /// Non-zero only inside a hold — one soft rise and fall, so the guide can
    /// stay alive while the body itself is genuinely still.
    public let holdPulse: Double
}

/// The phase clock. Port of `breathing-poc/src/breathing-engine.js`.
///
/// Everything downstream — the region profiles, the layer transforms, the
/// exporter — reads its timing from here, so a change to a config cannot leave
/// one surface out of step with another.
public struct BreathClock: Sendable {
    public static let fps = 30

    public let config: BreathConfig
    public let phases: [PhaseSpan]
    public let cycleSeconds: Double
    public let totalSeconds: Double
    public let frameCount: Int

    public init(_ config: BreathConfig) {
        self.config = config

        var t = 0.0
        var built: [PhaseSpan] = []
        for phase in BreathPhase.allCases {
            let seconds = config.seconds(of: phase)
            built.append(PhaseSpan(
                phase: phase,
                seconds: seconds,
                start: t,
                end: t + seconds,
                startFrame: Int((t * Double(Self.fps)).rounded()),
                endFrame: Int(((t + seconds) * Double(Self.fps)).rounded())
            ))
            t += seconds
        }
        // Filtered *after* the starts are accumulated, so dropping an absent
        // hold does not shift the phases that follow it.
        self.phases = built.filter { $0.seconds > 0 }

        self.cycleSeconds = t
        self.totalSeconds = t * Double(config.cycles)
        self.frameCount = Int((totalSeconds * Double(Self.fps)).rounded())
    }

    /// Breath amount within a phase. Holds are flat **by definition**, which is
    /// what gives them zero velocity at both ends and lets them butt against an
    /// eased phase without a step.
    private func phaseValue(_ phase: BreathPhase, _ u: Double) -> Double {
        switch phase {
        case .inhale: return config.easeIn(u)
        case .holdAfterInhale: return 1
        case .exhale: return 1 - config.easeOut(u)
        case .holdAfterExhale: return 0
        }
    }

    /// One soft rise and fall across a hold.
    private func pulse(_ u: Double) -> Double {
        let x = min(1, max(0, u))
        return x <= 0.5 ? Easing.smooth(x / 0.5) : Easing.smooth((1 - x) / 0.5)
    }

    /// Sample the timeline. `time` may run past the end; it wraps.
    public func at(_ time: Double) -> BreathState {
        let wrapped = ((time.truncatingRemainder(dividingBy: totalSeconds)) + totalSeconds)
            .truncatingRemainder(dividingBy: totalSeconds)
        // Truncation rather than floor, and they are the same thing here:
        // `wrapped` is non-negative by construction after the double modulo, so
        // there is no negative case for the two to disagree on. Verified by
        // swapping them and watching nothing change.
        let cycle = Int(wrapped / cycleSeconds)
        let cycleTime = wrapped - Double(cycle) * cycleSeconds

        // Two separate rules live in these four lines.
        //
        // **A boundary instant belongs to the phase that follows it.** The
        // comparison is strictly `<`, so at t = 4.0 of a 4-6 breath the state is
        // *exhale at 0*, not *inhale at 1*. Relaxing it to `<=` reverses that
        // and fails 24 of the fixture's assertions — and note what that failure
        // looks like: both states put the body in the same place, so nothing on
        // screen is wrong. Only the phase label, and everything keyed off it,
        // is.
        //
        // **The fallback catches the end of the cycle.** Starting from the last
        // phase means `cycleTime == cycleSeconds` — reachable only through
        // floating point — lands there rather than falling off the end.
        var span = phases[phases.count - 1]
        for p in phases where cycleTime < p.end {
            span = p
            break
        }

        let phaseProgress = span.seconds > 0
            ? min(1, max(0, (cycleTime - span.start) / span.seconds))
            : 0

        return BreathState(
            time: wrapped,
            cycle: cycle,
            cycleTime: cycleTime,
            phase: span.phase,
            phaseIndex: phases.firstIndex(of: span) ?? 0,
            phaseSeconds: span.seconds,
            phaseStart: span.start,
            phaseProgress: phaseProgress,
            progress: phaseValue(span.phase, phaseProgress),
            holdPulse: span.phase.isHold ? pulse(phaseProgress) : 0
        )
    }
}
