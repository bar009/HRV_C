import SwiftUI

/// A selectable support option (breathing / movement / delay) — Stage-1
/// loop-exit tools. Selection shown by fill + border + checkmark, not colour alone.
struct SupportActionCard: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let selected: Bool
    let action: () -> Void
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let t = HRVTheme.resolve(scheme)
        Button(action: action) {
            HStack(spacing: HRVLayout.space12) {
                Image(systemName: systemImage)
                    .font(.hrvTitle3)
                    .foregroundStyle(t.accentPrimary)
                    .frame(width: HRVLayout.iconLarge)
                VStack(alignment: .leading, spacing: HRVLayout.space4) {
                    Text(title).font(.hrvHeadline).foregroundStyle(t.textPrimary)
                    Text(subtitle).font(.hrvSubheadline).foregroundStyle(t.textSecondary)
                }
                Spacer(minLength: 0)
                if selected {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(t.accentPrimary)
                }
            }
            .padding(HRVLayout.space16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(selected ? t.accentSoft : t.surfacePrimary,
                        in: RoundedRectangle(cornerRadius: HRVLayout.radius16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: HRVLayout.radius16, style: .continuous)
                    .stroke(selected ? t.accentPrimary : t.borderSubtle,
                            lineWidth: selected ? HRVLayout.strongStrokeWidth : HRVLayout.hairlineWidth)
            )
        }
        .buttonStyle(.plain)
    }
}
