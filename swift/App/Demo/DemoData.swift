// Launch checklist #10 -- synthetic HRV samples for Demo Mode (a reviewer without
// an Apple Watch). Deterministic; mirrors sim/synthetic.py. Mac-only (uses HRVCore).
import Foundation
import HRVCore

enum DemoData {
    /// ~30 days ending *now*: a healthy baseline, one resolved suppression event
    /// (Events history), and a suppression over the final slots so ingest ends on
    /// the alert tick -- the reviewer lands on the live Attention state and can
    /// walk the Guided Moment + feedback flow.
    ///
    /// The last sample is timestamped `Date()` so it is always inside the
    /// coordinator's staleness window (otherwise Today shows "Unavailable").
    static func generate(days: Int = 30,
                         samplesPerDay: Int = 6,
                         baselineMs: Double = 45,
                         eventStartDay: Int = 20,
                         eventLenDays: Int = 4,
                         liveEventSlots: Int = 3,
                         dropFraction: Double = 0.45) -> [HRVSample] {
        let wobble: [Double] = [-3, 0, 3, 1, -2, 2]   // small spread -> MAD > 0
        let slotInterval: TimeInterval = 3 * 3_600
        let now = Date()
        var out: [HRVSample] = []
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
                if inHistoricalEvent || inLiveEvent {
                    v *= (1 - dropFraction)
                }
                out.append(HRVSample(timestamp: ts, valueMs: v, metric: .sdnnApple,
                                     quality: .high, source: .healthKitDirect))
                n += 1
            }
        }
        return out
    }
}
