// Track F -- status + baseline summary, styled from the design system (Mac-only).
import SwiftUI
import HRVCore

struct StatusView: View {
    @Environment(MonitoringCoordinator.self) private var coordinator

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    stateCard
                    baselineCard
                    trendCard
                }
                .padding(20)
            }
            .background(HRVColor.surfaceBackground)
            .navigationTitle("HRV")
        }
    }

    private var stateCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("מצב הניטור")
                    .font(.hrvSubheadline).foregroundStyle(HRVColor.textSecondary)
                Text(stateText(coordinator.state))
                    .font(.hrvTitle3).foregroundStyle(HRVColor.textPrimary)
            }
            Spacer()
            Circle().fill(HRVColor.accentPrimary).frame(width: 12, height: 12)
        }
        .hrvCard()
    }

    private var baselineCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Baseline אישי")
                .font(.hrvSubheadline).foregroundStyle(HRVColor.textSecondary)
            if let b = coordinator.latestBaseline {
                LabeledRow("חציון (ln RMSSD)", String(format: "%.3f", b.median))
                LabeledRow("סף תחתון", String(format: "%.3f", b.lowerBound))
                LabeledRow("דגימות בחלון", "\(b.sampleCount)")
            } else {
                Text("לומד את ה-baseline שלך…")
                    .font(.hrvCallout).foregroundStyle(HRVColor.textSecondary)
            }
        }
        .hrvCard()
    }

    private var trendCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("מגמה (30 יום)")
                .font(.hrvSubheadline).foregroundStyle(HRVColor.textSecondary)
            BaselineChartView()
        }
        .hrvCard()
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

private struct LabeledRow: View {
    let label: String
    let value: String
    init(_ label: String, _ value: String) { self.label = label; self.value = value }
    var body: some View {
        HStack {
            Text(label).foregroundStyle(HRVColor.textSecondary)
            Spacer()
            Text(value).foregroundStyle(HRVColor.textPrimary)
        }
        .font(.hrvCallout)
    }
}

private extension View {
    func hrvCard() -> some View {
        padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(HRVColor.surfacePrimary,
                        in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
