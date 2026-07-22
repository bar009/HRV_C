// Track J -- the beat stream that feeds the coherence session. Abstracted so
// the phone UI doesn't care whether beats come from a real watch workout
// session or the simulator used for development and screenshots.
import Foundation
import HRVCore

protocol HeartRateSource: AnyObject {
    /// Emits (secondsSinceStart, ibiMs). Called on an arbitrary queue; the
    /// session controller hops to the main actor.
    var onBeat: ((IBISample) -> Void)? { get set }
    func start()
    func stop()
}

/// Synthetic source: a coherent (clean ~0.1 Hz rhythm) or incoherent (noisy)
/// beat stream. Drives the UI and tests until a real watch is available.
final class SimulatedHeartRateSource: HeartRateSource {
    var onBeat: ((IBISample) -> Void)?
    var coherent: Bool

    private var timer: Timer?
    private var t: TimeInterval = 0
    private let hz = 4.0
    private var rngState: UInt64 = 0x2545F4914F6CDD1D

    init(coherent: Bool = true) { self.coherent = coherent }

    func start() {
        t = 0
        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / hz, repeats: true) { [weak self] _ in
            guard let self else { return }
            self.t += 1.0 / self.hz
            self.onBeat?(IBISample(t: self.t, ibiMs: self.nextIBI()))
        }
    }

    func stop() { timer?.invalidate(); timer = nil }

    private func nextIBI() -> Double {
        let base = 900.0
        if coherent {
            return base + 40 * sin(2 * Double.pi * 0.1 * t) + 1.5 * noise()
        } else {
            return base + 35 * noise()
        }
    }

    private func noise() -> Double {
        rngState ^= rngState >> 12; rngState ^= rngState << 25; rngState ^= rngState >> 27
        let v = (rngState &* 0x2545F4914F6CDD1D) >> 11
        return Double(v) / Double(1 << 53) * 2 - 1
    }
}

/// Real source: beats arrive from the watch's workout session over
/// WatchConnectivity (see WatchApp/WorkoutCoherenceController). The watch tells
/// the phone to start/stop the session out of band; here we just relay beats.
/// DEVICE-DEFERRED validation -- the watch half needs real hardware.
#if canImport(WatchConnectivity)
final class WatchWorkoutHeartRateSource: HeartRateSource {
    var onBeat: ((IBISample) -> Void)?
    private let sync: PhoneWatchSync

    init(sync: PhoneWatchSync = .shared) {
        self.sync = sync
        sync.onCoherenceBeat = { [weak self] t, ibiMs in
            self?.onBeat?(IBISample(t: t, ibiMs: ibiMs))
        }
    }

    // Tell the watch to start/stop its HKWorkoutSession; beats arrive via
    // the sync's onCoherenceBeat callback while it runs.
    func start() { sync.sendCoherenceCommand(start: true) }
    func stop() { sync.sendCoherenceCommand(start: false) }
}
#endif
