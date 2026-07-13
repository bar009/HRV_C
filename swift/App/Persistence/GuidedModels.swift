// P2/P6 — SwiftData models for events + Guided Moment responses. Mac-only.
// GuidedResponse is stored SEPARATELY from detector truth (METHOD_PRODUCT_PRINCIPLES):
// the app records only what the user confirmed, never inferred interpretation.
#if canImport(SwiftData)
import Foundation
import SwiftData

/// A confirmed detector Alert surfaced as a user-visible event (P6 — Events screen).
@Model final class EventRecord {
    @Attribute(.unique) var id: UUID
    var firedAt: Date
    var robustZ: Double
    var rawValueMs: Double
    var reason: String
    var durationHours: Double?   // filled when the sustained change resolves
    var seen: Bool               // isNew == !seen

    init(id: UUID = UUID(), firedAt: Date, robustZ: Double, rawValueMs: Double,
         reason: String, durationHours: Double? = nil, seen: Bool = false) {
        self.id = id
        self.firedAt = firedAt
        self.robustZ = robustZ
        self.rawValueMs = rawValueMs
        self.reason = reason
        self.durationHours = durationHours
        self.seen = seen
    }
}

/// The user's Guided Moment answers (M3). One per event the user chose to reflect on.
@Model final class GuidedResponse {
    @Attribute(.unique) var id: UUID
    var eventID: UUID          // links to the EventRecord that triggered it
    var createdAt: Date
    var body: String
    var mind: String
    var context: String
    var supportChoice: String
    var ifThenPlan: String
    var relevance: String      // "timely" / "notRelevant" / "unsure"

    init(id: UUID = UUID(), eventID: UUID, createdAt: Date = .now,
         body: String = "", mind: String = "", context: String = "",
         supportChoice: String = "", ifThenPlan: String = "", relevance: String = "") {
        self.id = id
        self.eventID = eventID
        self.createdAt = createdAt
        self.body = body
        self.mind = mind
        self.context = context
        self.supportChoice = supportChoice
        self.ifThenPlan = ifThenPlan
        self.relevance = relevance
    }
}
#endif
