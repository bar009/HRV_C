import Foundation
@testable import HRVCore

// 2026-01-01T00:00:00Z. Matches the Python tests' datetime(2026,1,1) under the
// BaselineEngine's UTC day-index bucketing (this epoch is an exact multiple of 86400).
let epoch2026 = Date(timeIntervalSince1970: 1_767_225_600)

/// A timestamp `d` days (and optional `hours`) after 2026-01-01T00:00:00Z.
func day(_ d: Int, hours h: Double = 0) -> Date {
    epoch2026.addingTimeInterval(Double(d) * 86_400 + h * 3_600)
}
