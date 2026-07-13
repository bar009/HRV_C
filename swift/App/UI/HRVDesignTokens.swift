import SwiftUI

// Generated from the HRV-C Figma foundations.
// Scaffold only: compile and validate in the app target and watch target.

enum HRVColor {
    static let neutral0 = Color(hex: 0xFFFFFF)
    static let neutral50 = Color(hex: 0xF7F8F6)
    static let neutral100 = Color(hex: 0xF0F2EF)
    static let neutral200 = Color(hex: 0xE1E5E1)
    static let neutral400 = Color(hex: 0xA3AAA5)
    static let neutral600 = Color(hex: 0x636B66)
    static let neutral800 = Color(hex: 0x29312D)
    static let neutral900 = Color(hex: 0x171C19)
    static let neutral950 = Color(hex: 0x0D100F)

    static let accent50 = Color(hex: 0xECF6F3)
    static let accent100 = Color(hex: 0xD6ECE6)
    static let accent300 = Color(hex: 0x8FC5B8)
    static let accent500 = Color(hex: 0x4E9284)
    static let accent600 = Color(hex: 0x39796D)
    static let accent700 = Color(hex: 0x2B5F57)
    static let accent900 = Color(hex: 0x15332F)

    static let blue300 = Color(hex: 0x9BB4CC)
    static let blue500 = Color(hex: 0x6484A3)
    static let amber300 = Color(hex: 0xE2BD7D)
    static let amber500 = Color(hex: 0xC18C34)
    static let red300 = Color(hex: 0xD79A95)
    static let red500 = Color(hex: 0xB45B57)
}

enum HRVLayout {
    static let space0: CGFloat = 0
    static let space2: CGFloat = 2
    static let space4: CGFloat = 4
    static let space8: CGFloat = 8
    static let space12: CGFloat = 12
    static let space16: CGFloat = 16
    static let space20: CGFloat = 20
    static let space24: CGFloat = 24
    static let space32: CGFloat = 32
    static let space40: CGFloat = 40
    static let space48: CGFloat = 48

    static let radius8: CGFloat = 8
    static let radius12: CGFloat = 12
    static let radius16: CGFloat = 16
    static let radius20: CGFloat = 20
    static let radius24: CGFloat = 24
    static let radiusPill: CGFloat = 999

    static let minimumTouchSize: CGFloat = 44
    static let watchButtonHeight: CGFloat = 48
    static let statusDotSize: CGFloat = 10
    static let iconSmall: CGFloat = 16
    static let iconMedium: CGFloat = 20
    static let iconLarge: CGFloat = 28
    static let hairlineWidth: CGFloat = 1
    static let strongStrokeWidth: CGFloat = 2

    static let opacityFull: Double = 1.0
    static let opacityPressed: Double = 0.82
}

struct HRVTheme: Equatable {
    let surfaceBackground: Color
    let surfacePrimary: Color
    let surfaceSecondary: Color
    let surfaceElevated: Color
    let surfaceInverse: Color

    let textPrimary: Color
    let textSecondary: Color
    let textTertiary: Color
    let textInverse: Color

    let borderSubtle: Color
    let borderStrong: Color

    let accentPrimary: Color
    let accentSoft: Color

    let statusLearning: Color
    let statusLearningSoft: Color
    let statusStable: Color
    let statusStableSoft: Color
    let statusAttention: Color
    let statusAttentionSoft: Color
    let statusCritical: Color
    let statusCriticalSoft: Color
    let statusUnavailable: Color

    let chartBand: Color
    let chartLine: Color
    let chartGrid: Color
    let overlayScrim: Color

    static func resolve(_ colorScheme: ColorScheme) -> HRVTheme {
        colorScheme == .dark ? .dark : .light
    }

    static let light = HRVTheme(
        surfaceBackground: HRVColor.neutral50,
        surfacePrimary: HRVColor.neutral0,
        surfaceSecondary: HRVColor.neutral100,
        surfaceElevated: HRVColor.neutral0,
        surfaceInverse: HRVColor.neutral900,
        textPrimary: HRVColor.neutral900,
        textSecondary: HRVColor.neutral600,
        textTertiary: HRVColor.neutral400,
        textInverse: HRVColor.neutral0,
        borderSubtle: HRVColor.neutral200,
        borderStrong: HRVColor.neutral400,
        accentPrimary: HRVColor.accent600,
        accentSoft: HRVColor.accent50,
        statusLearning: HRVColor.blue500,
        statusLearningSoft: HRVColor.blue300,
        statusStable: HRVColor.accent600,
        statusStableSoft: HRVColor.accent100,
        statusAttention: HRVColor.amber500,
        statusAttentionSoft: HRVColor.amber300,
        statusCritical: HRVColor.red500,
        statusCriticalSoft: HRVColor.red300,
        statusUnavailable: HRVColor.neutral600,
        chartBand: HRVColor.accent100,
        chartLine: HRVColor.accent700,
        chartGrid: HRVColor.neutral200,
        overlayScrim: HRVColor.neutral950.opacity(0.42)
    )

    static let dark = HRVTheme(
        surfaceBackground: HRVColor.neutral950,
        surfacePrimary: HRVColor.neutral900,
        surfaceSecondary: HRVColor.neutral800,
        surfaceElevated: HRVColor.neutral800,
        surfaceInverse: HRVColor.neutral50,
        textPrimary: HRVColor.neutral50,
        textSecondary: HRVColor.neutral400,
        textTertiary: HRVColor.neutral600,
        textInverse: HRVColor.neutral900,
        borderSubtle: HRVColor.neutral800,
        borderStrong: HRVColor.neutral600,
        accentPrimary: HRVColor.accent300,
        accentSoft: HRVColor.accent900,
        statusLearning: HRVColor.blue300,
        statusLearningSoft: HRVColor.neutral800,
        statusStable: HRVColor.accent300,
        statusStableSoft: HRVColor.accent900,
        statusAttention: HRVColor.amber300,
        statusAttentionSoft: HRVColor.neutral800,
        statusCritical: HRVColor.red300,
        statusCriticalSoft: HRVColor.neutral800,
        statusUnavailable: HRVColor.neutral400,
        chartBand: HRVColor.accent900,
        chartLine: HRVColor.accent300,
        chartGrid: HRVColor.neutral800,
        overlayScrim: HRVColor.neutral950.opacity(0.42)
    )
}

extension Color {
    init(hex: UInt32, opacity: Double = 1.0) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0,
            opacity: opacity
        )
    }
}
