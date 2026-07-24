import SwiftUI
import HRVCore

/// Live 0–10 coherence ring: a progress arc + the level in the centre, its
/// tint following the band. Colour is never the only signal — the number and
/// the band label carry it too (AGENTS.md). 10 is a real, reachable top.
struct CoherenceRing: View {
    let level: Int      // 0-10
    let band: CoherenceBand
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let t = HRVTheme.resolve(scheme)
        ZStack {
            Circle()
                .stroke(t.surfaceSecondary, lineWidth: 14)
            Circle()
                .trim(from: 0, to: CGFloat(level) / 10)
                .stroke(color(t), style: StrokeStyle(lineWidth: 14, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(HRVMotion.standard, value: level)
            VStack(spacing: HRVLayout.space4) {
                HStack(alignment: .lastTextBaseline, spacing: 2) {
                    Text("\(level)")
                        .font(.system(size: 56, weight: .semibold, design: .rounded))
                        .foregroundStyle(t.textPrimary)
                        .contentTransition(.numericText())
                        .animation(HRVMotion.standard, value: level)
                    Text("/10")
                        .font(.hrvTitle3)
                        .foregroundStyle(t.textTertiary)
                }
                Text(bandLabel)
                    .font(.hrvSubheadline)
                    .foregroundStyle(t.textSecondary)
            }
        }
        .frame(width: 200, height: 200)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("רמת קוהרנטיות \(level) מתוך 10, \(bandLabel)")
    }

    private var bandLabel: String {
        switch band {
        case .low:    "נמוך"
        case .medium: "בינוני"
        case .high:   "גבוה"
        }
    }

    private func color(_ t: HRVTheme) -> Color {
        switch band {
        case .low:    t.statusCritical   // red
        case .medium: t.statusLearning   // blue
        case .high:   t.statusStable     // green
        }
    }
}
