import SwiftUI

/// Time-range control for the Trends chart.
///
/// Four side-by-side segments cannot survive accessibility text sizes (the
/// labels overlap each other), so at those sizes this switches to a menu that
/// shows the current window and lists the rest — same control, readable shape.
struct RangeSelector: View {
    @Binding var selection: TrendRange
    @Environment(\.colorScheme) private var scheme
    @Environment(\.dynamicTypeSize) private var typeSize
    @Namespace private var pill

    var body: some View {
        if typeSize.isAccessibilitySize {
            menu
        } else {
            segmented
        }
    }

    // MARK: standard text sizes

    private var segmented: some View {
        let t = HRVTheme.resolve(scheme)
        return HStack(spacing: HRVLayout.space4) {
            ForEach(TrendRange.allCases) { range in
                let active = selection == range
                Button {
                    withAnimation(HRVMotion.standard) { selection = range }
                } label: {
                    Text(range.title)
                        .font(.hrvSubheadline)
                        .fontWeight(active ? .semibold : .regular)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .foregroundStyle(active ? t.textInverse : t.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, HRVLayout.space8)
                        .background {
                            if active {
                                Capsule()
                                    .fill(t.accentPrimary)
                                    .matchedGeometryEffect(id: "rangePill", in: pill)
                            }
                        }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(range.subtitle)
                .accessibilityAddTraits(active ? [.isSelected] : [])
            }
        }
        .padding(HRVLayout.space4)
        .background(t.surfaceSecondary, in: Capsule())
    }

    // MARK: accessibility text sizes

    private var menu: some View {
        let t = HRVTheme.resolve(scheme)
        return Menu {
            ForEach(TrendRange.allCases) { range in
                Button {
                    withAnimation(HRVMotion.standard) { selection = range }
                } label: {
                    if selection == range {
                        Label(range.title, systemImage: "checkmark")
                    } else {
                        Text(range.title)
                    }
                }
            }
        } label: {
            HStack(spacing: HRVLayout.space8) {
                Text(selection.title)
                    .font(.hrvSubheadline).fontWeight(.semibold)
                    .foregroundStyle(t.textPrimary)
                Image(systemName: "chevron.down")
                    .font(.hrvCaption)
                    .foregroundStyle(t.textSecondary)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, HRVLayout.space16)
            .padding(.vertical, HRVLayout.space12)
            .frame(maxWidth: .infinity, minHeight: HRVLayout.minimumTouchSize)
            .background(t.surfaceSecondary, in: RoundedRectangle(cornerRadius: HRVLayout.radius16, style: .continuous))
        }
        .accessibilityLabel("טווח זמן: \(selection.subtitle)")
    }
}
