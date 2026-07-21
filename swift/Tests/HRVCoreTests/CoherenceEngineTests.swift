import XCTest
@testable import HRVCore

// Track J -- coherence pipeline. Synthetic signals give deterministic expectations
// (like the Python oracle for the rest of the core).
final class CoherenceEngineTests: XCTestCase {

    /// Build 64s of beat samples whose IBI follows a sine at `freqHz`, plus
    /// optional white noise. `coherent` amplitude is a clean rhythm.
    private func samples(freqHz: Double, amp: Double, noise: Double,
                         seconds: Double = 64, hz: Double = 4) -> [IBISample] {
        var rng = SeededRNG(seed: 42)
        let baseIBI = 900.0   // ~67 bpm
        let step = 1.0 / hz
        var out: [IBISample] = []
        var t = 0.0
        while t <= seconds {
            let s = amp * sin(2 * Double.pi * freqHz * t)
            let n = noise * (rng.nextUnit() * 2 - 1)
            out.append(IBISample(t: t, ibiMs: baseIBI + s + n))
            t += step
        }
        return out
    }

    func testCoherentBreathingScoresHigh() {
        // 0.1 Hz = 10s breathing cycle, clean.
        let result = CoherenceEngine.analyze(samples(freqHz: 0.1, amp: 40, noise: 1))
        let r = try? XCTUnwrap(result)
        XCTAssertNotNil(r)
        XCTAssertGreaterThan(r?.score ?? 0, 70, "a clean 0.1 Hz rhythm should read as high coherence")
        XCTAssertEqual(r?.band, .high)
        XCTAssertEqual(r?.peakHz ?? 0, 0.1, accuracy: 0.02, "peak should sit at the breathing rate")
    }

    func testNoiseScoresLow() {
        let result = CoherenceEngine.analyze(samples(freqHz: 0.1, amp: 0, noise: 40))
        let r = try? XCTUnwrap(result)
        XCTAssertNotNil(r)
        XCTAssertLessThan(r?.score ?? 100, 40, "unstructured noise should read as low coherence")
        XCTAssertEqual(r?.band, .low)
    }

    func testPeakIsFoundAtTheDrivingFrequency() {
        let result = CoherenceEngine.analyze(samples(freqHz: 0.15, amp: 40, noise: 2))
        XCTAssertEqual(result?.peakHz ?? 0, 0.15, accuracy: 0.02)
    }

    func testTooFewSamplesReturnsNil() {
        let few = (0..<4).map { IBISample(t: Double($0), ibiMs: 900) }
        XCTAssertNil(CoherenceEngine.analyze(few))
    }

    func testScoreMappingIsMonotoneAndBounded() {
        XCTAssertEqual(CoherenceEngine.scoreFrom(ratio: 0), 0)
        XCTAssertLessThan(CoherenceEngine.scoreFrom(ratio: 0.5),
                          CoherenceEngine.scoreFrom(ratio: 5))
        XCTAssertLessThanOrEqual(CoherenceEngine.scoreFrom(ratio: 1_000), 100)
        XCTAssertGreaterThanOrEqual(CoherenceEngine.scoreFrom(ratio: 1_000), 0)
    }

    // MARK: FFT correctness (vs a naive DFT)

    func testFFTMatchesDFT() {
        let signal = (0..<8).map { sin(2 * Double.pi * Double($0) / 8) + 0.5 * Double($0 % 3) }
        let fft = FFT.transform(signal.map { Complex($0) })
        let dft = naiveDFT(signal)
        for k in 0..<signal.count {
            XCTAssertEqual(fft[k].re, dft[k].re, accuracy: 1e-9)
            XCTAssertEqual(fft[k].im, dft[k].im, accuracy: 1e-9)
        }
    }

    func testPowerSpectrumPeaksAtInputTone() {
        // 64-sample pure tone at bin 8 -> spectrum peak at bin 8 (and its mirror).
        let n = 64
        let bin = 8
        let signal = (0..<n).map { sin(2 * Double.pi * Double(bin) * Double($0) / Double(n)) }
        let spectrum = FFT.powerSpectrum(signal)
        let peakBin = (1..<(n / 2)).max { spectrum[$0] < spectrum[$1] }
        XCTAssertEqual(peakBin, bin)
    }

    private func naiveDFT(_ x: [Double]) -> [Complex] {
        let n = x.count
        return (0..<n).map { k in
            var acc = Complex(0, 0)
            for t in 0..<n {
                let ang = -2 * Double.pi * Double(k) * Double(t) / Double(n)
                acc = acc + Complex(x[t]) * Complex(cos(ang), sin(ang))
            }
            return acc
        }
    }
}

/// Tiny deterministic RNG so the "noise" test is reproducible across machines.
private struct SeededRNG {
    var state: UInt64
    init(seed: UInt64) { state = seed &+ 0x9E3779B97F4A7C15 }
    mutating func nextUnit() -> Double {
        state ^= state >> 12; state ^= state << 25; state ^= state >> 27
        let v = (state &* 0x2545F4914F6CDD1D) >> 11
        return Double(v) / Double(1 << 53)
    }
}
