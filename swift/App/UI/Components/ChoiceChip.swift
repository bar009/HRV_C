import SwiftUI

/// A selectable pill choice.
struct ChoiceChip: View {
    let title: String
    let selected: Bool
    let action: () -> Void
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let t = HRVTheme.resolve(scheme)
        Button(action: action) {
            Text(title)
                .font(.hrvSubheadline).fontWeight(selected ? .semibold : .regular)
                .foregroundStyle(selected ? t.textInverse : t.textPrimary)
                .padding(.horizontal, HRVLayout.space16)
                .padding(.vertical, HRVLayout.space8)
                .background(selected ? t.accentPrimary : t.surfaceSecondary, in: Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? [.isSelected] : [])
    }
}
