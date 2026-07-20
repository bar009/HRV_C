import SwiftUI

/// A secondary explanation that stays out of the way: one compact row that
/// expands its body text on tap. Used instead of InformationCard where the
/// text is an aside (Trends, event detail) rather than the screen's content.
struct CollapsibleNote: View {
    let title: String
    let message: String
    var systemImage: String = "info.circle"
    @State private var expanded = false
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let t = HRVTheme.resolve(scheme)
        VStack(alignment: .leading, spacing: HRVLayout.space8) {
            Button {
                withAnimation(HRVMotion.standard) { expanded.toggle() }
            } label: {
                HStack(spacing: HRVLayout.space8) {
                    Image(systemName: systemImage)
                        .font(.hrvCallout)
                        .foregroundStyle(t.accentPrimary)
                    Text(title)
                        .font(.hrvSubheadline)
                        .foregroundStyle(t.textSecondary)
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.down")
                        .font(.hrvCaption)
                        .foregroundStyle(t.textTertiary)
                        .rotationEffect(.degrees(expanded ? 180 : 0))
                }
                .frame(minHeight: HRVLayout.minimumTouchSize)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityAddTraits(expanded ? [.isSelected] : [])
            .accessibilityHint(expanded ? "הקש כדי לסגור" : "הקש כדי לקרוא")

            if expanded {
                Text(message)
                    .font(.hrvCallout)
                    .foregroundStyle(t.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                    .padding(.bottom, HRVLayout.space8)
            }
        }
        .padding(.horizontal, HRVLayout.space16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(t.surfacePrimary, in: RoundedRectangle(cornerRadius: HRVLayout.radius16, style: .continuous))
    }
}
