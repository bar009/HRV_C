import Foundation

/// Robust statistics used by the baseline (Deep Dive B.3). Swift has no stdlib
/// median, so it is implemented here to match Python's statistics.median.
public enum Statistics {

    /// Median of `values` (average of the two middle values for even counts).
    public static func median(_ values: [Double]) -> Double {
        precondition(!values.isEmpty, "median of empty array")
        let sorted = values.sorted()
        let n = sorted.count
        if n % 2 == 1 { return sorted[n / 2] }
        return (sorted[n / 2 - 1] + sorted[n / 2]) / 2.0
    }

    /// Median Absolute Deviation. Returns 0 for an empty input (matches Python).
    public static func mad(_ values: [Double], center: Double? = nil) -> Double {
        guard !values.isEmpty else { return 0.0 }
        let med = center ?? median(values)
        return median(values.map { abs($0 - med) })
    }
}
