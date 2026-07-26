import Foundation

public enum TechniqueAccessTier: String, Codable, Sendable, CaseIterable {
    case recommended
    case manual
    case knowledgeOnly
}

public enum PracticeGoal: String, Codable, Sendable, CaseIterable {
    case quickReset
    case calming
    case coherence
    case grounding
    case focus
    case sleep
    case recovery
    case awareness
    case energizing
    case traditional
}

public enum SensorMode: String, Codable, Sendable, CaseIterable {
    case polarRR
    case watchEstimatedRhythm
    case noSensor
}

public struct LocalizedText: Codable, Sendable, Equatable {
    public let he: String
    public let en: String

    public init(he: String, en: String) {
        self.he = he
        self.en = en
    }
}

public struct BreathingTechnique: Identifiable, Codable, Sendable, Equatable {
    public let id: String
    public let catalogNumber: Int
    public let name: LocalizedText
    public let accessTier: TechniqueAccessTier
    public let goals: Set<PracticeGoal>
    public let hasRetention: Bool
    public let isRapid: Bool
    public let safetyNote: LocalizedText?

    public init(id: String, catalogNumber: Int, name: LocalizedText,
                accessTier: TechniqueAccessTier, goals: Set<PracticeGoal>,
                hasRetention: Bool = false, isRapid: Bool = false,
                safetyNote: LocalizedText? = nil) {
        self.id = id
        self.catalogNumber = catalogNumber
        self.name = name
        self.accessTier = accessTier
        self.goals = goals
        self.hasRetention = hasRetention
        self.isRapid = isRapid
        self.safetyNote = safetyNote
    }
}

public struct PracticeProtocol: Identifiable, Codable, Sendable, Equatable {
    public let id: String
    public let techniqueID: String
    public let name: LocalizedText
    public let goals: Set<PracticeGoal>
    public let durationSeconds: Int
    public let inhaleSeconds: Double?
    public let exhaleSeconds: Double?
    public let instructions: [LocalizedText]
    public let warning: LocalizedText?

    public init(id: String, techniqueID: String, name: LocalizedText,
                goals: Set<PracticeGoal>, durationSeconds: Int,
                inhaleSeconds: Double? = nil, exhaleSeconds: Double? = nil,
                instructions: [LocalizedText], warning: LocalizedText? = nil) {
        self.id = id
        self.techniqueID = techniqueID
        self.name = name
        self.goals = goals
        self.durationSeconds = durationSeconds
        self.inhaleSeconds = inhaleSeconds
        self.exhaleSeconds = exhaleSeconds
        self.instructions = instructions
        self.warning = warning
    }
}

public struct PracticeOutcome: Codable, Sendable, Equatable {
    public let protocolID: String
    public let goal: PracticeGoal
    public let completed: Bool
    public let comfortable: Bool?
    public let wouldChooseAgain: Bool?
    public let intensityBefore: Int?
    public let intensityAfter: Int?
    public let physiologicalTrend: Double?

    public init(protocolID: String, goal: PracticeGoal, completed: Bool,
                comfortable: Bool? = nil, wouldChooseAgain: Bool? = nil,
                intensityBefore: Int? = nil, intensityAfter: Int? = nil,
                physiologicalTrend: Double? = nil) {
        self.protocolID = protocolID
        self.goal = goal
        self.completed = completed
        self.comfortable = comfortable
        self.wouldChooseAgain = wouldChooseAgain
        self.intensityBefore = intensityBefore
        self.intensityAfter = intensityAfter
        self.physiologicalTrend = physiologicalTrend
    }
}

public struct RecommendationProfile: Codable, Sendable, Equatable {
    public var favoriteProtocolIDs: Set<String>
    public var hiddenTechniqueIDs: Set<String>
    public var temporarilyHiddenTechniqueIDs: Set<String>
    public var outcomes: [PracticeOutcome]

    public init(favoriteProtocolIDs: Set<String> = [],
                hiddenTechniqueIDs: Set<String> = [],
                temporarilyHiddenTechniqueIDs: Set<String> = [],
                outcomes: [PracticeOutcome] = []) {
        self.favoriteProtocolIDs = favoriteProtocolIDs
        self.hiddenTechniqueIDs = hiddenTechniqueIDs
        self.temporarilyHiddenTechniqueIDs = temporarilyHiddenTechniqueIDs
        self.outcomes = outcomes
    }
}

public struct PracticeRecommendation: Sendable, Equatable {
    public let protocolValue: PracticeProtocol
    public let reason: LocalizedText
    public let isExploration: Bool

    public init(protocolValue: PracticeProtocol, reason: LocalizedText,
                isExploration: Bool) {
        self.protocolValue = protocolValue
        self.reason = reason
        self.isExploration = isExploration
    }
}
