import SwiftUI

/// M3 Post-Alert Guided Moment — 8 steps, one question per screen, every step
/// skippable. The app invites reflection but never fills the user's answer
/// (METHOD_PRODUCT_PRINCIPLES); answers persist to GuidedResponse, separate
/// from detector truth.
struct GuidedMomentView: View {
    let alertID: UUID?
    @Environment(MonitoringCoordinator.self) private var coordinator
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme

    @State private var step = 1
    @State private var bodyText = ""
    @State private var mindText = ""
    @State private var contextText = ""
    @State private var support = ""
    @State private var ifText = ""
    @State private var thenText = ""
    @State private var relevance: Relevance?
    private let total = 8

    var body: some View {
        let t = HRVTheme.resolve(scheme)
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: HRVLayout.space16) { content }
                        .padding(HRVLayout.space24)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                footer(t)
            }
            .background(t.surfaceBackground)
            .navigationTitle("רגע של בדיקה")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("לא עכשיו") { skip() }
                }
            }
        }
        .environment(\.layoutDirection, .rightToLeft)
    }

    // MARK: footer
    private func footer(_ t: HRVTheme) -> some View {
        VStack(spacing: HRVLayout.space12) {
            StepProgress(current: step, total: total)
            PrimaryButton(title: primaryTitle) { advance() }
            if step > 1 && step < total {
                Button("דלג") { advance() }
                    .font(.hrvSubheadline).foregroundStyle(t.textTertiary)
            }
        }
        .padding(HRVLayout.space20)
    }

    private var primaryTitle: String {
        switch step {
        case 1:     "להתחיל"
        case total: "סיום"
        default:    "המשך"
        }
    }

    private func advance() {
        if step < total { step += 1 } else { finish() }
    }

    /// PRODUCT_STATE_MODEL: completing or skipping the Guided Moment exits the
    /// Attention state, so both paths mark the triggering event as seen.
    private func skip() {
        if let alertID { coordinator.markEventSeen(alertID) }
        dismiss()
    }

    private func finish() {
        let plan = (ifText.isEmpty && thenText.isEmpty) ? "" : "אם \(ifText) אז \(thenText)"
        coordinator.saveGuidedResponse(
            GuidedResponse(eventID: alertID ?? UUID(),
                           body: bodyText, mind: mindText, context: contextText,
                           supportChoice: support, ifThenPlan: plan,
                           relevance: relevance?.rawValue ?? "")
        )
        if let alertID { coordinator.markEventSeen(alertID) }
        dismiss()
    }

    // MARK: content
    @ViewBuilder private var content: some View {
        Group { stepContent }
            .transition(.asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            ))
            .animation(HRVMotion.standard, value: step)
    }

    @ViewBuilder private var stepContent: some View {
        let t = HRVTheme.resolve(scheme)
        switch step {
        case 1:
            heading("זוהה שינוי מתמשך", t)
            InformationCard(title: "מה זה אומר",
                            message: "כמה מדידות רצופות נמצאות מחוץ לטווח האישי שלך. זו אינה אבחנה — רק הזמנה לעצור ולשים לב.")
        case 2:
            heading("רגע קצר לעצמך", t)
            InformationCard(title: "איך זה עובד",
                            message: "כמה שאלות קצרות, אפשר לדלג על כל אחת. לא נגיד לך מה אתה מרגיש — רק מזמינים אותך לשים לב.")
        case 3:
            GuidedQuestionCard(question: "מה אתה מרגיש בגוף עכשיו?",
                               helper: "לדוגמה: מתח בכתפיים, נשימה קצרה", text: $bodyText)
        case 4:
            GuidedQuestionCard(question: "אילו מחשבות עולות?", text: $mindText)
        case 5:
            GuidedQuestionCard(question: "מה קרה סביב הזמן הזה?",
                               helper: "אירוע, שיחה, מקום", text: $contextText)
        case 6:
            heading("מה יעזור עכשיו?", t)
            SupportActionCard(title: "נשימה", subtitle: "כמה נשימות איטיות",
                              systemImage: "wind", selected: support == "breathing") { support = "breathing" }
            SupportActionCard(title: "תנועה", subtitle: "לזוז מעט, לשנות תנוחה",
                              systemImage: "figure.walk", selected: support == "movement") { support = "movement" }
            SupportActionCard(title: "דחייה", subtitle: "לדחות תגובה לרגע",
                              systemImage: "clock", selected: support == "delay") { support = "delay" }
            if support == "breathing" {
                BreathingRing().frame(maxWidth: .infinity).padding(.top, HRVLayout.space8)
            }
        case 7:
            heading("תוכנית קטנה", t)
            IfThenRow(ifText: $ifText, thenText: $thenText)
        default:
            heading("האם זה היה במקום?", t)
            RelevanceFeedback(selection: $relevance)
        }
    }

    private func heading(_ text: String, _ t: HRVTheme) -> some View {
        Text(text)
            .font(.hrvDisplay).foregroundStyle(t.textPrimary)
            .fixedSize(horizontal: false, vertical: true)
    }
}
