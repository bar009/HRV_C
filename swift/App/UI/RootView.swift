import SwiftUI

/// The app shell: header (title + Settings gear), the active tab, and the tab bar.
/// RTL-first, accent tint. Settings is a separate sheet (not a tab).
struct RootView: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(MonitoringCoordinator.self) private var coordinator
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
        // P3: a tapped alert notification lands on Today, where StatusScreen
        // opens the Guided Moment for the pending alert.
        .onChange(of: coordinator.pendingGuidedAlertID) { _, id in
            if id != nil { withAnimation(HRVMotion.standard) { tab = .today } }
        }
        // Signal-with-shift: the alert offers a breathing shift -> jump there.
        .onChange(of: coordinator.pendingBreathingShift) { _, shift in
            if shift {
                withAnimation(HRVMotion.standard) { tab = .practice }
                coordinator.pendingBreathingShift = false
            }
        }
    }

    private func mainShell(_ t: HRVTheme) -> some View {
        VStack(spacing: 0) {
            header(t)
            Group {
                switch tab {
                case .today:    StatusScreen().transition(.opacity)
                case .trends:   TrendsScreen().transition(.opacity)
                case .practice: PracticeScreen().transition(.opacity)
                case .events:   EventsScreen().transition(.opacity)
                }
            }
            .animation(HRVMotion.standard, value: tab)
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
