// Launch checklist #10 -- synthetic HRV samples for Demo Mode (a reviewer without
// an Apple Watch). Deterministic; mirrors sim/synthetic.py. Mac-only (uses HRVCore).
import Foundation
import HRVCore

enum DemoData {
    /// ~30 days: a healthy baseline with a short injected suppression event, so the
    /// reviewer sees Learning -> Stable and one Event in history.
    static func generate(days: Int = 30,
                         samplesPerDay: Int = 6,
                         baselineMs: Double = 45,
                         eventStartDay: Int = 24,
                         eventLenDays: Int = 4,
                         dropFraction: Double = 0.45) -> [HRVSample] {
        let wobble: [Double] = [-3, 0, 3, 1, -2, 2]   // small spread -> MAD > 0
        let start = Date().addingTimeInterval(-Double(days) * 86_400)
        var out: [HRVSample] = []
        var n = 0
        for d in 0..<days {
            for s in 0..<samplesPerDay {
                let ts = start.addingTimeInterval(Double(d) * 86_400 + Double(s) * 3 * 3_600)
                var v = baselineMs + wobble[n % wobble.count]
                if d >= eventStartDay && d < eventStartDay + eventLenDays {
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
