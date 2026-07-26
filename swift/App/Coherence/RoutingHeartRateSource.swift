// Routes the coherence session's beat stream to whichever sensor the current
// mode selects. Existing separately from CoherenceSessionController because
// that type takes its source once, as an immutable `let`; a routing layer lets
// the user switch modes without rebuilding the session controller.
import Foundation
import HRVCore

/// Beats fed from a connected strap. `StrapMonitor` pushes into it; the
/// coherence session pulls out of it via the routing source.
final class StrapHeartRateSource: HeartRateSource {
    var onBeat: ((IBISample) -> Void)?
    private var startedAt: Date?

    func start() { startedAt = Date() }
    func stop() { startedAt = nil }

    /// Called by the app layer for every RR interval the strap reports.
    func ingest(ibiMs: Double, at time: Date = Date()) {
        guard let startedAt else { return }   // only during an active session
        onBeat?(IBISample(t: time.timeIntervalSince(startedAt), ibiMs: ibiMs))
    }
}

/// Forwards beats from exactly one underlying source at a time.
final class RoutingHeartRateSource: HeartRateSource {
    var onBeat: ((IBISample) -> Void)?

    /// Which source to use. Read at `start()`, so switching mode mid-session
    /// cannot swap the stream underneath a running measurement.
    var activeSourceProvider: () -> HeartRateSource

    private var running: HeartRateSource?

    init(activeSourceProvider: @escaping () -> HeartRateSource) {
        self.activeSourceProvider = activeSourceProvider
    }

    func start() {
        let source = activeSourceProvider()
        source.onBeat = { [weak self] sample in self?.onBeat?(sample) }
        running = source
        source.start()
    }

    func stop() {
        running?.stop()
        running?.onBeat = nil
        running = nil
    }
}
