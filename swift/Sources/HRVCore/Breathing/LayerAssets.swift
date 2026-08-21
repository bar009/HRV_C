import Foundation

/// The exported layer images and the crops they were cut from.
///
/// **This file is generated** by `tools/export-swift-placements.mjs` in the
/// breathing-poc repo, from the built asset manifests. Regenerate it after
/// `npm run assets` — the crops are derived from each layer's support box, so
/// a change to the rig's geometry moves them.
public enum LayerAssets {
    /// 22 images, assetScale 1.
    public static let standing: [String: LayerAsset] = [
        "base": LayerAsset(file: "base.png", cropX: 163.00000000000000, cropY: 204.00000000000000, width: 663, height: 956),
        "torso": LayerAsset(file: "torso.png", cropX: 163.00000000000000, cropY: 718.00000000000000, width: 663, height: 391),
        "ribs": LayerAsset(file: "ribs.png", cropX: 163.00000000000000, cropY: 788.00000000000000, width: 663, height: 226),
        "chest": LayerAsset(file: "chest.png", cropX: 163.00000000000000, cropY: 723.00000000000000, width: 663, height: 186),
        "bellyUpper": LayerAsset(file: "bellyUpper.png", cropX: 328.00000000000000, cropY: 792.00000000000000, width: 334, height: 188),
        "bellyLower": LayerAsset(file: "bellyLower.png", cropX: 333.00000000000000, cropY: 863.00000000000000, width: 334, height: 239),
        "arms": LayerAsset(file: "arms.png", cropX: 163.00000000000000, cropY: 908.00000000000000, width: 578, height: 186),
        "tail": LayerAsset(file: "tail.png", cropX: 730.00000000000000, cropY: 868.00000000000000, width: 169, height: 378),
        "head": LayerAsset(file: "head.png", cropX: 163.00000000000000, cropY: 204.00000000000000, width: 663, height: 599),
        "ears": LayerAsset(file: "ears.png", cropX: 163.00000000000000, cropY: 204.00000000000000, width: 650, height: 280),
        "lidSoft": LayerAsset(file: "eyes-soft.png", cropX: 291.00000000000000, cropY: 497.00000000000000, width: 371, height: 159),
        "lidHalf": LayerAsset(file: "eyes-half-closed.png", cropX: 291.00000000000000, cropY: 497.00000000000000, width: 371, height: 159),
        "lidMostly": LayerAsset(file: "eyes-mostly-closed.png", cropX: 291.00000000000000, cropY: 497.00000000000000, width: 371, height: 159),
        "lidClosed": LayerAsset(file: "eyes-closed.png", cropX: 291.00000000000000, cropY: 497.00000000000000, width: 371, height: 159),
        "mouthPursed": LayerAsset(file: "mouth-pursed.png", cropX: 396.00000000000000, cropY: 626.00000000000000, width: 190, height: 85),
        "mouthTongue": LayerAsset(file: "mouth-tongue.png", cropX: 396.00000000000000, cropY: 626.00000000000000, width: 190, height: 85),
        "mouthSigh": LayerAsset(file: "mouth-sigh.png", cropX: 396.00000000000000, cropY: 626.00000000000000, width: 190, height: 85),
        "mouthNose": LayerAsset(file: "nose-flare.png", cropX: 446.00000000000000, cropY: 614.00000000000000, width: 103, height: 51),
        "mouthNoseLeft": LayerAsset(file: "mouthNoseLeft.png", cropX: 388.00000000000000, cropY: 606.00000000000000, width: 207, height: 103),
        "mouthNoseRight": LayerAsset(file: "mouthNoseRight.png", cropX: 388.00000000000000, cropY: 606.00000000000000, width: 207, height: 103),
        "mouthLion": LayerAsset(file: "mouthLion.png", cropX: 396.00000000000000, cropY: 626.00000000000000, width: 190, height: 99),
        "mouthCheek": LayerAsset(file: "cheeks-hum.png", cropX: 276.00000000000000, cropY: 618.00000000000000, width: 411, height: 105),
    ]

    /// 22 images, assetScale 1.
    public static let seated: [String: LayerAsset] = [
        "base": LayerAsset(file: "base.png", cropX: 83.000000000000000, cropY: 135.00000000000000, width: 825, height: 1077),
        "torso": LayerAsset(file: "torso.png", cropX: 83.000000000000000, cropY: 778.00000000000000, width: 825, height: 378),
        "ribs": LayerAsset(file: "ribs.png", cropX: 83.000000000000000, cropY: 853.00000000000000, width: 825, height: 226),
        "chest": LayerAsset(file: "chest.png", cropX: 83.000000000000000, cropY: 783.00000000000000, width: 825, height: 191),
        "bellyUpper": LayerAsset(file: "bellyUpper.png", cropX: 341.00000000000000, cropY: 788.00000000000000, width: 282, height: 204),
        "bellyLower": LayerAsset(file: "bellyLower.png", cropX: 341.00000000000000, cropY: 918.00000000000000, width: 282, height: 273),
        "tail": LayerAsset(file: "tail.png", cropX: 748.00000000000000, cropY: 848.00000000000000, width: 246, height: 456),
        "head": LayerAsset(file: "head.png", cropX: 83.000000000000000, cropY: 135.00000000000000, width: 825, height: 659),
        "legs": LayerAsset(file: "legs.png", cropX: 83.000000000000000, cropY: 1118.0000000000000, width: 825, height: 220),
        "ears": LayerAsset(file: "ears.png", cropX: 88.000000000000000, cropY: 139.00000000000000, width: 733, height: 322),
        "lidSoft": LayerAsset(file: "eyes-soft.png", cropX: 266.00000000000000, cropY: 486.00000000000000, width: 418, height: 175),
        "lidHalf": LayerAsset(file: "eyes-half-closed.png", cropX: 266.00000000000000, cropY: 486.00000000000000, width: 418, height: 175),
        "lidMostly": LayerAsset(file: "eyes-mostly-closed.png", cropX: 266.00000000000000, cropY: 486.00000000000000, width: 418, height: 175),
        "lidClosed": LayerAsset(file: "eyes-closed.png", cropX: 266.00000000000000, cropY: 486.00000000000000, width: 418, height: 175),
        "mouthPursed": LayerAsset(file: "mouth-pursed.png", cropX: 398.00000000000000, cropY: 648.00000000000000, width: 186, height: 87),
        "mouthTongue": LayerAsset(file: "mouth-tongue.png", cropX: 398.00000000000000, cropY: 648.00000000000000, width: 186, height: 87),
        "mouthSigh": LayerAsset(file: "mouth-sigh.png", cropX: 398.00000000000000, cropY: 648.00000000000000, width: 186, height: 87),
        "mouthNose": LayerAsset(file: "nose-flare.png", cropX: 443.00000000000000, cropY: 628.00000000000000, width: 108, height: 52),
        "mouthNoseLeft": LayerAsset(file: "mouthNoseLeft.png", cropX: 388.00000000000000, cropY: 620.00000000000000, width: 211, height: 105),
        "mouthNoseRight": LayerAsset(file: "mouthNoseRight.png", cropX: 388.00000000000000, cropY: 620.00000000000000, width: 211, height: 105),
        "mouthLion": LayerAsset(file: "mouthLion.png", cropX: 398.00000000000000, cropY: 648.00000000000000, width: 186, height: 100),
        "mouthCheek": LayerAsset(file: "cheeks-hum.png", cropX: 264.00000000000000, cropY: 628.00000000000000, width: 430, height: 91),
    ]
}
