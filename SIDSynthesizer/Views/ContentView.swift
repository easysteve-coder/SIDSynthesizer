// ContentView.swift
// Main layout: title bar + preset selector, three voice panels,
// filter panel, and the piano keyboard at the bottom.

import SwiftUI

struct ContentView: View {
    @StateObject private var engine = SIDEngine()
    @State private var selectedPreset: SIDPreset? = nil
    @State private var showPresetPicker = false

    var body: some View {
        VStack(spacing: 0) {
            titleBar
            Divider().background(Color.c64Border)
            mainPanel
            Divider().background(Color.c64Border)
            KeyboardView(engine: engine)
        }
        .background(Color.c64Dark)
        .onAppear { engine.start() }
        .onDisappear { engine.stop() }
    }

    // MARK: - Title bar

    private var titleBar: some View {
        HStack(spacing: 12) {
            Text("★ SID SYNTHESIZER ★")
                .font(.c64Title)
                .foregroundColor(.c64Bright)

            Text("6581/8580")
                .font(.c64Small)
                .foregroundColor(.c64Dim)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .overlay(
                    RoundedRectangle(cornerRadius: 3)
                        .stroke(Color.c64Border, lineWidth: 1)
                )

            Spacer()

            // Preset picker
            Menu {
                ForEach(SIDPreset.library) { preset in
                    Button(preset.name) {
                        engine.apply(preset)
                        selectedPreset = preset
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Text(selectedPreset?.name ?? "PRESET")
                        .font(.c64Label)
                        .foregroundColor(.c64Cyan)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 9))
                        .foregroundColor(.c64Dim)
                }
                .padding(.horizontal, 8).padding(.vertical, 4)
                .background(Color.c64Panel)
                .overlay(RoundedRectangle(cornerRadius: 3)
                    .stroke(Color.c64Border, lineWidth: 1))
                .cornerRadius(3)
            }

            // Play / Stop
            Button(engine.isRunning ? "■ STOP" : "▶ START") {
                if engine.isRunning { engine.stop() } else { engine.start() }
            }
            .font(.c64Label)
            .foregroundColor(engine.isRunning ? .c64Red : .c64Green)
            .padding(.horizontal, 10).padding(.vertical, 4)
            .background(Color.c64Panel)
            .overlay(RoundedRectangle(cornerRadius: 3)
                .stroke(engine.isRunning ? Color.c64Red : Color.c64Green, lineWidth: 1))
            .cornerRadius(3)

            // Panic
            Button("PANIC") { engine.panicAllVoices() }
                .font(.c64Label)
                .foregroundColor(.c64Red)
                .padding(.horizontal, 8).padding(.vertical, 4)
                .background(Color.c64Panel)
                .overlay(RoundedRectangle(cornerRadius: 3)
                    .stroke(Color.c64Red, lineWidth: 1))
                .cornerRadius(3)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Color.c64Panel)
    }

    // MARK: - Main panel

    private var mainPanel: some View {
        HStack(alignment: .top, spacing: 8) {
            ForEach(0 ..< 3, id: \.self) { i in
                VoicePanel(
                    index: i,
                    voice: engine.voices[i],
                    isPlaying: engine.playingNotes[i] != nil
                )
                .frame(maxWidth: .infinity)
            }

            FilterPanel(filter: engine.filter)
                .frame(width: 190)
        }
        .padding(10)
    }
}

#Preview {
    ContentView()
        .frame(width: 900, height: 650)
}
