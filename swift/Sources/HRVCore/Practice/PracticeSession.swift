import Foundation

public enum PracticeSessionStatus: String, Codable, Sendable, Equatable {
    case ready
    case running
    case paused
    case completed
    case interrupted
    case uncomfortable
}

public enum LiveMetricKind: String, Codable, Sendable, Equatable {
    case heartRateBPM
    case trueRRMilliseconds
    case coherence
    case estimatedRhythm
}

public struct LiveMetric: Codable, Sendable, Equatable {
    public let kind: LiveMetricKind
    public let value: Double
    public let sensorMode: SensorMode

    public init?(kind: LiveMetricKind, value: Double, sensorMode: SensorMode) {
        if (kind == .trueRRMilliseconds || kind == .coherence) && sensorMode != .polarRR {
            return nil
        }
        if kind == .estimatedRhythm && sensorMode != .watchEstimatedRhythm {
            return nil
        }
        self.kind = kind
        self.value = value
        self.sensorMode = sensorMode
    }
}

public struct PracticeSessionState: Codable, Sendable, Equatable {
    public let id: UUID
    public let protocolID: String
    public let goal: PracticeGoal
    public private(set) var status: PracticeSessionStatus
    public private(set) var elapsedSeconds: Int
    public private(set) var paceScale: Double
    public private(set) var discomfortReason: String?

    public init(id: UUID = UUID(), protocolID: String, goal: PracticeGoal) {
        self.id = id
        self.protocolID = protocolID
        self.goal = goal
        self.status = .ready
        self.elapsedSeconds = 0
        self.paceScale = 1
    }

    public mutating func start() {
        guard status == .ready || status == .paused else { return }
        status = .running
    }

    public mutating func pause() {
        guard status == .running else { return }
        status = .paused
    }

    public mutating func tick(seconds: Int = 1) {
        guard status == .running, seconds > 0 else { return }
        elapsedSeconds += seconds
    }

    public mutating func slowDown() {
        guard status == .running || status == .paused else { return }
        paceScale = min(1.5, paceScale + 0.1)
    }

    public mutating func complete() {
        guard status == .running || status == .paused else { return }
        status = .completed
    }

    public mutating func interrupt() {
        guard status == .running || status == .paused else { return }
        status = .interrupted
    }

    public mutating func markUncomfortable(reason: String? = nil) {
        guard status == .running || status == .paused else { return }
        status = .uncomfortable
        discomfortReason = reason
    }
}
