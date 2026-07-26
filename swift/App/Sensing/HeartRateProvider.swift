// The generic Bluetooth heart-rate source. Deliberately vendor-neutral: RR
// delivery is a Bluetooth SIG standard (Heart Rate Service 0x180D), so any
// compliant strap works -- Polar H10/H9/Verity Sense, Garmin HRM-Pro/Dual,
// Wahoo TICKR, and unknown-but-compliant devices we have never seen.
import Foundation
import HRVCore

enum ProviderState: Equatable {
    case idle
    case scanning
    case connecting
    case connected(name: String)
    /// Connected, but the device never sends the optional RR-Interval field --
    /// heart rate only, so no HRV feature can work. Surfaced explicitly rather
    /// than leaving the user in a silently broken mode.
    case noRRSupport(name: String)
    case disconnected
    case unauthorized
    case poweredOff
    case unsupported

    var connectedName: String? {
        switch self {
        case .connected(let n), .noRRSupport(let n): return n
        default: return nil
        }
    }
    var isConnected: Bool { connectedName != nil }
}

struct DiscoveredDevice: Identifiable, Equatable {
    let id: UUID
    let displayName: String
    let rssi: Int
    /// From the known-device catalog: a hint for UI copy only, never a gate.
    let expectsRR: Bool
}

protocol HeartRateProviding: AnyObject {
    var onMeasurement: ((HeartRateMeasurement, Date) -> Void)? { get set }
    var onState: ((ProviderState) -> Void)? { get set }
    var onDiscover: ((DiscoveredDevice) -> Void)? { get set }
    var state: ProviderState { get }
    var capabilities: SensorCapabilities { get }
    var batteryPercent: Int? { get }
    var pairedDeviceID: UUID? { get }

    func startScan()
    func stopScan()
    func connect(_ id: UUID)
    func disconnect()
    /// Forget the remembered device so the app stops auto-reconnecting.
    func forget()
}

/// Friendly labels for straps we know about. Used ONLY to make the scan list
/// readable -- connection never depends on being in this list, because the
/// whole point of a standards-based provider is that unknown compliant devices
/// work automatically.
enum KnownStraps {
    struct Info {
        let label: String
        /// Whether this family is known to expose RR intervals.
        let expectsRR: Bool
    }

    private static let catalog: [(prefix: String, info: Info)] = [
        ("Polar H10",     Info(label: "Polar H10", expectsRR: true)),
        ("Polar H9",      Info(label: "Polar H9", expectsRR: true)),
        ("Polar Verity",  Info(label: "Polar Verity Sense", expectsRR: true)),
        ("Polar",         Info(label: "Polar", expectsRR: true)),
        ("HRM",           Info(label: "Garmin HRM", expectsRR: true)),
        ("TICKR",         Info(label: "Wahoo TICKR", expectsRR: true)),
        ("Wahoo",         Info(label: "Wahoo", expectsRR: true)),
        ("Movesense",     Info(label: "Movesense", expectsRR: true)),
        ("COOSPO",        Info(label: "Coospo", expectsRR: true)),
        ("Magene",        Info(label: "Magene", expectsRR: true)),
        ("Decathlon",     Info(label: "Decathlon", expectsRR: true)),
        ("Geonaute",      Info(label: "Decathlon", expectsRR: true)),
    ]

    static func info(forAdvertisedName name: String) -> Info? {
        let n = name.trimmingCharacters(in: .whitespaces)
        return catalog.first { n.localizedCaseInsensitiveContains($0.prefix) }?.info
    }

    static func displayName(for advertised: String?) -> String {
        guard let advertised, !advertised.isEmpty else { return "חיישן דופק" }
        return advertised
    }
}

/// Synthetic provider: lets the whole pipeline (windowing -> metrics ->
/// detection -> UI) run in the Simulator and in tests, where CoreBluetooth has
/// no hardware to talk to. `sendsRR: false` exercises the BPM-only path.
final class SimulatedHeartRateProvider: HeartRateProviding {
    var onMeasurement: ((HeartRateMeasurement, Date) -> Void)?
    var onState: ((ProviderState) -> Void)?
    var onDiscover: ((DiscoveredDevice) -> Void)?
    private(set) var state: ProviderState = .idle { didSet { onState?(state) } }
    var batteryPercent: Int? { 87 }
    private(set) var pairedDeviceID: UUID? = UUID()

    /// When false the device reports heart rate only -- the BPM-only strap case.
    var sendsRR: Bool
    /// Beats-per-minute base; RR wobbles around it at ~0.1 Hz when coherent.
    var coherent: Bool

    private var timer: Timer?
    private var t: TimeInterval = 0
    private let deviceName = "Simulated Strap"

    init(sendsRR: Bool = true, coherent: Bool = true) {
        self.sendsRR = sendsRR
        self.coherent = coherent
    }

    var capabilities: SensorCapabilities {
        sendsRR ? .simulated : .bleBpmOnly
    }

    func startScan() {
        state = .scanning
        onDiscover?(DiscoveredDevice(id: pairedDeviceID ?? UUID(),
                                     displayName: deviceName, rssi: -55, expectsRR: sendsRR))
    }

    func stopScan() { if case .scanning = state { state = .idle } }

    func connect(_ id: UUID) {
        pairedDeviceID = id
        state = .connecting
        state = sendsRR ? .connected(name: deviceName) : .noRRSupport(name: deviceName)
        t = 0
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    func disconnect() {
        timer?.invalidate(); timer = nil
        state = .disconnected
    }

    func forget() {
        disconnect()
        pairedDeviceID = nil
        state = .idle
    }

    private func tick() {
        t += 1
        // ~0.1 Hz respiratory wobble around a 900 ms interval, or flat noise.
        let ibi = coherent ? 900 + 40 * sin(2 * .pi * 0.1 * t) : 900 + Double.random(in: -12...12)
        let bpm = Int((60_000 / ibi).rounded())
        let m = HeartRateMeasurement(bpm: bpm, rrIntervalsMs: sendsRR ? [ibi] : [])
        onMeasurement?(m, Date())
    }
}
