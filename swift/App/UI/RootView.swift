// Track F -- iOS UI root (Mac-only). Applies the design-system accent + RTL-first.
import SwiftUI

struct RootView: View {
    @AppStorage("didOnboard") private var didOnboard = false

    var body: some View {
        Group {
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
        .tint(HRVColor.accentPrimary)
        .environment(\.layoutDirection, .rightToLeft)   // RTL-first (Figma design)
    }
}
