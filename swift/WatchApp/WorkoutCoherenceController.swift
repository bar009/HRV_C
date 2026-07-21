// Track J -- watch sensor role. During a coherence session the watch runs an
// HKWorkoutSession (the only way to get frequent heart-rate delivery on
// watchOS) and streams each HR sample to the phone, which owns the breathing
// UI and the coherence math.
//
// DEVICE-DEFERRED: HKWorkoutSession has no simulator support, so this compiles
// but is validated on real hardware (it also finally answers Q-A -- how dense
// the passive/active beat stream really is).
#if os(watchOS) && canImport(HealthKit)
import Foundation
import HealthKit
import WatchConnectivity

final class WorkoutCoherenceController: NSObject, ObservableObject {
    @Published private(set) var isRunning = false

    private let store = HKHealthStore()
    private var session: HKWorkoutSession?
    private var builder: HKLiveWorkoutBuilder?
    private var startDate = Date()

    /// Ask for the HR read auth the live session needs, then start a
    /// mind-and-body workout (low-impact, appropriate for a breathing session).
    func start() {
        let hrType = HKQuantityType(.heartRate)
        store.requestAuthorization(toShare: [], read: [hrType]) { [weak self] ok, _ in
            guard ok else { return }
            DispatchQueue.main.async { self?.beginWorkout() }
        }
    }

    private func beginWorkout() {
        let config = HKWorkoutConfiguration()
        config.activityType = .mindAndBody
        config.locationType = .indoor
        do {
            let session = try HKWorkoutSession(healthStore: store, configuration: config)
            let builder = session.associatedWorkoutBuilder()
            builder.dataSource = HKLiveWorkoutDataSource(healthStore: store, workoutConfiguration: config)
            session.delegate = self
            builder.delegate = self
            self.session = session
            self.builder = builder
            startDate = Date()
            session.startActivity(with: startDate)
            builder.beginCollection(withStart: startDate) { _, _ in }
            isRunning = true
        } catch {
            isRunning = false
        }
    }

    func stop() {
        session?.end()
        builder?.endCollection(withEnd: Date()) { [weak self] _, _ in
            self?.builder?.finishWorkout { _, _ in }
        }
        isRunning = false
    }

    /// Convert an instantaneous HR sample to an approximate IBI and stream it to
    /// the phone. WCSession.sendMessage is the low-latency path for a live loop.
    private func sendBeat(bpm: Double) {
        guard bpm > 0, WCSession.default.isReachable else { return }
        let ibiMs = 60_000.0 / bpm
        let t = Date().timeIntervalSince(startDate)
        WCSession.default.sendMessage(["coherenceBeat": ["t": t, "ibiMs": ibiMs]],
                                      replyHandler: nil, errorHandler: nil)
    }
}

extension WorkoutCoherenceController: HKWorkoutSessionDelegate {
    func workoutSession(_ workoutSession: HKWorkoutSession,
                        didChangeTo toState: HKWorkoutSessionState,
                        from fromState: HKWorkoutSessionState, date: Date) {}
    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        isRunning = false
    }
}

extension WorkoutCoherenceController: HKLiveWorkoutBuilderDelegate {
    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {}
    func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder,
                        didCollectDataOf collectedTypes: Set<HKSampleType>) {
        let hrType = HKQuantityType(.heartRate)
        guard collectedTypes.contains(hrType),
              let stats = workoutBuilder.statistics(for: hrType),
              let bpm = stats.mostRecentQuantity()?
                .doubleValue(for: HKUnit.count().unitDivided(by: .minute())) else { return }
        sendBeat(bpm: bpm)
    }
}
#endif
