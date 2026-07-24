import SwiftUI
import Charts

/// The "we're actually collecting data" panel shown during a breathing session:
/// a heart that pulses per beat, the live BPM + beat count, and a rolling
/// mini-waveform of recent heart rate. Before the first coherence reading it
/// also shows a "building your first reading" progress bar, so the ~30s warm-up
/// never looks like "just a moving ring". Respects Reduce Motion.
struct LiveBeatPanel: View {
    let bpm: Int
    let beatCount: Int
    let recentBPM: [Double]
    /// 0…1 progress toward the first coherence reading.
    let firstReadingProgress: Double
    /// Once true, the first reading is in — the warm-up bar is hidden.
    let hasReading: Bool

    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pulse = false

    var body: some View {
        let t = HRVTheme.resolve(scheme)
        VStack(spacing: HRVLayout.space12) {
            HStack(spacing: HRVLayout.space12) {
                Image(systemName: "heart.fill")
                    .font(.hrvTitle)
                    .foregroundStyle(t.statusStable)
                    .scaleEffect(pulse && !reduceMotion ? 1.18 : 1.0)
                    .animation(.easeOut(duration: 0.18), value: pulse)
                VStack(alignment: .leading, spacing: HRVLayout.space2) {
                    HStack(alignment: .lastTextBaseline, spacing: 4) {
                        Text(bpm > 0 ? "\(bpm)" : "—")
                            .font(.hrvTitle).fontWeight(.semibold)
                            .foregroundStyle(t.textPrimary)
                            .contentTransition(.numericText())
                        Text("bpm").font(.hrvSubheadline).foregroundStyle(t.textSecondary)
                    }
                    Text("\(beatCount) פעימות נאספו")
                        .font(.hrvCaption).foregroundStyle(t.textTertiary)
                        .contentTransition(.numericText())
                }
                Spacer()
            }

            waveform(t)

            if !hasReading {
                VStack(alignment: .leading, spacing: HRVLayout.space4) {
                    Text("אוסף נתונים… בונה קריאה ראשונה")
                        .font(.hrvCaption).foregroundStyle(t.textSecondary)
                    ProgressView(value: min(max(firstReadingProgress, 0), 1))
                        .tint(t.accentPrimary)
                }
            }
        }
        .padding(HRVLayout.space16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(t.surfacePrimary, in: RoundedRectangle(cornerRadius: HRVLayout.radius16, style: .continuous))
        .onChange(of: beatCount) { _, _ in
            pulse.toggle()
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("דופק \(bpm), \(beatCount) פעימות נאספו")
    }

    @ViewBuilder
    private func waveform(_ t: HRVTheme) -> some View {
        if recentBPM.count >= 2 {
            let lo = (recentBPM.min() ?? 0) - 2
            let hi = (recentBPM.max() ?? 1) + 2
            Chart {
                ForEach(Array(recentBPM.enumerated()), id: \.offset) { i, v in
                    LineMark(x: .value("i", i), y: .value("bpm", v))
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(t.statusStable)
                        .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round))
                }
            }
            .chartYScale(domain: lo...max(hi, lo + 1))
            .chartXAxis(.hidden)
            .chartYAxis(.hidden)
            .frame(height: 48)
            .environment(\.layoutDirection, .leftToRight)   // time flows left→right
        } else {
            // Nothing to draw yet — keep the layout height stable.
            Color.clear.frame(height: 48)
        }
    }
}
