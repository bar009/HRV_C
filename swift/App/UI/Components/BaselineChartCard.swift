import SwiftUI
import Charts
import HRVCore

/// The "personal baseline" chart: a normal-range band + median line + sample
/// points on ln(SDNN). Realizes the cover motif with real data.
struct BaselineChartCard: View {
    let samples: [ProcessedHRVSample]
    let baseline: Baseline?
    var title: String = "הטווח האישי שלך"
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let t = HRVTheme.resolve(scheme)
        VStack(alignment: .leading, spacing: HRVLayout.space12) {
            Text(title)
                .font(.hrvHeadline)
                .foregroundStyle(t.textPrimary)
            Chart {
                if let b = baseline {
                    RectangleMark(
                        yStart: .value("סף תחתון", b.lowerBound),
                        yEnd: .value("סף עליון", b.upperBound)
                    )
                    .foregroundStyle(t.chartBand)
                    RuleMark(y: .value("חציון", b.median))
                        .foregroundStyle(t.chartLine)
                        .lineStyle(StrokeStyle(lineWidth: 1.5))
                }
                ForEach(samples, id: \.id) { s in
                    PointMark(
                        x: .value("זמן", s.timestamp),
                        y: .value("ln SDNN", s.lnRmssd)
                    )
                    .foregroundStyle(t.chartLine)
                    .symbolSize(20)
                }
            }
            .chartYAxis { AxisMarks(position: .leading) }
            .frame(height: 180)
            .overlay {
                if samples.isEmpty {
                    Text("אין עדיין נתונים")
                        .font(.hrvCallout)
                        .foregroundStyle(t.textSecondary)
                }
            }
        }
        .padding(HRVLayout.space20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(t.surfacePrimary, in: RoundedRectangle(cornerRadius: HRVLayout.radius20, style: .continuous))
    }
}
