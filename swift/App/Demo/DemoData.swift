// Launch checklist #10 -- synthetic HRV samples for Demo Mode (a reviewer without
// an Apple Watch). Deterministic; mirrors sim/synthetic.py. Mac-only (uses HRVCore).
import Foundation
import HRVCore

enum DemoData {
    /// Samples plus the Track H context classifier that matches them, so Demo
    /// Mode exercises the same stratified pipeline as real HealthKit data.
    struct Batch {
        let samples: [HRVSample]
        let classifier: ContextClassifier
    }

    /// ~30 days ending *now*:
    /// - a healthy baseline (Learning -> Stable),
    /// - a deep "workout" dip on `workoutDay` that is tagged active and must
    ///   NOT fire an event (stratification demo),
    /// - one resolved suppression event (Events history, with a duration),
    /// - a suppression over the final slots so ingest ends on the alert tick --
    ///   the reviewer lands on the live Attention state and can walk the
    ///   Guided Moment + feedback flow.
    ///
    /// The last sample is timestamped `Date()` so it is always inside the
    /// coordinator's staleness window (otherwise Today shows "Unavailable").
    static func generate(days: Int = 30,
                         samplesPerDay: Int = 6,
                         baselineMs: Double = 45,
                         workoutDay: Int = 10,
                         eventStartDay: Int = 20,
                         eventLenDays: Int = 4,
                         liveEventSlots: Int = 3,
                         dropFraction: Double = 0.45) -> Batch {
        let wobble: [Double] = [-3, 0, 3, 1, -2, 2]   // small spread -> MAD > 0
        let slotInterval: TimeInterval = 3 * 3_600
        let now = Date()
        var out: [HRVSample] = []
        var workoutIntervals: [DateInterval] = []
        var n = 0
        for d in 0..<days {
            for s in 0..<samplesPerDay {
                // Walk backwards from `now` so the final slot lands exactly on it.
                let ts = now
                    .addingTimeInterval(-Double(days - 1 - d) * 86_400)
                    .addingTimeInterval(-Double(samplesPerDay - 1 - s) * slotInterval)
                var v = baselineMs + wobble[n % wobble.count]
                let inHistoricalEvent = d >= eventStartDay && d < eventStartDay + eventLenDays
                let inLiveEvent = d == days - 1 && s >= samplesPerDay - liveEventSlots
                // 3 consecutive suppressed slots would fire an alert
                // (persistenceWindow) if the classifier didn't exclude them.
                let inWorkout = d == workoutDay && (2...4).contains(s)
                if inHistoricalEvent || inLiveEvent || inWorkout {
                    v *= (1 - dropFraction)
                }
                if inWorkout {
                    workoutIntervals.append(DateInterval(start: ts.addingTimeInterval(-10 * 60),
                                                         end: ts.addingTimeInterval(10 * 60)))
                }
                out.append(HRVSample(timestamp: ts, valueMs: v, metric: .sdnnApple,
                                     quality: .high, source: .healthKitDirect))
                n += 1
            }
        }
        return Batch(samples: out, classifier: ContextClassifier(workouts: workoutIntervals))
    }
}
