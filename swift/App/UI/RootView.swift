// Track F -- iOS UI root (Mac-only). Gates onboarding, then the main tabs.
import SwiftUI

struct RootView: View {
    @AppStorage("didOnboard") private var didOnboard = false

    var body: some View {
        if didOnboard {
            TabView {
                StatusView()
                    .tabItem { Label("סטטוס", systemImage: "waveform.path.ecg") }
                AlertHistoryView()
                    .tabItem { Label("התראות", systemImage: "bell") }
            }
        } else {
            OnboardingView(onDone: { didOnboard = true })
        }
    }
}
