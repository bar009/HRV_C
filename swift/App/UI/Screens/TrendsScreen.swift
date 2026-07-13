import SwiftUI

/// Trends (מגמות) tab. TODO(Step 5): baseline chart (30d) + factual help card.
struct TrendsScreen: View {
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let t = HRVTheme.resolve(scheme)
        VStack(alignment: .leading, spacing: HRVLayout.space16) {
            Text("מגמות").font(.hrvDisplay).foregroundStyle(t.textPrimary)
            Spacer()
        }
        .padding(HRVLayout.space20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(t.surfaceBackground)
    }
}
