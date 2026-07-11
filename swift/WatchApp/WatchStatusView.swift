// Track E -- minimal watch status surface (Mac-only).
// TODO(Track E): share state from the phone via WatchConnectivity / App Group,
// and add a Workout Session to source a dense beat stream for the active mode.
import SwiftUI

struct WatchStatusView: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "waveform.path.ecg")
                .font(.title)
                .foregroundStyle(.pink)
            Text("HRV")
                .font(.headline)
            Text("הניטור פעיל ברקע")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}
