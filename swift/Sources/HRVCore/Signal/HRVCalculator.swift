import Foundation

/// Time-domain HRV metrics (Deep Dive A.3). Pure functions.
/// Port of hrv_core/signal/calculator.py -- the Python tests are the numeric oracle.
///
/// All inputs are NN (Normal-to-Normal) intervals in milliseconds that already
/// passed artifact rejection. Each function returns nil when there is not enough
/// data (mirrors Python's Optional return).
public enum HRVCalculator {

    static func successiveDiffs(_ nn: [Double]) -> [Double] {
        guard nn.count >= 2 else { return [] }
        return (0..<(nn.count - 1)).map { nn[$0 + 1] - nn[$0] }
    }

    /// Root mean square of successive differences -- the primary metric (A.3.1).
    public static func rmssd(_ nn: [Double]) -> Double? {
        guard nn.count >= 2 else { return nil }
        let diffs = successiveDiffs(nn)
        let meanSq = diffs.map { $0 * $0 }.reduce(0, +) / Double(diffs.count)
        return meanSq.squareRoot()
    }

    /// Sample standard deviation of NN intervals (A.3, divide by N-1).
    public static func sdnn(_ nn: [Double]) -> Double? {
        guard nn.count >= 2 else { return nil }
        let mean = nn.reduce(0, +) / Double(nn.count)
        let variance = nn.map { ($0 - mean) * ($0 - mean) }.reduce(0, +) / Double(nn.count - 1)
        return variance.squareRoot()
    }

    /// Percentage of successive differences greater than 50 ms (A.3).
    public static func pnn50(_ nn: [Double]) -> Double? {
        guard nn.count >= 2 else { return nil }
        let diffs = successiveDiffs(nn)
        let nn50 = diffs.filter { abs($0) > 50.0 }.count
        return (Double(nn50) / Double(diffs.count)) * 100.0
    }

    /// Standard deviation of successive differences (A.3).
    public static func sdsd(_ nn: [Double]) -> Double? {
        guard nn.count >= 3 else { return nil }
        let diffs = successiveDiffs(nn)
        let mean = diffs.reduce(0, +) / Double(diffs.count)
        let variance = diffs.map { ($0 - mean) * ($0 - mean) }.reduce(0, +) / Double(diffs.count - 1)
        return variance.squareRoot()
    }
}
