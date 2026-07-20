import SwiftUI
import HRVCore

/// Trends (מגמות) tab — the baseline chart over a selectable window
/// (day/week/month/all) plus a collapsed factual note (P2).
struct TrendsScreen: View {
    @Environment(MonitoringCoordinator.self) private var coordinator
    @Environment(\.colorScheme) private var scheme
    @State private var range: TrendRange = .month
    @State private var samples: [ProcessedHRVSample] = []

    init() {
        #if DEBUG
        // Dev/QA hook: `-startRange day|week|month|all` opens on that window
        // (the simulator can't be tapped headlessly), mirroring `-startTab`.
        if let raw = UserDefaults.standard.string(forKey: "startRange"),
           let initial = TrendRange(rawValue: raw) {
            _range = State(initialValue: initial)
        }
        #endif
    }

    var body: some View {
        let t = HRVTheme.resolve(scheme)
        ScrollView {
            VStack(alignment: .leading, spacing: HRVLayout.space16) {
                VStack(alignment: .leading, spacing: HRVLayout.space4) {
                    Text("מגמות").font(.hrvDisplay).foregroundStyle(t.textPrimary)
                    Text(range.subtitle)
                        .font(.hrvSubheadline).foregroundStyle(t.textSecondary)
                        .contentTransition(.opacity)
                }
                RangeSelector(selection: $range)
                BaselineChartCard(samples: samples, baseline: coordinator.baseline, range: range)
                CollapsibleNote(
                    title: "מה זה אומר?",
                    message: "הטווח מחושב מהמדידות האישיות שלך ומתעדכן בהדרגה עם הגוף. הרצועה מסמנת את הטווח הרגיל עבורך, והקו המקווקו הוא החציון האישי."
                )
            }
            .padding(HRVLayout.space20)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(t.surfaceBackground)
        // Loading here (not in `body`) keeps the repository fetch off the
        // render path; it re-runs whenever the range changes.
        .task(id: range) {
            samples = coordinator.samples(since: range.cutoff())
        }
        // A newly ingested sample should refresh the visible window too.
        .onChange(of: coordinator.recentSamples.count) { _, _ in
            samples = coordinator.samples(since: range.cutoff())
        }
    }
}
