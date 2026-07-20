// Track H -- sample stratification (Deep Dive B.5). Foundation-only so it can
// be exercised from Demo Mode and future tests without HealthKit.
import Foundation
import HRVCore

/// Classifies a sample timestamp as active / sleep / rest from known intervals.
/// Built platform-side (HealthKit workouts + sleepAnalysis) and handed to
/// `MonitoringCoordinator.ingest` so the core pipeline stays platform-free.
struct ContextClassifier {
    /// HRV stays suppressed for a while after exertion; samples inside this
    /// buffer after a workout must not feed the baseline or fire alerts.
    static let postWorkoutRecovery: TimeInterval = 45 * 60

    /// Workouts as reported, without the recovery padding -- the padded copy
    /// is what gates samples; this is what we show the user.
    let workoutIntervals: [DateInterval]
    let sleepIntervals: [DateInterval]

    private let activeIntervals: [DateInterval]

    /// Workout intervals are extended by the recovery buffer at construction.
    init(workouts: [DateInterval] = [], sleep: [DateInterval] = []) {
        workoutIntervals = workouts
        activeIntervals = workouts.map {
            DateInterval(start: $0.start, end: $0.end.addingTimeInterval(Self.postWorkoutRecovery))
        }
        sleepIntervals = sleep
    }

    func context(at date: Date) -> SampleContext {
        SampleContext(isRestful: !isActive(at: date), isSleep: isSleep(at: date))
    }

    /// Storage label ("rest"/"sleep"/"active") -- restorePipelineState() drops
    /// "active" samples when rebuilding the baseline after a relaunch.
    func label(at date: Date) -> String {
        if isActive(at: date) { return "active" }
        if isSleep(at: date) { return "sleep" }
        return "rest"
    }

    private func isActive(at date: Date) -> Bool {
        activeIntervals.contains { $0.contains(date) }
    }
    private func isSleep(at date: Date) -> Bool {
        sleepIntervals.contains { $0.contains(date) }
    }
}
