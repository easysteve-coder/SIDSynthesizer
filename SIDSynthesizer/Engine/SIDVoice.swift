// SIDVoice.swift
// Emulates one voice of the MOS 6581/8580 SID chip.
// Each voice has: oscillator (TRI/SAW/PUL/NOI), ADSR envelope,
// ring modulation input, and hard sync input.

import Foundation
import Combine

// MARK: - Envelope state machine

private enum EnvState {
    case idle, attack, decay, sustain, release
}

// MARK: - SIDVoice

final class SIDVoice: ObservableObject {

    // ── Waveform selection ─────────────────────────────────────────────
    @Published var triangle: Bool = false
    @Published var sawtooth: Bool = true
    @Published var pulse:    Bool = false
    @Published var noise:    Bool = false

    // ── Pulse width (0.0 … 1.0)  ──────────────────────────────────────
    @Published var pulseWidth: Double = 0.5

    // ── Tuning ────────────────────────────────────────────────────────
    @Published var coarseTune: Int    = 0     // semitones: -24 … +24
    @Published var fineTune:   Double = 0.0   // cents:    -100 … +100

    // ── ADSR (0 … 15, matching original SID time constants) ──────────
    @Published var attack:  Int = 4
    @Published var decay:   Int = 2
    @Published var sustain: Int = 8
    @Published var release: Int = 4

    // ── Modifiers ────────────────────────────────────────────────────
    @Published var ringMod:  Bool = false
    @Published var hardSync: Bool = false
    @Published var muted:    Bool = false

    // ── Base frequency (Hz) set by NoteOn ────────────────────────────
    var frequency: Double = 440.0

    // ── DSP state (accessed only from audio thread) ──────────────────
    private(set) var phase:    Double = 0.0
    private(set) var envelope: Double = 0.0
    private var prevPhase:     Double = 0.0
    private var envState:      EnvState = .idle
    private var gate:          Bool = false
    private var lfsr:          UInt32 = 0x7FFFF8   // 23-bit LFSR seed
    private var lfsrAccum:     Double = 0.0
    private var noiseSample:   Double = 0.0

    // ── SID original time constants ───────────────────────────────────

    /// Attack times in seconds (indices 0 … 15)
    static let attackTimes: [Double] = [
        0.002, 0.008, 0.016, 0.024, 0.038, 0.056, 0.068, 0.080,
        0.100, 0.250, 0.500, 0.800, 1.000, 3.000, 5.000, 8.000
    ]

    /// Decay / Release times in seconds (indices 0 … 15)
    static let decRelTimes: [Double] = [
        0.006, 0.024, 0.048, 0.072, 0.114, 0.168, 0.204, 0.240,
        0.300, 0.750, 1.500, 2.400, 3.000, 9.000, 15.000, 24.000
    ]

    // MARK: - Control

    func noteOn(frequency hz: Double) {
        frequency = hz
        gate      = true
        envState  = .attack
    }

    func noteOff() {
        gate = false
        if envState != .idle { envState = .release }
    }

    func reset() {
        phase       = 0; prevPhase = 0
        envelope    = 0; envState  = .idle
        gate        = false
        lfsr        = 0x7FFFF8
        lfsrAccum   = 0; noiseSample = 0
    }

    // MARK: - DSP render

    /// Render one audio sample.
    /// - Parameters:
    ///   - sampleRate: host sample rate in Hz
    ///   - syncSource: voice that hard-syncs this voice (resets phase on wrap)
    ///   - ringSource: voice whose MSB modulates the triangle waveform
    /// - Returns: sample in the range −1.0 … +1.0 (before master volume)
    func render(sampleRate: Double,
                syncSource: SIDVoice? = nil,
                ringSource: SIDVoice? = nil) -> Double {

        // ── Envelope ─────────────────────────────────────────────────
        let atkRate  = 1.0 / (SIDVoice.attackTimes[clamp(attack,  0, 15)] * sampleRate)
        let decRate  = 1.0 / (SIDVoice.decRelTimes[clamp(decay,   0, 15)] * sampleRate)
        let relRate  = 1.0 / (SIDVoice.decRelTimes[clamp(release, 0, 15)] * sampleRate)
        let sustLvl  = Double(clamp(sustain, 0, 15)) / 15.0

        switch envState {
        case .idle:
            envelope = 0.0
        case .attack:
            envelope += atkRate
            if envelope >= 1.0 { envelope = 1.0; envState = .decay }
        case .decay:
            envelope -= decRate
            if envelope <= sustLvl { envelope = sustLvl; envState = .sustain }
        case .sustain:
            envelope = sustLvl
        case .release:
            envelope -= relRate
            if envelope <= 0.0 { envelope = 0.0; envState = .idle }
        }

        // ── Oscillator phase accumulation ─────────────────────────────
        prevPhase = phase
        let detunedFreq = frequency * pow(2.0,
                          (Double(coarseTune) + fineTune / 100.0) / 12.0)
        phase += detunedFreq / sampleRate

        // Hard sync: reset phase when sync source wraps around
        if hardSync, let src = syncSource, src.phase < src.prevPhase {
            phase = 0.0
        }
        if phase >= 1.0 { phase -= floor(phase) }

        // Ring modulation: invert triangle phase on MSB of ring source
        let ringSign: Double
        if ringMod, let rSrc = ringSource {
            ringSign = rSrc.phase < 0.5 ? 1.0 : -1.0
        } else {
            ringSign = 1.0
        }

        // ── Waveform generation ───────────────────────────────────────
        var out: Double = 0.0
        var cnt: Int    = 0

        // Triangle
        if triangle {
            let tri = phase < 0.5
                ? (phase * 4.0 - 1.0)          //  rising  0→1
                : (3.0 - phase * 4.0)           //  falling 1→0
            out += tri * ringSign
            cnt += 1
        }

        // Sawtooth
        if sawtooth {
            out += phase * 2.0 - 1.0            // -1 … +1
            cnt += 1
        }

        // Pulse (with ring mod applied as a sign flip)
        if pulse {
            let pw: Double = max(0.01, min(0.99, pulseWidth))
            out += (phase < pw ? 1.0 : -1.0) * ringSign
            cnt += 1
        }

        // Noise – 23-bit LFSR, clocked at oscillator frequency
        if noise {
            lfsrAccum += detunedFreq / sampleRate
            if lfsrAccum >= 1.0 {
                lfsrAccum -= 1.0
                let fb = ((lfsr >> 22) ^ (lfsr >> 17)) & 1
                lfsr = ((lfsr << 1) | fb) & 0x7FFFFF
                // Extract 8 bits from specific LFSR taps → −1 … +1
                var n: UInt8 = 0
                n |= UInt8((lfsr >> 22) & 1) << 7
                n |= UInt8((lfsr >> 20) & 1) << 6
                n |= UInt8((lfsr >> 16) & 1) << 5
                n |= UInt8((lfsr >> 13) & 1) << 4
                n |= UInt8((lfsr >> 11) & 1) << 3
                n |= UInt8((lfsr >>  7) & 1) << 2
                n |= UInt8((lfsr >>  4) & 1) << 1
                n |= UInt8((lfsr >>  2) & 1)
                noiseSample = (Double(Int(n)) - 128.0) / 128.0
            }
            out += noiseSample
            cnt += 1
        }

        if cnt > 1 { out /= Double(cnt) }
        return muted ? 0.0 : out * envelope
    }

    // MARK: - Helpers

    private func clamp(_ v: Int, _ lo: Int, _ hi: Int) -> Int {
        Swift.max(lo, Swift.min(hi, v))
    }
}
