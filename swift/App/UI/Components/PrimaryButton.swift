import SwiftUI

/// The single primary call-to-action per screen (AGENTS.md). Accent fill.
struct PrimaryButton: View {
    let title: String
    var enabled: Bool = true
    let action: () -> Void
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let t = HRVTheme.resolve(scheme)
        Button(action: action) {
            Text(title)
                .font(.hrvCallout).fontWeight(.semibold)
                .foregroundStyle(t.textInverse)
                .frame(maxWidth: .infinity, minHeight: HRVLayout.minimumTouchSize)
                .background(t.accentPrimary, in: RoundedRectangle(cornerRadius: HRVLayout.radius12, style: .continuous))
        }
        .pressable()
        .opacity(enabled ? HRVLayout.opacityFull : HRVLayout.opacityPressed)
        .disabled(!enabled)
    }
}
