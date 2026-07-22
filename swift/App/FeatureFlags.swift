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

    /// The guided breathing tab. ON: a standalone breathing pacer usable on
    /// iPhone alone. The live coherence *score* inside it stays hidden until real
    /// beats stream from an Apple Watch (see `CoherenceSessionController
    /// .hasCoherence`), so with no watch it is purely a breathing exercise.
    /// `coherenceEnabled` still gates the coherence *trend* in the Trends tab.
    static var breathingEnabled: Bool { true }

    /// Beat-series metrics (RMSSD/pNN50/SDSD from HKHeartbeatSeriesSample).
    /// ENABLED for TestFlight: it works on iPhone alone (no watch app needed)
    /// and doubles as the Q-A field test -- the "מדדים מפורטים" card appears
    /// only if the device has beat-to-beat series. Display-only, graceful when
    /// absent. Revisit before public submission if Q-A comes back negative.
    static var advancedMetricsEnabled: Bool { true }
}
