// Movement classification for the continuous (strap) path.
//
// Why this exists: a Bluetooth strap gives no workouts and no sleep, so the
// context that keeps the Apple Watch path honest is simply absent. Without a
// movement signal, a live trigger cannot tell a stress drop from standing up.
//
// Behind a protocol on purpose. CoreMotion (the phone in your pocket) answers
// "is this person moving?" for every strap brand at no dependency cost. A
// Polar chest-accelerometer provider can be added later for *posture*
// specifically -- it needs Polar's proprietary PMD service via their SDK, so
// it is Polar-only and must not be the only way to get motion context.
import Foundation
import HRVCore

protocol MotionContextProviding: AnyObject {
    var onMotion: ((MotionState, Date) -> Void)? { get set }
    /// False when the source is unavailable or access was denied, so the app
    /// can say plainly that live triggers are ungated.
    var isAvailable: Bool { get }
    func start()
    func stop()
}

#if canImport(CoreMotion)
import CoreMotion

/// Uses the phone's own activity classifier. Works with every strap, needs no
/// third-party SDK, and costs almost nothing in battery (the coprocessor does
/// the work).
final class CoreMotionContextProvider: MotionContextProviding {
    var onMotion: ((MotionState, Date) -> Void)?

    private let manager = CMMotionActivityManager()
    private var running = false

    var isAvailable: Bool {
        CMMotionActivityManager.isActivityAvailable()
            && CMMotionActivityManager.authorizationStatus() != .denied
            && CMMotionActivityManager.authorizationStatus() != .restricted
    }

    func start() {
        guard CMMotionActivityManager.isActivityAvailable(), !running else { return }
        running = true
        manager.startActivityUpdates(to: .main) { [weak self] activity in
            guard let self, let activity else { return }
            self.onMotion?(Self.state(from: activity), activity.startDate)
        }
    }

    func stop() {
        guard running else { return }
        manager.stopActivityUpdates()
        running = false
    }

    /// Low-confidence readings are reported as `.unknown` rather than guessed:
    /// the gate treats unknown as restful, so a shaky classification never
    /// silently discards a user's data.
    static func state(from a: CMMotionActivity) -> MotionState {
        guard a.confidence != .low else { return .unknown }
        if a.running { return .running }
        if a.cycling { return .cycling }
        if a.automotive { return .automotive }
        if a.walking { return .walking }
        if a.stationary { return .stationary }
        return .unknown
    }
}
#endif

/// Test/simulator double: the pipeline can be driven without a device.
final class SimulatedMotionContextProvider: MotionContextProviding {
    var onMotion: ((MotionState, Date) -> Void)?
    var isAvailable: Bool = true
    private(set) var isRunning = false

    func start() { isRunning = true }
    func stop() { isRunning = false }

    /// Push a state from a test.
    func emit(_ state: MotionState, at time: Date = Date()) {
        guard isRunning else { return }
        onMotion?(state, time)
    }
}
