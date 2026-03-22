// SIDFilter.swift
// State-variable filter emulating the MOS 6581/8580 SID chip filter.
// Supports LP, BP, HP outputs (combinable), per-voice routing,
// and a non-linear cutoff mapping matching the original chip.

import Foundation
import Combine

// MARK: - SIDFilter

final class SIDFilter: ObservableObject {

    // ── Parameters ────────────────────────────────────────────────────

    /// Cutoff register value (0 … 2047) – matches the 11-bit SID register
    @Published var cutoff:    Int  = 1024   // ~1 kHz
    /// Resonance register value (0 … 15) – 4-bit SID register
    @Published var resonance: Int  = 4
    /// Which filter modes are active
    @Published var lpOn: Bool = true
    @Published var bpOn: Bool = false
    @Published var hpOn: Bool = false
    /// Which voices are routed through the filter
    @Published var routeVoice: [Bool] = [true, true, true]
    /// Master volume (0 … 15) – kept here for convenience
    @Published var masterVolume: Int = 12

    // ── DSP state ─────────────────────────────────────────────────────
    private var lp: Double = 0.0
    private var bp: Double = 0.0
    private var hp: Double = 0.0

    // MARK: - Cutoff mapping

    /// Map the 11-bit cutoff register to a frequency in Hz.
    /// The 6581 has a very non-linear response; this exponential
    /// approximation gives ~30 Hz at 0 and ~12 kHz at 2047.
    var cutoffFrequency: Double {
        let t = Double(clamp(cutoff, 0, 2047)) / 2047.0
        return 30.0 * pow(400.0, t)   // 30 Hz → 12 000 Hz
    }

    /// Q factor derived from the resonance register (0 … 15).
    var qFactor: Double {
        0.5 + Double(clamp(resonance, 0, 15)) * 1.4
    }

    // MARK: - DSP render

    /// Process one stereo pair (or mono here) sample through the SVF.
    /// - Parameters:
    ///   - filteredInput:  pre-summed signal of all routed voices
    ///   - bypassInput:    pre-summed signal of un-routed voices
    ///   - sampleRate:     host sample rate in Hz
    /// - Returns: mixed output sample (−1.0 … +1.0 before master vol)
    func process(filteredInput: Double,
                 bypassInput:   Double,
                 sampleRate:    Double) -> Double {

        // ── Compute SVF coefficients ──────────────────────────────────
        // f = 2·sin(π·Fc/Fs) is accurate for Fc << Fs; clamp for safety.
        let fc = min(cutoffFrequency, sampleRate * 0.49)
        let f  = 2.0 * sin(.pi * fc / sampleRate)
        let q  = 1.0 / qFactor       // feedback coefficient

        // ── State-variable filter (Chamberlin topology) ───────────────
        hp  = filteredInput - lp - q * bp
        bp += f * hp
        lp += f * bp

        // Soft-clip to prevent runaway on high resonance
        lp = tanh(lp)
        bp = tanh(bp)
        hp = tanh(hp)

        // ── Mix selected outputs ──────────────────────────────────────
        var filtered: Double = 0.0
        if lpOn { filtered += lp }
        if bpOn { filtered += bp }
        if hpOn { filtered += hp }

        // If nothing selected, pass through as allpass-ish (use LP)
        if !lpOn && !bpOn && !hpOn { filtered = lp }

        return (filtered + bypassInput) * (Double(clamp(masterVolume, 0, 15)) / 15.0)
    }

    func reset() {
        lp = 0; bp = 0; hp = 0
    }

    // MARK: - Helpers

    private func clamp(_ v: Int, _ lo: Int, _ hi: Int) -> Int {
        Swift.max(lo, Swift.min(hi, v))
    }
}
