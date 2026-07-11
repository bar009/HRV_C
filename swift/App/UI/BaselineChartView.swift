// Track F -- ln(RMSSD) trend, mirrors the Python sim's scenario_A.png (Mac-only).
import SwiftUI
import SwiftData
import Charts

struct BaselineChartView: View {
    @Query(sort: \StoredSample.timestamp) private var samples: [StoredSample]

    var body: some View {
        Chart(samples) { s in
            PointMark(
                x: .value("זמן", s.timestamp),
                y: .value("ln RMSSD", s.lnRmssd)
            )
            .foregroundStyle(.blue.opacity(0.5))
            .symbolSize(20)
        }
        .frame(height: 200)
        .overlay {
            if samples.isEmpty {
                Text("אין עדיין נתונים").foregroundStyle(.secondary)
            }
        }
    }
}
