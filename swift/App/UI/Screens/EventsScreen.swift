import SwiftUI

/// Events (אירועים) tab. TODO(Step 5): list `coordinator.events` via EventRow.
struct EventsScreen: View {
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let t = HRVTheme.resolve(scheme)
        VStack(alignment: .leading, spacing: HRVLayout.space16) {
            Text("אירועים").font(.hrvDisplay).foregroundStyle(t.textPrimary)
            Spacer()
        }
        .padding(HRVLayout.space20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(t.surfaceBackground)
    }
}
