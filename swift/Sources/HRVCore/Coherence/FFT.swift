import Foundation

// Track J -- frequency-domain support for Coherence (Deep Dive / HeartMath §2).
// A tiny pure-Swift FFT: HRVCore stays Foundation-only and verifiable off-Mac
// (Accelerate/vDSP would break that), matching the project's whole ethos.

/// A complex number, kept local so HRVCore pulls in nothing but Foundation.
public struct Complex: Equatable {
    public var re: Double
    public var im: Double
    public init(_ re: Double, _ im: Double = 0) { self.re = re; self.im = im }

    public var magnitudeSquared: Double { re * re + im * im }

    static func + (a: Complex, b: Complex) -> Complex { Complex(a.re + b.re, a.im + b.im) }
    static func - (a: Complex, b: Complex) -> Complex { Complex(a.re - b.re, a.im - b.im) }
    static func * (a: Complex, b: Complex) -> Complex {
        Complex(a.re * b.re - a.im * b.im, a.re * b.im + a.im * b.re)
    }
}

public enum FFT {
    /// Iterative radix-2 Cooley–Tukey FFT. `input.count` must be a power of two;
    /// use `nextPowerOfTwo` + zero-padding to satisfy that.
    public static func transform(_ input: [Complex]) -> [Complex] {
        let n = input.count
        guard n > 1 else { return input }
        precondition(n & (n - 1) == 0, "FFT length must be a power of two")

        // Bit-reversal permutation.
        var a = input
        var j = 0
        for i in 1..<n {
            var bit = n >> 1
            while j & bit != 0 { j ^= bit; bit >>= 1 }
            j ^= bit
            if i < j { a.swapAt(i, j) }
        }

        // Butterfly stages.
        var len = 2
        while len <= n {
            let ang = -2.0 * Double.pi / Double(len)
            let wLen = Complex(cos(ang), sin(ang))
            var i = 0
            while i < n {
                var w = Complex(1, 0)
                for k in 0..<(len / 2) {
                    let u = a[i + k]
                    let v = a[i + k + len / 2] * w
                    a[i + k] = u + v
                    a[i + k + len / 2] = u - v
                    w = w * wLen
                }
                i += len
            }
            len <<= 1
        }
        return a
    }

    /// Power spectrum (|X_k|²) of a real signal, zero-padded up to a power of two.
    public static func powerSpectrum(_ signal: [Double]) -> [Double] {
        guard !signal.isEmpty else { return [] }
        let n = nextPowerOfTwo(signal.count)
        var padded = signal.map { Complex($0) }
        if padded.count < n { padded += Array(repeating: Complex(0), count: n - padded.count) }
        return transform(padded).map(\.magnitudeSquared)
    }

    public static func nextPowerOfTwo(_ n: Int) -> Int {
        guard n > 1 else { return 1 }
        var p = 1
        while p < n { p <<= 1 }
        return p
    }
}
