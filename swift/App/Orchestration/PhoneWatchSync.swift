// Track E -- mirror the phone's presentation state to the watch app.
// The iPhone owns HealthKit + detection; the watch is a read-only status
// surface. A Workout Session for a dense beat stream (active/Coherence mode)
// still needs a physical watch and stays deferred (D-COH / Q-A).
#if canImport(WatchConnectivity)
import Foundation
import WatchConnectivity

final class PhoneWatchSync: NSObject, WCSessionDelegate {
    /// The newest snapshot; re-sent once activation completes, because the
    /// first refresh() usually runs before WCSession finishes activating.
    private var pendingContext: [String: Any]?

    override init() {
        super.init()
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
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
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) {
        // Re-activate after a watch switch, per Apple's guidance.
        session.activate()
    }
}
#endif
