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
                for: StoredSample.self, StoredBaseline.self, StoredAlert.self, StoredAnchor.self
            )
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
        let repo = SwiftDataRepository(context: ModelContext(container))
        _coordinator = State(initialValue: MonitoringCoordinator(repository: repo))
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
