// Track F -- pre-permission explainer (Mac-only). A pre-permission screen lifts
// the HealthKit authorization acceptance rate (Deep Dive 2.2.1).
import SwiftUI

struct OnboardingView: View {
    let onDone: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "waveform.path.ecg")
                .font(.system(size: 64))
                .foregroundStyle(.pink)
            Text("ניטור HRV אישי")
                .font(.largeTitle.bold())
            Text("האפליקציה קוראת את נתוני ה-HRV שה-Apple Watch אוסף, בונה baseline אישי, "
                 + "ומודיעה לך על שינוי חריג. הכול נשאר על המכשיר שלך — ללא ענן וללא שרת.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
            Text("זהו כלי wellness, לא אבחון רפואי.")
                .font(.footnote)
                .foregroundStyle(.secondary)
            Spacer()
            Button(action: onDone) {
                Text("להמשיך ולאשר הרשאות")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal)
        }
        .padding()
    }
}
