import SwiftUI

/// "What happened today" on the Today tab — the events that fired since
/// midnight, so the user never has to switch tabs and scan dates. Rows reuse
/// EventRow (press feedback, "חדש" badge) and open the same EventDetailView
/// sheet as the Events tab.
struct TodayEventsSection: View {
    let events: [EventRecord]
    @Environment(\.colorScheme) private var scheme
    @State private var selectedEvent: EventRecord?

    var body: some View {
        let t = HRVTheme.resolve(scheme)
        VStack(alignment: .leading, spacing: HRVLayout.space12) {
            Text("האירועים של היום")
                .font(.hrvHeadline)
                .foregroundStyle(t.textPrimary)

            if events.isEmpty {
                // No full EmptyState card: "no events" is the good outcome
                // here and shouldn't take up space or shout.
                Text("לא זוהו אירועים היום")
                    .font(.hrvCallout)
                    .foregroundStyle(t.textSecondary)
                    .transition(.opacity)
            } else {
                ForEach(events, id: \.id) { event in
                    EventRow(title: Self.title(for: event),
                             subtitle: EventsScreen.subtitle(for: event),
                             isNew: !event.seen) {
                        selectedEvent = event
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
        .animation(HRVMotion.standard, value: events.map(\.id))
        .frame(maxWidth: .infinity, alignment: .leading)
        .sheet(item: $selectedEvent) { event in
            EventDetailView(event: event)
        }
    }

    /// Time of day, since every row here is from today.
    static func title(for event: EventRecord) -> String {
        "\(timeFmt.string(from: event.firedAt)) · \(EventShapePresentation.label(event.shape))"
    }

    private static let timeFmt: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "he")
        f.dateFormat = "HH:mm"
        return f
    }()
}
