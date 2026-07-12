// Track F -- pre-permission explainer, styled from the Figma cover (Mac-only).
// A pre-permission screen lifts HealthKit acceptance (Deep Dive 2.2.1).
import SwiftUI

struct OnboardingView: View {
    let onDone: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("HRV-C")
                .font(.hrvSubheadline).fontWeight(.semibold)
                .tracking(2)
                .foregroundStyle(HRVColor.accentPrimary)

            Text("דפוסים אישיים,\nבהבנה רגועה.")
                .font(.hrvDisplay)
                .foregroundStyle(HRVColor.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            Text("ממשק wellness לניטור HRV פסיבי ב-iPhone וב-Apple Watch. הכול נשאר על המכשיר שלך — ללא ענן וללא שרת.")
                .font(.hrvCallout)
                .foregroundStyle(HRVColor.textSecondary)

            BaselineMotif()
                .frame(height: 150)
                .padding(20)
                .background(HRVColor.surfacePrimary,
                            in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                .padding(.vertical, 8)

            Text("זהו כלי wellness, לא אבחון רפואי.")
                .font(.hrvSubheadline)
                .foregroundStyle(HRVColor.textSecondary)

            Spacer()

            Button(action: onDone) {
                Text("להמשיך ולאשר הרשאות")
                    .font(.hrvCallout).fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
            }
            .buttonStyle(.borderedProminent)
            .tint(HRVColor.accentPrimary)
            .controlSize(.large)
        }
        .padding(28)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(HRVColor.surfaceBackground)
    }
}
