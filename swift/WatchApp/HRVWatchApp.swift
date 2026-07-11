// Track E -- watchOS app entry (Mac-only). Minimal for the passive MVP: the
// iPhone app reads HealthKit and owns detection. Full on-watch data + the
// Workout Session for the future active/Coherence mode (D-COH) land in Track E.
import SwiftUI

@main
struct HRVWatchApp: App {
    var body: some Scene {
        WindowGroup {
            WatchStatusView()
        }
    }
}
