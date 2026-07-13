import Foundation

// User-visible presentation state (PRODUCT_STATE_MODEL). Distinct from the
// internal detector state machine: Watching and Cooldown never surface here.

public enum HRVStatusKind: String, Codable, Equatable, Sendable {
    case setupRequired
    case learning
    case stable
    case attention
    case unavailable
}

public enum HRVUnavailableReason: String, Codable, Equatable, Sendable {
    case noRecentData
    case syncIssue
}

public enum HRVPresentationState: Equatable, Sendable {
    case setupRequired
    case learning(day: Int, totalDays: Int)
    case stable(lastUpdated: Date?)
    case attention(alertID: UUID?, lastUpdated: Date?)
    case unavailable(lastValidSample: Date?, reason: HRVUnavailableReason)

    public var kind: HRVStatusKind {
        switch self {
        case .setupRequired: return .setupRequired
        case .learning:      return .learning
        case .stable:        return .stable
        case .attention:     return .attention
        case .unavailable:   return .unavailable
        }
    }
}
