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
    @State private var strap: StrapMonitor
    /// Bridges strap beats into the coherence session while one is running.
    private let strapBeats = StrapHeartRateSource()

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
        // The BLE provider needs real hardware, which the Simulator has none of,
        // so simulator builds get a synthetic strap that drives the identical
        // pipeline (and `-strapBpmOnly` exercises the heart-rate-only path).
        let provider: HeartRateProviding
        #if targetEnvironment(simulator)
        provider = SimulatedHeartRateProvider(
            sendsRR: !ProcessInfo.processInfo.arguments.contains("-strapBpmOnly"))
        #else
        provider = BLEHeartRateProvider()
        #endif
        let strap = StrapMonitor(provider: provider)
        _strap = State(initialValue: strap)

        // Coherence beats follow the selected mode: the strap when it's driving,
        // otherwise the watch workout session (or a synthetic stream in the
        // Simulator, which has no HKWorkoutSession).
        let watchSource: HeartRateSource
        #if targetEnvironment(simulator)
        watchSource = SimulatedHeartRateSource(coherent: true)
        #else
        watchSource = WatchWorkoutHeartRateSource()
        #endif
        let beats = strapBeats
        let router = RoutingHeartRateSource {
            SensorMode.current == .bleStrap ? beats : watchSource
        }
        _coherence = State(initialValue: CoherenceSessionController(
            source: router,
            context: ModelContext(container)))
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(coordinator)
                .environment(coherence)
                .environment(strap)
                .task {
                    wireStrap()
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

    /// Connect the strap pipeline to storage, detection and the live coherence
    /// session. Strap windows are persisted and charted, but never fed into the
    /// passive SDNN baseline -- StrapMonitor runs its own detector.
    @MainActor
    private func wireStrap() {
        strap.onSample = { [coordinator] sample in
            coordinator.recordStrapSample(sample)
            coordinator.strapCapabilities = strap.capabilities
        }
        strap.onLiveEvent = { [coordinator] event in
            coordinator.recordLiveEvent(event)
        }
        strap.onBeat = { [strapBeats] ibi in
            strapBeats.ingest(ibiMs: ibi)
        }
        if SensorMode.current == .bleStrap { strap.resumeIfPaired() }
    }
}
