import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// Settings → חיבור: a real connection & permissions self-test.
///
/// Fixes the "button does nothing" trap: iOS shows the HealthKit permission sheet
/// only once (dad already passed it in onboarding), and read-grant status is
/// opaque — so re-requesting silently no-ops. This screen instead *actually reads*
/// Health data and reports what came back, shows the Apple Watch link, and offers
/// a working Open-Settings deep link (the only way to change read access later).
struct ConnectionDiagnosticsView: View {
    @Environment(MonitoringCoordinator.self) private var coordinator
    @Environment(\.colorScheme) private var scheme
    @State private var result: ConnectionDiagnostic?
    @State private var isRunning = false

    var body: some View {
        let t = HRVTheme.resolve(scheme)
        ScrollView {
            VStack(alignment: .leading, spacing: HRVLayout.space16) {
                Text("בדיקה שהאפליקציה מקבלת נתונים מ-Apple Health ומ-Apple Watch. חשוב לדעת: iOS מבקש הרשאת בריאות פעם אחת בלבד — כל שינוי לאחר מכן נעשה דרך ההגדרות.")
                    .font(.hrvCallout).foregroundStyle(t.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                PrimaryButton(title: isRunning ? "בודק…" : "בדוק חיבור והרשאות",
                              enabled: !isRunning) { run() }

                if let r = result {
                    resultCard(t, r)

                    if case .canPrompt = r.prompt {
                        PrimaryButton(title: "אפשר גישה ל-Health") {
                            Task { await coordinator.requestHealthAccess(); run() }
                        }
                    }

                    Button { openSettings() } label: {
                        Text("פתח הגדרות")
                            .font(.hrvCallout).fontWeight(.semibold)
                            .foregroundStyle(t.accentPrimary)
                            .frame(maxWidth: .infinity, minHeight: HRVLayout.minimumTouchSize)
                            .background(t.surfacePrimary, in: RoundedRectangle(cornerRadius: HRVLayout.radius12, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    Text("בהגדרות אפשר לאשר או לשנות את הגישה ל-Apple Health עבור HRV-C.")
                        .font(.hrvCaption).foregroundStyle(t.textTertiary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(HRVLayout.space20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .animation(HRVMotion.gentle, value: result?.probe.sdnnCount)
        }
        .background(t.surfaceBackground)
        .navigationTitle("חיבור והרשאות")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: result

    private func resultCard(_ t: HRVTheme, _ r: ConnectionDiagnostic) -> some View {
        VStack(alignment: .leading, spacing: HRVLayout.space12) {
            let hasData = r.probe.sdnnCount > 0 || r.probe.restingHRCount > 0
            // Health data read-test — the honest signal.
            row(t, ok: hasData,
                title: "נתוני Apple Health",
                detail: healthDetail(r))
            // Permission hint.
            row(t, ok: hasData || r.prompt == .canPrompt,
                title: "הרשאת בריאות",
                detail: permissionDetail(r))
            // Apple Watch link.
            row(t, ok: r.watchReachable || r.watchAppInstalled,
                title: "Apple Watch",
                detail: watchDetail(r))
        }
        .padding(HRVLayout.space16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(t.surfacePrimary, in: RoundedRectangle(cornerRadius: HRVLayout.radius16, style: .continuous))
    }

    private func row(_ t: HRVTheme, ok: Bool, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: HRVLayout.space12) {
            Image(systemName: ok ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .font(.hrvHeadline)
                .foregroundStyle(ok ? Color.green : Color.orange)
            VStack(alignment: .leading, spacing: HRVLayout.space2) {
                Text(title).font(.hrvSubheadline).fontWeight(.semibold).foregroundStyle(t.textPrimary)
                Text(detail).font(.hrvCaption).foregroundStyle(t.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
    }

    // MARK: copy

    private func healthDetail(_ r: ConnectionDiagnostic) -> String {
        guard r.healthAvailable else { return "Apple Health לא זמין במכשיר הזה." }
        if r.probe.sdnnCount > 0 {
            let latest = r.probe.latestSDNN.map(Self.relative) ?? ""
            return "נמצאו \(r.probe.sdnnCount) מדידות HRV בשבוע האחרון" + (latest.isEmpty ? "." : ", האחרונה \(latest).")
        }
        if r.probe.restingHRCount > 0 {
            return "התקבל דופק במנוחה, אך אין עדיין מדידות HRV. עשו תרגיל נשימה בשעון וללבוש אותו בשינה."
        }
        return "לא התקבלו נתונים. ודאו שההרשאה מאושרת בהגדרות, שה-Apple Watch נלבש, ושבוצע תרגיל נשימה אחד לפחות."
    }

    private func permissionDetail(_ r: ConnectionDiagnostic) -> String {
        switch r.prompt {
        case .canPrompt:    return "עדיין לא נשאלת. לחצו \"אפשר גישה ל-Health\" כדי לאשר."
        case .alreadyAsked: return "כבר נשאלת פעם אחת. iOS אינו שואל שוב — לשינוי, פתחו את ההגדרות."
        case .unknown:      return "מצב ההרשאה אינו ידוע."
        }
    }

    private func watchDetail(_ r: ConnectionDiagnostic) -> String {
        if r.watchReachable { return "מחובר וזמין." }
        if r.watchAppInstalled { return "מותקן, כרגע לא בהישג יד (זה תקין כשהשעון נעול)." }
        if r.watchPaired { return "מזווג לטלפון. אפליקציית השעון עדיין לא הותקנה." }
        return "לא זוהה Apple Watch מזווג. ה-HRV מגיע בעיקר מהשעון."
    }

    // MARK: actions

    private func run() {
        isRunning = true
        Task {
            let r = await coordinator.runConnectionDiagnostic()
            await MainActor.run { result = r; isRunning = false }
        }
    }

    private func openSettings() {
        #if canImport(UIKit)
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
        #endif
    }

    private static func relative(_ date: Date) -> String {
        let f = RelativeDateTimeFormatter()
        f.locale = Locale(identifier: "he")
        f.unitsStyle = .full
        return f.localizedString(for: date, relativeTo: Date())
    }
}
