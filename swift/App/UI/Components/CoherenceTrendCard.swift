import SwiftUI
import Charts

/// Coherence score (0–100) per practice session over time — the "pattern"
/// counterpart to the SDNN baseline chart. Separate axis by design: coherence
/// is a 0–100 score, not milliseconds. Dashed lines mark our band thresholds.
struct CoherenceTrendCard: View {
    let sessions: [CoherenceSummary]   // newest-first
    var title: String = "ציון קוהרנטיות לאורך זמן"
    @Environment(\.colorScheme) private var scheme

    private var points: [CoherenceSummary] { sessions.sorted { $0.startedAt < $1.startedAt } }

    var body: some View {
        let t = HRVTheme.resolve(scheme)
        VStack(alignment: .leading, spacing: HRVLayout.space12) {
            Text(title).font(.hrvHeadline).foregroundStyle(t.textPrimary)
            Chart {
                // Band thresholds (40 = low/med, 70 = med/high).
                ForEach([40, 70], id: \.self) { th in
                    RuleMark(y: .value("סף", th))
                        .foregroundStyle(t.chartLine.opacity(0.3))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                }
                ForEach(points) { s in
                    LineMark(x: .value("תאריך", s.startedAt), y: .value("ציון", s.avgScore))
                        .interpolationMethod(.monotone)
                        .foregroundStyle(t.chartLine)
                        .lineStyle(StrokeStyle(lineWidth: 2))
                    PointMark(x: .value("תאריך", s.startedAt), y: .value("ציון", s.avgScore))
                        .foregroundStyle(t.chartLine)
                        .symbolSize(14)
                }
            }
            .chartYScale(domain: 0...100)
            .chartYAxis { AxisMarks(position: .leading, values: [0, 40, 70, 100]) }
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.day().month())
                }
            }
            .chartYAxisLabel("ציון", position: .topLeading)
            .environment(\.layoutDirection, .leftToRight)
            .dynamicTypeSize(...DynamicTypeSize.xLarge)
            .frame(height: 180)
            .overlay {
                if points.isEmpty {
                    Text("אין עדיין סשנים")
                        .font(.hrvCallout).foregroundStyle(t.textSecondary)
                }
            }
        }
        .padding(HRVLayout.space20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(t.surfacePrimary, in: RoundedRectangle(cornerRadius: HRVLayout.radius20, style: .continuous))
    }
}
