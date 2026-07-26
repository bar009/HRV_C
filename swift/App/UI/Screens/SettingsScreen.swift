import SwiftUI
import HRVCore

/// Settings (separate screen, not a tab): HealthKit · Notifications · Privacy ·
/// About · Wellness (P4). Factual, local-first language.
struct SettingsScreen: View {
    @Environment(MonitoringCoordinator.self) private var coordinator
    @Environment(\.dismiss) private var dismiss
    @State private var showDeleteConfirm = false

    private var sexBinding: Binding<BiologicalSex> {
        Binding(get: { coordinator.biologicalSex }, set: { coordinator.biologicalSex = $0 })
    }

    private var modeBinding: Binding<SensorMode> {
        Binding(get: { coordinator.sensorMode }, set: { coordinator.sensorMode = $0 })
    }

    var body: some View {
        NavigationStack {
            List {
                Section("חיבור") {
                    NavigationLink {
                        ConnectionDiagnosticsView()
                    } label: { Label("חיבור והרשאות", systemImage: "heart.text.square") }

                    NavigationLink {
                        SettingsDetail(
                            title: "התראות",
                            text: "התראה נשלחת רק כשמזוהה שינוי מתמשך מאומת. הכול מקומי — ללא שרת.",
                            actionTitle: "אפשר התראות",
                            action: { Task { await coordinator.requestNotifications() } }
                        )
                    } label: { Label("התראות", systemImage: "bell") }
                }

                if FeatureFlags.bleStrapEnabled {
                    Section {
                        Picker("מקור המדידה", selection: modeBinding) {
                            Text("Apple Watch").tag(SensorMode.appleWatch)
                            Text("רצועת דופק").tag(SensorMode.bleStrap)
                        }
                        NavigationLink {
                            StrapSetupView()
                        } label: { Label("רצועת דופק", systemImage: "sensor.tag.radiowaves.forward") }
                    } header: {
                        Text("מצב חיישן")
                    } footer: {
                        Text("Apple Watch מודד כמה פעמים ביום במנוחה — מספיק לזיהוי שינוי מתמשך. רצועת דופק מודדת ברציפות בין פעימה לפעימה, ומאפשרת גם זיהוי בזמן אמת וקוהרנטיות מדויקת. שינוי המצב ייכנס לתוקף בהפעלה הבאה.")
                    }

                    Section {
                        IndicatorAvailabilityList(capabilities: coordinator.capabilities)
                            .listRowInsets(EdgeInsets())
                            .listRowBackground(Color.clear)
                    }
                }

                Section {
                    Picker("מין ביולוגי", selection: sexBinding) {
                        Text("לא צוין").tag(BiologicalSex.unspecified)
                        Text("נקבה").tag(BiologicalSex.female)
                        Text("זכר").tag(BiologicalSex.male)
                    }
                } header: {
                    Text("כיול אישי")
                } footer: {
                    Text("שונות קצב הלב שונה בין המינים. הטווח האישי שלך כבר מסתגל אליך אישית; פרט זה נשמר כדי לדייק את הכיול בהמשך. אופציונלי, נשמר במכשיר בלבד.")
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

                Section {
                    Button {
                        coordinator.loadDemoData()
                    } label: {
                        Label("טעינת נתוני הדגמה", systemImage: "wand.and.stars")
                    }
                    Button(role: .destructive) {
                        showDeleteConfirm = true
                    } label: {
                        Label("מחיקת כל הנתונים", systemImage: "trash")
                    }
                } header: {
                    Text("נתונים")
                } footer: {
                    Text("נתוני הדגמה מאפשרים לראות את האפליקציה עובדת ללא Apple Watch. מחיקה מסירה את כל ההיסטוריה, הטווח האישי וההגדרות מהמכשיר ומחזירה למצב התחלתי.")
                }
            }
            .navigationTitle("הגדרות")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("סגירה") { dismiss() } }
            }
            .confirmationDialog("למחוק את כל הנתונים?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
                Button("מחיקה", role: .destructive) { coordinator.deleteAllData(); dismiss() }
                Button("ביטול", role: .cancel) {}
            } message: {
                Text("הפעולה בלתי הפיכה. כל ההיסטוריה והטווח האישי יימחקו מהמכשיר.")
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
