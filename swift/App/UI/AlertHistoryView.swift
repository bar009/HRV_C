// Track F -- alert history (Mac-only).
import SwiftUI
import SwiftData

struct AlertHistoryView: View {
    @Query(sort: \StoredAlert.firedAt, order: .reverse) private var alerts: [StoredAlert]

    var body: some View {
        NavigationStack {
            List(alerts) { a in
                VStack(alignment: .leading, spacing: 4) {
                    Text(a.firedAt, format: .dateTime.day().month().hour().minute())
                        .font(.headline)
                    Text(a.reason)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("היסטוריית התראות")
            .overlay {
                if alerts.isEmpty {
                    ContentUnavailableView("אין התראות", systemImage: "checkmark.circle",
                                           description: Text("הכול נראה תקין."))
                }
            }
        }
    }
}
