import SwiftUI
import HRVCore

/// Track J -- the guided coherence practice tab (D-COH). A short active
/// breathing session that computes a HeartMath-style coherence score.
/// Wellness-framed; takes only HeartMath's math, never the metaphysics.
struct PracticeScreen: View {
    @Environment(CoherenceSessionController.self) private var session
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let t = HRVTheme.resolve(scheme)
        ScrollView {
            VStack(alignment: .leading, spacing: HRVLayout.space16) {
                switch session.phase {
                case .idle:     intro(t)
                case .running:  active(t)
                case .finished: results(t)
                }
            }
            .padding(HRVLayout.space20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .animation(HRVMotion.gentle, value: session.phase)
        }
        .background(t.surfaceBackground)
        #if DEBUG
        // QA hook: `-coherenceAutostart` begins a session on appear (the start
        // button can't be tapped headlessly), for screenshotting the live state.
        .onAppear {
            let args = ProcessInfo.processInfo.arguments
            if session.phase == .idle {
                if args.contains("-coherenceAutostart") { session.start() }
                else if args.contains("-coherenceResults") { session.debugShowResults() }
                else if args.contains("-coherenceSeedHistory") { session.debugSeedHistory() }
            }
        }
        #endif
    }

    // MARK: idle -> intro + history
    private func intro(_ t: HRVTheme) -> some View {
        VStack(alignment: .leading, spacing: HRVLayout.space16) {
            Text("תרגול נשימה")
                .font(.hrvDisplay).foregroundStyle(t.textPrimary)
            Text("סשן נשימה קצר ומודרך. נשמו יחד עם המעגל — פנימה כשהוא גדל, החוצה כשהוא מתכווץ. נשימה איטית וסדירה עוזרת להרגיע את הגוף.")
                .font(.hrvCallout).foregroundStyle(t.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            InformationCard(title: "איך זה עובד",
                            message: "בחרו מקום נוח, נשמו לפי המעגל, ותנו לזה כמה דקות. אין \"נכון\" — זה תרגול, לא מבחן. עם Apple Watch מחובר, האפליקציה גם תמדוד קוהרנטיות (עד כמה קצב הלב מסודר) בזמן אמת.")
            PrimaryButton(title: "להתחיל תרגול") { session.start() }
            if !session.history.isEmpty { historySection(t) }
        }
    }

    private func historySection(_ t: HRVTheme) -> some View {
        VStack(alignment: .leading, spacing: HRVLayout.space12) {
            Text("סשנים קודמים")
                .font(.hrvHeadline).foregroundStyle(t.textPrimary)
                .padding(.top, HRVLayout.space8)
            ForEach(session.history) { s in
                HStack {
                    VStack(alignment: .leading, spacing: HRVLayout.space2) {
                        Text(Self.dateFmt.string(from: s.startedAt))
                            .font(.hrvCallout).fontWeight(.semibold).foregroundStyle(t.textPrimary)
                        Text("\(Int(s.durationSec)) שניות")
                            .font(.hrvSubheadline).foregroundStyle(t.textSecondary)
                    }
                    Spacer()
                    if s.coherencePct > 0 || s.peakLevel > 0 {
                        scorePill(t, label: "בקוהרנטיות", value: "\(s.coherencePct)%")
                        scorePill(t, label: "שיא", value: "\(s.peakLevel)/10")
                    }
                }
                .padding(HRVLayout.space16)
                .background(t.surfacePrimary, in: RoundedRectangle(cornerRadius: HRVLayout.radius16, style: .continuous))
            }
        }
    }

    private func scorePill(_ t: HRVTheme, label: String, value: String) -> some View {
        VStack(spacing: HRVLayout.space2) {
            Text(value).font(.hrvTitle3).fontWeight(.semibold).foregroundStyle(t.textPrimary)
            Text(label).font(.hrvCaption).foregroundStyle(t.textTertiary)
        }
        .frame(minWidth: 52)
    }

    // MARK: running -> pacer + live data + level
    private func active(_ t: HRVTheme) -> some View {
        VStack(spacing: HRVLayout.space24) {
            Text(Self.clock(session.elapsed))
                .font(.hrvTitle3).foregroundStyle(t.textSecondary)
                .contentTransition(.numericText())
            BreathingRing(period: session.breathingPace / 2)
            // The coherence level appears once the first reading is in; the live
            // data panel shows from the first beat, so the ~30s warm-up doesn't
            // look like "just a moving ring". With no beats at all (iPhone, no
            // watch) this stays a pure breathing pacer.
            if session.hasCoherence {
                CoherenceRing(level: session.level, band: session.band)
                    .transition(.opacity.combined(with: .scale))
            }
            if session.isReceivingBeats {
                LiveBeatPanel(bpm: session.currentBPM,
                              beatCount: session.beatCount,
                              recentBPM: session.recentBPM,
                              firstReadingProgress: session.firstReadingProgress,
                              hasReading: session.hasCoherence)
                    .transition(.opacity)
            } else {
                Text("מדידת קוהרנטיות תופיע עם Apple Watch מחובר")
                    .font(.hrvCaption).foregroundStyle(t.textTertiary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, HRVLayout.space24)
            }
            PrimaryButton(title: "סיום") { session.finish() }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, HRVLayout.space16)
        .animation(HRVMotion.gentle, value: session.hasCoherence)
        .animation(HRVMotion.gentle, value: session.isReceivingBeats)
    }

    // MARK: finished -> results
    private func results(_ t: HRVTheme) -> some View {
        VStack(alignment: .leading, spacing: HRVLayout.space16) {
            Text("סיכום הסשן")
                .font(.hrvDisplay).foregroundStyle(t.textPrimary)
            if let s = session.lastSaved {
                HStack(spacing: 0) {
                    // Coherence cells only when a real measurement was captured;
                    // otherwise it was a plain breathing session (duration only).
                    if s.coherencePct > 0 || s.peakLevel > 0 {
                        resultCell(t, label: "% בקוהרנטיות", value: "\(s.coherencePct)%")
                        divider(t)
                        resultCell(t, label: "שיא רמה", value: "\(s.peakLevel)/10")
                        divider(t)
                    }
                    resultCell(t, label: "משך", value: "\(Int(s.durationSec))s")
                }
                .padding(.vertical, HRVLayout.space16)
                .background(t.surfacePrimary, in: RoundedRectangle(cornerRadius: HRVLayout.radius16, style: .continuous))
            }
            Text("נשמר בהיסטוריה. אפשר לחזור לתרגל בכל עת.")
                .font(.hrvSubheadline).foregroundStyle(t.textTertiary)
            PrimaryButton(title: "סיום") { session.reset() }
        }
    }

    private func resultCell(_ t: HRVTheme, label: String, value: String) -> some View {
        VStack(spacing: HRVLayout.space4) {
            Text(value).font(.hrvTitle).fontWeight(.semibold).foregroundStyle(t.textPrimary)
            Text(label).font(.hrvCaption).foregroundStyle(t.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func divider(_ t: HRVTheme) -> some View {
        Rectangle().fill(t.borderSubtle).frame(width: HRVLayout.hairlineWidth, height: 40)
    }

    private static func clock(_ s: TimeInterval) -> String {
        String(format: "%d:%02d", Int(s) / 60, Int(s) % 60)
    }
    private static let dateFmt: DateFormatter = {
        let f = DateFormatter(); f.locale = Locale(identifier: "he")
        f.dateFormat = "d בMMMM, HH:mm"; return f
    }()
}
