import Foundation

public struct BLEHeartRateMeasurement: Sendable, Equatable {
    public let bpm: Int
    public let rrMilliseconds: [Double]

    public init(bpm: Int, rrMilliseconds: [Double]) {
        self.bpm = bpm
        self.rrMilliseconds = rrMilliseconds
    }
}

/// Parses Bluetooth SIG Heart Rate Measurement (0x2A37), including Polar H10
/// RR-interval fields. RR units are 1/1024 second.
public enum BLEHeartRateMeasurementParser {
    public static func parse(_ bytes: [UInt8]) -> BLEHeartRateMeasurement? {
        guard bytes.count >= 2 else { return nil }
        let flags = bytes[0]
        let isUInt16HeartRate = flags & 0x01 != 0
        let hasEnergyExpended = flags & 0x08 != 0
        let hasRR = flags & 0x10 != 0
        var index = 1

        let bpm: Int
        if isUInt16HeartRate {
            guard bytes.count >= index + 2 else { return nil }
            bpm = Int(UInt16(bytes[index]) | UInt16(bytes[index + 1]) << 8)
            index += 2
        } else {
            bpm = Int(bytes[index])
            index += 1
        }

        if hasEnergyExpended {
            guard bytes.count >= index + 2 else { return nil }
            index += 2
        }

        var intervals: [Double] = []
        if hasRR {
            while bytes.count >= index + 2 {
                let raw = UInt16(bytes[index]) | UInt16(bytes[index + 1]) << 8
                intervals.append(Double(raw) * 1000.0 / 1024.0)
                index += 2
            }
        }
        return BLEHeartRateMeasurement(bpm: bpm, rrMilliseconds: intervals)
    }
}
