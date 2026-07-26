#if canImport(SwiftData)
import Foundation
import SwiftData

@Model final class PracticeSessionRecord {
    @Attribute(.unique) var id: UUID
    var protocolID: String
    var techniqueID: String
    var goal: String
    var startedAt: Date
    var durationSeconds: Int
    var status: String
    var sensorMode: String
    var intensityBefore: Int?
    var intensityAfter: Int?
    var comfortable: Bool?
    var wouldChooseAgain: Bool?
    var bodyNote: String
    var mindNote: String
    var contextNote: String
    var triggerNote: String

    init(id: UUID = UUID(), protocolID: String, techniqueID: String,
         goal: String, startedAt: Date = .now, durationSeconds: Int = 0,
         status: String, sensorMode: String, intensityBefore: Int? = nil,
         intensityAfter: Int? = nil, comfortable: Bool? = nil,
         wouldChooseAgain: Bool? = nil, bodyNote: String = "",
         mindNote: String = "", contextNote: String = "", triggerNote: String = "") {
        self.id = id
        self.protocolID = protocolID
        self.techniqueID = techniqueID
        self.goal = goal
        self.startedAt = startedAt
        self.durationSeconds = durationSeconds
        self.status = status
        self.sensorMode = sensorMode
        self.intensityBefore = intensityBefore
        self.intensityAfter = intensityAfter
        self.comfortable = comfortable
        self.wouldChooseAgain = wouldChooseAgain
        self.bodyNote = bodyNote
        self.mindNote = mindNote
        self.contextNote = contextNote
        self.triggerNote = triggerNote
    }
}

@Model final class PracticePreferenceRecord {
    @Attribute(.unique) var key: String
    var value: String

    init(key: String, value: String) {
        self.key = key
        self.value = value
    }
}
#endif
