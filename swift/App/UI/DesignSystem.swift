// Track F -- design system codified from Figma "HRV-C — UX Wireframes v0.1"
// (file hlCzE7OlX9yaZa7s5UJyhL). Tokens copied 1:1 from the Figma variables.
// Mac-only (SwiftUI).
import SwiftUI

extension Color {
    init(hexRGB hex: UInt, alpha: Double = 1) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255,
                  opacity: alpha)
    }
}

/// Colour tokens (Figma: --hrv-light-*). A calm, wellness-first teal palette.
enum HRVColor {
    static let accentPrimary    = Color(hexRGB: 0x39796D)
    static let textPrimary      = Color(hexRGB: 0x171C19)
    static let textSecondary    = Color(hexRGB: 0x636B66)
    static let chartBand        = Color(hexRGB: 0xD6ECE6)  // "normal range" band
    static let chartLine        = Color(hexRGB: 0x2B5F57)  // baseline signal
    static let surfacePrimary   = Color(hexRGB: 0xFFFFFF)
    static let surfaceSecondary = Color(hexRGB: 0xF0F2EF)
    static let surfaceBackground = Color(hexRGB: 0xF7F8F6)
}

/// Type ramp (Figma: iOS/*). SF Pro is the system font, so these map to it.
extension Font {
    static let hrvDisplay     = Font.system(size: 34, weight: .semibold)  // iOS/Display
    static let hrvTitle3      = Font.system(size: 20, weight: .semibold)  // iOS/Title 3
    static let hrvCallout     = Font.system(size: 16, weight: .regular)   // iOS/Callout
    static let hrvSubheadline = Font.system(size: 15, weight: .regular)   // iOS/Subheadline
}

/// The signature "Personal Baseline Motif" from the cover: a normal-range band
/// with a jittering signal line + points. Reused in onboarding / empty states.
struct BaselineMotif: View {
    var values: [Double] = [0.55, 0.42, 0.62, 0.36, 0.52, 0.30, 0.48, 0.26, 0.44]

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ZStack {
                RoundedRectangle(cornerRadius: h * 0.30, style: .continuous)
                    .fill(HRVColor.chartBand)
                    .frame(height: h * 0.55)
                Canvas { ctx, size in
                    guard values.count > 1 else { return }
                    let stepX = size.width / CGFloat(values.count - 1)
                    var line = Path()
                    var points: [CGPoint] = []
                    for (i, v) in values.enumerated() {
                        let p = CGPoint(x: CGFloat(i) * stepX,
                                        y: size.height * (1 - CGFloat(v)))
                        points.append(p)
                        if i == 0 { line.move(to: p) } else { line.addLine(to: p) }
                    }
                    ctx.stroke(line, with: .color(HRVColor.chartLine), lineWidth: 3)
                    for p in points {
                        let r: CGFloat = 5
                        ctx.fill(Path(ellipseIn: CGRect(x: p.x - r, y: p.y - r, width: 2 * r, height: 2 * r)),
                                 with: .color(HRVColor.chartLine))
                    }
                }
            }
            .frame(width: w, height: h)
        }
    }
}
