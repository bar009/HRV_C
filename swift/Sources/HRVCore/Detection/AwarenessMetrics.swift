import Foundation

// Time-to-awareness (strategy memo — the headline progress metric: "פער הזמן
// בין תחילת הסטרס לבין הזיהוי", now measured in the body, not only self-report).
// Here it's the gap between when an event fired and when the user acknowledged
// it. Pure + value-typed so it's unit-testable independent of storage.

public enum AwarenessMetrics {
    /// Mean gap (seconds) over the acknowledged events. `nil` if there are none.
    public static func average(_ gaps: [TimeInterval]) -> TimeInterval? {
        let valid = gaps.filter { $0 >= 0 }
        guard !valid.isEmpty else { return nil }
        return valid.reduce(0, +) / Double(valid.count)
    }

    /// Whether the user is noticing sooner over time. Compares the mean of the
    /// most recent half against the older half (needs ≥4 points to judge);
    /// `nil` when there isn't enough history. `gaps` must be chronological
    /// (oldest first).
    public static func isImproving(chronological gaps: [TimeInterval]) -> Bool? {
        let valid = gaps.filter { $0 >= 0 }
        guard valid.count >= 4 else { return nil }
        let mid = valid.count / 2
        let older = valid[..<mid]
        let recent = valid[mid...]
        let olderMean = older.reduce(0, +) / Double(older.count)
        let recentMean = recent.reduce(0, +) / Double(recent.count)
        return recentMean < olderMean   // shorter gap = noticing sooner
    }
}
