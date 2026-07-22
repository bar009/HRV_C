import SwiftUI
import HRVCore

/// Which trend the מגמות tab is showing. Coherence only appears when Track J
/// is enabled -- see FeatureFlags.
enum TrendMetric: String, CaseIterable, Identifiable {
    case sdnn, rmssd, coherence
    var id: String { rawValue }
    var title: String {
        switch self {
        case .sdnn:      "שונות (HRV)"
        case .rmssd:     "RMSSD"
        case .coherence: "קוהרנטיות"
        }
    }
    /// RMSSD only appears when the advanced-metrics feature is on.
    static var visible: [TrendMetric] {
        allCases.filter { $0 != .rmssd || FeatureFlags.advancedMetricsEnabled }
                .filter { $0 != .coherence || FeatureFlags.coherenceEnabled }
    }
}

/// Trends (מגמות) tab — the SDNN baseline chart over a selectable window, and
/// (behind the flag) a coherence-score trend, plus a collapsed factual note.
struct TrendsScreen: View {
    @Environment(MonitoringCoordinator.self) private var coordinator
    @Environment(CoherenceSessionController.self) private var coherence
    @Environment(\.colorScheme) private var scheme
    @State private var range: TrendRange = .month
    @State private var metric: TrendMetric = .sdnn
    @State private var samples: [ProcessedHRVSample] = []

    init() {
        #if DEBUG
        // Dev/QA hook: `-startRange day|week|month|all` opens on that window
        // (the simulator can't be tapped headlessly), mirroring `-startTab`.
        if let raw = UserDefaults.standard.string(forKey: "startRange"),
           let initial = TrendRange(rawValue: raw) {
            _range = State(initialValue: initial)
        }
        if let raw = UserDefaults.standard.string(forKey: "startMetric"),
           let initial = TrendMetric(rawValue: raw) {
            _metric = State(initialValue: initial)
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
                if TrendMetric.visible.count > 1 { metricSelector(t) }
                RangeSelector(selection: $range)

                switch metric {
                case .sdnn:
                    BaselineChartCard(samples: samples, baseline: coordinator.baseline, range: range)
                    CollapsibleNote(
                        title: "מה זה אומר?",
                        message: "הטווח מחושב מהמדידות האישיות שלך ומתעדכן בהדרגה עם הגוף. הרצועה מסמנת את הטווח הרגיל עבורך, והקו המקווקו הוא החציון האישי.")
                case .rmssd:
                    // No personal band -- we don't compute an RMSSD baseline.
                    BaselineChartCard(samples: rmssdInRange, baseline: nil, range: range,
                                      title: "RMSSD (ms)", yAxisLabel: "RMSSD (ms)")
                    CollapsibleNote(
                        title: "מה זה אומר?",
                        message: "RMSSD מחושב מרצף פעימות (beat-to-beat) כשזמין, ולכן מופיע בדלילות. הוא רגיש יותר לפעילות הפאראסימפתטית קצרת-הטווח מ-SDNN.")
                case .coherence:
                    CoherenceTrendCard(sessions: coherenceInRange)
                    CollapsibleNote(
                        title: "מה זה אומר?",
                        message: "כל נקודה היא ציון הקוהרנטיות הממוצע של סשן תרגול. הקווים המקווקווים מסמנים את גבולות הרמות (נמוך/בינוני/גבוה). זהו מדד נפרד מה-HRV — סדר הריתמוס, לא כמות השונות.")
                }
            }
            .padding(HRVLayout.space20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .animation(HRVMotion.standard, value: metric)
        }
        .background(t.surfaceBackground)
        // Loading here (not in `body`) keeps the repository fetch off the
        // render path; it re-runs whenever the range changes.
        .task(id: range) {
            samples = coordinator.samples(since: range.cutoff())
        }
        .onChange(of: coordinator.recentSamples.count) { _, _ in
            samples = coordinator.samples(since: range.cutoff())
        }
    }

    private var coherenceInRange: [CoherenceSummary] {
        let cutoff = range.cutoff()
        return coherence.history.filter { $0.startedAt >= cutoff }
    }

    private var rmssdInRange: [ProcessedHRVSample] {
        coordinator.rmssdSamples(since: range.cutoff())
    }

    /// Two-item metric toggle. Scales down rather than truncating at large text
    /// sizes; only two short-ish options, so no menu fallback needed.
    private func metricSelector(_ t: HRVTheme) -> some View {
        HStack(spacing: HRVLayout.space4) {
            ForEach(TrendMetric.visible) { m in
                let active = metric == m
                Button { withAnimation(HRVMotion.standard) { metric = m } } label: {
                    Text(m.title)
                        .font(.hrvSubheadline).fontWeight(active ? .semibold : .regular)
                        .lineLimit(1).minimumScaleFactor(0.7)
                        .foregroundStyle(active ? t.textInverse : t.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, HRVLayout.space8)
                        .background { if active { Capsule().fill(t.accentPrimary) } }
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(active ? [.isSelected] : [])
            }
        }
        .padding(HRVLayout.space4)
        .background(t.surfaceSecondary, in: Capsule())
    }
}
