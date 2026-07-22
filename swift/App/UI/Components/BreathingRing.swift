import SwiftUI

/// A calm breathing pacer. The word, the circle scale, and the surrounding
/// visuals all move on one timed phase, so the guidance ("שאיפה"/"נשיפה")
/// stays in sync with the animation. Layered: a soft aura + a glow halo +
/// outward ripple rings behind the main breathing circle.
struct BreathingRing: View {
    /// Seconds for one half-breath (inhale, then exhale). A full cycle = 2×.
    var period: Double = 4.0
    @State private var inhaling = false
    @State private var rippleOut = false
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var breath: Animation { .easeInOut(duration: period) }

    var body: some View {
        let t = HRVTheme.resolve(scheme)
        ZStack {
            aura(t)
            if !reduceMotion { ripples(t) }
            glow(t)
            core(t)
        }
        .frame(width: 240, height: 240)
        .accessibilityLabel("מדריך נשימה")
        .onAppear {
            withAnimation(breath) { inhaling = true }
            rippleOut = true
        }
        // Drive the phase from a timer so the word and scale flip together.
        .onReceive(Timer.publish(every: period, on: .main, in: .common).autoconnect()) { _ in
            withAnimation(breath) { inhaling.toggle() }
        }
    }

    // A soft radial aura that swells on the inhale.
    private func aura(_ t: HRVTheme) -> some View {
        Circle()
            .fill(RadialGradient(colors: [t.accentSoft, .clear],
                                 center: .center, startRadius: 10, endRadius: 150))
            .scaleEffect(inhaling ? 1.2 : 0.75)
            .opacity(inhaling ? 0.9 : 0.35)
    }

    // Faint rings that drift outward continuously — breath spreading.
    private func ripples(_ t: HRVTheme) -> some View {
        ForEach(0..<3, id: \.self) { i in
            Circle()
                .stroke(t.accentPrimary.opacity(0.22), lineWidth: 1.5)
                .frame(width: 150, height: 150)
                .scaleEffect(rippleOut ? 1.5 : 0.75)
                .opacity(rippleOut ? 0 : 0.5)
                .animation(.easeOut(duration: period * 1.6)
                    .repeatForever(autoreverses: false)
                    .delay(Double(i) * period * 0.55), value: rippleOut)
        }
    }

    // A blurred halo that brightens on the inhale.
    private func glow(_ t: HRVTheme) -> some View {
        Circle()
            .fill(t.accentPrimary)
            .frame(width: 150, height: 150)
            .blur(radius: 28)
            .opacity(inhaling ? 0.32 : 0.10)
            .scaleEffect(inhaling ? 1.0 : 0.72)
    }

    // The main breathing circle with the in-sync guidance word.
    private func core(_ t: HRVTheme) -> some View {
        ZStack {
            Circle().fill(t.accentSoft)
            Circle().stroke(t.accentPrimary, lineWidth: HRVLayout.strongStrokeWidth)
            Text(inhaling ? "שאיפה" : "נשיפה")
                .font(.hrvTitle3).foregroundStyle(t.accentPrimary)
                .contentTransition(.opacity)
        }
        .frame(width: 150, height: 150)
        .scaleEffect(inhaling ? 1.0 : 0.62)
    }
}
