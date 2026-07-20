import SwiftUI
import HRVCore

/// The factual numbers behind the current state: latest SDNN and the personal
/// range. The pipeline works on ln(SDNN); values map back to ms with exp() so
/// they match what users see in Apple Health. Factual only -- no interpretation.
struct MeasuresRow: View {
    let latestMs: Double?
    let baseline: Baseline?
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let t = HRVTheme.resolve(scheme)
        HStack(spacing: 0) {
            cell(t, label: "מדידה אחרונה", value: latestText, unit: "ms")
            divider(t)
            cell(t, label: "טווח אישי", value: rangeText, unit: "ms")
            divider(t)
            cell(t, label: "חציון אישי", value: medianText, unit: "ms")
        }
        .padding(.vertical, HRVLayout.space16)
        .frame(maxWidth: .infinity)
        .background(t.surfacePrimary, in: RoundedRectangle(cornerRadius: HRVLayout.radius16, style: .continuous))
    }

    private var latestText: String {
        latestMs.map { String(Int($0.rounded())) } ?? "—"
    }
    private var rangeText: String {
        guard let b = baseline else { return "—" }
        return "\(Int(exp(b.lowerBound).rounded()))–\(Int(exp(b.upperBound).rounded()))"
    }
    private var medianText: String {
        guard let b = baseline else { return "—" }
        return String(Int(exp(b.median).rounded()))
    }

    private func cell(_ t: HRVTheme, label: String, value: String, unit: String) -> some View {
        VStack(spacing: HRVLayout.space4) {
            HStack(alignment: .firstTextBaseline, spacing: HRVLayout.space2) {
                Text(value)
                    .font(.hrvTitle3).fontWeight(.semibold)
                    .foregroundStyle(t.textPrimary)
                    .contentTransition(.numericText())
                    .animation(HRVMotion.standard, value: value)
                Text(unit)
                    .font(.hrvCaption)
                    .foregroundStyle(t.textTertiary)
            }
            // Numbers + Latin unit read left-to-right even inside the RTL shell.
            .environment(\.layoutDirection, .leftToRight)
            Text(label)
                .font(.hrvCaption)
                .foregroundStyle(t.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func divider(_ t: HRVTheme) -> some View {
        Rectangle()
            .fill(t.borderSubtle)
            .frame(width: HRVLayout.hairlineWidth, height: 32)
    }
}
