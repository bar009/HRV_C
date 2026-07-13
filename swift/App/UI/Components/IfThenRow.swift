import SwiftUI

/// The user's "if–then" plan: two free-text fields. The app never fills them.
struct IfThenRow: View {
    @Binding var ifText: String
    @Binding var thenText: String
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let t = HRVTheme.resolve(scheme)
        VStack(alignment: .leading, spacing: HRVLayout.space12) {
            field(label: "אם…", text: $ifText, placeholder: "מתי זה עשוי לקרות שוב", t: t)
            field(label: "אז…", text: $thenText, placeholder: "מה אבחר לעשות", t: t)
        }
        .padding(HRVLayout.space20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(t.surfacePrimary, in: RoundedRectangle(cornerRadius: HRVLayout.radius20, style: .continuous))
    }

    private func field(label: String, text: Binding<String>, placeholder: String, t: HRVTheme) -> some View {
        VStack(alignment: .leading, spacing: HRVLayout.space4) {
            Text(label).font(.hrvHeadline).foregroundStyle(t.textPrimary)
            TextField(placeholder, text: text, axis: .vertical)
                .lineLimit(2...4)
                .font(.hrvCallout).foregroundStyle(t.textPrimary)
                .padding(HRVLayout.space12)
                .background(t.surfaceSecondary, in: RoundedRectangle(cornerRadius: HRVLayout.radius12, style: .continuous))
        }
    }
}
