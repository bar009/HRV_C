// CoreBluetooth transport for the standard Heart Rate Service. Deliberately
// thin: all the risky logic (payload parsing, windowing, capability rules)
// lives in pure HRVCore code that is unit-tested without hardware, because
// CoreBluetooth does not work in the Simulator.
#if canImport(CoreBluetooth)
import Foundation
import CoreBluetooth
import HRVCore

final class BLEHeartRateProvider: NSObject, HeartRateProviding {
    // Bluetooth SIG assigned numbers.
    private static let heartRateService = CBUUID(string: "180D")
    private static let heartRateMeasurement = CBUUID(string: "2A37")
    private static let batteryService = CBUUID(string: "180F")
    private static let batteryLevel = CBUUID(string: "2A19")

    private static let pairedKey = "bleStrapPairedID"
    /// How long to wait for a single RR-bearing packet before concluding the
    /// device is heart-rate-only. The RR field is optional in the spec.
    private static let rrProbeSeconds: TimeInterval = 15

    var onMeasurement: ((HeartRateMeasurement, Date) -> Void)?
    var onState: ((ProviderState) -> Void)?
    var onDiscover: ((DiscoveredDevice) -> Void)?

    private(set) var state: ProviderState = .idle {
        didSet { if state != oldValue { onState?(state) } }
    }
    private(set) var batteryPercent: Int?

    var pairedDeviceID: UUID? {
        get { UserDefaults.standard.string(forKey: Self.pairedKey).flatMap(UUID.init(uuidString:)) }
        set {
            if let newValue { UserDefaults.standard.set(newValue.uuidString, forKey: Self.pairedKey) }
            else { UserDefaults.standard.removeObject(forKey: Self.pairedKey) }
        }
    }

    /// Starts pessimistic; upgraded to beat-to-beat the moment a packet
    /// actually carries RR intervals.
    private(set) var capabilities: SensorCapabilities = .none

    private var central: CBCentralManager!
    private var peripheral: CBPeripheral?
    private var sawRR = false
    private var probeTimer: Timer?

    override init() {
        super.init()
        // Main queue keeps @Observable consumers race-free; the notification
        // rate (a few per second) is nowhere near enough to matter.
        central = CBCentralManager(delegate: self, queue: .main, options: [
            CBCentralManagerOptionRestoreIdentifierKey: "hrvc.ble.central"
        ])
    }

    // MARK: HeartRateProviding

    func startScan() {
        guard central.state == .poweredOn else { return }
        state = .scanning
        central.scanForPeripherals(withServices: [Self.heartRateService], options: nil)
    }

    func stopScan() {
        central.stopScan()
        if case .scanning = state { state = .idle }
    }

    func connect(_ id: UUID) {
        guard let p = central.retrievePeripherals(withIdentifiers: [id]).first else { return }
        pairedDeviceID = id
        attach(p)
    }

    func disconnect() {
        if let p = peripheral { central.cancelPeripheralConnection(p) }
        peripheral = nil
        state = .disconnected
    }

    func forget() {
        disconnect()
        pairedDeviceID = nil
        capabilities = .none
        batteryPercent = nil
        state = .idle
    }

    // MARK: internals

    private func attach(_ p: CBPeripheral) {
        central.stopScan()
        peripheral = p
        p.delegate = self
        state = .connecting
        central.connect(p, options: nil)
    }

    /// Reconnect to the remembered strap after a relaunch or a range loss.
    private func reconnectPairedIfPossible() {
        guard peripheral == nil, let id = pairedDeviceID,
              let p = central.retrievePeripherals(withIdentifiers: [id]).first else { return }
        attach(p)
    }

    private func startRRProbe(name: String) {
        sawRR = false
        probeTimer?.invalidate()
        probeTimer = Timer.scheduledTimer(withTimeInterval: Self.rrProbeSeconds, repeats: false) { [weak self] _ in
            guard let self, !self.sawRR else { return }
            // Heart-rate-only device: every HRV feature must switch off, and
            // the user needs to be told rather than left staring at a blank.
            self.capabilities = .bleBpmOnly
            self.state = .noRRSupport(name: name)
        }
    }
}

// MARK: - CBCentralManagerDelegate

extension BLEHeartRateProvider: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            if case .idle = state { reconnectPairedIfPossible() }
            else if peripheral == nil { reconnectPairedIfPossible() }
        case .poweredOff:   state = .poweredOff
        case .unauthorized: state = .unauthorized
        case .unsupported:  state = .unsupported
        default:            break
        }
    }

    func centralManager(_ central: CBCentralManager, willRestoreState dict: [String: Any]) {
        if let restored = dict[CBCentralManagerRestoredStatePeripheralsKey] as? [CBPeripheral],
           let p = restored.first {
            peripheral = p
            p.delegate = self
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover p: CBPeripheral,
                        advertisementData: [String: Any], rssi RSSI: NSNumber) {
        let advertised = (advertisementData[CBAdvertisementDataLocalNameKey] as? String) ?? p.name
        let known = advertised.flatMap(KnownStraps.info(forAdvertisedName:))
        onDiscover?(DiscoveredDevice(id: p.identifier,
                                     displayName: known?.label ?? KnownStraps.displayName(for: advertised),
                                     rssi: RSSI.intValue,
                                     expectsRR: known?.expectsRR ?? false))
    }

    func centralManager(_ central: CBCentralManager, didConnect p: CBPeripheral) {
        p.discoverServices([Self.heartRateService, Self.batteryService])
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect p: CBPeripheral, error: Error?) {
        state = .disconnected
        peripheral = nil
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral p: CBPeripheral, error: Error?) {
        probeTimer?.invalidate(); probeTimer = nil
        peripheral = nil
        state = .disconnected
        // CoreBluetooth completes this whenever the strap comes back in range.
        if pairedDeviceID == p.identifier {
            peripheral = p
            p.delegate = self
            central.connect(p, options: nil)
        }
    }
}

// MARK: - CBPeripheralDelegate

extension BLEHeartRateProvider: CBPeripheralDelegate {
    func peripheral(_ p: CBPeripheral, didDiscoverServices error: Error?) {
        for service in p.services ?? [] {
            switch service.uuid {
            case Self.heartRateService: p.discoverCharacteristics([Self.heartRateMeasurement], for: service)
            case Self.batteryService:   p.discoverCharacteristics([Self.batteryLevel], for: service)
            default: break
            }
        }
    }

    func peripheral(_ p: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        for c in service.characteristics ?? [] {
            switch c.uuid {
            case Self.heartRateMeasurement:
                p.setNotifyValue(true, for: c)
                let name = KnownStraps.displayName(for: p.name)
                pairedDeviceID = p.identifier
                state = .connected(name: name)
                startRRProbe(name: name)
            case Self.batteryLevel:
                p.readValue(for: c)
            default: break
            }
        }
    }

    func peripheral(_ p: CBPeripheral, didUpdateValueFor c: CBCharacteristic, error: Error?) {
        guard error == nil, let data = c.value else { return }

        if c.uuid == Self.batteryLevel {
            batteryPercent = data.first.map(Int.init)
            return
        }

        guard c.uuid == Self.heartRateMeasurement,
              let m = HeartRateMeasurement.parse(data) else { return }

        if m.hasRR && !sawRR {
            sawRR = true
            probeTimer?.invalidate(); probeTimer = nil
            capabilities = .bleChestStrap
            state = .connected(name: KnownStraps.displayName(for: p.name))
        }
        onMeasurement?(m, Date())
    }
}
#endif
