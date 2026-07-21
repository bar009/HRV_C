// Track J -- stored summary of a completed coherence practice session.
// Local-only like everything else (checklist #5/#6); wiped by deleteAllData.
#if canImport(SwiftData)
import Foundation
import SwiftData

@Model final class CoherenceSession {
    @Attribute(.unique) var id: UUID
    var startedAt: Date
    var durationSec: Double
    var avgScore: Int
    var peakScore: Int
    var breathingPace: Double   // seconds per full breath cycle

    init(id: UUID = UUID(), startedAt: Date, durationSec: Double,
         avgScore: Int, peakScore: Int, breathingPace: Double) {
        self.id = id
        self.startedAt = startedAt
        self.durationSec = durationSec
        self.avgScore = avgScore
        self.peakScore = peakScore
        self.breathingPace = breathingPace
    }
}
#endif
