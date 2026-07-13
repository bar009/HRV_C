import Foundation

enum HRVStatusKind: String, Codable, Equatable, Sendable {
    case setupRequired
    case learning
    case stable
    case attention
    case unavailable
}

enum HRVUnavailableReason: String, Codable, Equatable, Sendable {
    case noRecentData
    case syncIssue
}

enum HRVPresentationState: Equatable, Sendable {
    case setupRequired
    case learning(day: Int, totalDays: Int)
    case stable(lastUpdated: Date?)
    case attention(alertID: UUID?, lastUpdated: Date?)
    case unavailable(lastValidSample: Date?, reason: HRVUnavailableReason)

    var kind: HRVStatusKind {
        switch self {
        case .setupRequired:
            return .setupRequired
        case .learning:
            return .learning
        case .stable:
            return .stable
        case .attention:
            return .attention
        case .unavailable:
            return .unavailable
        }
    }
}

// Mapping belongs in MonitoringCoordinator or a dedicated presentation mapper.
//
// Rules:
// - Detector Learning -> .learning
// - Detector Normal -> .stable
// - Detector Watching -> keep the last stable visual state
// - Detector Alert -> .attention
// - Detector Cooldown -> .stable while suppressing another notification
// - Missing/stale reliable sample -> .unavailable
// - HealthKit empty reads must not be described as a confirmed permission denial
//
// Keep user-facing copy outside HRVCore so the detector remains pure and testable.
