import SwiftUI
import HRVCore

// Status styling shared by the indicator + card. Colour never carries state
// alone (AGENTS.md) — always paired with a label and an SF Symbol.
extension HRVStatusKind {
    func color(_ t: HRVTheme) -> Color {
        switch self {
        case .learning:      return t.statusLearning
        case .stable:        return t.statusStable
        case .attention:     return t.statusAttention
        case .unavailable:   return t.statusUnavailable
        case .setupRequired: return t.accentPrimary
        }
    }
    func soft(_ t: HRVTheme) -> Color {
        switch self {
        case .learning:      return t.statusLearningSoft
        case .stable:        return t.statusStableSoft
        case .attention:     return t.statusAttentionSoft
        case .unavailable:   return t.statusUnavailable.opacity(0.15)
        case .setupRequired: return t.accentSoft
        }
    }
    var symbol: String {
        switch self {
        case .learning:      return "hourglass"
        case .stable:        return "checkmark.circle.fill"
        case .attention:     return "exclamationmark.triangle.fill"
        case .unavailable:   return "wifi.slash"
        case .setupRequired: return "heart.text.square"
        }
    }
}

/// A small pill: icon + label on a soft tinted background. Never colour-only.
struct StatusIndicator: View {
    let kind: HRVStatusKind
    let label: String
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let t = HRVTheme.resolve(scheme)
        HStack(spacing: HRVLayout.space8) {
            Image(systemName: kind.symbol)
                .font(.hrvSubheadline)
                .foregroundStyle(kind.color(t))
            Text(label)
                .font(.hrvSubheadline)
                .foregroundStyle(t.textSecondary)
        }
        .padding(.horizontal, HRVLayout.space12)
        .padding(.vertical, HRVLayout.space8)
        .background(kind.soft(t), in: Capsule())
    }
}
