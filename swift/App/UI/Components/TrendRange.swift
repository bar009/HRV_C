import Foundation
import HRVCore

/// The time window the Trends chart is showing. Owns every range-dependent
/// decision (label, cutoff, axis stride, aggregation) so the chart body stays
/// readable and the behaviour is unit-testable without a view.
enum TrendRange: String, CaseIterable, Identifiable {
    case day, week, month, all

    var id: String { rawValue }

    /// Short by design -- four segments must survive accessibility text sizes.
    var title: String {
        switch self {
        case .day:   "יום"
        case .week:  "שבוע"
        case .month: "חודש"
        case .all:   "הכול"
        }
    }

    var subtitle: String {
        switch self {
        case .day:   "24 השעות האחרונות"
        case .week:  "7 הימים האחרונים"
        case .month: "30 הימים האחרונים"
        case .all:   "כל ההיסטוריה"
        }
    }

    /// Start of the window. `all` reaches back past any stored sample.
    func cutoff(from now: Date = Date()) -> Date {
        switch self {
        case .day:   now.addingTimeInterval(-86_400)
        case .week:  now.addingTimeInterval(-7 * 86_400)
        case .month: now.addingTimeInterval(-30 * 86_400)
        case .all:   .distantPast
        }
    }

    /// A single day holds only a handful of passive samples; aggregating them
    /// to a daily median would collapse the whole chart to one point.
    var isIntraday: Bool { self == .day }

    var emptyMessage: String {
        switch self {
        case .day: "אין מדידות היום"
        default:   "אין עדיין נתונים"
        }
    }
}

/// One plotted point. Intraday points keep their real timestamp; the longer
/// ranges carry the day's median.
struct TrendPoint: Identifiable, Equatable {
    let date: Date
    let valueMs: Double
    var id: Date { date }
}

/// Pure series construction -- kept out of the view so it can be tested.
enum TrendSeries {
    static func points(for samples: [ProcessedHRVSample], range: TrendRange) -> [TrendPoint] {
        range.isIntraday ? intraday(samples) : dailyMedians(samples)
    }

    /// Raw samples in time order.
    static func intraday(_ samples: [ProcessedHRVSample]) -> [TrendPoint] {
        samples
            .sorted { $0.timestamp < $1.timestamp }
            .map { TrendPoint(date: $0.timestamp, valueMs: $0.rawValueMs) }
    }

    /// One point per calendar day (median of that day's samples, in ms) --
    /// raw samples over weeks plot as unreadable noise.
    static func dailyMedians(_ samples: [ProcessedHRVSample],
                             calendar: Calendar = .current) -> [TrendPoint] {
        Dictionary(grouping: samples) { calendar.startOfDay(for: $0.timestamp) }
            .map { day, group in
                TrendPoint(date: day, valueMs: median(group.map(\.rawValueMs)))
            }
            .sorted { $0.date < $1.date }
    }

    static func median(_ values: [Double]) -> Double {
        let sorted = values.sorted()
        guard !sorted.isEmpty else { return 0 }
        let mid = sorted.count / 2
        return sorted.count % 2 == 0 ? (sorted[mid - 1] + sorted[mid]) / 2 : sorted[mid]
    }
}
