import SwiftUI
import Charts
import HRVCore

/// The "personal baseline" chart: a normal-range band + median line + the
/// measurement trend, all in milliseconds so the numbers match what users see
/// in Apple Health. The detector works on ln(SDNN); bounds are mapped back
/// with exp() so band, median and data share one axis.
///
/// The `range` drives both the aggregation (raw samples for a single day,
/// daily medians for longer windows) and the x-axis marks.
struct BaselineChartCard: View {
    let samples: [ProcessedHRVSample]
    let baseline: Baseline?
    var range: TrendRange = .month
    var title: String = "הטווח האישי שלך"
    @Environment(\.colorScheme) private var scheme

    private var points: [TrendPoint] { TrendSeries.points(for: samples, range: range) }

    var body: some View {
        let t = HRVTheme.resolve(scheme)
        VStack(alignment: .leading, spacing: HRVLayout.space12) {
            Text(title)
                .font(.hrvHeadline)
                .foregroundStyle(t.textPrimary)
            Chart {
                if let b = baseline {
                    RectangleMark(
                        yStart: .value("סף תחתון", exp(b.lowerBound)),
                        yEnd: .value("סף עליון", exp(b.upperBound))
                    )
                    .foregroundStyle(t.chartBand)
                    RuleMark(y: .value("חציון", exp(b.median)))
                        .foregroundStyle(t.chartLine.opacity(0.5))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                }
                ForEach(points) { p in
                    LineMark(
                        x: .value("זמן", p.date),
                        y: .value("SDNN", p.valueMs)
                    )
                    .interpolationMethod(.monotone)
                    .foregroundStyle(t.chartLine)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                    PointMark(
                        x: .value("זמן", p.date),
                        y: .value("SDNN", p.valueMs)
                    )
                    .foregroundStyle(t.chartLine)
                    .symbolSize(12)
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let ms = value.as(Double.self) {
                            Text("\(Int(ms))")
                        }
                    }
                }
            }
            .chartXAxis { xAxis }
            .chartYAxisLabel("SDNN (ms)", position: .topLeading)
            // Time series stay left-to-right even in the RTL app shell --
            // a mirrored time axis reads as a broken line.
            .environment(\.layoutDirection, .leftToRight)
            // Axis labels are inside a fixed-height plot; letting them grow to
            // accessibility sizes makes them collide with each other and the
            // data. The card's title and the note stay fully scalable, and the
            // same numbers are available as text in MeasuresRow.
            .dynamicTypeSize(...DynamicTypeSize.xLarge)
            .frame(height: 180)
            .animation(HRVMotion.gentle, value: points)
            .overlay {
                if points.isEmpty {
                    Text(range.emptyMessage)
                        .font(.hrvCallout)
                        .foregroundStyle(t.textSecondary)
                        .transition(.opacity)
                }
            }
            .animation(HRVMotion.standard, value: points.isEmpty)
        }
        .padding(HRVLayout.space20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(t.surfacePrimary, in: RoundedRectangle(cornerRadius: HRVLayout.radius20, style: .continuous))
    }

    /// Marks sized to the window: hours within a day, days across a week,
    /// weeks across a month, months across the full history.
    @AxisContentBuilder private var xAxis: some AxisContent {
        switch range {
        case .day:
            AxisMarks(values: .stride(by: .hour, count: 6)) { _ in
                AxisGridLine()
                AxisValueLabel(format: .dateTime.hour())
            }
        case .week:
            AxisMarks(values: .stride(by: .day, count: 1)) { _ in
                AxisGridLine()
                AxisValueLabel(format: .dateTime.day().month())
            }
        case .month:
            AxisMarks(values: .stride(by: .day, count: 7)) { _ in
                AxisGridLine()
                AxisValueLabel(format: .dateTime.day().month())
            }
        case .all:
            AxisMarks(values: .stride(by: .month, count: 1)) { _ in
                AxisGridLine()
                AxisValueLabel(format: .dateTime.month().year())
            }
        }
    }
}
