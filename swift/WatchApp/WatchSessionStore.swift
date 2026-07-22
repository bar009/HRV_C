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
    /// True while a coherence workout session is running (Track J).
    private(set) var measuring = false

    var hasData: Bool { state != nil }

    #if canImport(HealthKit)
    private let workout = WorkoutCoherenceController()
    #endif

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

    // Track J: the phone starts/stops the coherence session; the watch runs the
    // workout that streams beats back.
    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        DispatchQueue.main.async { self.handle(message) }
    }

    private func handle(_ message: [String: Any]) {
        guard let command = message["coherenceCommand"] as? String else {
            apply(message); return
        }
        #if canImport(HealthKit)
        if command == "start" { workout.start(); measuring = true }
        else { workout.stop(); measuring = false }
        #endif
    }

    private func apply(_ ctx: [String: Any]) {
        // A command can also arrive via application context (fallback path).
        if let command = ctx["coherenceCommand"] as? String {
            #if canImport(HealthKit)
            if command == "start" { workout.start(); measuring = true }
            else { workout.stop(); measuring = false }
            #endif
            return
        }
        state = ctx["state"] as? String
        latestMs = ctx["latestMs"] as? Double
        rangeLoMs = ctx["rangeLoMs"] as? Double
        rangeHiMs = ctx["rangeHiMs"] as? Double
        updatedAt = ctx["updatedAt"] as? Date
    }
}
