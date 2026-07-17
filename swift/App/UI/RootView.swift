import SwiftUI

/// The app shell: header (title + Settings gear), the active tab, and the tab bar.
/// RTL-first, accent tint. Settings is a separate sheet (not a tab).
struct RootView: View {
    @Environment(\.colorScheme) private var scheme
    @AppStorage("didOnboard") private var didOnboard = false
    @State private var tab: HRVTab = .today
    @State private var showSettings = false

    init() {
        #if DEBUG
        // Dev/UI-test hook: `-startTab trends|events|today` opens on that tab
        // (launch arguments surface through the UserDefaults argument domain).
        if let raw = UserDefaults.standard.string(forKey: "startTab"),
           let initial = HRVTab(rawValue: raw) {
            _tab = State(initialValue: initial)
        }
        #endif
    }

    var body: some View {
        let t = HRVTheme.resolve(scheme)
        Group {
            if didOnboard {
                mainShell(t)
            } else {
                OnboardingFlow(onDone: { didOnboard = true })
            }
        }
        .tint(t.accentPrimary)
        .environment(\.layoutDirection, .rightToLeft)
    }

    private func mainShell(_ t: HRVTheme) -> some View {
        VStack(spacing: 0) {
            header(t)
            Group {
                switch tab {
                case .today:  StatusScreen()
                case .trends: TrendsScreen()
                case .events: EventsScreen()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            HRVTabBar(selection: $tab)
        }
        .background(t.surfaceBackground)
        .sheet(isPresented: $showSettings) { SettingsScreen() }
    }

    private func header(_ t: HRVTheme) -> some View {
        HStack {
            Text("HRV-C")
                .font(.hrvTitle3)
                .foregroundStyle(t.textPrimary)
            Spacer()
            Button { showSettings = true } label: {
                Image(systemName: "gearshape")
                    .font(.hrvTitle3)
                    .foregroundStyle(t.textSecondary)
            }
            .accessibilityLabel("הגדרות")
        }
        .padding(.horizontal, HRVLayout.space20)
        .padding(.vertical, HRVLayout.space12)
    }
}
