import SwiftUI
import HRVCore

/// "What this mode actually gives you" — every indicator resolved against the
/// connected sensor's capabilities. Devices differ (a chest strap streams true
/// beat-to-beat RR, an optical armband is noisier, some straps send heart rate
/// only, the watch has context no strap has), so the app states plainly what is
/// available, approximate, or off, rather than leaving blanks on screens.
struct IndicatorAvailabilityList: View {
    let capabilities: SensorCapabilities
    var title: String = "מה זמין במצב הזה"
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let t = HRVTheme.resolve(scheme)
        VStack(alignment: .leading, spacing: HRVLayout.space12) {
            Text(title).font(.hrvHeadline).foregroundStyle(t.textPrimary)
            ForEach(IndicatorResolver.all(given: capabilities), id: \.0) { indicator, availability in
                HStack(alignment: .top, spacing: HRVLayout.space12) {
                    icon(availability, t)
                    VStack(alignment: .leading, spacing: HRVLayout.space2) {
                        Text(Self.label(indicator))
                            .font(.hrvCallout)
                            .foregroundStyle(availability.isUsable ? t.textPrimary : t.textTertiary)
                        if let reason = Self.reason(availability) {
                            Text(reason)
                                .font(.hrvCaption).foregroundStyle(t.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    Spacer(minLength: 0)
                }
                .accessibilityElement(children: .combine)
            }
        }
        .padding(HRVLayout.space16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(t.surfacePrimary, in: RoundedRectangle(cornerRadius: HRVLayout.radius20, style: .continuous))
    }

    @ViewBuilder
    private func icon(_ a: IndicatorAvailability, _ t: HRVTheme) -> some View {
        switch a {
        case .available:
            Image(systemName: "checkmark.circle.fill")
                .font(.hrvSubheadline).foregroundStyle(t.statusStable)
        case .approximate:
            Image(systemName: "circle.lefthalf.filled")
                .font(.hrvSubheadline).foregroundStyle(t.statusAttention)
        case .unavailable:
            Image(systemName: "minus.circle")
                .font(.hrvSubheadline).foregroundStyle(t.textTertiary)
        }
    }

    static func label(_ i: HealthIndicator) -> String {
        switch i {
        case .liveBPM:            return "דופק חי"
        case .sdnn:               return "SDNN (מ-Apple Health)"
        case .rmssd:              return "RMSSD"
        case .pnn50:              return "pNN50"
        case .sdsd:               return "SDSD"
        case .coherence:          return "קוהרנטיות"
        case .restingHeartRate:   return "דופק במנוחה"
        case .sleepContext:       return "נתוני שינה"
        case .workoutContext:     return "נתוני אימון"
        case .sustainedDetection: return "זיהוי שינוי מתמשך"
        case .liveTriggers:       return "זיהוי בזמן אמת"
        }
    }

    static func reason(_ a: IndicatorAvailability) -> String? {
        guard let limitation = a.limitation else { return nil }
        switch limitation {
        case .needsBeatToBeat:
            return "דורש מדידה בין פעימה לפעימה (רצועת דופק)"
        case .rrDerivedFromHeartRate:
            return "מחושב מדגימות דופק ולא מכל פעימה — מקורב"
        case .needsContinuousCoverage:
            return "דורש מדידה רציפה לאורך היום"
        case .needsHealthKit:
            return "מגיע מ-Apple Health"
        case .noSensor:
            return "אין חיישן מחובר"
        }
    }
}
