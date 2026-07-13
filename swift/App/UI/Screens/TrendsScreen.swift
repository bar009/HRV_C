import SwiftUI
import HRVCore

/// Trends (מגמות) tab — the 30-day baseline chart + a factual help card (P2).
struct TrendsScreen: View {
    @Environment(MonitoringCoordinator.self) private var coordinator
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let t = HRVTheme.resolve(scheme)
        ScrollView {
            VStack(alignment: .leading, spacing: HRVLayout.space16) {
                VStack(alignment: .leading, spacing: HRVLayout.space4) {
                    Text("מגמות").font(.hrvDisplay).foregroundStyle(t.textPrimary)
                    Text("30 הימים האחרונים").font(.hrvSubheadline).foregroundStyle(t.textSecondary)
                }
                BaselineChartCard(samples: coordinator.recentSamples, baseline: coordinator.baseline)
                InformationCard(
                    title: "הטווח האישי שלך",
                    message: "הטווח מחושב מהמדידות האישיות שלך ומתעדכן בהדרגה עם הגוף."
                )
            }
            .padding(HRVLayout.space20)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(t.surfaceBackground)
    }
}
