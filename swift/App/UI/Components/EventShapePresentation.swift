import Foundation
import HRVCore

/// Factual Hebrew phrasing for an event's drop shape. Describes the measurement
/// pattern only (how sharp/deep vs. gradual) — never an emotion or a cause, to
/// stay on the right side of the Wellness (non-diagnostic) line.
extension EventRecord {
    var shape: EventShape { EventShapeClassifier.classify(robustZ: robustZ) }
}

enum EventShapePresentation {
    static func label(_ s: EventShape) -> String {
        switch s {
        case .acute:     return "שינוי חד"
        case .sustained: return "שינוי מתמשך ומתון"
        }
    }

    static func description(_ s: EventShape) -> String {
        switch s {
        case .acute:
            return "ירידה חדה ומהירה יחסית, מתחת לטווח האישי שלך."
        case .sustained:
            return "ירידה מתונה שנמשכה לאורך זמן — קלה יותר לפספס."
        }
    }
}
