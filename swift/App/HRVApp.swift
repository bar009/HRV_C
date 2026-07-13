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
            container = try ModelContainer(
                for: StoredSample.self, StoredBaseline.self, StoredAlert.self, StoredAnchor.self,
                     EventRecord.self, GuidedResponse.self
            )
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
                .task { await coordinator.start() }
        }
        .modelContainer(container)
    }
}
