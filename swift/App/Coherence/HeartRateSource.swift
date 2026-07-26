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

/// Watch workout samples are BPM, not RR. Keep them on a separate interface so
/// they cannot accidentally feed the true-RR coherence engine.
#if canImport(WatchConnectivity)
final class WatchEstimatedRhythmSource {
    var onHeartRate: ((TimeInterval, Double) -> Void)?
    private let sync: PhoneWatchSync

    init(sync: PhoneWatchSync) {
        self.sync = sync
        sync.onPracticeHeartRate = { [weak self] t, bpm in
            self?.onHeartRate?(t, bpm)
        }
    }
}
#endif
