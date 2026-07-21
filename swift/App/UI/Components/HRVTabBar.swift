import SwiftUI

/// The three primary tabs. Settings is NOT here — it is a separate screen.
enum HRVTab: String, CaseIterable, Identifiable {
    case today, trends, practice, events
    var id: String { rawValue }
    var title: String {
        switch self {
        case .today:    return "היום"
        case .trends:   return "מגמות"
        case .practice: return "תרגול"
        case .events:   return "אירועים"
        }
    }
    var symbol: String {
        switch self {
        case .today:    return "waveform.path.ecg"
        case .trends:   return "chart.xyaxis.line"
        case .practice: return "wind"
        case .events:   return "bell"
        }
    }

    /// Tabs actually shown -- the practice (coherence) tab is behind its flag.
    static var visible: [HRVTab] {
        allCases.filter { $0 != .practice || FeatureFlags.coherenceEnabled }
    }
}

/// Custom bottom tab bar (RTL-first). Label + icon — never colour alone.
struct HRVTabBar: View {
    @Binding var selection: HRVTab
    @Environment(\.colorScheme) private var scheme
    @Namespace private var indicator

    var body: some View {
        let t = HRVTheme.resolve(scheme)
        HStack(spacing: 0) {
            ForEach(HRVTab.visible) { tab in
                let active = selection == tab
                Button {
                    withAnimation(HRVMotion.standard) { selection = tab }
                } label: {
                    VStack(spacing: HRVLayout.space4) {
                        ZStack {
                            if active {
                                Circle()
                                    .fill(t.accentSoft)
                                    .frame(width: 32, height: 32)
                                    .matchedGeometryEffect(id: "tabIndicator", in: indicator)
                            }
                            Image(systemName: tab.symbol)
                                .font(.hrvHeadline)
                        }
                        .frame(width: 32, height: 32)
                        Text(tab.title)
                            .font(.hrvCaption)
                    }
                    .foregroundStyle(active ? t.accentPrimary : t.textTertiary)
                    .frame(maxWidth: .infinity, minHeight: HRVLayout.minimumTouchSize)
                    .accessibilityAddTraits(active ? [.isSelected] : [])
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, HRVLayout.space8)
        .background(t.surfaceElevated)
        .overlay(alignment: .top) {
            Rectangle().fill(t.borderSubtle).frame(height: HRVLayout.hairlineWidth)
        }
    }
}
