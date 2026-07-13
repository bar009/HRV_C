import SwiftUI

/// Onboarding step indicator (1..total). Filled segments = completed/current.
struct StepProgress: View {
    let current: Int   // 1-based
    let total: Int
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let t = HRVTheme.resolve(scheme)
        HStack(spacing: HRVLayout.space4) {
            ForEach(1...max(total, 1), id: \.self) { i in
                Capsule()
                    .fill(i <= current ? t.accentPrimary : t.surfaceSecondary)
                    .frame(height: HRVLayout.space4)
            }
        }
        .accessibilityLabel("שלב \(current) מתוך \(total)")
    }
}
