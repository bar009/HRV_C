import SwiftUI

/// Detail sheet for a past event (P6): the factual measures behind the alert
/// (value, depth, duration) plus a permanent home for the relevance feedback --
/// previously feedback was only reachable while the alert was live.
struct EventDetailView: View {
    let event: EventRecord
    @Environment(MonitoringCoordinator.self) private var coordinator
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme
    @State private var relevance: Relevance?

    var body: some View {
        let t = HRVTheme.resolve(scheme)
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: HRVLayout.space16) {
                    Text(EventsScreen.title(for: event.firedAt))
                        .font(.hrvDisplay).foregroundStyle(t.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(Self.timeFmt.string(from: event.firedAt))
                        .font(.hrvSubheadline).foregroundStyle(t.textSecondary)

                    measures(t)

                    CollapsibleNote(
                        title: "מה זה אומר?",
                        message: "כמה מדידות רצופות היו מחוץ לטווח האישי שלך. זו אינה אבחנה — רק תיעוד עובדתי של השינוי."
                    )

                    VStack(alignment: .leading, spacing: HRVLayout.space8) {
                        Text("האם ההתראה הייתה במקום?")
                            .font(.hrvHeadline).foregroundStyle(t.textPrimary)
                        RelevanceFeedback(selection: $relevance)
                        if relevance != nil {
                            Text("התשובה נשמרה")
                                .font(.hrvCaption).foregroundStyle(t.textTertiary)
                                .transition(.opacity)
                        }
                    }
                    .animation(HRVMotion.standard, value: relevance)
                }
                .padding(HRVLayout.space24)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(t.surfaceBackground)
            .navigationTitle("פרטי אירוע")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("סגירה") { dismiss() } }
            }
        }
        .environment(\.layoutDirection, .rightToLeft)
        .onAppear {
            // Only clear the "new" badge for events that already resolved.
            // The still-open (live) event must stay unseen here: Attention's
            // intended exit is the Guided Moment, not merely glancing at this
            // sheet from the Events list and closing it.
            if event.durationHours != nil {
                coordinator.markEventSeen(event.id)
            }
            relevance = coordinator.savedRelevance(for: event.id).flatMap(Relevance.init(rawValue:))
        }
        .onChange(of: relevance) { _, new in
            if let new { coordinator.saveRelevance(new.rawValue, for: event.id) }
        }
    }

    /// The stored numbers behind this event, phrased factually.
    private func measures(_ t: HRVTheme) -> some View {
        VStack(spacing: 0) {
            row(t, label: "המדידה בזמן האירוע", value: "\(Int(event.rawValueMs.rounded())) ms")
            divider(t)
            row(t, label: "עומק השינוי", value: String(format: "%.1f סטיות מתחת לטווח", abs(event.robustZ)))
            divider(t)
            row(t, label: "משך", value: durationText)
        }
        .background(t.surfacePrimary, in: RoundedRectangle(cornerRadius: HRVLayout.radius16, style: .continuous))
    }

    private var durationText: String {
        guard let h = event.durationHours else { return "טרם הסתיים" }
        return "\(Int(h.rounded())) שעות"
    }

    private func row(_ t: HRVTheme, label: String, value: String) -> some View {
        HStack {
            Text(label).font(.hrvCallout).foregroundStyle(t.textSecondary)
            Spacer()
            Text(value).font(.hrvCallout).fontWeight(.semibold).foregroundStyle(t.textPrimary)
        }
        .padding(HRVLayout.space16)
    }

    private func divider(_ t: HRVTheme) -> some View {
        Rectangle()
            .fill(t.borderSubtle)
            .frame(height: HRVLayout.hairlineWidth)
            .padding(.horizontal, HRVLayout.space16)
    }

    private static let timeFmt: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "he")
        f.dateFormat = "HH:mm"
        return f
    }()
}
