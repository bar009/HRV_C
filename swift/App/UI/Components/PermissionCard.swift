import SwiftUI

/// Reassurance bullets for a permission request (read-only, no cloud, revocable).
struct PermissionCard: View {
    let bullets: [String]
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let t = HRVTheme.resolve(scheme)
        VStack(alignment: .leading, spacing: HRVLayout.space12) {
            ForEach(bullets, id: \.self) { bullet in
                HStack(spacing: HRVLayout.space8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.hrvCallout)
                        .foregroundStyle(t.accentPrimary)
                    Text(bullet)
                        .font(.hrvCallout)
                        .foregroundStyle(t.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                }
            }
        }
        .padding(HRVLayout.space16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(t.surfaceSecondary, in: RoundedRectangle(cornerRadius: HRVLayout.radius16, style: .continuous))
    }
}
