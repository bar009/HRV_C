import SwiftUI
import HRVCore

/// The primary status card on the Today screen. Factual only — never claims a
/// feeling or diagnosis; copy comes from PRODUCT_STATE_MODEL.
struct StatusCard: View {
    let kind: HRVStatusKind
    let eyebrow: String            // e.g. "מצב נוכחי"
    let title: String             // e.g. "יציב" / "זוהה שינוי מתמשך"
    var message: String? = nil    // optional factual explanation
    var timestamp: Date? = nil
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let t = HRVTheme.resolve(scheme)
        VStack(alignment: .leading, spacing: HRVLayout.space12) {
            HStack(alignment: .firstTextBaseline) {
                Text(eyebrow)
                    .font(.hrvSubheadline)
                    .foregroundStyle(t.textSecondary)
                Spacer()
                Image(systemName: kind.symbol)
                    .font(.hrvTitle3)
                    .foregroundStyle(kind.color(t))
            }
            Text(title)
                .font(.hrvTitle)
                .foregroundStyle(t.textPrimary)
            if let message {
                Text(message)
                    .font(.hrvCallout)
                    .foregroundStyle(t.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if let timestamp {
                Text(Self.updated(timestamp))
                    .font(.hrvSubheadline)
                    .foregroundStyle(t.textTertiary)
            }
        }
        .padding(HRVLayout.space20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(t.surfacePrimary, in: RoundedRectangle(cornerRadius: HRVLayout.radius20, style: .continuous))
    }

    private static let rel: RelativeDateTimeFormatter = {
        let f = RelativeDateTimeFormatter()
        f.locale = Locale(identifier: "he")
        f.unitsStyle = .full
        return f
    }()
    static func updated(_ date: Date) -> String {
        // A just-arrived sample would otherwise render as "in 0 seconds".
        if abs(date.timeIntervalSinceNow) < 60 { return "עודכן עכשיו" }
        return "עודכן " + rel.localizedString(for: date, relativeTo: Date())
    }
}
