import SwiftUI

/// Learning window progress — "יום N מתוך 7" + a factual explanation.
struct LearningProgress: View {
    let day: Int
    let total: Int
    @Environment(\.colorScheme) private var scheme

    private var progress: Double { total > 0 ? min(1, Double(day) / Double(total)) : 0 }

    var body: some View {
        let t = HRVTheme.resolve(scheme)
        VStack(alignment: .leading, spacing: HRVLayout.space16) {
            VStack(alignment: .leading, spacing: HRVLayout.space8) {
                Text("יום \(day) מתוך \(total)")
                    .font(.hrvSubheadline)
                    .foregroundStyle(t.textSecondary)
                ProgressTrack(progress: progress, color: t.statusLearning, track: t.surfaceSecondary)
            }
            VStack(alignment: .leading, spacing: HRVLayout.space4) {
                Text("מה קורה עכשיו?")
                    .font(.hrvHeadline)
                    .foregroundStyle(t.textPrimary)
                Text("אנחנו אוספים מדידות במנוחה כדי להבין מה רגיל עבורך. בתקופה הזאת לא יישלחו התראות.")
                    .font(.hrvCallout)
                    .foregroundStyle(t.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(HRVLayout.space20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(t.surfacePrimary, in: RoundedRectangle(cornerRadius: HRVLayout.radius20, style: .continuous))
    }
}

/// A simple rounded progress track (RTL-aware via .leading alignment).
struct ProgressTrack: View {
    let progress: Double
    let color: Color
    let track: Color

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(track)
                Capsule().fill(color)
                    .frame(width: max(0, geo.size.width * progress))
            }
        }
        .frame(height: HRVLayout.space8)
    }
}
