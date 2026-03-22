// SIDPreset.swift
// Data model for a complete SID synthesizer patch.
// Includes a library of classic C64-style sounds.

import Foundation

// MARK: - Voice preset

struct SIDVoicePreset {
    var triangle:   Bool   = false
    var sawtooth:   Bool   = true
    var pulse:      Bool   = false
    var noise:      Bool   = false
    var pulseWidth: Double = 0.5
    var coarseTune: Int    = 0
    var fineTune:   Double = 0.0
    var attack:     Int    = 0
    var decay:      Int    = 2
    var sustain:    Int    = 8
    var release:    Int    = 4
    var ringMod:    Bool   = false
    var hardSync:   Bool   = false
    var muted:      Bool   = false
}

// MARK: - Full preset

struct SIDPreset: Identifiable {
    let id   = UUID()
    var name: String

    var voices: [SIDVoicePreset]   // always 3
    var cutoff:       Int    = 1200
    var resonance:    Int    = 4
    var lpOn:         Bool   = true
    var bpOn:         Bool   = false
    var hpOn:         Bool   = false
    var routeVoice:   [Bool] = [true, true, false]
    var masterVolume: Int    = 12

    // MARK: - Factory presets

    static let library: [SIDPreset] = [
        sidBass(),
        fatLead(),
        arpPulse(),
        retroFX(),
        spaceChord(),
        drumNoise(),
        ringBell(),
        syncScream()
    ]

    // ── Classic C64 bass ──────────────────────────────────────────────
    static func sidBass() -> SIDPreset {
        var v1 = SIDVoicePreset()
        v1.sawtooth   = true
        v1.attack     = 0; v1.decay = 3; v1.sustain = 0; v1.release = 2

        var v2 = SIDVoicePreset()
        v2.sawtooth   = true
        v2.coarseTune = -12
        v2.fineTune   = 5
        v2.attack     = 0; v2.decay = 3; v2.sustain = 0; v2.release = 2

        var v3 = SIDVoicePreset(); v3.muted = true

        return SIDPreset(name: "SID Bass",
                         voices: [v1, v2, v3],
                         cutoff: 600, resonance: 8,
                         lpOn: true, routeVoice: [true, true, false],
                         masterVolume: 14)
    }

    // ── Fat saw lead ──────────────────────────────────────────────────
    static func fatLead() -> SIDPreset {
        var v1 = SIDVoicePreset()
        v1.sawtooth = true
        v1.attack   = 2; v1.decay = 4; v1.sustain = 10; v1.release = 5

        var v2 = SIDVoicePreset()
        v2.sawtooth   = true
        v2.fineTune   = 12.0
        v2.attack     = 2; v2.decay = 4; v2.sustain = 10; v2.release = 5

        var v3 = SIDVoicePreset()
        v3.sawtooth   = true
        v3.fineTune   = -12.0
        v3.attack     = 2; v3.decay = 4; v3.sustain = 10; v3.release = 5

        return SIDPreset(name: "Fat Lead",
                         voices: [v1, v2, v3],
                         cutoff: 1400, resonance: 6,
                         lpOn: true, routeVoice: [true, true, true],
                         masterVolume: 12)
    }

    // ── Arpeggio pulse ────────────────────────────────────────────────
    static func arpPulse() -> SIDPreset {
        var v1 = SIDVoicePreset()
        v1.pulse      = true
        v1.pulseWidth = 0.25
        v1.attack     = 0; v1.decay = 1; v1.sustain = 12; v1.release = 2

        var v2 = SIDVoicePreset(); v2.muted = true
        var v3 = SIDVoicePreset(); v3.muted = true

        return SIDPreset(name: "Arp Pulse",
                         voices: [v1, v2, v3],
                         cutoff: 1800, resonance: 10,
                         lpOn: true, routeVoice: [true, false, false],
                         masterVolume: 13)
    }

    // ── Retro FX sweep ────────────────────────────────────────────────
    static func retroFX() -> SIDPreset {
        var v1 = SIDVoicePreset()
        v1.noise  = true
        v1.attack = 0; v1.decay = 8; v1.sustain = 0; v1.release = 6

        var v2 = SIDVoicePreset(); v2.muted = true
        var v3 = SIDVoicePreset(); v3.muted = true

        return SIDPreset(name: "Retro FX",
                         voices: [v1, v2, v3],
                         cutoff: 900, resonance: 12,
                         lpOn: false, bpOn: true,
                         routeVoice: [true, false, false],
                         masterVolume: 12)
    }

    // ── Space chord ───────────────────────────────────────────────────
    static func spaceChord() -> SIDPreset {
        var v1 = SIDVoicePreset()
        v1.triangle   = true
        v1.coarseTune = 0
        v1.attack     = 6; v1.decay = 4; v1.sustain = 10; v1.release = 8

        var v2 = SIDVoicePreset()
        v2.triangle   = true
        v2.coarseTune = 7          // fifth
        v2.attack     = 6; v2.decay = 4; v2.sustain = 10; v2.release = 8

        var v3 = SIDVoicePreset()
        v3.triangle   = true
        v3.coarseTune = 4          // major third (approx)
        v3.attack     = 6; v3.decay = 4; v3.sustain = 10; v3.release = 8

        return SIDPreset(name: "Space Chord",
                         voices: [v1, v2, v3],
                         cutoff: 1600, resonance: 3,
                         lpOn: true, routeVoice: [false, false, false],
                         masterVolume: 11)
    }

    // ── Drum / noise hit ──────────────────────────────────────────────
    static func drumNoise() -> SIDPreset {
        var v1 = SIDVoicePreset()
        v1.noise  = true
        v1.attack = 0; v1.decay = 4; v1.sustain = 0; v1.release = 2

        var v2 = SIDVoicePreset()
        v2.sawtooth   = true
        v2.coarseTune = -24
        v2.attack     = 0; v2.decay = 5; v2.sustain = 0; v2.release = 3

        var v3 = SIDVoicePreset(); v3.muted = true

        return SIDPreset(name: "Drum",
                         voices: [v1, v2, v3],
                         cutoff: 500, resonance: 14,
                         lpOn: true, routeVoice: [true, true, false],
                         masterVolume: 15)
    }

    // ── Ring-mod bell ─────────────────────────────────────────────────
    static func ringBell() -> SIDPreset {
        var v1 = SIDVoicePreset()
        v1.triangle = true
        v1.ringMod  = true
        v1.attack   = 1; v1.decay = 7; v1.sustain = 0; v1.release = 9

        var v2 = SIDVoicePreset()         // modulator (audible too)
        v2.triangle   = true
        v2.coarseTune = 9                 // major sixth
        v2.attack     = 1; v2.decay = 7; v2.sustain = 0; v2.release = 9

        var v3 = SIDVoicePreset(); v3.muted = true

        return SIDPreset(name: "Ring Bell",
                         voices: [v1, v2, v3],
                         cutoff: 2000, resonance: 2,
                         lpOn: true, routeVoice: [false, false, false],
                         masterVolume: 12)
    }

    // ── Hard-sync scream ──────────────────────────────────────────────
    static func syncScream() -> SIDPreset {
        var v1 = SIDVoicePreset()
        v1.sawtooth  = true
        v1.hardSync  = true
        v1.attack    = 0; v1.decay = 2; v1.sustain = 12; v1.release = 3

        var v2 = SIDVoicePreset()         // sync master (muted, just clocks v1)
        v2.sawtooth   = true
        v2.coarseTune = 12
        v2.muted      = true

        var v3 = SIDVoicePreset(); v3.muted = true

        return SIDPreset(name: "Sync Scream",
                         voices: [v1, v2, v3],
                         cutoff: 1700, resonance: 9,
                         lpOn: true, hpOn: false,
                         routeVoice: [true, false, false],
                         masterVolume: 12)
    }
}
