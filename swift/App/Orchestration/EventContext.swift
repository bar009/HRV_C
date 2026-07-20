import Foundation

/// Facts that co-occurred with an event -- sleep, a recent workout, resting
/// heart rate -- each compared to the user's own usual value.
///
/// METHOD_PRODUCT_PRINCIPLES: the app "does not identify the pattern itself"
/// and records "only user-confirmed context". So this is deliberately NOT an
/// explanation: nothing here claims a cause, ranks likelihood, or picks a
/// reason. It is neutral co-occurring data, shown after the user's own
/// reflection, so *they* can recognise a pattern across events.
struct EventContext: Equatable {
    /// Hours slept the night before the event, and the personal usual.
    var sleepHours: Double?
    var usualSleepHours: Double?
    /// How long before the event the most recent workout ended.
    var hoursSinceWorkout: Double?
    /// Resting heart rate around the event, and the personal usual.
    var restingHeartRate: Double?
    var usualRestingHeartRate: Double?

    var isEmpty: Bool {
        sleepHours == nil && hoursSinceWorkout == nil && restingHeartRate == nil
    }

    /// A signal is worth calling out only when it is both present and
    /// meaningfully different from the person's own usual. Thresholds are
    /// intentionally loose -- this only affects emphasis, never detection.
    var sleepIsBelowUsual: Bool {
        guard let sleepHours, let usualSleepHours else { return false }
        return sleepHours < usualSleepHours - 1
    }

    var restingHeartRateIsAboveUsual: Bool {
        guard let restingHeartRate, let usualRestingHeartRate else { return false }
        return restingHeartRate > usualRestingHeartRate + 3
    }
}

/// Pure assembly of an EventContext -- no HealthKit, no SwiftData, so the
/// whole thing is unit-testable.
enum EventContextBuilder {
    /// Window used to decide a workout is "recent enough" to be worth showing.
    static let workoutLookback: TimeInterval = 12 * 3600
    /// "Last night" = sleep ending within this window before the event. A
    /// plain lookback is robust to the event firing at any time of day (a
    /// calendar-day window breaks for very-early-morning events).
    static let sleepLookback: TimeInterval = 20 * 3600

    static func build(eventDate: Date,
                      sleepIntervals: [DateInterval],
                      workoutIntervals: [DateInterval],
                      restingHeartRate: Double? = nil,
                      usualRestingHeartRate: Double? = nil,
                      calendar: Calendar = .current) -> EventContext {
        EventContext(
            sleepHours: sleepHours(before: eventDate, in: sleepIntervals, calendar: calendar),
            usualSleepHours: usualSleepHours(from: sleepIntervals, calendar: calendar),
            hoursSinceWorkout: hoursSinceWorkout(before: eventDate, in: workoutIntervals),
            restingHeartRate: restingHeartRate,
            usualRestingHeartRate: usualRestingHeartRate
        )
    }

    /// Total sleep in the night before the event. Sleep is stored as several
    /// fragments per night, so they are summed rather than taking the longest.
    static func sleepHours(before eventDate: Date,
                           in intervals: [DateInterval],
                           calendar: Calendar = .current) -> Double? {
        let windowStart = eventDate.addingTimeInterval(-sleepLookback)
        let relevant = intervals.filter { $0.end > windowStart && $0.end <= eventDate }
        guard !relevant.isEmpty else { return nil }
        return relevant.reduce(0) { $0 + $1.duration } / 3600
    }

    /// Median nightly total, so one wild night doesn't move "usual".
    static func usualSleepHours(from intervals: [DateInterval],
                                calendar: Calendar = .current) -> Double? {
        guard !intervals.isEmpty else { return nil }
        let byNight = Dictionary(grouping: intervals) { calendar.startOfDay(for: $0.end) }
        let nightlyTotals = byNight.values.map { night in
            night.reduce(0) { $0 + $1.duration } / 3600
        }
        guard nightlyTotals.count >= 2 else { return nil }
        return median(nightlyTotals)
    }

    /// Hours between the end of the most recent workout and the event, if one
    /// falls inside the lookback window.
    static func hoursSinceWorkout(before eventDate: Date,
                                  in intervals: [DateInterval]) -> Double? {
        let earlier = intervals
            .filter { $0.end <= eventDate && eventDate.timeIntervalSince($0.end) <= workoutLookback }
            .map(\.end)
        guard let mostRecent = earlier.max() else { return nil }
        return eventDate.timeIntervalSince(mostRecent) / 3600
    }

    static func median(_ values: [Double]) -> Double {
        let sorted = values.sorted()
        guard !sorted.isEmpty else { return 0 }
        let mid = sorted.count / 2
        return sorted.count % 2 == 0 ? (sorted[mid - 1] + sorted[mid]) / 2 : sorted[mid]
    }
}
