import SwiftUI
import Charts
import HRVCore

/// The "personal baseline" chart: a normal-range band + median line + a daily
/// trend line, all in milliseconds so the numbers match what users see in
/// Apple Health. The detector works on ln(SDNN); bounds are mapped back with
/// exp() so band, median and data share one axis.
struct BaselineChartCard: View {
    let samples: [ProcessedHRVSample]
    let baseline: Baseline?
    var title: String = "הטווח האישי שלך"
    @Environment(\.colorScheme) private var scheme

    /// One point per calendar day (median of that day's samples, in ms) --
    /// raw samples arrive a few times a day and plot as unreadable noise.
    private struct DailyPoint: Identifiable {
        let day: Date
        let valueMs: Double
        var id: Date { day }
    }

    private var dailyPoints: [DailyPoint] {
        let cal = Calendar.current
        return Dictionary(grouping: samples) { cal.startOfDay(for: $0.timestamp) }
            .map { day, group in
                DailyPoint(day: day, valueMs: Self.median(group.map(\.rawValueMs)))
            }
            .sorted { $0.day < $1.day }
    }

    private static func median(_ values: [Double]) -> Double {
        let sorted = values.sorted()
        let mid = sorted.count / 2
        return sorted.count % 2 == 0 ? (sorted[mid - 1] + sorted[mid]) / 2 : sorted[mid]
    }

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
                ForEach(dailyPoints) { p in
                    LineMark(
                        x: .value("יום", p.day),
                        y: .value("SDNN", p.valueMs)
                    )
                    .interpolationMethod(.monotone)
                    .foregroundStyle(t.chartLine)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                    PointMark(
                        x: .value("יום", p.day),
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
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: 7)) { _ in
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.day().month(), centered: false)
                }
            }
            .chartYAxisLabel("SDNN (ms)", position: .topLeading)
            // Time series stay left-to-right even in the RTL app shell --
            // a mirrored time axis reads as a broken line.
            .environment(\.layoutDirection, .leftToRight)
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
