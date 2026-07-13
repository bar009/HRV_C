import SwiftUI

/// Empty / no-data state: icon + factual title + explanation. No blame language.
struct EmptyState: View {
    let title: String
    let message: String
    var systemImage: String = "clock.arrow.circlepath"
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let t = HRVTheme.resolve(scheme)
        VStack(spacing: HRVLayout.space12) {
            Image(systemName: systemImage)
                .font(.system(size: HRVLayout.iconLarge))
                .foregroundStyle(t.textTertiary)
            Text(title)
                .font(.hrvHeadline)
                .foregroundStyle(t.textPrimary)
            Text(message)
                .font(.hrvCallout)
                .foregroundStyle(t.textSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .padding(HRVLayout.space24)
        .background(t.surfacePrimary, in: RoundedRectangle(cornerRadius: HRVLayout.radius20, style: .continuous))
    }
}
