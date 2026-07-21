import SwiftUI

/// Shared tap feedback: a small scale + opacity dip on press. Used instead of
/// bare `.buttonStyle(.plain)` wherever a button has custom chrome, so taps
/// feel acknowledged instead of the app reading as static/unresponsive.
struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? HRVLayout.opacityPressed : HRVLayout.opacityFull)
            .animation(HRVMotion.quick, value: configuration.isPressed)
    }
}

extension View {
    /// `.buttonStyle(.plain)` + press feedback, in one call.
    func pressable() -> some View { buttonStyle(PressableButtonStyle()) }
}
