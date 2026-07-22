// Track E -- live watch status mirrored from the phone (WatchConnectivity).
// Read-only surface: detection stays on the iPhone. The Workout Session for a
// dense beat stream (active/Coherence mode) needs a physical watch -- deferred.
import SwiftUI

struct WatchStatusView: View {
    @State private var store = WatchSessionStore()

    var body: some View {
        Group {
            if store.measuring {
                measuring
            } else if store.hasData {
                statusBody
            } else {
                waiting
            }
        }
        .environment(\.layoutDirection, .rightToLeft)
    }

    // Track J: a coherence session is running on the phone; the watch is the
    // sensor. Minimal on purpose — the full breathing UI is on the phone.
    private var measuring: some View {
        VStack(spacing: 8) {
            Image(systemName: "heart.fill")
                .font(.title2)
                .foregroundStyle(.pink)
                .symbolEffect(.pulse)
            Text("מודד קוהרנטיות…")
                .font(.caption)
                .multilineTextAlignment(.center)
            Text("המשך בטלפון")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding()
    }

    private var waiting: some View {
        VStack(spacing: 8) {
            Image(systemName: "iphone.radiowaves.left.and.right")
                .font(.title2)
                .foregroundStyle(.secondary)
            Text("ממתין לנתונים מהאייפון")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    private var statusBody: some View {
        VStack(alignment: .trailing, spacing: 6) {
            HStack(spacing: 6) {
                Circle().fill(statusColor).frame(width: 8, height: 8)
                Text(statusTitle)
                    .font(.headline)
                    .minimumScaleFactor(0.7)
            }
            if let v = store.latestMs {
                HStack(alignment: .firstTextBaseline, spacing: 3) {
                    Text("\(Int(v.rounded()))")
                        .font(.system(.title2, design: .rounded).weight(.semibold))
                    Text("ms")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .environment(\.layoutDirection, .leftToRight)
            }
            if let lo = store.rangeLoMs, let hi = store.rangeHiMs {
                // LRI/PDI isolate keeps the numeric range reading 39-51 inside
                // the Hebrew sentence instead of being bidi-flipped.
                Text("טווח אישי: \u{2066}\(Int(lo.rounded()))–\(Int(hi.rounded())) ms\u{2069}")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            if let at = store.updatedAt {
                Text(at, style: .relative)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding()
    }

    private var statusTitle: String {
        switch store.state {
        case "attention":     "זוהה שינוי מתמשך"
        case "learning":      "לומדים את הטווח"
        case "unavailable":   "ממתינים למדידה"
        case "setupRequired": "נדרשת הגדרה באייפון"
        default:              "בטווח האישי שלך"
        }
    }

    private var statusColor: Color {
        switch store.state {
        case "attention":   .orange
        case "stable":      .green
        default:            .gray
        }
    }
}
