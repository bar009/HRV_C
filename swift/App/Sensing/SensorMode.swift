import Foundation
import HRVCore

/// Which sensor the app is currently driven by. Explicit and user-chosen -- the
/// app never switches on its own, so the user always knows which indicators
/// they should expect (see HealthIndicator / IndicatorResolver).
enum SensorMode: String, CaseIterable, Sendable {
    /// Passive Apple Health: sparse resting SDNN plus sleep/workout/resting-HR
    /// context. No live triggers.
    case appleWatch
    /// A Bluetooth heart-rate strap streaming beat-to-beat RR continuously.
    case bleStrap

    /// Baseline capabilities of the mode itself, before a specific device is
    /// connected (the connected provider can downgrade this -- e.g. a strap
    /// that turns out to be heart-rate-only).
    var baseCapabilities: SensorCapabilities {
        switch self {
        case .appleWatch: return .appleWatchPassive
        case .bleStrap:   return .bleChestStrap
        }
    }

    static let storageKey = "sensorMode"

    static var current: SensorMode {
        get { SensorMode(rawValue: UserDefaults.standard.string(forKey: storageKey) ?? "") ?? .appleWatch }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: storageKey) }
    }
}
