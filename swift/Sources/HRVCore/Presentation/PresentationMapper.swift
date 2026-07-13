import Foundation

/// Inputs the mapper needs to decide the user-visible state. Pure value type.
public struct PresentationInput: Sendable {
    public var detectorState: DetectorState
    public var hasCompletedSetup: Bool        // Health authorized + at least one sample ever
    public var hasReliableRecentSample: Bool  // last reliable sample within the staleness window
    public var learningDay: Int
    public var learningTotalDays: Int
    public var lastUpdated: Date?
    public var lastValidSample: Date?
    public var alertID: UUID?
    public var unavailableReason: HRVUnavailableReason

    public init(detectorState: DetectorState,
                hasCompletedSetup: Bool,
                hasReliableRecentSample: Bool,
                learningDay: Int = 0,
                learningTotalDays: Int = 7,
                lastUpdated: Date? = nil,
                lastValidSample: Date? = nil,
                alertID: UUID? = nil,
                unavailableReason: HRVUnavailableReason = .noRecentData) {
        self.detectorState = detectorState
        self.hasCompletedSetup = hasCompletedSetup
        self.hasReliableRecentSample = hasReliableRecentSample
        self.learningDay = learningDay
        self.learningTotalDays = learningTotalDays
        self.lastUpdated = lastUpdated
        self.lastValidSample = lastValidSample
        self.alertID = alertID
        self.unavailableReason = unavailableReason
    }
}

/// Pure detector -> presentation mapping (PRODUCT_STATE_MODEL / AGENTS.md).
/// The single connection point between the compute pipeline and the UI.
public enum PresentationMapper {
    public static func map(_ input: PresentationInput) -> HRVPresentationState {
        // Precedence: setup gate, then data availability, then the detector state.
        guard input.hasCompletedSetup else { return .setupRequired }
        guard input.hasReliableRecentSample else {
            return .unavailable(lastValidSample: input.lastValidSample, reason: input.unavailableReason)
        }
        switch input.detectorState {
        case .learning:
            return .learning(day: input.learningDay, totalDays: input.learningTotalDays)
        case .normal, .watching, .cooldown:
            // Watching (verifying persistence) and Cooldown (suppressing repeats)
            // are internal — they must render as Stable.
            return .stable(lastUpdated: input.lastUpdated)
        case .alert:
            return .attention(alertID: input.alertID, lastUpdated: input.lastUpdated)
        }
    }
}
