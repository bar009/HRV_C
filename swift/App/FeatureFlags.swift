// Practice-engine capabilities open independently after their own device,
// content, privacy and accessibility gates pass.
import Foundation

enum FeatureFlags {
    static var practiceCatalogEnabled: Bool { enabled("practiceCatalog") }
    static var practiceRunnerEnabled: Bool { enabled("practiceRunner") }
    static var polarLiveMetricsEnabled: Bool { enabled("polarLiveMetrics") }
    static var watchPracticeCompanionEnabled: Bool { enabled("watchPracticeCompanion") }
    static var personalRecommendationsEnabled: Bool { enabled("personalRecommendations") }
    static var personalCalibrationEnabled: Bool { enabled("personalCalibration") }
    static var recordedGuidanceEnabled: Bool { enabled("recordedGuidance") }

    // Compatibility name for the existing Track-J tab while PracticeScreen is
    // replaced incrementally by the personal practice engine.
    static var coherenceEnabled: Bool {
        practiceCatalogEnabled || enabled("coherence")
    }

    private static func enabled(_ name: String) -> Bool {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-\(name)On") { return true }
        #endif
        return false
    }
}
