// Track E -- mirror the phone's presentation state to the watch app.
// The iPhone owns HealthKit + detection; the watch is a read-only status
// surface. A Workout Session for a dense beat stream (active/Coherence mode)
// still needs a physical watch and stays deferred (D-COH / Q-A).
#if canImport(WatchConnectivity)
import Foundation
import WatchConnectivity

final class PhoneWatchSync: NSObject, WCSessionDelegate {
    /// One WCSession delegate per app, so both the status mirror
    /// (MonitoringCoordinator) and the coherence beat stream
    /// (WatchWorkoutHeartRateSource) share this single instance.
    static let shared = PhoneWatchSync()

    /// The newest snapshot; re-sent once activation completes, because the
    /// first refresh() usually runs before WCSession finishes activating.
    private var pendingContext: [String: Any]?

    /// Track J: live beats streamed from the watch's workout session during a
    /// coherence practice. Set by WatchWorkoutHeartRateSource.
    var onCoherenceBeat: ((TimeInterval, Double) -> Void)?

    override init() {
        super.init()
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    /// Tell the watch to start/stop its coherence workout session (which then
    /// streams beats back via `coherenceBeat`). `sendMessage` is the
    /// low-latency path; it needs the watch app reachable (it is during a
    /// live session).
    func sendCoherenceCommand(start: Bool) {
        let session = WCSession.default
        guard WCSession.isSupported(), session.activationState == .activated else { return }
        let msg = ["coherenceCommand": start ? "start" : "stop"]
        if session.isReachable {
            session.sendMessage(msg, replyHandler: nil, errorHandler: nil)
        } else {
            // Fall back to context so a briefly-unreachable watch still gets it.
            try? session.updateApplicationContext(msg)
        }
    }

    /// Push the latest UI state; `updateApplicationContext` keeps only the
    /// newest snapshot and delivers it when the watch wakes -- exactly the
    /// semantics a status mirror wants.
    func push(state: String, latestMs: Double?, rangeLoMs: Double?, rangeHiMs: Double?, updatedAt: Date?) {
        guard WCSession.isSupported() else { return }
        var ctx: [String: Any] = ["state": state]
        if let latestMs { ctx["latestMs"] = latestMs }
        if let rangeLoMs { ctx["rangeLoMs"] = rangeLoMs }
        if let rangeHiMs { ctx["rangeHiMs"] = rangeHiMs }
        if let updatedAt { ctx["updatedAt"] = updatedAt }
        pendingContext = ctx
        sendPendingIfActivated()
    }

    private func sendPendingIfActivated() {
        let session = WCSession.default
        guard session.activationState == .activated, let ctx = pendingContext else { return }
        try? session.updateApplicationContext(ctx)
    }

    // MARK: WCSessionDelegate (iOS side)
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState,
                 error: Error?) {
        DispatchQueue.main.async { self.sendPendingIfActivated() }
    }
    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        guard let beat = message["coherenceBeat"] as? [String: Any],
              let t = beat["t"] as? TimeInterval,
              let ibiMs = beat["ibiMs"] as? Double else { return }
        DispatchQueue.main.async { self.onCoherenceBeat?(t, ibiMs) }
    }

    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) {
        // Re-activate after a watch switch, per Apple's guidance.
        session.activate()
    }
}
#endif
