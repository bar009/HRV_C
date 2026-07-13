import SwiftUI

/// A calm breathing pacer (Stage-1 loop-exit). Expands/contracts on a slow cycle.
struct BreathingRing: View {
    var period: Double = 4.0
    @State private var expanded = false
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let t = HRVTheme.resolve(scheme)
        ZStack {
            Circle().fill(t.accentSoft)
            Circle().stroke(t.accentPrimary, lineWidth: HRVLayout.strongStrokeWidth)
            Text(expanded ? "נשיפה" : "שאיפה")
                .font(.hrvTitle3).foregroundStyle(t.accentPrimary)
        }
        .frame(width: 200, height: 200)
        .scaleEffect(expanded ? 1.0 : 0.62)
        .animation(.easeInOut(duration: period).repeatForever(autoreverses: true), value: expanded)
        .onAppear { expanded = true }
        .accessibilityLabel("מדריך נשימה")
    }
}
