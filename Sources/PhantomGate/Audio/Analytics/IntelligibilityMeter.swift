import Foundation
import AVFoundation
import Accelerate

/// Simple, low-cost intelligibility / obfuscation metrics (stub implementation).
/// Future enhancement: replace heuristic with proper STOI / PESQ proxy (offline) or a lightweight NN.
final class IntelligibilityMeter: ObservableObject {
    struct Metrics: Sendable {
        let overallRMS: Float
        let spectralFlux: Float
        let highBandRatio: Float
        let obfuscationScore: Float // 0 (clear) – 100 (highly obfuscated)
    }

    @Published private(set) var latest: Metrics = .init(overallRMS: 0, spectralFlux: 0, highBandRatio: 0, obfuscationScore: 0)

    private var previousSpectrum: [Float] = []
    private let fftSize: Int
    private let log2Size: vDSP_Length
    private var fftSetup: vDSP.DFT?
    private var window: [Float]

    init(fftSize: Int = 1024) {
        precondition(fftSize.isPowerOfTwo, "FFT size must be power of two")
        self.fftSize = fftSize
        self.log2Size = vDSP_Length(log2(Float(fftSize)))
        self.window = vDSP.window(ofType: Float.self, usingSequence: .hanningDenormalized, count: fftSize, isHalfWindow: false)
        self.fftSetup = vDSP.DFT(count: fftSize, direction: .forward, transformType: .real, ofType: Float.self)
    }

    func process(buffer: AVAudioPCMBuffer) {
        guard let channel = buffer.floatChannelData?.first else { return }
        let frameCount = Int(buffer.frameLength)
        if frameCount < fftSize { return } // need at least one frame

        // Take first fftSize samples (future: stride & average)
        var frame = Array(UnsafeBufferPointer(start: channel, count: fftSize))
        vDSP.multiply(frame, window, result: &frame)

        var real = frame
        var imag = [Float](repeating: 0, count: fftSize/2)
        real.withUnsafeMutableBufferPointer { realPtr in
            imag.withUnsafeMutableBufferPointer { imagPtr in
                fftSetup?.transform(inputReal: realPtr.baseAddress!, inputImaginary: nil,
                                    outputReal: realPtr.baseAddress!, outputImaginary: imagPtr.baseAddress!)
            }
        }

        // Magnitude spectrum (first N/2 bins)
        var magnitudes = [Float](repeating: 0, count: fftSize/2)
        magnitudes.withUnsafeMutableBufferPointer { magPtr in
            real.withUnsafeBufferPointer { rPtr in
                imag.withUnsafeBufferPointer { iPtr in
                    vDSP.squareMagnitudes(rPtr.baseAddress!, iPtr.baseAddress!, result: magPtr.baseAddress!, count: fftSize/2)
                }
            }
        }
        // Convert to linear magnitude
        vDSP.sqrt(magnitudes, result: &magnitudes)

        // Spectral flux (simple): L2 distance between normalized spectra
        var spectralFlux: Float = 0
        if !previousSpectrum.isEmpty && previousSpectrum.count == magnitudes.count {
            var normPrev = previousSpectrum
            var normCurr = magnitudes
            if let maxP = normPrev.max(), maxP > 0 { vDSP.divide(normPrev, maxP, result: &normPrev) }
            if let maxC = normCurr.max(), maxC > 0 { vDSP.divide(normCurr, maxC, result: &normCurr) }
            var diff = [Float](repeating: 0, count: normCurr.count)
            vDSP.subtract(normCurr, normPrev, result: &diff)
            vDSP.multiply(diff, diff, result: &diff)
            vDSP.sum(diff, result: &spectralFlux)
            spectralFlux = sqrt(spectralFlux / Float(diff.count))
        }
        previousSpectrum = magnitudes

        // High-band ratio (energy above 3000 Hz vs 200-4000 Hz)
        // Map bin to frequency: binFreq = bin * sampleRate / fftSize
        let sampleRate = buffer.format.sampleRate
        let nyquist = sampleRate / 2
        let binWidth = nyquist / Double(magnitudes.count)
        var highEnergy: Float = 0
        var midEnergy: Float = 0
        for (i, mag) in magnitudes.enumerated() {
            let f = Double(i) * binWidth
            if f >= 200 && f <= 4000 { midEnergy += mag * mag }
            if f >= 3000 && f <= 4000 { highEnergy += mag * mag }
        }
        let highBandRatio = (midEnergy > 0) ? min(highEnergy / midEnergy, 1) : 0

        // Overall RMS (use entire buffer first channel)
        var overallRMS: Float = 0
        vDSP.rootMeanSquare(channel, result: &overallRMS, count: frameCount)

        // Derive obfuscation score (heuristic): high spectral flux + low highBandRatio => higher obfuscation
        // Normalize terms roughly into [0,1]
        let fluxComponent = min(spectralFlux * 2.5, 1) // scale
        let clarityComponent = 1 - highBandRatio // if high consonant energy present -> clearer speech
        let rawScore = (0.6 * fluxComponent + 0.4 * clarityComponent)
        let obfuscationScore = max(0, min(rawScore * 100, 100))

        DispatchQueue.main.async {
            self.latest = Metrics(overallRMS: overallRMS,
                                  spectralFlux: spectralFlux,
                                  highBandRatio: highBandRatio,
                                  obfuscationScore: obfuscationScore)
        }
    }
}

private extension Int {
    var isPowerOfTwo: Bool { self > 0 && (self & (self - 1)) == 0 }
}