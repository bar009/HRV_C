import Foundation

/// The layer tables, one per body.
///
/// **This file is generated** by `tools/export-swift-fixtures.mjs` in the
/// breathing-poc repo, from `buildLayers(pose)`. Do not edit it: the geometry
/// is measured there, and some of these amplitudes are derived from a pose's own
/// landmarks rather than declared — the arms' horizontal scale divides a pixel
/// target by the distance from the pivot to the arm's outer edge.
///
/// The two stacks are the same length. Seated trades arms for folded legs
/// one-for-one, so **a layer count can never tell them apart** — only the ids
/// can. That has already caused one silent failure in the reference.
public enum PoseLayers {
    /// 26 layers.
    public static let standing: [PoseLayer] = [
        PoseLayer(id: "root", kind: .root, region: .root, pivot: (500.00000000000000, 1290.0000000000000), scale: (-0.0040000000000000001, 0.020000000000000000)),
        PoseLayer(id: "base", kind: .mascot),
        PoseLayer(id: "torso", kind: .mascot, region: .torso, pivot: (500.00000000000000, 1150.0000000000000), scale: (0.010000000000000000, 0.0032000000000000002)),
        PoseLayer(id: "ribs", kind: .mascot, region: .ribs, pivot: (500.00000000000000, 1150.0000000000000), scale: (0.017821782178217838, 0.0000000000000000)),
        PoseLayer(id: "chest", kind: .mascot, region: .chest, pivot: (500.00000000000000, 1150.0000000000000), scale: (0.0010000000000000000, 0.0000000000000000), translate: (0.0000000000000000, -1.5847407407407403)),
        PoseLayer(id: "bellyUpper", kind: .mascot, region: .bellyUpper, pivot: (522.00000000000000, 1105.0000000000000), scale: (0.0030000000000000001, 0.0000000000000000), translate: (0.0000000000000000, -0.23614814814814811), extras: [.init(region: .lock, translate: (0.0000000000000000, -2.8703703703703702))]),
        PoseLayer(id: "bellyLower", kind: .mascot, region: .bellyLower, pivot: (522.00000000000000, 1105.0000000000000), scale: (0.023762376237623783, 0.013755980861243744), extras: [.init(region: .lock, translate: (0.0000000000000000, -6.3148148148148149))]),
        PoseLayer(id: "arms", kind: .mascot, region: .arms, pivot: (500.00000000000000, 1150.0000000000000), scale: (0.015164220824598182, 0.0032000000000000002), translate: (0.0000000000000000, -2.7555555555555555), extras: [.init(region: .release, translate: (0.0000000000000000, 2.0666666666666669)), .init(region: .hold, translate: (0.0000000000000000, -1.6074074074074074))]),
        PoseLayer(id: "tail", kind: .mascot, region: .tail, translate: (0.0000000000000000, 3.2148148148148148)),
        PoseLayer(id: "head", kind: .mascot, region: .head, pivot: (505.00000000000000, 780.00000000000000), translate: (0.0000000000000000, -2.0092592592592591), counter: true),
        PoseLayer(id: "ears", kind: .mascot, region: .ears, pivot: (505.00000000000000, 780.00000000000000), translate: (0.0000000000000000, 3.6740740740740740), counter: true, extras: [.init(region: .release, translate: (0.0000000000000000, 2.9851851851851854)), .init(region: .hold, translate: (0.0000000000000000, -2.5259259259259261))]),
        PoseLayer(id: "lidSoft", kind: .lid, breathLid: true, close: 0.25000000000000000),
        PoseLayer(id: "lidHalf", kind: .lid, close: 0.55000000000000004),
        PoseLayer(id: "lidMostly", kind: .lid, close: 0.80000000000000004),
        PoseLayer(id: "lidClosed", kind: .lid, close: 1.0000000000000000),
        PoseLayer(id: "mouthPursed", kind: .mouth, mouthState: "pursed"),
        PoseLayer(id: "mouthTongue", kind: .mouth, mouthState: "tongue"),
        PoseLayer(id: "mouthSigh", kind: .mouth, mouthState: "sigh"),
        PoseLayer(id: "mouthNose", kind: .mouth, mouthState: "nose", phaseCue: .noseOut),
        PoseLayer(id: "mouthNoseLeft", kind: .mouth, mouthState: "noseLeft"),
        PoseLayer(id: "mouthNoseRight", kind: .mouth, mouthState: "noseRight"),
        PoseLayer(id: "mouthLion", kind: .mouth, mouthState: "lion"),
        PoseLayer(id: "mouthCheek", kind: .mouth, mouthState: "cheek"),
        PoseLayer(id: "markerBelly", kind: .marker),
        PoseLayer(id: "markerRibs", kind: .marker),
        PoseLayer(id: "markerChest", kind: .marker),
    ]

    /// 26 layers.
    public static let seated: [PoseLayer] = [
        PoseLayer(id: "root", kind: .root, region: .root, pivot: (506.00000000000000, 1358.0000000000000), scale: (-0.0037599999999999999, 0.018800000000000001)),
        PoseLayer(id: "base", kind: .mascot),
        PoseLayer(id: "torso", kind: .mascot, region: .torso, pivot: (506.00000000000000, 1150.0000000000000), scale: (0.0094000000000000004, 0.0030079999999999998)),
        PoseLayer(id: "ribs", kind: .mascot, region: .ribs, pivot: (506.00000000000000, 1150.0000000000000), scale: (0.016752475247524767, 0.0000000000000000)),
        PoseLayer(id: "chest", kind: .mascot, region: .chest, pivot: (506.00000000000000, 1150.0000000000000), scale: (0.00093999999999999997, 0.0000000000000000), translate: (0.0000000000000000, -1.4896562962962958)),
        PoseLayer(id: "bellyUpper", kind: .mascot, region: .bellyUpper, pivot: (503.00000000000000, 1200.0000000000000), scale: (0.0028200000000000000, 0.0000000000000000), translate: (0.0000000000000000, -0.22197925925925921), extras: [.init(region: .lock, translate: (0.0000000000000000, -2.8703703703703702))]),
        PoseLayer(id: "bellyLower", kind: .mascot, region: .bellyLower, pivot: (503.00000000000000, 1200.0000000000000), scale: (0.022336633663366356, 0.012930622009569119), extras: [.init(region: .lock, translate: (0.0000000000000000, -6.3148148148148149))]),
        PoseLayer(id: "tail", kind: .mascot, region: .tail, translate: (0.0000000000000000, 3.2148148148148148)),
        PoseLayer(id: "head", kind: .mascot, region: .head, pivot: (506.00000000000000, 803.00000000000000), translate: (0.0000000000000000, -1.8887037037037033), counter: true),
        PoseLayer(id: "legs", kind: .mascot, pivot: (506.00000000000000, 1358.0000000000000), counter: true),
        PoseLayer(id: "ears", kind: .mascot, region: .ears, pivot: (506.00000000000000, 803.00000000000000), translate: (0.0000000000000000, 3.6740740740740740), counter: true, extras: [.init(region: .release, translate: (0.0000000000000000, 2.9851851851851854)), .init(region: .hold, translate: (0.0000000000000000, -2.5259259259259261))]),
        PoseLayer(id: "lidSoft", kind: .lid, breathLid: true, close: 0.25000000000000000),
        PoseLayer(id: "lidHalf", kind: .lid, close: 0.55000000000000004),
        PoseLayer(id: "lidMostly", kind: .lid, close: 0.80000000000000004),
        PoseLayer(id: "lidClosed", kind: .lid, close: 1.0000000000000000),
        PoseLayer(id: "mouthPursed", kind: .mouth, mouthState: "pursed"),
        PoseLayer(id: "mouthTongue", kind: .mouth, mouthState: "tongue"),
        PoseLayer(id: "mouthSigh", kind: .mouth, mouthState: "sigh"),
        PoseLayer(id: "mouthNose", kind: .mouth, mouthState: "nose", phaseCue: .noseOut),
        PoseLayer(id: "mouthNoseLeft", kind: .mouth, mouthState: "noseLeft"),
        PoseLayer(id: "mouthNoseRight", kind: .mouth, mouthState: "noseRight"),
        PoseLayer(id: "mouthLion", kind: .mouth, mouthState: "lion"),
        PoseLayer(id: "mouthCheek", kind: .mouth, mouthState: "cheek"),
        PoseLayer(id: "markerBelly", kind: .marker),
        PoseLayer(id: "markerRibs", kind: .marker),
        PoseLayer(id: "markerChest", kind: .marker),
    ]
}
