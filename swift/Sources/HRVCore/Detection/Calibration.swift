import Foundation

// Personal calibration profile (strategy memo — "כיול לפי מגדר"). HRV
// physiology differs by sex, and the memo plans the pilot with that in mind
// (women calibrated separately). This is the pure, platform-free hook that
// carries the profile into detection.

public enum BiologicalSex: String, Sendable, CaseIterable, Equatable {
    case unspecified, female, male
}

public struct CalibrationProfile: Sendable, Equatable {
    public var sex: BiologicalSex
    public init(sex: BiologicalSex = .unspecified) { self.sex = sex }
}

public enum CalibrationProfiles {
    /// The detector config tuned for this profile.
    ///
    /// HRV differs by sex at the *population* level — but this app already
    /// compares each person to their OWN baseline (median + MAD on their ln
    /// history), which neutralizes most population differences. So today this
    /// returns the base config unchanged for every sex. The hook exists so that
    /// once the calibration study provides validated, sex-specific parameters
    /// (and a real female cohort — Q-B), they drop in here. We deliberately do
    /// NOT invent deltas before then.
    public static func config(for profile: CalibrationProfile,
                              base: DetectorConfig = DetectorConfig()) -> DetectorConfig {
        switch profile.sex {
        case .unspecified, .female, .male:
            return base
        }
    }
}
