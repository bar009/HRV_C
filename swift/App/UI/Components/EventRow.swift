import SwiftUI

/// A row in the Events (אירועים) history. Factual: date + duration, "לצפייה במגמה".
struct EventRow: View {
    let title: String          // "היום · שינוי מתמשך"
    let subtitle: String       // "חדש" / "לצפייה במגמה"
    var isNew: Bool = false
    var action: () -> Void = {}
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let t = HRVTheme.resolve(scheme)
        Button(action: action) {
            HStack(spacing: HRVLayout.space12) {
                Circle()
                    .fill(t.statusAttention)
                    .frame(width: HRVLayout.statusDotSize, height: HRVLayout.statusDotSize)
                VStack(alignment: .leading, spacing: HRVLayout.space4) {
                    Text(title)
                        .font(.hrvCallout).fontWeight(.semibold)
                        .foregroundStyle(t.textPrimary)
                    Text(subtitle)
                        .font(.hrvSubheadline)
                        .foregroundStyle(t.textSecondary)
                }
                Spacer()
                if isNew {
                    Text("חדש")
                        .font(.hrvCaption).fontWeight(.semibold)
                        .foregroundStyle(t.accentPrimary)
                        .padding(.horizontal, HRVLayout.space8)
                        .padding(.vertical, HRVLayout.space2)
                        .background(t.accentSoft, in: Capsule())
                }
                Image(systemName: "chevron.forward")
                    .font(.hrvSubheadline)
                    .foregroundStyle(t.textTertiary)
            }
            .padding(HRVLayout.space16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(t.surfacePrimary, in: RoundedRectangle(cornerRadius: HRVLayout.radius16, style: .continuous))
        }
        .pressable()
    }
}
