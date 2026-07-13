import SwiftUI

/// Settings (separate screen, not a tab): HealthKit · Notifications · Privacy ·
/// About · Wellness (P4). Factual, local-first language.
struct SettingsScreen: View {
    @Environment(MonitoringCoordinator.self) private var coordinator
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("חיבור") {
                    NavigationLink {
                        SettingsDetail(
                            title: "HealthKit והרשאות",
                            text: coordinator.isHealthAuthorized
                                ? "הגישה ל-Apple Health מאושרת. האפליקציה קוראת HRV ודופק כדי לבנות טווח אישי."
                                : "האפליקציה צריכה גישה ל-Apple Health (קריאה בלבד) כדי לבנות טווח אישי ולזהות שינוי מתמשך.",
                            actionTitle: coordinator.isHealthAuthorized ? nil : "אפשר גישה ל-Health",
                            action: { Task { await coordinator.requestHealthAccess() } }
                        )
                    } label: { Label("HealthKit והרשאות", systemImage: "heart.text.square") }

                    NavigationLink {
                        SettingsDetail(
                            title: "התראות",
                            text: "התראה נשלחת רק כשמזוהה שינוי מתמשך מאומת. הכול מקומי — ללא שרת.",
                            actionTitle: "אפשר התראות",
                            action: { Task { await coordinator.requestNotifications() } }
                        )
                    } label: { Label("התראות", systemImage: "bell") }
                }

                Section("פרטיות") {
                    NavigationLink {
                        SettingsDetail(title: "פרטיות ואחסון מקומי",
                                       text: "כל הנתונים נשמרים במכשיר שלך בלבד. אין חשבון, אין ענן, ואין איסוף מידע.")
                    } label: { Label("פרטיות ואחסון מקומי", systemImage: "lock") }
                }

                Section {
                    NavigationLink {
                        SettingsDetail(title: "אודות HRV-C",
                                       text: "HRV-C לומדת את הטווח האישי שלך מנתוני ה-HRV שה-Apple Watch אוסף, ומודיעה על שינוי מתמשך. גרסה 0.1.")
                    } label: { Label("אודות HRV-C", systemImage: "info.circle") }

                    NavigationLink {
                        SettingsDetail(title: "הצהרת Wellness",
                                       text: "זהו כלי wellness ואינו אבחון רפואי. הוא אינו מזהה רגש, דפוס תת-מודע או מצב רפואי, ואינו מחליף ייעוץ מקצועי.")
                    } label: { Label("הצהרת Wellness", systemImage: "checkmark.seal") }
                }
            }
            .navigationTitle("הגדרות")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("סגירה") { dismiss() } }
            }
        }
        .environment(\.layoutDirection, .rightToLeft)
    }
}

/// A titled text detail with an optional primary action (used by Settings rows).
private struct SettingsDetail: View {
    let title: String
    let text: String
    var actionTitle: String? = nil
    var action: () -> Void = {}
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let t = HRVTheme.resolve(scheme)
        ScrollView {
            VStack(alignment: .leading, spacing: HRVLayout.space16) {
                Text(text)
                    .font(.hrvCallout).foregroundStyle(t.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                if let actionTitle {
                    PrimaryButton(title: actionTitle, action: action)
                }
            }
            .padding(HRVLayout.space20)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(t.surfaceBackground)
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}
