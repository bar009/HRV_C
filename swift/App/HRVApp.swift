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
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(coordinator)
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
