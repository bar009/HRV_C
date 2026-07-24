import SwiftUI

/// Time-to-awareness progress (strategy memo's headline metric): how quickly the
/// user notices a change after it fires. Factual and encouraging — never a score
/// to "beat", just a mirror of the gap getting shorter over time.
struct AwarenessCard: View {
    let averageSeconds: TimeInterval
    let count: Int
    let isImproving: Bool?
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let t = HRVTheme.resolve(scheme)
        VStack(alignment: .leading, spacing: HRVLayout.space8) {
            Text("זמן עד מודעות")
                .font(.hrvHeadline).foregroundStyle(t.textPrimary)
            HStack(alignment: .lastTextBaseline, spacing: HRVLayout.space8) {
                Text(Self.duration(averageSeconds))
                    .font(.hrvTitle).fontWeight(.semibold).foregroundStyle(t.textPrimary)
                if let trend = trendText {
                    Text(trend).font(.hrvSubheadline).foregroundStyle(t.statusStable)
                }
            }
            Text("בממוצע, כמה זמן לקח לשים לב לשינוי — על סמך \(count) אירועים. ככל שהפער מתקצר, אתה שם לב מוקדם יותר.")
                .font(.hrvCaption).foregroundStyle(t.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(HRVLayout.space16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(t.surfacePrimary, in: RoundedRectangle(cornerRadius: HRVLayout.radius20, style: .continuous))
    }

    private var trendText: String? {
        switch isImproving {
        case .some(true):  return "↓ משתפר"
        case .some(false): return nil   // don't nudge negatively
        case .none:        return nil
        }
    }

    static func duration(_ s: TimeInterval) -> String {
        let minutes = Int((s / 60).rounded())
        if minutes < 60 { return "כ-\(max(minutes, 1)) דקות" }
        let hours = Int((s / 3600).rounded())
        return "כ-\(hours) שעות"
    }
}
