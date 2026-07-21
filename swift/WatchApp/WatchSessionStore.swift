// Track E -- receive the phone's status mirror (WatchConnectivity).
// The phone owns HealthKit + detection; this store only caches the last
// application context so the watch UI can render it.
import Foundation
import Observation
import WatchConnectivity

@Observable
final class WatchSessionStore: NSObject, WCSessionDelegate {
    private(set) var state: String?
    private(set) var latestMs: Double?
    private(set) var rangeLoMs: Double?
    private(set) var rangeHiMs: Double?
    private(set) var updatedAt: Date?

    var hasData: Bool { state != nil }

    override init() {
        super.init()
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState,
                 error: Error?) {
        // Cold start: the last pushed context is already available locally.
        let ctx = session.receivedApplicationContext
        guard !ctx.isEmpty else { return }
        DispatchQueue.main.async { self.apply(ctx) }
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        DispatchQueue.main.async { self.apply(applicationContext) }
    }

    private func apply(_ ctx: [String: Any]) {
        state = ctx["state"] as? String
        latestMs = ctx["latestMs"] as? Double
        rangeLoMs = ctx["rangeLoMs"] as? Double
        rangeHiMs = ctx["rangeHiMs"] as? Double
        updatedAt = ctx["updatedAt"] as? Date
    }
}
