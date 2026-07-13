import SwiftUI

/// Settings (separate screen, not a tab). TODO(Step 5): HealthKit · Notifications
/// · Privacy · About · Wellness disclaimer.
struct SettingsScreen: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let t = HRVTheme.resolve(scheme)
        NavigationStack {
            VStack(alignment: .leading, spacing: HRVLayout.space16) {
                Spacer()
            }
            .padding(HRVLayout.space20)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(t.surfaceBackground)
            .navigationTitle("הגדרות")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("סגירה") { dismiss() }
                }
            }
        }
        .environment(\.layoutDirection, .rightToLeft)
    }
}
