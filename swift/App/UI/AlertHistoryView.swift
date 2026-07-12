// Track F -- alert history, styled from the design system (Mac-only).
import SwiftUI
import SwiftData

struct AlertHistoryView: View {
    @Query(sort: \StoredAlert.firedAt, order: .reverse) private var alerts: [StoredAlert]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(alerts) { a in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(a.firedAt, format: .dateTime.day().month().hour().minute())
                                .font(.hrvCallout).fontWeight(.semibold)
                                .foregroundStyle(HRVColor.textPrimary)
                            Text(a.reason)
                                .font(.hrvSubheadline)
                                .foregroundStyle(HRVColor.textSecondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16)
                        .background(HRVColor.surfacePrimary,
                                    in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                }
                .padding(20)
            }
            .background(HRVColor.surfaceBackground)
            .navigationTitle("התראות")
            .overlay {
                if alerts.isEmpty {
                    ContentUnavailableView("אין התראות", systemImage: "checkmark.circle",
                                           description: Text("הכול נראה תקין."))
                }
            }
        }
    }
}
