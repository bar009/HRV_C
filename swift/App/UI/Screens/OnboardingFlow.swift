import SwiftUI

/// M2 Onboarding — 4 steps. Permissions are requested only after explaining
/// value; Health and Notifications are separate; a skip path is offered.
struct OnboardingFlow: View {
    @Environment(MonitoringCoordinator.self) private var coordinator
    @Environment(\.colorScheme) private var scheme
    let onDone: () -> Void

    @State private var step = 1
    private let total = 4

    var body: some View {
        let t = HRVTheme.resolve(scheme)
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: HRVLayout.space16) {
                    content
                }
                .padding(HRVLayout.space24)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            footer(t)
        }
        .background(t.surfaceBackground)
        .environment(\.layoutDirection, .rightToLeft)
    }

    // MARK: footer (progress + primary action + skip)
    private func footer(_ t: HRVTheme) -> some View {
        VStack(spacing: HRVLayout.space12) {
            StepProgress(current: step, total: total)
            PrimaryButton(title: primaryTitle) { advance() }
            if step == 2 {
                Button("אפשר לחבר מאוחר יותר") { onDone() }
                    .font(.hrvSubheadline)
                    .foregroundStyle(t.textTertiary)
            }
        }
        .padding(HRVLayout.space20)
    }

    private var primaryTitle: String {
        switch step {
        case 1:  "המשך"
        case 2:  "המשך ל־HealthKit"
        case 3:  "אפשר התראות"
        default: "סיום"
        }
    }

    private func advance() {
        switch step {
        case 1: step = 2
        case 2: Task { await coordinator.requestHealthAccess(); step = 3 }
        case 3: Task { await coordinator.requestNotifications(); step = 4 }
        default: onDone()
        }
    }

    // MARK: step content
    @ViewBuilder private var content: some View {
        Group {
            switch step {
            case 1:  valuePrivacy
            case 2:  appleHealth
            case 3:  notifications
            default: learningBegins
            }
        }
        .transition(.asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        ))
        .animation(HRVMotion.standard, value: step)
    }

    private var valuePrivacy: some View {
        let t = HRVTheme.resolve(scheme)
        return VStack(alignment: .leading, spacing: HRVLayout.space16) {
            Text("HRV-C")
                .font(.hrvSubheadline).fontWeight(.semibold).tracking(2)
                .foregroundStyle(t.accentPrimary)
            Text("להבין את הגוף שלך\nדרך הדפוס האישי שלך")
                .font(.hrvDisplay).foregroundStyle(t.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
            Text("HRV-C לומדת את הטווח האישי שלך ומזהה שינויים מתמשכים בדפוסי המנוחה. הכול נשאר על המכשיר שלך.")
                .font(.hrvCallout).foregroundStyle(t.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            PermissionCard(bullets: ["ללא חשבון או ענן", "כל הנתונים נשמרים במכשיר", "כלי wellness, לא אבחון רפואי"])
        }
    }

    private var appleHealth: some View {
        let t = HRVTheme.resolve(scheme)
        return VStack(alignment: .leading, spacing: HRVLayout.space16) {
            Text("חיבור לנתוני הבריאות")
                .font(.hrvDisplay).foregroundStyle(t.textPrimary)
            Text("כדי לבנות טווח אישי, האפליקציה צריכה לקרוא מדידות HRV ודופק מ־HealthKit.")
                .font(.hrvCallout).foregroundStyle(t.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            PermissionCard(bullets: ["קריאה בלבד", "ללא חשבון או ענן", "אפשר לשנות הרשאות בכל עת"])
            Text("האפליקציה אינה כלי רפואי ואינה מחליפה ייעוץ מקצועי.")
                .font(.hrvSubheadline).foregroundStyle(t.textTertiary)
        }
    }

    private var notifications: some View {
        let t = HRVTheme.resolve(scheme)
        return VStack(alignment: .leading, spacing: HRVLayout.space16) {
            Text("התראות")
                .font(.hrvDisplay).foregroundStyle(t.textPrimary)
            Text("נודיע לך רק כשמזוהה שינוי מתמשך מאומת — בשפה עדינה, לא אבחנתית.")
                .font(.hrvCallout).foregroundStyle(t.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            InformationCard(title: "רק כשחשוב",
                            message: "לא תוצף בהתראות. התראה נשלחת רק אחרי כמה מדידות רצופות מחוץ לטווח האישי.")
        }
    }

    private var learningBegins: some View {
        let t = HRVTheme.resolve(scheme)
        return VStack(alignment: .leading, spacing: HRVLayout.space16) {
            Text("מתחילים ללמוד")
                .font(.hrvDisplay).foregroundStyle(t.textPrimary)
            Text("בשבוע הקרוב נאסוף מדידות מנוחה כדי להבין מה רגיל עבורך. בתקופה הזאת לא יישלחו התראות.")
                .font(.hrvCallout).foregroundStyle(t.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            LearningProgress(day: 1, total: 7)
        }
    }
}
