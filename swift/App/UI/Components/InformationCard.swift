import SwiftUI

/// A titled explanatory card (help text, privacy, about). Factual, calm.
struct InformationCard: View {
    let title: String
    let message: String
    var systemImage: String? = nil
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let t = HRVTheme.resolve(scheme)
        VStack(alignment: .leading, spacing: HRVLayout.space8) {
            HStack(spacing: HRVLayout.space8) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.hrvCallout)
                        .foregroundStyle(t.accentPrimary)
                }
                Text(title)
                    .font(.hrvHeadline)
                    .foregroundStyle(t.textPrimary)
            }
            Text(message)
                .font(.hrvCallout)
                .foregroundStyle(t.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(HRVLayout.space16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(t.surfacePrimary, in: RoundedRectangle(cornerRadius: HRVLayout.radius16, style: .continuous))
    }
}
