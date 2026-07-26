import Foundation

// Turns a continuous RR stream into overlapping analysis windows.
//
// A strap delivers RR intervals a few per second; the detection layer wants a
// stable statistic every so often. This buffers a rolling `windowSeconds` of
// intervals and emits the window every `stepSeconds`, which the app then runs
// through `RRExtractor.metrics(fromRR:)`.
//
// Pure and value-typed so the cadence logic is unit-testable without a sensor.

public struct RRWindower: Sendable {
    /// How much history each emitted window covers.
    public var windowSeconds: Double
    /// How often a window is emitted (overlapping when < windowSeconds).
    public var stepSeconds: Double
    /// Refuse to emit a window thinner than this -- too few beats makes RMSSD
    /// meaningless (the artefact corrector also has its own floor).
    public var minBeats: Int

    private var buffer: [(t: Date, rrMs: Double)] = []
    private var lastEmit: Date?

    public init(windowSeconds: Double = 120, stepSeconds: Double = 30, minBeats: Int = 60) {
        self.windowSeconds = windowSeconds
        self.stepSeconds = stepSeconds
        self.minBeats = minBeats
    }

    /// Beats currently held (for status UI).
    public var bufferedBeats: Int { buffer.count }

    /// Feed the intervals from one measurement notification. Returns a window
    /// of RR values when one is due, otherwise nil.
    public mutating func add(_ rrMs: [Double], at time: Date) -> [Double]? {
        for value in rrMs where value > 0 {
            buffer.append((t: time, rrMs: value))
        }
        // Keep only the rolling window.
        let cutoff = time.addingTimeInterval(-windowSeconds)
        buffer.removeAll { $0.t < cutoff }

        guard buffer.count >= minBeats else { return nil }
        if let last = lastEmit, time.timeIntervalSince(last) < stepSeconds { return nil }

        lastEmit = time
        return buffer.map(\.rrMs)
    }

    /// Drop all state -- used when the sensor disconnects, so a window can
    /// never straddle a gap in coverage.
    public mutating func reset() {
        buffer.removeAll()
        lastEmit = nil
    }
}
