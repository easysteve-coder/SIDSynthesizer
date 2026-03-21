import SwiftUI
import CoreMIDI

struct SettingsView: View {
    @EnvironmentObject var engine: SequencerEngine
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // ── Header ──────────────────────────────────────────────────
            HStack {
                Text("SETTINGS")
                    .font(VintageTheme.monoTitle)
                    .foregroundColor(VintageTheme.textAmber)
                Spacer()
                Button("CLOSE") { dismiss() }
                    .buttonStyle(VintageSmallButtonStyle(isActive: false, accent: VintageTheme.amber))
            }
            .padding(16)
            .background(VintageTheme.panelDark)

            Rectangle().fill(VintageTheme.panelBorder).frame(height: 1)

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {

                    // ── Tracks ───────────────────────────────────────────
                    SectionLabel("TRACKS")
                    Text("Use + / × buttons directly in the track list to add or remove tracks.")
                        .font(VintageTheme.monoSmall)
                        .foregroundColor(VintageTheme.textSecondary)

                    settingsDivider

                    // ── MIDI Output ──────────────────────────────────────
                    SectionLabel("MIDI OUTPUT")
                    HStack {
                        SettingsLabel("Device")
                        Picker("", selection: $engine.midi.selectedOutput) {
                            Text("None").tag(MIDIEndpointRef(0))
                            ForEach(engine.midi.outputs, id: \.ref) { out in
                                Text(out.name).tag(out.ref)
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.menu)
                        .frame(width: 220)
                    }

                    settingsDivider

                    // ── MIDI Input (Clock) ───────────────────────────────
                    SectionLabel("MIDI INPUT  (clock sync)")
                    HStack {
                        SettingsLabel("Source")
                        Picker("", selection: $engine.midi.selectedInput) {
                            Text("None").tag(MIDIEndpointRef(0))
                            ForEach(engine.midi.inputs, id: \.ref) { src in
                                Text(src.name).tag(src.ref)
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.menu)
                        .frame(width: 220)
                        .onChange(of: engine.midi.selectedInput) { ep in
                            engine.midi.connectInput(ep)
                        }
                    }

                    Button("Refresh MIDI Ports") { engine.midi.refreshPorts() }
                        .buttonStyle(VintageSmallButtonStyle(isActive: false,
                                                             accent: VintageTheme.amber))

                    settingsDivider

                    // ── CC assignments per track ─────────────────────────
                    SectionLabel("CC ASSIGNMENTS  (per track)")
                    ForEach(engine.currentPattern.tracks) { track in
                        TrackCCRow(track: track)
                    }

                    settingsDivider

                    settingsDivider

                    // ── CC Remote Control ────────────────────────────────
                    SectionLabel("CC REMOTE CONTROL")
                    HStack(spacing: 12) {
                        SettingsLabel("Pattern switch CC#")
                        Stepper(engine.patternSwitchCC < 0 ? "Off" : "\(engine.patternSwitchCC)",
                                value: $engine.patternSwitchCC, in: -1...127)
                            .font(VintageTheme.monoMedium)
                            .foregroundColor(VintageTheme.textPrimary)
                    }
                    Text("Values 0–31=A  32–63=B  64–95=C  96–127=D")
                        .font(VintageTheme.monoSmall)
                        .foregroundColor(VintageTheme.textSecondary)

                    ForEach(engine.currentPattern.tracks.indices, id: \.self) { i in
                        HStack(spacing: 12) {
                            SettingsLabel("Mute Track \(i+1) CC#")
                            Stepper(i < engine.trackMuteCCs.count && engine.trackMuteCCs[i] >= 0
                                        ? "\(engine.trackMuteCCs[i])" : "Off",
                                    value: Binding(
                                        get: { i < engine.trackMuteCCs.count ? engine.trackMuteCCs[i] : -1 },
                                        set: { v in if i < engine.trackMuteCCs.count { engine.trackMuteCCs[i] = v } }),
                                    in: -1...127)
                                .font(VintageTheme.monoMedium)
                                .foregroundColor(VintageTheme.textPrimary)
                        }
                    }

                }
                .padding(16)
            }
        }
        .background(VintageTheme.background)
        .frame(width: 500, height: 720)
        .preferredColorScheme(.dark)
    }

    // MARK: - Helpers

    private var settingsDivider: some View {
        Rectangle().fill(VintageTheme.panelBorder).frame(height: 1)
    }

}

// MARK: - Per-track CC row

private struct TrackCCRow: View {
    @ObservedObject var track: Track

    var body: some View {
        HStack(spacing: 10) {
            Text(track.name)
                .font(VintageTheme.monoMedium)
                .foregroundColor(VintageTheme.textPrimary)
                .frame(width: 72, alignment: .leading)

            // CC1
            HStack(spacing: 4) {
                Text("CC1")
                    .font(VintageTheme.monoSmall)
                    .foregroundColor(VintageTheme.textSecondary)
                TextField("Label", text: $track.cc1Label)
                    .font(VintageTheme.monoSmall)
                    .frame(width: 52)
                    .textFieldStyle(.roundedBorder)
                Stepper("\(track.cc1Number)", value: $track.cc1Number, in: 0...127)
                    .font(VintageTheme.monoSmall)
                    .frame(width: 88)
            }

            // CC2
            HStack(spacing: 4) {
                Text("CC2")
                    .font(VintageTheme.monoSmall)
                    .foregroundColor(VintageTheme.textSecondary)
                TextField("Label", text: $track.cc2Label)
                    .font(VintageTheme.monoSmall)
                    .frame(width: 52)
                    .textFieldStyle(.roundedBorder)
                Stepper("\(track.cc2Number)", value: $track.cc2Number, in: 0...127)
                    .font(VintageTheme.monoSmall)
                    .frame(width: 88)
            }
        }
        .padding(.vertical, 3)
    }
}

// MARK: - Small helpers

private struct SectionLabel: View {
    let text: String
    init(_ text: String) { self.text = text }
    var body: some View {
        Text(text)
            .font(VintageTheme.monoBold)
            .foregroundColor(VintageTheme.textAmber)
    }
}

private struct SettingsLabel: View {
    let text: String
    init(_ text: String) { self.text = text }
    var body: some View {
        Text(text)
            .font(VintageTheme.monoMedium)
            .foregroundColor(VintageTheme.textPrimary)
    }
}
