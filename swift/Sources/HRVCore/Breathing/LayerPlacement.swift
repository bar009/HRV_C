import Foundation

/// Where a layer's PNG sits in the composition, and how big.
public struct Placement: Sendable, Equatable {
    /// Top-left of the asset, in composition pixels.
    public var position: SIMD2<Double>
    /// 1 = the asset at its authored size.
    public var scale: SIMD2<Double>
    public var opacity: Double
}

/// One exported layer image: the crop it was cut from, in art units.
public struct LayerAsset: Sendable, Equatable {
    public let file: String
    public let cropX: Double
    public let cropY: Double
    public let width: Int
    public let height: Int

    public init(file: String, cropX: Double, cropY: Double, width: Int, height: Int) {
        self.file = file
        self.cropX = cropX
        self.cropY = cropY
        self.width = width
        self.height = height
    }
}

/// The one conversion between the artwork's coordinates and the composition's.
public enum ArtSpace {
    public static let artWidth = 1024.0
    public static let artHeight = 1536.0
    public static let out = 1080.0

    /// Square crop in art units; centres the content with about 6.7% margin.
    public static let cropX = -76.0
    public static let cropY = 133.0
    public static let cropSize = 1240.0

    /// Art units to composition pixels. One output pixel is 1.148 art units.
    public static let k = out / cropSize

    public static func toComposition(_ x: Double, _ y: Double) -> SIMD2<Double> {
        SIMD2((x - cropX) * k, (y - cropY) * k)
    }
}

/// Turns layer transforms into image placements. Port of `totalTransform` and
/// `lottieTransform` in `breathing-poc/tools/generate-lottie.mjs`.
///
/// The reference verifies that path against the browser to within a pixel over
/// every frame, so it is the one worth matching — rather than deriving a
/// placement independently and hoping the two agree.
public enum LayerPlacement {

    /// A layer's transform folded into `scale * v + offset`, in art
    /// coordinates, with its parents already composed in.
    ///
    /// Folding here rather than nesting transforms is both simpler and exact:
    /// a chain of scale-about-a-pivot operations composes to a single scale and
    /// offset, so there is nothing to accumulate error between.
    static func fold(_ id: String,
                     _ transforms: [String: LayerTransform],
                     _ parentOf: [String: String]) -> (scale: SIMD2<Double>, offset: SIMD2<Double>) {
        guard let v = transforms[id] else { return (SIMD2(1, 1), SIMD2(0, 0)) }

        // A scale about a pivot is `s * (x - pivot) + pivot`, which rearranges
        // to `s * x + pivot * (1 - s)`. That is the offset below.
        let own = (
            scale: v.scale,
            offset: SIMD2(v.translate.x + v.pivot.x * (1 - v.scale.x),
                          v.translate.y + v.pivot.y * (1 - v.scale.y))
        )

        guard let parent = parentOf[id] else { return own }
        let p = fold(parent, transforms, parentOf)
        return (
            scale: SIMD2(p.scale.x * own.scale.x, p.scale.y * own.scale.y),
            offset: SIMD2(p.scale.x * own.offset.x + p.offset.x,
                          p.scale.y * own.offset.y + p.offset.y)
        )
    }

    /// Every drawable layer's placement for one instant.
    ///
    /// `root` is applied to all of them, which is what makes the whole-avatar
    /// stretch free of seams: every layer rides the same transform, so there is
    /// no differential anywhere and no mask edge to smear. The layers that
    /// cancel it — the head and the ears — do so through their own scale, so
    /// they are folded exactly like everything else rather than being special
    /// cased here.
    public static func place(layers: [PoseLayer],
                             transforms: [String: LayerTransform],
                             assets: [String: LayerAsset],
                             assetScale: Double = 1) -> [String: Placement] {
        var parentOf: [String: String] = [:]
        for layer in layers where layer.kind != .root {
            // Everything hangs off the root; a layer that follows another hangs
            // off that instead, and reaches the root through it.
            parentOf[layer.id] = layer.parent ?? "root"
        }

        var out: [String: Placement] = [:]
        for layer in layers {
            guard let asset = assets[layer.id], let v = transforms[layer.id] else { continue }
            let f = fold(layer.id, transforms, parentOf)

            // The anchor stays at the asset's top-left, so position carries the
            // whole offset — which keeps scale a pure two-channel value and
            // leaves nothing implicit in the anchor.
            let x = (f.scale.x * asset.cropX + f.offset.x - ArtSpace.cropX) * ArtSpace.k
            let y = (f.scale.y * asset.cropY + f.offset.y - ArtSpace.cropY) * ArtSpace.k

            out[layer.id] = Placement(
                position: SIMD2(x, y),
                scale: SIMD2(f.scale.x / assetScale, f.scale.y / assetScale),
                opacity: v.opacity
            )
        }
        return out
    }
}
