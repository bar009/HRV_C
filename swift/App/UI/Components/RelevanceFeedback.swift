import SwiftUI

/// Was the alert useful? Feeds the success metric (usefulness, not alert count).
enum Relevance: String, CaseIterable, Identifiable {
    case timely, notRelevant, unsure
    var id: String { rawValue }
    var title: String {
        switch self {
        case .timely:      "היה במקום"
        case .notRelevant: "לא רלוונטי"
        case .unsure:      "לא בטוח/ה"
        }
    }
    var symbol: String {
        switch self {
        case .timely:      "hand.thumbsup"
        case .notRelevant: "hand.thumbsdown"
        case .unsure:      "questionmark.circle"
        }
    }
}

struct RelevanceFeedback: View {
    @Binding var selection: Relevance?
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let t = HRVTheme.resolve(scheme)
        VStack(spacing: HRVLayout.space8) {
            ForEach(Relevance.allCases) { option in
                let selected = selection == option
                Button {
                    withAnimation(HRVMotion.quick) { selection = option }
                } label: {
                    HStack(spacing: HRVLayout.space12) {
                        Image(systemName: option.symbol).foregroundStyle(t.accentPrimary)
                        Text(option.title).font(.hrvCallout).foregroundStyle(t.textPrimary)
                        Spacer(minLength: 0)
                        if selected {
                            Image(systemName: "checkmark").foregroundStyle(t.accentPrimary)
                                .transition(.scale.combined(with: .opacity))
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
                .pressable()
                .accessibilityAddTraits(selected ? [.isSelected] : [])
            }
        }
    }
}
