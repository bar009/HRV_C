import SwiftUI

/// The app shell: header (title + Settings gear), the active tab, and the tab bar.
/// RTL-first, accent tint. Settings is a separate sheet (not a tab).
struct RootView: View {
    @Environment(\.colorScheme) private var scheme
    @State private var tab: HRVTab = .today
    @State private var showSettings = false

    var body: some View {
        let t = HRVTheme.resolve(scheme)
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
        .tint(t.accentPrimary)
        .environment(\.layoutDirection, .rightToLeft)
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
