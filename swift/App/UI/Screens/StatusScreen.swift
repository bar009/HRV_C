import SwiftUI
import HRVCore

/// The Today (היום) tab — renders the user-visible state from
/// `coordinator.presentation` (see docs/UI_WIRING.md). Copy is canonical
/// (PRODUCT_STATE_MODEL): factual, never a feeling/diagnosis.
struct StatusScreen: View {
    @Environment(MonitoringCoordinator.self) private var coordinator
    @Environment(\.colorScheme) private var scheme
    @State private var showGuided = false

    var body: some View {
        let t = HRVTheme.resolve(scheme)
        ScrollView {
            VStack(alignment: .leading, spacing: HRVLayout.space16) {
                content
            }
            .padding(HRVLayout.space20)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(t.surfaceBackground)
        .sheet(isPresented: $showGuided) {
            GuidedMomentView(alertID: pendingAlertID ?? currentAlertID)
        }
        // P3: notification tap -> open the Guided Moment for that alert.
        // onAppear covers the cold-launch-from-notification case, where the
        // pending id is set before this view exists.
        .onAppear {
            if pendingAlertID != nil { showGuided = true }
        }
        .onChange(of: coordinator.pendingGuidedAlertID) { _, id in
            if id != nil { showGuided = true }
        }
        .onChange(of: showGuided) { _, shown in
            if !shown { coordinator.pendingGuidedAlertID = nil }
        }
    }

    private var pendingAlertID: UUID? { coordinator.pendingGuidedAlertID }

    private var currentAlertID: UUID? {
        if case let .attention(id, _) = coordinator.presentation { return id }
        return nil
    }

    /// Newest sample's raw SDNN in ms -- the concrete number behind the state.
    private var latestValueMs: Double? {
        coordinator.recentSamples.max { $0.timestamp < $1.timestamp }?.rawValueMs
    }

    @ViewBuilder private var content: some View {
        Group {
            switch coordinator.presentation {
            case .setupRequired:                 setupRequired
            case let .learning(day, total):      learning(day: day, total: total)
            case let .stable(updated):           stable(updated: updated)
            case let .attention(_, updated):     attention(updated: updated)
            case .unavailable:                   unavailable
            }
        }
        .transition(.opacity)
        .animation(HRVMotion.gentle, value: coordinator.presentation)
    }

    // MARK: - states
    private var setupRequired: some View {
        let t = HRVTheme.resolve(scheme)
        return VStack(alignment: .leading, spacing: HRVLayout.space16) {
            Text("כדי להתחיל, נחבר את נתוני ה־HRV שלך")
                .font(.hrvDisplay).foregroundStyle(t.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
            Text("הנתונים נקראים מ־Apple Health ונשמרים במכשיר שלך.")
                .font(.hrvCallout).foregroundStyle(t.textSecondary)
            PermissionCard(bullets: ["קריאה בלבד", "ללא חשבון או ענן", "אפשר לשנות הרשאות בכל עת"])
            PrimaryButton(title: "המשך להגדרה") {
                Task { await coordinator.requestHealthAccess() }
            }
            Text("זהו כלי wellness, לא אבחון רפואי.")
                .font(.hrvSubheadline).foregroundStyle(t.textTertiary)
        }
    }

    private func learning(day: Int, total: Int) -> some View {
        let t = HRVTheme.resolve(scheme)
        return VStack(alignment: .leading, spacing: HRVLayout.space16) {
            Text("לומדים את הטווח האישי שלך")
                .font(.hrvDisplay).foregroundStyle(t.textPrimary)
            LearningProgress(day: day, total: total)
        }
    }

    private func stable(updated: Date?) -> some View {
        VStack(alignment: .leading, spacing: HRVLayout.space16) {
            StatusCard(kind: .stable, eyebrow: "מצב נוכחי", title: "בטווח האישי שלך", timestamp: updated)
            MeasuresRow(latestMs: latestValueMs, baseline: coordinator.baseline)
            BaselineChartCard(samples: coordinator.recentSamples, baseline: coordinator.baseline)
        }
    }

    private func attention(updated: Date?) -> some View {
        let t = HRVTheme.resolve(scheme)
        return VStack(alignment: .leading, spacing: HRVLayout.space16) {
            StatusCard(kind: .attention, eyebrow: "אירוע חדש", title: "זוהה שינוי מתמשך",
                       message: "הדפוס שלך נמצא מתחת לטווח האישי במשך כמה מדידות רצופות.",
                       timestamp: updated)
            MeasuresRow(latestMs: latestValueMs, baseline: coordinator.baseline)
            PrimaryButton(title: "לבדוק מה קורה עכשיו") { showGuided = true }
            Text("אפשר להתייחס לזה כהזמנה לעצור, לנוח ולשים לב להרגשה הכללית שלך.")
                .font(.hrvCallout).foregroundStyle(t.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var unavailable: some View {
        let t = HRVTheme.resolve(scheme)
        return VStack(alignment: .leading, spacing: HRVLayout.space16) {
            Text("ממתינים למדידה חדשה")
                .font(.hrvDisplay).foregroundStyle(t.textPrimary)
            EmptyState(title: "אין נתון עדכני",
                       message: "המדידה האחרונה התקבלה בעבר. נעדכן כשיגיע נתון חדש.",
                       systemImage: "clock.arrow.circlepath")
            PrimaryButton(title: "בדיקת חיבור והרשאות") {
                Task { await coordinator.requestHealthAccess() }
            }
        }
    }
}
