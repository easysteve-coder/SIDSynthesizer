// VoicePanel.swift
// Controls for one SID voice: waveform, PW, tune, ADSR, ring/sync.

import SwiftUI

struct VoicePanel: View {
    let index:  Int
    @ObservedObject var voice: SIDVoice
    var isPlaying: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {

            // ── Header ────────────────────────────────────────────────
            HStack {
                C64SectionHeader(text: "VOICE \(index + 1)")
                Spacer()
                C64LED(on: isPlaying, color: .c64Green)
                C64ToggleButton(label: "MUTE", isOn: $voice.muted, width: 44)
            }

            // ── Waveform selector ─────────────────────────────────────
            HStack(spacing: 4) {
                C64ToggleButton(label: "TRI", isOn: $voice.triangle, width: 38)
                C64ToggleButton(label: "SAW", isOn: $voice.sawtooth, width: 38)
                C64ToggleButton(label: "PUL", isOn: $voice.pulse,    width: 38)
                C64ToggleButton(label: "NOI", isOn: $voice.noise,    width: 38)
            }

            // ── Pulse width ───────────────────────────────────────────
            C64Knob(label: "PULSE WIDTH",
                    value: $voice.pulseWidth,
                    range: 0.01 ... 0.99,
                    format: "%.0f%%")
                .environment(\.c64KnobScale, 100)
                .opacity(voice.pulse ? 1 : 0.35)

            Divider().background(Color.c64Border)

            // ── Tuning ────────────────────────────────────────────────
            HStack(spacing: 10) {
                VStack(spacing: 2) {
                    Text("\(voice.coarseTune > 0 ? "+" : "")\(voice.coarseTune)")
                        .font(.c64Value).foregroundColor(.c64Cyan).frame(width: 36)
                    Slider(value: Binding(get: { Double(voice.coarseTune) },
                                         set: { voice.coarseTune = Int($0.rounded()) }),
                           in: -24 ... 24, step: 1)
                        .tint(.c64Blue).frame(width: 80)
                    Text("TUNE ST").font(.c64Small).foregroundColor(.c64Dim)
                }

                VStack(spacing: 2) {
                    Text(String(format: "%+.0f", voice.fineTune))
                        .font(.c64Value).foregroundColor(.c64Cyan).frame(width: 36)
                    Slider(value: $voice.fineTune, in: -100 ... 100, step: 1)
                        .tint(.c64Blue).frame(width: 80)
                    Text("FINE CT").font(.c64Small).foregroundColor(.c64Dim)
                }
            }

            Divider().background(Color.c64Border)

            // ── ADSR ──────────────────────────────────────────────────
            HStack(spacing: 6) {
                ADSRSlider(label: "A", value: $voice.attack,  color: .c64Cyan)
                ADSRSlider(label: "D", value: $voice.decay,   color: .c64Blue)
                ADSRSlider(label: "S", value: $voice.sustain, color: .c64Blue)
                ADSRSlider(label: "R", value: $voice.release, color: .c64Dim)
            }
            .padding(.horizontal, 4)

            Divider().background(Color.c64Border)

            // ── Modifiers ─────────────────────────────────────────────
            HStack(spacing: 6) {
                C64ToggleButton(label: "RING",  isOn: $voice.ringMod,  width: 44)
                C64ToggleButton(label: "SYNC",  isOn: $voice.hardSync, width: 44)
            }
        }
        .padding(10)
        .background(Color.c64Panel)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color.c64Border, lineWidth: 1)
        )
        .cornerRadius(6)
    }
}

// MARK: - Environment key for knob scale factor

private struct C64KnobScaleKey: EnvironmentKey {
    static let defaultValue: Double = 1.0
}
extension EnvironmentValues {
    var c64KnobScale: Double {
        get { self[C64KnobScaleKey.self] }
        set { self[C64KnobScaleKey.self] = newValue }
    }
}
