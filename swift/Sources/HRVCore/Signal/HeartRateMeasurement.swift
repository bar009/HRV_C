import Foundation

// Parser for the Bluetooth SIG *Heart Rate Measurement* characteristic
// (0x2A37, inside the Heart Rate Service 0x180D). This is a STANDARD, not a
// vendor format, so one parser serves every compliant strap -- Polar H10/H9/
// Verity Sense, Garmin HRM-Pro/Dual, Wahoo TICKR, and any other device that
// implements the profile.
//
// Layout (Bluetooth SIG, Heart Rate Service 1.0):
//   byte 0      flags
//                 bit 0  HR value format   0 = UInt8, 1 = UInt16
//                 bit 1-2 sensor contact   (ignored here)
//                 bit 3  energy expended present -> UInt16 field
//                 bit 4  RR-Interval(s) present  -> one or more UInt16
//   byte 1..     heart rate (1 or 2 bytes, little-endian)
//   [2 bytes]    energy expended, when bit 3 is set
//   [2n bytes]   RR intervals, little-endian, in units of 1/1024 second
//
// Pure + bounds-checked: it must never trap on a malformed packet from
// unknown hardware, so every read is length-guarded and bad input returns nil.

public struct HeartRateMeasurement: Sendable, Equatable {
    /// Beats per minute as reported by the device.
    public let bpm: Int
    /// Inter-beat intervals in milliseconds. Empty when the device does not
    /// send the optional RR field -- which is exactly the "BPM-only strap"
    /// case that makes every HRV feature impossible.
    public let rrIntervalsMs: [Double]

    public init(bpm: Int, rrIntervalsMs: [Double]) {
        self.bpm = bpm
        self.rrIntervalsMs = rrIntervalsMs
    }

    public var hasRR: Bool { !rrIntervalsMs.isEmpty }

    /// RR values arrive in 1/1024-second ticks.
    static let rrTickMs: Double = 1000.0 / 1024.0

    public static func parse(_ bytes: [UInt8]) -> HeartRateMeasurement? {
        guard let flags = bytes.first else { return nil }
        var i = 1

        let isWideHR = flags & 0x01 != 0
        let hasEnergy = flags & 0x08 != 0
        let hasRRField = flags & 0x10 != 0

        // Heart rate
        let bpm: Int
        if isWideHR {
            guard i + 1 < bytes.count else { return nil }
            bpm = Int(bytes[i]) | Int(bytes[i + 1]) << 8
            i += 2
        } else {
            guard i < bytes.count else { return nil }
            bpm = Int(bytes[i])
            i += 1
        }

        // Energy expended -- skipped, but the offset matters for the RR values
        // that follow, so a truncated field means we can't trust the rest.
        if hasEnergy {
            guard i + 1 < bytes.count else { return nil }
            i += 2
        }

        guard hasRRField else { return HeartRateMeasurement(bpm: bpm, rrIntervalsMs: []) }

        var rr: [Double] = []
        // A trailing odd byte is ignored rather than treated as a failure:
        // the intervals already read are still valid.
        while i + 1 < bytes.count {
            let raw = Int(bytes[i]) | Int(bytes[i + 1]) << 8
            rr.append(Double(raw) * rrTickMs)
            i += 2
        }
        return HeartRateMeasurement(bpm: bpm, rrIntervalsMs: rr)
    }

    /// Convenience for the CoreBluetooth call site, which hands over `Data`.
    public static func parse(_ data: Data) -> HeartRateMeasurement? { parse([UInt8](data)) }
}
