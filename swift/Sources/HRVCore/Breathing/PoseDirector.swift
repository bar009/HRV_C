import Foundation

/// Which body the character is wearing.
public enum PoseName: String, Sendable, CaseIterable {
    case standing, seated
    case greet, celebrate, demonstrate, pause, sleep, demonstrateNostril

    /// The two that carry exercises. Everything else plays for a second or two.
    public var isBreathing: Bool { self == .standing || self == .seated }

    public var layers: [PoseLayer] {
        switch self {
        case .standing: return PoseLayers.standing
        case .seated: return PoseLayers.seated
        case .greet: return PoseLayers.greet
        case .celebrate: return PoseLayers.celebrate
        case .demonstrate: return PoseLayers.demonstrate
        case .pause: return PoseLayers.pause
        case .sleep: return PoseLayers.sleep
        case .demonstrateNostril: return PoseLayers.demonstrateNostril
        }
    }

    public var assets: [String: LayerAsset] {
        switch self {
        case .standing: return LayerAssets.standing
        case .seated: return LayerAssets.seated
        case .greet: return LayerAssets.greet
        case .celebrate: return LayerAssets.celebrate
        case .demonstrate: return LayerAssets.demonstrate
        case .pause: return LayerAssets.pause
        case .sleep: return LayerAssets.sleep
        case .demonstrateNostril: return LayerAssets.demonstrateNostril
        }
    }

    /// A drawing whose eyes are shut has no eyelid layers, so nothing can blink
    /// on it. Derived from the stack rather than declared twice.
    public var canBlink: Bool { layers.contains { $0.kind == .lid } }
}

/// What the character is doing right now.
public struct PoseFrame: Sendable, Equatable {
    public let pose: PoseName
    /// Non-nil while a one-shot is playing: how far into it, in seconds.
    public let beatTime: Double?
    public let beat: String?
}

/// Decides which body is on screen, and when it changes.
///
/// ## Why the swap hides inside a beat
///
/// Swapping one drawing for another is a cut, and a cut is hidden when it is
/// **smaller than the motion around it**. So a swap never happens on a still
/// character: it happens at the fastest instant of a one-shot, where the body is
/// already travelling hard enough that a change of silhouette reads as part of
/// the movement.
///
/// Those instants are measured, not chosen. See `OneShot.swapAt` — the first
/// version of this used control-point positions, which are neither the fastest
/// instant nor the largest displacement.
public struct PoseDirector: Sendable {

    /// The body an exercise breathes in. Derived in the reference from what the
    /// exercise asks of a person — energising practices stand, sleep practices
    /// sit regardless of length, practices counted in rounds stand, and anything
    /// five minutes or longer sits.
    public let breathingPose: PoseName

    /// Whether this exercise's first cycle demonstrates a technique, and which
    /// drawing shows it.
    public let demonstration: PoseName?

    public init(breathingPose: PoseName, demonstration: PoseName? = nil) {
        precondition(breathingPose.isBreathing,
                     "an exercise breathes in a breathing pose, not \(breathingPose)")
        self.breathingPose = breathingPose
        self.demonstration = demonstration
    }

    /// The pose at one instant of a session.
    ///
    /// `beat` is whichever one-shot is playing, with the time since it started.
    /// Outside a beat the character is simply breathing.
    public func frame(at t: Double, beat: OneShot?, beatStartedAt: Double?) -> PoseFrame {
        guard let beat, let started = beatStartedAt else {
            return PoseFrame(pose: breathingPose, beatTime: nil, beat: nil)
        }
        let local = t - started
        guard local >= 0, local < beat.duration else {
            return PoseFrame(pose: breathingPose, beatTime: nil, beat: nil)
        }

        // Before the swap instant the character is still in the body it was in;
        // after it, the beat's own. That is what makes the cut land inside the
        // movement rather than at either end of it.
        let target: PoseName = beat.name == "intro" ? .greet : .celebrate
        let pose = local < beat.swapAt ? breathingPose : target
        return PoseFrame(pose: pose, beatTime: local, beat: beat.name)
    }
}
