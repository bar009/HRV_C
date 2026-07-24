// Track J -- stored summary of a completed coherence practice session.
// Local-only like everything else (checklist #5/#6); wiped by deleteAllData.
#if canImport(SwiftData)
import Foundation
import SwiftData

@Model final class CoherenceSession {
    @Attribute(.unique) var id: UUID
    var startedAt: Date
    var durationSec: Double
    /// % of readings that were in coherence (medium+high), 0-100 -- the honest,
    /// reachable session metric. `peakLevel` is the best 0-10 level reached.
    /// Defaulted so this is a lightweight additive migration over older rows.
    var coherencePct: Int = 0
    var peakLevel: Int = 0
    /// Legacy 0-100 avg/peak from the old scale; no longer written (kept for
    /// SwiftData migration compatibility with existing on-device rows).
    var avgScore: Int = 0
    var peakScore: Int = 0
    var breathingPace: Double   // seconds per full breath cycle

    init(id: UUID = UUID(), startedAt: Date, durationSec: Double,
         coherencePct: Int, peakLevel: Int, breathingPace: Double) {
        self.id = id
        self.startedAt = startedAt
        self.durationSec = durationSec
        self.coherencePct = coherencePct
        self.peakLevel = peakLevel
        self.breathingPace = breathingPace
    }
}
#endif
