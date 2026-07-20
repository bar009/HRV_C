import SwiftUI

/// Facts that co-occurred with an event: sleep, a recent workout, resting
/// heart rate — each next to the user's own usual value.
///
/// Phrasing is deliberately non-causal. METHOD_PRODUCT_PRINCIPLES: the app is
/// a recognition aid that "does not identify the pattern itself", so this
/// never says a signal explains the change; it lists what was also true and
/// leaves the interpreting to the person.
struct EventContextCard: View {
    let context: EventContext
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let t = HRVTheme.resolve(scheme)
        VStack(alignment: .leading, spacing: HRVLayout.space12) {
            Text("מה עוד היה נכון סביב האירוע")
                .font(.hrvHeadline)
                .foregroundStyle(t.textPrimary)

            VStack(spacing: 0) {
                if let hours = context.sleepHours {
                    row(t,
                        icon: "bed.double",
                        label: "שינה בלילה שלפני",
                        value: Self.duration(hours),
                        comparison: context.usualSleepHours.map { "הרגיל שלך \(Self.duration($0))" },
                        highlighted: context.sleepIsBelowUsual)
                }
                if let since = context.hoursSinceWorkout {
                    if context.sleepHours != nil { divider(t) }
                    row(t,
                        icon: "figure.walk",
                        label: "אימון לפני האירוע",
                        value: Self.hoursBefore(since),
                        comparison: nil,
                        highlighted: false)
                }
                if let bpm = context.restingHeartRate {
                    if context.sleepHours != nil || context.hoursSinceWorkout != nil { divider(t) }
                    row(t,
                        icon: "heart",
                        label: "דופק במנוחה",
                        value: "\(Int(bpm.rounded())) bpm",
                        comparison: context.usualRestingHeartRate.map { "הרגיל שלך \(Int($0.rounded()))" },
                        highlighted: context.restingHeartRateIsAboveUsual)
                }
            }
            .background(t.surfacePrimary, in: RoundedRectangle(cornerRadius: HRVLayout.radius16, style: .continuous))

            Text("אלו עובדות שהתרחשו באותו הזמן — לא הסבר ולא סיבה. רק אתה יכול לדעת מה משמעותן עבורך.")
                .font(.hrvCaption)
                .foregroundStyle(t.textTertiary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func row(_ t: HRVTheme, icon: String, label: String, value: String,
                     comparison: String?, highlighted: Bool) -> some View {
        HStack(spacing: HRVLayout.space12) {
            Image(systemName: icon)
                .font(.hrvCallout)
                // Colour never carries meaning alone (AGENTS.md): the comparison
                // text always states the usual value too.
                .foregroundStyle(highlighted ? t.statusAttention : t.textTertiary)
                .frame(width: HRVLayout.iconMedium)
            VStack(alignment: .leading, spacing: HRVLayout.space2) {
                Text(label).font(.hrvCallout).foregroundStyle(t.textSecondary)
                if let comparison {
                    Text(comparison).font(.hrvCaption).foregroundStyle(t.textTertiary)
                }
            }
            Spacer(minLength: 0)
            Text(value)
                .font(.hrvCallout).fontWeight(.semibold)
                .foregroundStyle(t.textPrimary)
        }
        .padding(HRVLayout.space16)
    }

    private func divider(_ t: HRVTheme) -> some View {
        Rectangle()
            .fill(t.borderSubtle)
            .frame(height: HRVLayout.hairlineWidth)
            .padding(.horizontal, HRVLayout.space16)
    }

    /// "6:50" reads as a clock duration in Hebrew far better than "6.8 שעות".
    static func duration(_ hours: Double) -> String {
        let total = Int((hours * 60).rounded())
        return String(format: "%d:%02d", total / 60, total % 60)
    }

    static func hoursBefore(_ hours: Double) -> String {
        hours < 1 ? "פחות משעה לפני" : "\(Int(hours.rounded())) שעות לפני"
    }
}
