import Foundation

/// What a layer does when the body breathes. Port of the motion fields of
/// `buildLayers` in `breathing-poc/src/mascot-layers.js`.
///
/// Only the fields that move. The reference's layer objects also carry a mask
/// and a support box, which exist to *generate* the layer's PNG — that happens
/// once, in the reference repo, and what ships is the resulting image plus its
/// crop. A renderer needs to know where to put the picture, not how it was cut
/// out.
public struct PoseLayer: Sendable {
    public enum Kind: String, Sendable {
        case root, mascot, lid, mouth, marker
    }

    /// A second, differently-eased movement laid on top of what the layer
    /// already does — the ears dropping on a release, the shoulders bracing.
    public struct Extra: Sendable {
        public let region: BreathRegion
        public let translate: (x: Double, y: Double)

        public init(region: BreathRegion, translate: (x: Double, y: Double)) {
            self.region = region
            self.translate = translate
        }
    }

    public let id: String
    public let kind: Kind
    public let region: BreathRegion?

    /// The layer this one rides. The reference has two fields for it — `parent`
    /// for a region nested inside another, `follows` for a face drawing carried
    /// by the head — and they behave identically when folding a transform, so
    /// they arrive merged. Anything without one hangs off the root.
    public let parent: String?

    public let pivot: (x: Double, y: Double)?
    public let scale: (x: Double, y: Double)?
    public let translate: (x: Double, y: Double)?

    /// Cancels the root's breath stretch exactly, so the head and ears keep
    /// their size while the body lengthens.
    public let counter: Bool

    public let extras: [Extra]

    /// Mouth layers: which face drawing this is, and whether it is driven by a
    /// phase rather than by the exercise's technique.
    public let mouthState: String?
    public let phaseCue: BreathRegion?

    /// Lid layers: the soft lid fades with the breath; the three blink drawings
    /// are switched by the blink controller instead.
    public let breathLid: Bool
    public let close: Double?

    public init(id: String,
                kind: Kind,
                region: BreathRegion? = nil,
                parent: String? = nil,
                pivot: (x: Double, y: Double)? = nil,
                scale: (x: Double, y: Double)? = nil,
                translate: (x: Double, y: Double)? = nil,
                counter: Bool = false,
                extras: [Extra] = [],
                mouthState: String? = nil,
                phaseCue: BreathRegion? = nil,
                breathLid: Bool = false,
                close: Double? = nil) {
        self.id = id
        self.kind = kind
        self.region = region
        self.parent = parent
        self.pivot = pivot
        self.scale = scale
        self.translate = translate
        self.counter = counter
        self.extras = extras
        self.mouthState = mouthState
        self.phaseCue = phaseCue
        self.breathLid = breathLid
        self.close = close
    }
}

/// One layer's transform at one instant.
public struct LayerTransform: Sendable, Equatable {
    public var pivot: SIMD2<Double>
    public var scale: SIMD2<Double>
    public var translate: SIMD2<Double>
    public var rotate: Double
    public var opacity: Double
}

/// Which face drawing each half of the breath uses.
public struct FacePair: Sendable, Equatable {
    public let inhale: String?
    public let exhale: String?

    public init(inhale: String? = nil, exhale: String? = nil) {
        self.inhale = inhale
        self.exhale = exhale
    }
}

/// Everything that can vary between two renders of the same instant.
public struct PoseOptions: Sendable {
    /// Multiplies every breath amount. 1 ships; higher is for inspection.
    public var exaggerate: Double = 1
    /// 0 = per-region breathing only, 1 = the whole living body.
    public var intensity: Double = 1
    /// Per-region amplitude gains. Focus scales amplitude, never timing.
    public var focus: [BreathRegion: Double] = [:]
    public var faces: FacePair = FacePair()
    /// Which blink drawing is showing, if any.
    public var lid: String?

    public init(exaggerate: Double = 1,
                intensity: Double = 1,
                focus: [BreathRegion: Double] = [:],
                faces: FacePair = FacePair(),
                lid: String? = nil) {
        self.exaggerate = exaggerate
        self.intensity = intensity
        self.focus = focus
        self.faces = faces
        self.lid = lid
    }
}

/// Every layer's transform for one instant. Port of `poseValues`.
///
/// The SVG the reference draws and the Lottie it exports are both built from
/// this one function, which is why they cannot disagree — and it is why this is
/// the module worth being most careful about.
public enum PoseComposer {

    /// The soft lid never goes past a quarter. Past that it stops reading as a
    /// relaxed eye and starts reading as a sleepy one.
    public static let softLidMaxOpacity = 0.25

    public static func compose(layers: [PoseLayer],
                               breath: [BreathRegion: Double],
                               options: PoseOptions = PoseOptions()) -> [String: LayerTransform] {
        let gain = options.exaggerate
        let life = options.intensity
        var out: [String: LayerTransform] = [:]

        func amount(_ region: BreathRegion?) -> Double {
            guard let region else { return 0 }
            return breath[region] ?? 0
        }

        // The root is computed first: the head and ears cancel it, so they need
        // its final value rather than their own breath amount.
        guard let rootLayer = layers.first(where: { $0.kind == .root }) else { return out }
        let rb = amount(.root) * gain
        let rootScale = rootLayer.scale ?? (x: 0, y: 0)

        // Breath and beat scales compose by multiplication rather than
        // addition, because in the export they are two nested nulls rather than
        // one. Splitting them is what lets each stay a single-channel property,
        // and a single-channel property is the only kind a Lottie keyframe
        // carries exactly rather than approximately.
        let breathScale = SIMD2(1 + rootScale.x * rb * life,
                                1 + rootScale.y * rb * life)

        out["root"] = LayerTransform(
            pivot: SIMD2(rootLayer.pivot?.x ?? 0, rootLayer.pivot?.y ?? 0),
            scale: breathScale,
            translate: SIMD2(0, 0),
            rotate: 0,
            opacity: 1
        )

        for layer in layers where layer.kind != .root {
            // Focus gains multiply a region's amplitude, not its timing: the
            // sequence is still belly then ribs then chest, but the region being
            // breathed into travels further and its neighbours are damped.
            let focusGain = layer.region.flatMap { options.focus[$0] } ?? 1
            let b = amount(layer.region) * gain * focusGain

            switch layer.kind {
            case .root:
                continue

            case .marker:
                // A preview aid, deliberately never exported. Kept in the table
                // so the two sides agree about what exists.
                out[layer.id] = LayerTransform(pivot: SIMD2(0, 0), scale: SIMD2(1, 1),
                                               translate: SIMD2(0, 0), rotate: 0, opacity: 0)

            case .mouth:
                // The two technique regions are never non-zero at the same time
                // — they belong to different phases — so summing them is exact,
                // and one drawing can serve both halves of the breath.
                var value = 0.0
                if options.faces.inhale == layer.mouthState { value += amount(.techniqueIn) }
                if options.faces.exhale == layer.mouthState { value += amount(.techniqueOut) }

                // The nostrils are lit by the phase instead. `max`, not a sum:
                // the two sources can never both be live — no technique draws
                // the nose — and a sum would hide it if one day one did.
                let cue = layer.phaseCue.map { amount($0) } ?? 0
                out[layer.id] = LayerTransform(pivot: SIMD2(0, 0), scale: SIMD2(1, 1),
                                               translate: SIMD2(0, 0), rotate: 0,
                                               opacity: min(1, max(value, cue)))

            case .lid:
                // The soft lid fades with the breath — fully open at the top of
                // an inhale, softened at rest. It hides completely while a blink
                // is playing, or two lids would stack into one much heavier
                // eyelid.
                let opacity: Double
                if layer.breathLid {
                    opacity = options.lid != nil ? 0 : amount(.release) * softLidMaxOpacity * life
                } else {
                    opacity = options.lid == layer.id ? 1 : 0
                }
                out[layer.id] = LayerTransform(pivot: SIMD2(0, 0), scale: SIMD2(1, 1),
                                               translate: SIMD2(0, 0), rotate: 0, opacity: opacity)

            case .mascot:
                // The counter cancels the *breath* stretch only. An idle bob is
                // left to carry the head with it: at 0.26% that is a whole-body
                // idle stretch, which is what a body at rest actually does.
                let scale: SIMD2<Double>
                if layer.counter {
                    scale = SIMD2(1 / breathScale.x, 1 / breathScale.y)
                } else if let s = layer.scale {
                    scale = SIMD2(1 + s.x * b, 1 + s.y * b)
                } else {
                    scale = SIMD2(1, 1)
                }

                // The release rides on top of whatever the layer already does.
                var extras = SIMD2(0.0, 0.0)
                for x in layer.extras {
                    let a = amount(x.region) * life
                    extras.x += x.translate.x * a
                    extras.y += x.translate.y * a
                }

                let hasOwnPivot = layer.counter || layer.scale != nil
                out[layer.id] = LayerTransform(
                    pivot: hasOwnPivot ? SIMD2(layer.pivot?.x ?? 0, layer.pivot?.y ?? 0) : SIMD2(0, 0),
                    scale: scale,
                    translate: SIMD2((layer.translate?.x ?? 0) * b + extras.x,
                                     (layer.translate?.y ?? 0) * b + extras.y),
                    rotate: 0,
                    opacity: 1
                )
            }
        }

        return out
    }
}
