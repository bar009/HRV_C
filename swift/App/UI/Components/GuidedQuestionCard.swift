import SwiftUI

/// One guided question + the user's free-text answer. The app never fills the
/// answer (METHOD_PRODUCT_PRINCIPLES) — it only invites reflection.
struct GuidedQuestionCard: View {
    let question: String
    var helper: String? = nil
    @Binding var text: String
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let t = HRVTheme.resolve(scheme)
        VStack(alignment: .leading, spacing: HRVLayout.space12) {
            Text(question)
                .font(.hrvTitle3).foregroundStyle(t.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
            if let helper {
                Text(helper).font(.hrvSubheadline).foregroundStyle(t.textSecondary)
            }
            TextField("כתוב/י כאן… (לא חובה)", text: $text, axis: .vertical)
                .lineLimit(3...6)
                .font(.hrvCallout).foregroundStyle(t.textPrimary)
                .padding(HRVLayout.space12)
                .background(t.surfaceSecondary, in: RoundedRectangle(cornerRadius: HRVLayout.radius12, style: .continuous))
        }
        .padding(HRVLayout.space20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(t.surfacePrimary, in: RoundedRectangle(cornerRadius: HRVLayout.radius20, style: .continuous))
    }
}
