// The calm pole (Track: two-pole model, from the strategy memo — "מיפוי שני
// הקטבים"). Alongside the arousal events the app detects, the user maps the
// SAFE pole: moments they feel calm, and their when / where / with whom. Purely
// user-logged (no sensor, no health data) — a wellness journal that builds a
// fuller picture of what steadies them. Local-only like everything else.
import Foundation

/// View-facing value type, so the UI never holds a SwiftData model directly.
struct CalmMomentSummary: Identifiable, Equatable {
    let id: UUID
    let createdAt: Date
    let place: String     // where (may be empty)
    let people: String    // with whom (may be empty)
    let note: String      // free text (may be empty)

    init(id: UUID = UUID(), createdAt: Date, place: String, people: String, note: String) {
        self.id = id; self.createdAt = createdAt
        self.place = place; self.people = people; self.note = note
    }
}

#if canImport(SwiftData)
import SwiftData

@Model final class CalmMoment {
    @Attribute(.unique) var id: UUID
    var createdAt: Date
    var place: String
    var people: String
    var note: String

    init(id: UUID = UUID(), createdAt: Date = Date(),
         place: String = "", people: String = "", note: String = "") {
        self.id = id; self.createdAt = createdAt
        self.place = place; self.people = people; self.note = note
    }
}

extension CalmMomentSummary {
    init(_ m: CalmMoment) {
        self.init(id: m.id, createdAt: m.createdAt, place: m.place, people: m.people, note: m.note)
    }
}
#endif
