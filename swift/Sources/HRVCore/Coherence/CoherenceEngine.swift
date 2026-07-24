import Foundation

// Track J -- HeartMath-style Coherence (docs/HRV_Research_HeartMath.md §2).
// The "pattern" axis, distinct from the passive "quantity" (SDNN/RMSSD) path:
// how ordered the rhythm is, not how much variance there is.
//
// Integrity note (track-J): this takes only HeartMath's documented MATH (the
// Coherence Ratio), never the metaphysical framing. Their exact score
// thresholds are proprietary, so the 0-100 mapping and bands here are OURS.

public enum CoherenceBand: String, Sendable, Equatable {
    case low, medium, high
}

/// One instantaneous beat sample: seconds since session start, and the
/// inter-beat interval in ms. Source-agnostic (simulated or real watch).
public struct IBISample: Sendable, Equatable {
    public let t: TimeInterval
    public let ibiMs: Double
    public init(t: TimeInterval, ibiMs: Double) { self.t = t; self.ibiMs = ibiMs }
}

public struct CoherenceResult: Sendable, Equatable {
    public let ratio: Double        // PeakPower / (TotalPower - PeakPower)
    public let peakHz: Double        // frequency of the LF peak
    public let level: Int            // 0-10 (our bounded, reachable mapping)
    public let band: CoherenceBand
}

/// Pure, value-typed. Feed it the samples accumulated in the current window;
/// it returns the coherence of that window (or nil if there isn't enough).
public enum CoherenceEngine {
    // HeartMath parameters (§2).
    public static let windowSeconds: Double = 64
    public static let resampleHz: Double = 4.0
    public static let bandLow: Double = 0.04     // LF search band
    public static let bandHigh: Double = 0.26
    public static let peakBandwidth: Double = 0.030   // integrated around the peak

    /// Coherence of one window of beat samples. Needs at least ~half a window
    /// of data spanning a usable duration; returns nil otherwise.
    public static func analyze(_ samples: [IBISample]) -> CoherenceResult? {
        guard samples.count >= 8,
              let first = samples.first?.t,
              let last = samples.last?.t,
              last - first >= windowSeconds / 2 else { return nil }

        let tachogram = resample(samples, from: first, to: last)
        guard tachogram.count >= 8 else { return nil }

        let detrended = removeMean(tachogram)
        let windowed = applyHanning(detrended)
        let spectrum = FFT.powerSpectrum(windowed)

        // Real signal -> use the first half of the spectrum. Bin k maps to
        // frequency k * fftHz / N, where fftHz is the resample rate.
        let n = spectrum.count
        let half = n / 2
        guard half > 1 else { return nil }
        let freqPerBin = resampleHz / Double(n)

        var peakPower = 0.0
        var peakBin = -1
        for k in 1..<half {
            let f = Double(k) * freqPerBin
            guard f >= bandLow && f <= bandHigh else { continue }
            if spectrum[k] > peakPower { peakPower = spectrum[k]; peakBin = k }
        }
        guard peakBin > 0 else { return nil }

        let peakHz = Double(peakBin) * freqPerBin
        // Integrate a 0.030 Hz-wide band around the peak.
        let halfBw = peakBandwidth / 2
        var peakBandPower = 0.0
        for k in 1..<half {
            let f = Double(k) * freqPerBin
            if abs(f - peakHz) <= halfBw { peakBandPower += spectrum[k] }
        }
        var totalPower = 0.0
        for k in 1..<half { totalPower += spectrum[k] }

        let denom = totalPower - peakBandPower
        let ratio = denom > 0 ? peakBandPower / denom : 0
        let level = level(forRatio: ratio)
        return CoherenceResult(ratio: ratio, peakHz: peakHz,
                               level: level, band: band(forLevel: level))
    }

    /// The Coherence Ratio at (and above) which we call the rhythm fully
    /// coherent -- i.e. where the 0-10 level saturates at 10. Unlike a 0-100
    /// score, 10 here is genuinely reachable. (Set against synthetic signals;
    /// real-data tuning is Q-B.)
    public static let excellentRatio: Double = 4.0

    /// Our own ratio -> 0-10 level. Linear against `excellentRatio`, capped, so
    /// the top of the scale is a real target rather than an asymptote.
    public static func level(forRatio ratio: Double) -> Int {
        guard ratio > 0 else { return 0 }
        let scaled = (ratio / excellentRatio * 10).rounded()
        return min(10, max(0, Int(scaled)))
    }

    public static func band(forLevel level: Int) -> CoherenceBand {
        switch level {
        case ...3:  return .low
        case 4...6: return .medium
        default:    return .high
        }
    }

    // MARK: - signal prep

    /// Linear-interpolate the (t, ibi) samples onto a uniform grid at resampleHz.
    static func resample(_ samples: [IBISample], from start: TimeInterval, to end: TimeInterval) -> [Double] {
        let step = 1.0 / resampleHz
        let sorted = samples.sorted { $0.t < $1.t }
        var out: [Double] = []
        var idx = 0
        var t = start
        while t <= end {
            // Advance to the segment [sorted[idx], sorted[idx+1]] containing t.
            while idx < sorted.count - 2 && sorted[idx + 1].t < t { idx += 1 }
            let a = sorted[idx]
            let b = sorted[min(idx + 1, sorted.count - 1)]
            if b.t == a.t {
                out.append(a.ibiMs)
            } else {
                let frac = max(0, min(1, (t - a.t) / (b.t - a.t)))
                out.append(a.ibiMs + frac * (b.ibiMs - a.ibiMs))
            }
            t += step
        }
        return out
    }

    static func removeMean(_ x: [Double]) -> [Double] {
        guard !x.isEmpty else { return x }
        let mean = x.reduce(0, +) / Double(x.count)
        return x.map { $0 - mean }
    }

    /// Hanning window reduces spectral leakage before the FFT.
    static func applyHanning(_ x: [Double]) -> [Double] {
        let n = x.count
        guard n > 1 else { return x }
        return x.enumerated().map { i, v in
            let w = 0.5 * (1 - cos(2 * Double.pi * Double(i) / Double(n - 1)))
            return v * w
        }
    }
}
