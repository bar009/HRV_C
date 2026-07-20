import SwiftUI

/// Events (אירועים) tab — the history of confirmed changes (P6). Factual only.
struct EventsScreen: View {
    @Environment(MonitoringCoordinator.self) private var coordinator
    @Environment(\.colorScheme) private var scheme
    @State private var selectedEvent: EventRecord?

    var body: some View {
        let t = HRVTheme.resolve(scheme)
        ScrollView {
            VStack(alignment: .leading, spacing: HRVLayout.space12) {
                Text("אירועים").font(.hrvDisplay).foregroundStyle(t.textPrimary)
                if coordinator.events.isEmpty {
                    EmptyState(title: "אין אירועים",
                               message: "כשיזוהה שינוי מתמשך הוא יופיע כאן.",
                               systemImage: "checkmark.circle")
                        .padding(.top, HRVLayout.space8)
                        .transition(.opacity)
                } else {
                    ForEach(coordinator.events, id: \.id) { event in
                        EventRow(title: Self.title(for: event.firedAt),
                                 subtitle: Self.subtitle(for: event),
                                 isNew: !event.seen) {
                            selectedEvent = event
                        }
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
            }
            .animation(HRVMotion.standard, value: coordinator.events.map(\.id))
            .padding(HRVLayout.space20)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(t.surfaceBackground)
        .sheet(item: $selectedEvent) { event in
            EventDetailView(event: event)
        }
    }

    private static let dateFmt: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "he")
        f.dateFormat = "d בMMMM"
        return f
    }()

    static func title(for date: Date) -> String {
        let day = Calendar.current.isDateInToday(date) ? "היום" : dateFmt.string(from: date)
        return "\(day) · שינוי מתמשך"
    }
    static func subtitle(for event: EventRecord) -> String {
        if let h = event.durationHours { return "נמשך \(Int(h.rounded())) שעות" }
        return "לצפייה במגמה"
    }
}
