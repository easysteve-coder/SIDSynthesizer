// SIDEngine.swift
// Main audio engine. Owns 3 SID voices + filter, drives AVAudioEngine
// with an AVAudioSourceNode render callback, and exposes a simple
// noteOn / noteOff / panic interface for the UI.

import AVFoundation
import Combine

// MARK: - SIDEngine

@MainActor
final class SIDEngine: ObservableObject {

    // ── Public sub-models (observed by SwiftUI) ───────────────────────
    let voices: [SIDVoice]   = [SIDVoice(), SIDVoice(), SIDVoice()]
    let filter: SIDFilter    = SIDFilter()

    // ── Voice-to-MIDI-note assignment (for simple poly / mono) ────────
    @Published var playingNotes: [Int?] = [nil, nil, nil]  // MIDI note per voice
    @Published var currentOctave: Int   = 4
    @Published var isRunning: Bool      = false

    // ── AVAudio graph ─────────────────────────────────────────────────
    private let engine    = AVAudioEngine()
    private var sourceNode: AVAudioSourceNode!
    private let sampleRate: Double = 44100.0

    // MARK: - Init

    init() {
        // Voice 2 default: slightly detuned for richness
        voices[1].sawtooth   = true
        voices[1].coarseTune = 0
        voices[1].fineTune   = 7.0   // +7 cents

        // Voice 3 default: sub-octave saw
        voices[2].sawtooth   = true
        voices[2].coarseTune = -12

        setupAudio()
    }

    // MARK: - Audio graph setup

    private func setupAudio() {
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!

        sourceNode = AVAudioSourceNode(format: format) { [weak self] _, _, frameCount, audioBufferList -> OSStatus in
            guard let self else { return noErr }
            let ablPointer = UnsafeMutableAudioBufferListPointer(audioBufferList)
            guard let buf = ablPointer.first,
                  let ptr = buf.mData?.assumingMemoryBound(to: Float.self) else { return noErr }

            // Capture all parameters once (avoids repeated property reads)
            let v  = self.voices
            let f  = self.filter
            let sr = self.sampleRate

            for frame in 0 ..< Int(frameCount) {
                // Render each voice
                // SID routing: sync  = previous voice, ring = previous voice
                // Voice 0 ← voice 2 (wrap), Voice 1 ← voice 0, Voice 2 ← voice 1
                let s0 = v[0].render(sampleRate: sr, syncSource: v[2], ringSource: v[2])
                let s1 = v[1].render(sampleRate: sr, syncSource: v[0], ringSource: v[0])
                let s2 = v[2].render(sampleRate: sr, syncSource: v[1], ringSource: v[1])

                // Sort voices into filtered vs bypass paths
                var filtered: Double = 0.0
                var bypass:   Double = 0.0
                let samples = [s0, s1, s2]
                for i in 0 ..< 3 {
                    if f.routeVoice.indices.contains(i) && f.routeVoice[i] {
                        filtered += samples[i]
                    } else {
                        bypass += samples[i]
                    }
                }

                // Run through SVF, apply master volume
                let mixed = f.process(filteredInput: filtered,
                                      bypassInput:   bypass,
                                      sampleRate:    sr)

                // Soft-clip output and write
                ptr[frame] = Float(tanh(mixed * 0.6))
            }
            return noErr
        }

        let mainMixer = engine.mainMixerNode
        engine.attach(sourceNode)
        engine.connect(sourceNode, to: mainMixer, format: format)
    }

    // MARK: - Transport

    func start() {
        do {
            try engine.start()
            isRunning = true
        } catch {
            print("AVAudioEngine start failed: \(error)")
        }
    }

    func stop() {
        engine.stop()
        isRunning = false
        panicAllVoices()
    }

    // MARK: - Note handling

    /// Convert a MIDI note number to frequency in Hz.
    static func midiNoteToHz(_ note: Int) -> Double {
        440.0 * pow(2.0, (Double(note) - 69.0) / 12.0)
    }

    /// Play a note (MIDI number). Distributes across voices in round-robin.
    func noteOn(midiNote: Int) {
        let hz = Self.midiNoteToHz(midiNote)

        // Find free voice, or steal oldest
        var target = 0
        if let free = playingNotes.firstIndex(where: { $0 == nil }) {
            target = free
        } else {
            // Round-robin steal: use voice that already plays this note, or voice 0
            target = playingNotes.firstIndex(where: { $0 == midiNote }) ?? 0
        }

        playingNotes[target] = midiNote
        voices[target].noteOn(frequency: hz)
    }

    /// Release a specific MIDI note.
    func noteOff(midiNote: Int) {
        for i in 0 ..< 3 where playingNotes[i] == midiNote {
            playingNotes[i] = nil
            voices[i].noteOff()
        }
    }

    /// Silence all voices immediately.
    func panicAllVoices() {
        for i in 0 ..< 3 {
            voices[i].noteOff()
            playingNotes[i] = nil
        }
    }

    // MARK: - Preset apply

    func apply(_ preset: SIDPreset) {
        for (i, vp) in preset.voices.enumerated() where i < voices.count {
            let v = voices[i]
            v.triangle   = vp.triangle
            v.sawtooth   = vp.sawtooth
            v.pulse      = vp.pulse
            v.noise      = vp.noise
            v.pulseWidth = vp.pulseWidth
            v.coarseTune = vp.coarseTune
            v.fineTune   = vp.fineTune
            v.attack     = vp.attack
            v.decay      = vp.decay
            v.sustain    = vp.sustain
            v.release    = vp.release
            v.ringMod    = vp.ringMod
            v.hardSync   = vp.hardSync
            v.muted      = vp.muted
        }
        filter.cutoff       = preset.cutoff
        filter.resonance    = preset.resonance
        filter.lpOn         = preset.lpOn
        filter.bpOn         = preset.bpOn
        filter.hpOn         = preset.hpOn
        filter.routeVoice   = preset.routeVoice
        filter.masterVolume = preset.masterVolume
    }
}
