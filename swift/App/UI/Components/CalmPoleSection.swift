import SwiftUI

/// The calm pole on Today (strategy memo, "map both poles"): alongside the
/// arousal events the app detects, let the user map what steadies them — when,
/// where, with whom. A gentle prompt + the most recent entries + one tap to add.
struct CalmPoleSection: View {
    let moments: [CalmMomentSummary]
    var onAdd: () -> Void
    @Environment(\.colorScheme) private var scheme

    private var recent: [CalmMomentSummary] { Array(moments.prefix(3)) }

    var body: some View {
        let t = HRVTheme.resolve(scheme)
        VStack(alignment: .leading, spacing: HRVLayout.space12) {
            HStack {
                Text("רגעים רגועים")
                    .font(.hrvHeadline).foregroundStyle(t.textPrimary)
                Spacer()
                Button(action: onAdd) {
                    Label("הוספה", systemImage: "plus.circle.fill")
                        .font(.hrvSubheadline)
                        .foregroundStyle(t.accentPrimary)
                }
                .buttonStyle(.plain)
            }

            if recent.isEmpty {
                Text("לצד רגעי העומס, כדאי גם לשים לב למה שמרגיע אתכם — מתי, איפה, ועם מי. זה בונה תמונה מלאה יותר.")
                    .font(.hrvCallout).foregroundStyle(t.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                Button(action: onAdd) {
                    Label("סימון רגע רגוע", systemImage: "leaf.fill")
                        .font(.hrvCallout).fontWeight(.semibold)
                        .foregroundStyle(t.accentPrimary)
                        .frame(maxWidth: .infinity, minHeight: HRVLayout.minimumTouchSize)
                        .background(t.accentSoft.opacity(0.5), in: RoundedRectangle(cornerRadius: HRVLayout.radius12, style: .continuous))
                }
                .buttonStyle(.plain)
            } else {
                ForEach(recent) { m in
                    HStack(alignment: .top, spacing: HRVLayout.space12) {
                        Image(systemName: "leaf.fill")
                            .font(.hrvSubheadline).foregroundStyle(t.statusStable)
                            .padding(.top, 2)
                        VStack(alignment: .leading, spacing: HRVLayout.space2) {
                            if !summary(m).isEmpty {
                                Text(summary(m)).font(.hrvCallout).fontWeight(.semibold).foregroundStyle(t.textPrimary)
                            }
                            if !m.note.isEmpty {
                                Text(m.note).font(.hrvSubheadline).foregroundStyle(t.textSecondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            Text(Self.relative(m.createdAt)).font(.hrvCaption).foregroundStyle(t.textTertiary)
                        }
                        Spacer(minLength: 0)
                    }
                }
            }
        }
        .padding(HRVLayout.space16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(t.surfacePrimary, in: RoundedRectangle(cornerRadius: HRVLayout.radius20, style: .continuous))
    }

    /// "בית · עם משפחה" — join the mapped context that's present.
    private func summary(_ m: CalmMomentSummary) -> String {
        var parts: [String] = []
        if !m.place.isEmpty { parts.append(m.place) }
        if !m.people.isEmpty { parts.append(m.people == "לבד" ? "לבד" : "עם \(m.people)") }
        return parts.joined(separator: " · ")
    }

    private static func relative(_ date: Date) -> String {
        let f = RelativeDateTimeFormatter()
        f.locale = Locale(identifier: "he"); f.unitsStyle = .full
        return f.localizedString(for: date, relativeTo: Date())
    }
}
