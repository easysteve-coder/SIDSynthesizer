import SwiftUI

struct TransportView: View {
    @EnvironmentObject var engine: SequencerEngine
    @State private var showSettings = false
    @State private var tapTimes: [Date] = []

    @AppStorage("showTooltips") private var showTooltips: Bool = true
    private func tip(_ text: String) -> String { showTooltips ? text : "" }

    private var bpmBinding: Binding<Double> {
        Binding(get: { engine.bpm },
                set: { engine.bpm = $0.clamped(to: 20...300) })
    }
    // Maps internal 50–75 range to display 0–100%
    private var swingBinding: Binding<Double> {
        Binding(
            get: { (engine.swing - 50.0) * 4.0 },
            set: { engine.swing = ($0 / 4.0) + 50.0 }
        )
    }

    var body: some View {
        HStack(spacing: 0) {

            // ── Logo ─────────────────────────────────────────────────────
            VStack(alignment: .leading, spacing: 1) {
                Text("STEPH SEQUENCER")
                    .font(VintageTheme.monoTitle)
                    .foregroundColor(VintageTheme.textAmber)
                Text("PROG ROCK EDITION  v\(VintageTheme.appVersion)")
                    .font(VintageTheme.monoSmall)
                    .foregroundColor(VintageTheme.textSecondary)
                // Dateiname + Unsaved-Indicator
                HStack(spacing: 3) {
                    if engine.hasUnsavedChanges {
                        Circle()
                            .fill(Color.orange)
                            .frame(width: 5, height: 5)
                    }
                    Text(engine.currentPresetURL?.lastPathComponent ?? "—")
                        .font(VintageTheme.monoMedium)
                        .foregroundColor(engine.hasUnsavedChanges
                            ? Color.orange.opacity(0.9)
                            : VintageTheme.textSecondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .frame(maxWidth: 160, alignment: .leading)
                }
            }
            .padding(.leading, 16)
            .padding(.trailing, 16)

            sep

            // ── Play / Stop ───────────────────────────────────────────────
            HStack(spacing: 10) {
                Button {
                    engine.isPlaying ? engine.stop() : engine.play()
                } label: {
                    Image(systemName: engine.isPlaying ? "stop.fill" : "play.fill")
                        .font(.system(size: 15, weight: .bold))
                        .frame(width: 36, height: 36)
                        .foregroundColor(engine.isPlaying ? .black : VintageTheme.textAmber)
                        .background(
                            engine.isPlaying
                                ? VintageTheme.amber
                                : VintageTheme.stepInactive
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 5))
                        .overlay(
                            RoundedRectangle(cornerRadius: 5)
                                .stroke(VintageTheme.panelBorder, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                .help(tip(engine.isPlaying ? "Stop (Leertaste)" : "Play (Leertaste)"))

                // Running LED
                Circle()
                    .fill(engine.isPlaying ? VintageTheme.amberBright : VintageTheme.amberDim)
                    .frame(width: 10, height: 10)
                    .shadow(color: VintageTheme.amber.opacity(engine.isPlaying ? 0.9 : 0),
                            radius: 7)
                    .animation(.easeInOut(duration: 0.12), value: engine.isPlaying)
            }
            .padding(.horizontal, 14)

            sep

            // ── BPM knob + fine adjust ────────────────────────────────────
            KnobView(label: "BPM", value: bpmBinding,
                     range: 20...300, size: 48,
                     accentColor: VintageTheme.amber)
                .padding(.horizontal, 6)

            VStack(spacing: 2) {
                Button("▲") { engine.bpm = min(300, engine.bpm + 1) }
                    .buttonStyle(.plain)
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(VintageTheme.textSecondary)

                Text(String(format: "%.1f", engine.bpm))
                    .font(VintageTheme.monoLarge)
                    .foregroundColor(VintageTheme.textAmber)
                    .frame(width: 54)
                    .monospacedDigit()

                Button("▼") { engine.bpm = max(20, engine.bpm - 1) }
                    .buttonStyle(.plain)
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(VintageTheme.textSecondary)
            }
            .padding(.trailing, 6)

            Button("TAP") { tapTempo() }
                .buttonStyle(VintageSmallButtonStyle(isActive: false, accent: VintageTheme.amber))
                .padding(.trailing, 10)
                .help(tip("Tap Tempo: 2× oder öfter klicken um BPM zu ermitteln"))

            sep

            // ── Swing ─────────────────────────────────────────────────────
            KnobView(label: "SWING", value: swingBinding,
                     range: 0...100, size: 36,
                     accentColor: VintageTheme.amber)
                .padding(.horizontal, 10)
                .help(tip("Swing: 0% = gerade, 100% = maximaler Swing (ungerade Steps werden verzögert)"))

            sep

            // ── Patterns ──────────────────────────────────────────────────
            VStack(spacing: 3) {
                Text("PATTERN")
                    .font(VintageTheme.monoSmall)
                    .foregroundColor(VintageTheme.textSecondary)
                HStack(spacing: 4) {
                    ForEach(0..<4) { i in
                        Button(["A","B","C","D"][i]) { engine.switchPattern(i) }
                            .buttonStyle(VintagePatternButtonStyle(
                                isActive: engine.currentPatternIndex == i,
                                isQueued: engine.queuedPatternIndex == i))
                            .help(tip(engine.queuedPatternIndex == i
                                  ? "Pattern \(["A","B","C","D"][i]) — wartet auf Track-1-Ende (cyan)"
                                  : "Pattern \(["A","B","C","D"][i]) wechseln (⌘\(i+1)) · Wechsel erfolgt am Ende von Track 1"))
                    }
                }
            }
            .padding(.horizontal, 12)

            sep

            // ── Clock mode ─────────────────────────────────────────────────
            VStack(spacing: 3) {
                Text("CLOCK")
                    .font(VintageTheme.monoSmall)
                    .foregroundColor(VintageTheme.textSecondary)
                HStack(spacing: 4) {
                    ForEach(ClockMode.allCases, id: \.self) { mode in
                        Button(mode.rawValue) { engine.clockMode = mode }
                            .buttonStyle(VintageSmallButtonStyle(
                                isActive: engine.clockMode == mode,
                                accent: mode == .external
                                    ? Color(red: 0.2, green: 0.8, blue: 1.0)
                                    : VintageTheme.amber))
                            .help(tip(mode == .external
                                ? "Externer MIDI-Clock — Sequencer synchronisiert sich auf eingehenden Clock-Signal"
                                : "Interner Clock — Sequencer läuft mit eigenem BPM-Takt"))
                    }
                }
            }
            .padding(.horizontal, 12)

            sep

            // ── MIDI Learn ────────────────────────────────────────────────
            VStack(spacing: 3) {
                Text("LEARN")
                    .font(VintageTheme.monoSmall)
                    .foregroundColor(VintageTheme.textSecondary)
                Button(engine.learnMode ? "ON" : "OFF") {
                    engine.learnMode.toggle()
                    if !engine.learnMode { engine.learnTarget = nil }
                }
                .buttonStyle(VintageSmallButtonStyle(
                    isActive: engine.learnMode,
                    accent: Color(red: 1.0, green: 1.0, blue: 0.3)))
                .help(tip(engine.learnMode
                    ? "MIDI Learn aktiv — nächste eingehende Note oder CC einem Parameter zuweisen · klicken zum Deaktivieren"
                    : "MIDI Learn — Parameter per eingehender MIDI-Nachricht belegen"))
            }
            .padding(.horizontal, 10)

            sep

            // ── Step size ─────────────────────────────────────────────────
            VStack(spacing: 3) {
                Text("STEPS")
                    .font(VintageTheme.monoSmall)
                    .foregroundColor(VintageTheme.textSecondary)
                HStack(spacing: 3) {
                    ForEach([("S", 38.0, "Klein (38 px) — mehr Steps sichtbar"),
                             ("M", 46.0, "Mittel (46 px)"),
                             ("L", 54.0, "Groß (54 px) — einfacher zu klicken")], id: \.0) { label, val, tooltip in
                        Button(label) { engine.stepDisplaySize = val }
                            .buttonStyle(VintageSmallButtonStyle(
                                isActive: engine.stepDisplaySize == val,
                                accent: VintageTheme.amber))
                            .help(tip(tooltip))
                    }
                }
            }
            .padding(.horizontal, 10)

            Spacer()

            // ── Settings ──────────────────────────────────────────────────
            Button {
                showSettings = true
            } label: {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 15))
                    .foregroundColor(VintageTheme.textSecondary)
                    .frame(width: 36, height: 36)
            }
            .buttonStyle(.plain)
            .padding(.trailing, 12)
            .help(tip("Einstellungen — MIDI-Ausgang, Step-Größe und weitere Optionen"))
            .sheet(isPresented: $showSettings) {
                SettingsView()
                    .environmentObject(engine)
            }
        }
        .frame(height: 100)
        .background(VintageTheme.panelDark)
        .overlay(
            Rectangle()
                .fill(VintageTheme.panelBorder)
                .frame(height: 1),
            alignment: .bottom
        )
    }

    // MARK: - Helpers

    private var sep: some View {
        Rectangle()
            .fill(VintageTheme.panelBorder)
            .frame(width: 1, height: 52)
            .padding(.horizontal, 2)
    }

    private func tapTempo() {
        let now = Date()
        tapTimes.append(now)
        tapTimes = tapTimes.filter { now.timeIntervalSince($0) < 3.0 }
        guard tapTimes.count >= 2 else { return }
        let intervals = zip(tapTimes, tapTimes.dropFirst())
            .map { $1.timeIntervalSince($0) }
        let avg = intervals.reduce(0, +) / Double(intervals.count)
        engine.bpm = (60.0 / avg).clamped(to: 20...300)
    }
}
