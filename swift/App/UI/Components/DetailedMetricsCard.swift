import SwiftUI
import HRVCore

/// Detailed time-domain HRV metrics (RMSSD / pNN50 / SDSD), computed from a
/// beat-to-beat series when one is available (Deep Dive A.6.1). Factual numbers
/// only — no interpretation. Shown on Today under the primary measures when the
/// advanced-metrics feature is on and a beat series has been read.
struct DetailedMetricsCard: View {
    let metrics: BeatSeriesMetrics
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let t = HRVTheme.resolve(scheme)
        VStack(alignment: .leading, spacing: HRVLayout.space12) {
            Text("מדדים מפורטים")
                .font(.hrvHeadline)
                .foregroundStyle(t.textPrimary)
            HStack(spacing: 0) {
                cell(t, "RMSSD", metrics.rmssd, "ms")
                divider(t)
                cell(t, "pNN50", metrics.pnn50, "%")
                divider(t)
                cell(t, "SDSD", metrics.sdsd, "ms")
            }
            Text("מחושבים מרצף פעימות (beat-to-beat) כשזמין. משלימים את ה-SDNN הפסיבי.")
                .font(.hrvCaption)
                .foregroundStyle(t.textTertiary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(HRVLayout.space20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(t.surfacePrimary, in: RoundedRectangle(cornerRadius: HRVLayout.radius20, style: .continuous))
    }

    private func cell(_ t: HRVTheme, _ label: String, _ value: Double?, _ unit: String) -> some View {
        VStack(spacing: HRVLayout.space4) {
            HStack(alignment: .firstTextBaseline, spacing: HRVLayout.space2) {
                Text(value.map { String(Int($0.rounded())) } ?? "—")
                    .font(.hrvTitle3).fontWeight(.semibold)
                    .foregroundStyle(t.textPrimary)
                Text(unit).font(.hrvCaption).foregroundStyle(t.textTertiary)
            }
            .environment(\.layoutDirection, .leftToRight)
            Text(label)
                .font(.hrvCaption).foregroundStyle(t.textSecondary)
                .environment(\.layoutDirection, .leftToRight)
        }
        .frame(maxWidth: .infinity)
    }

    private func divider(_ t: HRVTheme) -> some View {
        Rectangle().fill(t.borderSubtle).frame(width: HRVLayout.hairlineWidth, height: 32)
    }
}
