import SwiftUI

/// The post-alert Guided Moment (M3). TODO(Step 7): the 8-step flow
/// (Alert Detail → Intro → Body → Mind → Context → Support → If-Then → Relevance),
/// one question per screen, skippable, answers saved to GuidedResponse.
struct GuidedMomentView: View {
    let alertID: UUID?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let t = HRVTheme.resolve(scheme)
        NavigationStack {
            VStack(spacing: HRVLayout.space16) {
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(t.surfaceBackground)
            .navigationTitle("רגע של בדיקה")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Not Now") { dismiss() }
                }
            }
        }
        .environment(\.layoutDirection, .rightToLeft)
    }
}
