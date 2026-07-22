// iOS app entry point. Mac-only (SwiftUI/SwiftData/HealthKit) -- written to
// Apple's documented APIs; compiles under Xcode, not on the Windows core build.
import SwiftUI
import SwiftData
import HRVCore

@main
struct HRVApp: App {
    // SwiftData container over the stored models (Track C).
    let container: ModelContainer
    @State private var coordinator: MonitoringCoordinator
    @State private var coherence: CoherenceSessionController

    init() {
        do {
            // Local-only, no CloudKit, excluded from backup, file-protected (checklist #6).
            container = try PrivacyStore.makeContainer()
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
        let context = ModelContext(container)
        let repo = SwiftDataRepository(context: context)
        _coordinator = State(initialValue: MonitoringCoordinator(repository: repo, context: context))
        // Track J (behind FeatureFlags.coherenceEnabled). On a real device the
        // beats come from the paired watch's workout session; the simulator has
        // no HKWorkoutSession, so it falls back to a synthetic stream (keeps the
        // dev/screenshot/test path working).
        let coherenceSource: HeartRateSource
        #if targetEnvironment(simulator)
        coherenceSource = SimulatedHeartRateSource(coherent: true)
        #else
        coherenceSource = WatchWorkoutHeartRateSource()
        #endif
        _coherence = State(initialValue: CoherenceSessionController(
            source: coherenceSource,
            context: ModelContext(container)))
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(coordinator)
                .environment(coherence)
                .task {
                    #if DEBUG
                    // Dev/UI-test hooks (simulator can't be driven through
                    // Settings headlessly): `-seedDemoData` loads the normal
                    // reviewer demo; `-qaLearning`/`-qaStale` preview the two
                    // states that need days/staleness to occur naturally
                    // (QA checklist §A).
                    let args = ProcessInfo.processInfo.arguments
                    if !coordinator.isDemoMode {
                        if args.contains("-qaLearning") {
                            coordinator.loadDemoData(days: 3)
                        } else if args.contains("-qaStable") {
                            // Demo history with no live episode -> lands on Stable.
                            coordinator.loadDemoData(liveEventSlots: 0)
                        } else if args.contains("-qaStale") {
                            coordinator.loadDemoData(ageOffset: 20 * 3600)
                        } else if args.contains("-seedDemoData") {
                            coordinator.loadDemoData()
                        }
                    }
                    #endif
                    await coordinator.start()
                }
        }
        .modelContainer(container)
    }
}
