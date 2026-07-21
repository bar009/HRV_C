import SwiftUI
import HRVCore

/// Live 0–100 coherence ring: a progress arc + the score in the centre, its
/// tint following the band. Colour is never the only signal — the number and
/// the band label carry it too (AGENTS.md).
struct CoherenceRing: View {
    let score: Int
    let band: CoherenceBand
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let t = HRVTheme.resolve(scheme)
        ZStack {
            Circle()
                .stroke(t.surfaceSecondary, lineWidth: 14)
            Circle()
                .trim(from: 0, to: CGFloat(score) / 100)
                .stroke(color(t), style: StrokeStyle(lineWidth: 14, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(HRVMotion.standard, value: score)
            VStack(spacing: HRVLayout.space4) {
                Text("\(score)")
                    .font(.system(size: 56, weight: .semibold, design: .rounded))
                    .foregroundStyle(t.textPrimary)
                    .contentTransition(.numericText())
                    .animation(HRVMotion.standard, value: score)
                Text(bandLabel)
                    .font(.hrvSubheadline)
                    .foregroundStyle(t.textSecondary)
            }
        }
        .frame(width: 200, height: 200)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("ציון קוהרנטיות \(score), \(bandLabel)")
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
        case .low:    t.statusUnavailable
        case .medium: t.statusLearning
        case .high:   t.statusStable
        }
    }
}
