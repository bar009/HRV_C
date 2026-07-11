// Track F -- current monitoring status + baseline summary (Mac-only).
import SwiftUI
import HRVCore

struct StatusView: View {
    @Environment(MonitoringCoordinator.self) private var coordinator

    var body: some View {
        NavigationStack {
            List {
                Section("מצב הניטור") {
                    LabeledContent("מצב", value: stateText(coordinator.state))
                    if let b = coordinator.latestBaseline {
                        LabeledContent("Baseline (חציון ln RMSSD)", value: String(format: "%.3f", b.median))
                        LabeledContent("סף תחתון", value: String(format: "%.3f", b.lowerBound))
                        LabeledContent("דגימות בחלון", value: "\(b.sampleCount)")
                    } else {
                        Text("לומד את ה-baseline שלך…").foregroundStyle(.secondary)
                    }
                }
                Section("מגמה (30 יום)") {
                    BaselineChartView()
                }
            }
            .navigationTitle("HRV")
        }
    }

    private func stateText(_ s: DetectorState) -> String {
        switch s {
        case .learning: return "לומד"
        case .normal:   return "תקין"
        case .watching: return "עוקב"
        case .alert:    return "התראה"
        case .cooldown: return "המתנה"
        }
    }
}
