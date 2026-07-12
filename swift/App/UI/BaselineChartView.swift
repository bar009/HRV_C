// Track F -- the "Personal Baseline Motif" realized as a real chart (Mac-only):
// a normal-range band (chartBand) + median line (chartLine) + sample points.
import SwiftUI
import SwiftData
import Charts
import HRVCore

struct BaselineChartView: View {
    @Environment(MonitoringCoordinator.self) private var coordinator
    @Query(sort: \StoredSample.timestamp) private var samples: [StoredSample]

    var body: some View {
        Chart {
            if let b = coordinator.latestBaseline {
                RectangleMark(
                    yStart: .value("סף תחתון", b.lowerBound),
                    yEnd: .value("סף עליון", b.upperBound)
                )
                .foregroundStyle(HRVColor.chartBand)

                RuleMark(y: .value("חציון", b.median))
                    .foregroundStyle(HRVColor.chartLine)
                    .lineStyle(StrokeStyle(lineWidth: 1.5))
            }

            ForEach(samples) { s in
                PointMark(
                    x: .value("זמן", s.timestamp),
                    y: .value("ln RMSSD", s.lnRmssd)
                )
                .foregroundStyle(HRVColor.chartLine)
                .symbolSize(24)
            }
        }
        .frame(height: 200)
        .chartYAxis { AxisMarks(position: .leading) }
        .overlay {
            if samples.isEmpty {
                Text("אין עדיין נתונים")
                    .font(.hrvCallout)
                    .foregroundStyle(HRVColor.textSecondary)
            }
        }
    }
}
