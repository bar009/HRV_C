// Track J ships behind a flag: coherence is built now but kept OUT of the
// first App Store submission (v1 = the validated passive app; coherence in
// v1.1 after real-watch validation). When the flag is off, the practice tab
// and its HealthKit needs don't exist.
import Foundation

enum FeatureFlags {
    /// Off for v1. A DEBUG launch arg (`-coherenceOn`) flips it for demo and
    /// screenshots, mirroring the existing `-startTab` hooks.
    static var coherenceEnabled: Bool {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-coherenceOn") { return true }
        #endif
        return false
    }
}
