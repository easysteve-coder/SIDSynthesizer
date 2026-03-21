import SwiftUI

struct StepDetailView: View {
    @ObservedObject var track: Track
    let index:       Int
    var accentColor: Color = VintageTheme.amber

    @Environment(\.dismiss)     private var dismiss
    @Environment(\.undoManager) private var undoManager

    private var step: Step { track.steps[index] }

    /// Modify a step field; registers undo, triggers @Published on track.steps
    private func modify(_ transform: (inout Step) -> Void) {
        let old = track.steps
        var updated = track.steps
        transform(&updated[index])
        undoManager?.registerUndo(withTarget: track) { $0.steps = old }
        undoManager?.setActionName("Step ändern")
        track.steps = updated
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {

            // ── Header ─────────────────────────────────────────────────────
            HStack {
                Circle().fill(accentColor).frame(width: 8, height: 8)
                    .shadow(color: accentColor.opacity(0.8), radius: 4)
                VStack(alignment: .leading, spacing: 1) {
                    Text("STEP \(index + 1)")
                        .font(VintageTheme.monoBold)
                        .foregroundColor(VintageTheme.textAmber)
                    if track.midiChannel == 10 {
                        Text(GMDrumMap.name(for: step.note) ?? step.noteName)
                            .font(VintageTheme.monoSmall).foregroundColor(accentColor.opacity(0.85))
                    } else {
                        Text(step.chordName)
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                            .foregroundColor(accentColor)
                    }
                }
                Spacer()
                Toggle("ACTIVE", isOn: Binding(
                    get: { step.isActive },
                    set: { v in modify { $0.isActive = v } }
                ))
                .toggleStyle(.switch).tint(accentColor)
                .font(VintageTheme.monoSmall)
            }

            Rectangle().fill(VintageTheme.panelBorder).frame(height: 1)

            // ── Dynamics ────────────────────────────────────────────────────
            // ROOT-Knob transponiert den gesamten Akkord
            HStack(spacing: 18) {
                KnobView(label: "ROOT",
                         value: Binding(
                            get: { Double(step.note) },
                            set: { v in modify { s in
                                let diff = Int(v) - s.note
                                let shifted = s.notes.map { $0 + diff }
                                // Nur transponieren wenn alle Noten im gültigen Bereich bleiben
                                guard shifted.allSatisfy({ (0...127).contains($0) }) else { return }
                                s.notes = shifted.sorted()
                            }}),
                         range: 0...127, size: 44, accentColor: accentColor)

                KnobView(label: "VEL",
                         value: Binding(get: { Double(step.velocity) },
                                        set: { v in modify { $0.velocity = Int(v) } }),
                         range: 1...127, size: 44, accentColor: accentColor)

                GateSelectorView(gate: Binding(
                    get: { step.gate },
                    set: { v in modify { $0.gate = v } }),
                    accentColor: accentColor)

                KnobView(label: "PROB%",
                         value: Binding(get: { step.probability * 100 },
                                        set: { v in modify { $0.probability = v / 100.0 } }),
                         range: 0...100, size: 44, accentColor: accentColor)
            }

            Rectangle().fill(VintageTheme.panelBorder).frame(height: 1)

            // ── CC + Ratchet ────────────────────────────────────────────────
            HStack(spacing: 18) {
                KnobView(label: track.cc1Label,
                         value: Binding(get: { Double(step.cc1Value) },
                                        set: { v in modify { $0.cc1Value = Int(v) } }),
                         range: 0...127, size: 44, accentColor: accentColor)

                KnobView(label: track.cc2Label,
                         value: Binding(get: { Double(step.cc2Value) },
                                        set: { v in modify { $0.cc2Value = Int(v) } }),
                         range: 0...127, size: 44, accentColor: accentColor)

                Spacer()

                VStack(alignment: .leading, spacing: 5) {
                    Text("RATCHET")
                        .font(VintageTheme.monoSmall)
                        .foregroundColor(VintageTheme.textSecondary)
                    HStack(spacing: 5) {
                        ForEach(RatchetCount.allCases) { r in
                            Button(r.label) { modify { $0.ratchet = r } }
                                .buttonStyle(VintageSmallButtonStyle(
                                    isActive: step.ratchet == r,
                                    accent: accentColor))
                        }
                    }
                }
            }

            // ── Akkord / Drum picker ────────────────────────────────────────
            if track.midiChannel == 10 {
                VStack(alignment: .leading, spacing: 4) {
                    Text("DRUM SOUND")
                        .font(VintageTheme.monoSmall)
                        .foregroundColor(VintageTheme.textSecondary)
                    DrumPickerGrid(
                        note: Binding(get: { step.note },
                                      set: { v in modify { $0.note = v } }),
                        accentColor: accentColor)
                }
            } else {
                PianoKeyboardView(
                    notes: Binding(
                        get: { step.notes },
                        set: { v in modify { $0.notes = v.isEmpty ? [60] : v } }),
                    accentColor: accentColor,
                    track: track,
                    onUnison: step.notes.count > 1 ? { modify { $0.notes = [$0.note] } } : nil)
            }
        }
        .padding(16)
        .background(VintageTheme.panelDark)
        .frame(width: track.midiChannel == 10 ? 480 : 660)
        .preferredColorScheme(.dark)
        // Enter schließt das Popover
        .background(
            Button("") { dismiss() }
                .keyboardShortcut(.return, modifiers: [])
                .opacity(0).frame(width: 0, height: 0)
        )
    }
}

// MARK: - Multi-step editor

struct MultiStepEditView: View {
    @ObservedObject var track: Track
    let indices: [Int]
    var accentColor: Color
    @EnvironmentObject private var engine: SequencerEngine
    @Environment(\.dismiss) private var dismiss

    // Local override values — nil = "not changed yet"
    @State private var noteVal: Double = 64
    @State private var velVal:  Double = 100
    @State private var gateVal: Double = 0.5   // Gate in Step-Vielfachen (0.5 = 1/32)
    @State private var probVal: Double = 100

    private func applyAll(_ transform: (inout Step) -> Void) {
        var steps = track.steps
        for i in indices { transform(&steps[i]) }
        track.steps = steps
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {

            // Header
            HStack {
                Circle().fill(accentColor).frame(width: 8, height: 8)
                    .shadow(color: accentColor.opacity(0.8), radius: 4)
                Text("\(indices.count) STEPS — BULK EDIT")
                    .font(VintageTheme.monoBold)
                    .foregroundColor(VintageTheme.textAmber)
                Spacer()
                Button("DONE") { dismiss() }
                    .buttonStyle(VintageSmallButtonStyle(isActive: false, accent: accentColor))
            }

            Rectangle().fill(VintageTheme.panelBorder).frame(height: 1)

            // Note / Drum picker
            VStack(alignment: .leading, spacing: 4) {
                Text(track.midiChannel == 10 ? "DRUM SOUND  →  alle markierten Steps" : "NOTE  →  alle markierten Steps")
                    .font(VintageTheme.monoSmall)
                    .foregroundColor(VintageTheme.textSecondary)
                if track.midiChannel == 10 {
                    DrumPickerGrid(
                        note: Binding(get: { Int(noteVal) },
                                      set: { v in noteVal = Double(v); applyAll { $0.note = v } }),
                        accentColor: accentColor)
                } else {
                    NotePickerRow(
                        note: Binding(get: { noteVal },
                                      set: { v in noteVal = v; applyAll { $0.note = Int(v) } }),
                        accentColor: accentColor)
                }
            }

            Rectangle().fill(VintageTheme.panelBorder).frame(height: 1)

            // Dynamics
            HStack(spacing: 18) {
                VStack(spacing: 2) {
                    KnobView(label: "VEL",
                             value: Binding(get: { velVal },
                                            set: { v in velVal = v; applyAll { $0.velocity = Int(v) } }),
                             range: 1...127, size: 44, accentColor: accentColor)
                }
                GateSelectorView(gate: Binding(
                    get: { gateVal },
                    set: { v in gateVal = v; applyAll { $0.gate = v } }),
                    accentColor: accentColor)
                VStack(spacing: 2) {
                    KnobView(label: "PROB%",
                             value: Binding(get: { probVal },
                                            set: { v in probVal = v; applyAll { $0.probability = v / 100 } }),
                             range: 0...100, size: 44, accentColor: accentColor)
                }
                Spacer()
            }

            Rectangle().fill(VintageTheme.panelBorder).frame(height: 1)

            // Bulk actions
            HStack(spacing: 6) {
                Button("ALLE AN")    { applyAll { $0.isActive = true  } }
                    .buttonStyle(VintageSmallButtonStyle(isActive: false, accent: accentColor))
                Button("ALLE AUS")   { applyAll { $0.isActive = false } }
                    .buttonStyle(VintageSmallButtonStyle(isActive: false, accent: .gray))
                Spacer()
                Button("KOPIEREN") { engine.copySteps(from: track, at: indices) }
                    .buttonStyle(VintageSmallButtonStyle(isActive: false, accent: accentColor))
                Button("LEEREN") { applyAll { $0 = Step() } }
                    .buttonStyle(VintageSmallButtonStyle(isActive: false, accent: .red))
            }
        }
        .padding(16)
        .background(VintageTheme.panelDark)
        .frame(width: track.midiChannel == 10 ? 460 : 400)
        .preferredColorScheme(.dark)
    }
}

// MARK: - Drum picker grid (channel 10)

private struct DrumPickerGrid: View {
    @Binding var note: Int
    var accentColor: Color

    // Groups: [label, [(note, shortName)]]
    private let groups: [(String, [(Int, String)])] = [
        ("KICK / SNARE", [(35,"Kick 2"),(36,"Kick"),(37,"Stick"),(38,"Snare"),(39,"Clap"),(40,"Snare 2")]),
        ("HI-HAT",       [(42,"HH Cls"),(44,"HH Ped"),(46,"HH Opn")]),
        ("TOMS",         [(41,"Tom FL"),(43,"Tom FH"),(45,"Tom L"),(47,"Tom LM"),(48,"Tom HM"),(50,"Tom H")]),
        ("CYMBAL",       [(49,"Crash"),(57,"Crash 2"),(51,"Ride"),(59,"Ride 2"),(52,"China"),(55,"Splash"),(56,"Cowbell")]),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(groups, id: \.0) { group in
                HStack(spacing: 4) {
                    Text(group.0)
                        .font(.system(size: 7, design: .monospaced))
                        .foregroundColor(VintageTheme.textDim)
                        .frame(width: 62, alignment: .leading)
                    ForEach(group.1, id: \.0) { midiNote, name in
                        Button(name) { note = midiNote }
                            .buttonStyle(VintageSmallButtonStyle(
                                isActive: note == midiNote,
                                accent: accentColor))
                    }
                }
            }
        }
    }
}

// MARK: - Piano keyboard (chord editor, 5 Oktaven)

private struct PianoKeyboardView: View {
    @Binding var notes: [Int]
    var accentColor: Color
    var track: Track? = nil
    var onUnison: (() -> Void)? = nil   // nil = Button nicht anzeigen

    @EnvironmentObject private var engine: SequencerEngine
    @State private var displayOctave: Int = 2   // C2–B6 als Standard (5 Oktaven)

    private let numOctaves   = 5
    private let whiteIntervals = [0, 2, 4, 5, 7, 9, 11]
    private let blackKeyData: [(semitone: Int, fraction: Double)] = [
        (1, 0.68), (3, 1.68), (6, 3.73), (8, 4.73), (10, 5.73)
    ]

    private var baseNote: Int { (displayOctave + 1) * 12 }
    private var numWhite:  Int { numOctaves * 7 }

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            // Navigation + 8va-Transpose + UNISON
            HStack(spacing: 5) {
                Button("◂") { if displayOctave > 0 { displayOctave -= 1 } }
                    .buttonStyle(VintageSmallButtonStyle(isActive: false, accent: accentColor))
                Text("C\(displayOctave)–B\(displayOctave + numOctaves - 1)")
                    .font(VintageTheme.monoSmall).foregroundColor(VintageTheme.textAmber)
                    .frame(width: 82, alignment: .center)
                Button("▸") { if displayOctave < 5 { displayOctave += 1 } }
                    .buttonStyle(VintageSmallButtonStyle(isActive: false, accent: accentColor))
                Spacer()
                Text("8va:")
                    .font(VintageTheme.monoSmall).foregroundColor(VintageTheme.textSecondary)
                Button("−") {
                    let s = notes.map { $0 - 12 }
                    if s.allSatisfy({ (0...127).contains($0) }) { notes = s.sorted() }
                }
                .buttonStyle(VintageSmallButtonStyle(isActive: false, accent: accentColor))
                Button("+") {
                    let s = notes.map { $0 + 12 }
                    if s.allSatisfy({ (0...127).contains($0) }) { notes = s.sorted() }
                }
                .buttonStyle(VintageSmallButtonStyle(isActive: false, accent: accentColor))
                if let unison = onUnison {
                    Divider().frame(height: 16).padding(.horizontal, 2)
                    Button("UNISON") { unison() }
                        .buttonStyle(VintageSmallButtonStyle(isActive: false, accent: .gray))
                }
            }

            // Tastatur-Rahmen (schwarz wie echtes Piano)
            ZStack {
                RoundedRectangle(cornerRadius: 5)
                    .fill(Color(white: 0.08))

                GeometryReader { geo in
                    let gap: CGFloat = 1.0
                    let wkW = (geo.size.width - CGFloat(numWhite - 1) * gap) / CGFloat(numWhite)
                    let wkH = geo.size.height
                    let bkW = wkW * 0.62
                    let bkH = wkH * 0.60

                    ZStack(alignment: .topLeading) {
                        // Weiße Tasten
                        HStack(spacing: gap) {
                            ForEach(0 ..< numWhite, id: \.self) { wi in
                                let oct  = wi / 7
                                let si   = wi % 7
                                let midi = baseNote + oct * 12 + whiteIntervals[si]
                                let ok   = midi <= 127
                                let inC  = ok && notes.contains(midi)
                                let inSc = !ok || (track?.noteInScale(midi) ?? true)
                                let isC  = whiteIntervals[si] == 0   // C-Taste

                                ZStack(alignment: .bottom) {
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(inC
                                            ? LinearGradient(colors: [accentColor.opacity(0.85), accentColor],
                                                             startPoint: .top, endPoint: .bottom)
                                            : LinearGradient(colors: [Color(white: inSc ? 0.97 : 0.78),
                                                                       Color(white: inSc ? 0.88 : 0.68)],
                                                             startPoint: .top, endPoint: .bottom))
                                    // C-Beschriftung
                                    if isC && ok {
                                        Text("C\(displayOctave + oct)")
                                            .font(.system(size: 6, design: .monospaced))
                                            .foregroundColor(inC ? .white.opacity(0.9)
                                                                  : Color(white: 0.5))
                                            .padding(.bottom, 3)
                                    }
                                }
                                .overlay(RoundedRectangle(cornerRadius: 2)
                                    .stroke(Color(white: 0.6), lineWidth: 0.5))
                                .frame(width: wkW, height: wkH)
                                .opacity(ok ? 1 : 0.15)
                            }
                        }

                        // Schwarze Tasten (Vordergrund)
                        ForEach(0 ..< numOctaves, id: \.self) { oct in
                            ForEach(0 ..< blackKeyData.count, id: \.self) { bi in
                                let bk   = blackKeyData[bi]
                                let midi = baseNote + oct * 12 + bk.semitone
                                let ok   = midi <= 127
                                let inC  = ok && notes.contains(midi)
                                let inSc = !ok || (track?.noteInScale(midi) ?? true)
                                let xCtr = (CGFloat(oct * 7) + CGFloat(bk.fraction)) * (wkW + gap)

                                RoundedRectangle(cornerRadius: 2)
                                    .fill(inC
                                        ? LinearGradient(colors: [accentColor.opacity(0.9), accentColor],
                                                         startPoint: .top, endPoint: .bottom)
                                        : LinearGradient(colors: [Color(white: 0.22), Color.black],
                                                         startPoint: .top, endPoint: .bottom))
                                    .overlay(RoundedRectangle(cornerRadius: 2)
                                        .stroke(inC ? accentColor.opacity(0.7)
                                                    : Color.gray.opacity(0.35), lineWidth: 0.5))
                                    .frame(width: bkW, height: bkH)
                                    .position(x: xCtr, y: bkH / 2)
                                    .opacity(ok ? (inSc ? 1.0 : 0.45) : 0.1)
                            }
                        }
                    }
                    // Manuelle Hit-Test-Geste (schwarze Tasten haben Priorität)
                    .gesture(
                        SpatialTapGesture()
                            .onEnded { val in
                                guard let midi = hitTest(val.location,
                                                         wkW: wkW, gap: gap, wkH: wkH,
                                                         bkW: bkW, bkH: bkH)
                                else { return }
                                previewNote(midi)
                                toggleNote(midi)
                            }
                    )
                }
                .padding(4)   // kleiner Rahmen
            }
            .frame(height: 92)

            // Tonart-Hinweis
            if let t = track, t.scaleIndex > 0 {
                Text("Tonart: \(Track.noteNames[t.scaleRoot]) \(Track.scales[t.scaleIndex].name) — abgedunkelt = außerhalb")
                    .font(.system(size: 8, design: .monospaced))
                    .foregroundColor(VintageTheme.textSecondary)
            }
        }
        .onAppear {
            if let first = notes.first {
                displayOctave = max(0, min(5, (first / 12) - 2))
            }
        }
    }

    // MARK: - Hit-Test: schwarze Tasten zuerst

    private func hitTest(_ p: CGPoint, wkW: CGFloat, gap: CGFloat, wkH: CGFloat,
                         bkW: CGFloat, bkH: CGFloat) -> Int? {
        for oct in 0 ..< numOctaves {
            for bk in blackKeyData {
                let midi  = baseNote + oct * 12 + bk.semitone
                guard midi <= 127 else { continue }
                let xCtr  = (CGFloat(oct * 7) + CGFloat(bk.fraction)) * (wkW + gap)
                let xLeft = xCtr - bkW / 2
                if CGRect(x: xLeft, y: 0, width: bkW, height: bkH).contains(p) { return midi }
            }
        }
        guard p.x >= 0, p.y >= 0, p.y <= wkH else { return nil }
        let wi = Int(p.x / (wkW + gap))
        guard wi >= 0, wi < numWhite else { return nil }
        let midi = baseNote + (wi / 7) * 12 + whiteIntervals[wi % 7]
        return midi <= 127 ? midi : nil
    }

    // MARK: - Note ein/aus-schalten + Preview

    private func previewNote(_ midi: Int) {
        let ch = track?.midiChannel ?? 1
        engine.midi.noteOn(channel: ch, note: midi, velocity: 90)
        DispatchQueue.global(qos: .userInteractive).asyncAfter(deadline: .now() + 0.35) {
            engine.midi.noteOff(channel: ch, note: midi)
        }
    }

    private func toggleNote(_ midi: Int) {
        let snapped = track?.quantizedNote(midi) ?? midi
        if notes.contains(snapped) {
            if notes.count > 1 { notes.removeAll { $0 == snapped } }
        } else {
            notes.append(snapped); notes.sort()
        }
    }
}

// MARK: - Gate selector (musikalische Notenwerte)

/// Ersetzt den GATE%-Drehknopf durch einen kompakten Selektor mit Notenbezeichnungen.
/// Zwei Zeilen: kurze Werte (stac … 1/16.) und lange Werte (1/8 … 1/1).
struct GateSelectorView: View {
    @Binding var gate: Double
    var accentColor: Color

    // Kurze Werte (sub-step bis legato)
    private let shortSteps = Step.gateSteps.filter { $0.value <= 1.5 }
    // Lange Werte (über einen Step hinaus)
    private let longSteps  = Step.gateSteps.filter { $0.value >  1.5 }

    private func isSelected(_ step: Step.GateStep) -> Bool {
        abs(gate - step.value) < 0.001
    }

    private func gateTooltip(_ s: Step.GateStep) -> String {
        let steps = s.value
        if steps < 1 {
            return "\(s.label) · \(Int(steps * 100))% eines 16tel-Steps"
        } else if steps == 1 {
            return "1/16 · Legato — füllt genau einen Step"
        } else {
            let beats = steps / 4
            if beats >= 1 {
                let b = beats == beats.rounded() ? String(Int(beats)) : String(format: "%.1f", beats)
                return "\(s.label) · \(b) Beat\(beats == 1 ? "" : "s") (\(Int(steps)) Steps)"
            }
            return "\(s.label) · \(Int(steps)) Steps lang"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("GATE  \(Step.gateLabel(gate))")
                .font(VintageTheme.monoSmall)
                .foregroundColor(VintageTheme.textSecondary)

            // Kurze Werte (staccato bis 1/16.)
            HStack(spacing: 3) {
                ForEach(shortSteps.indices, id: \.self) { i in
                    let s = shortSteps[i]
                    Button(s.label) { gate = s.value }
                        .buttonStyle(VintageSmallButtonStyle(isActive: isSelected(s), accent: accentColor))
                        .help(gateTooltip(s))
                }
            }

            // Lange Werte (1/8 bis 1/1) — hält über mehrere Steps
            HStack(spacing: 3) {
                ForEach(longSteps.indices, id: \.self) { i in
                    let s = longSteps[i]
                    Button(s.label) { gate = s.value }
                        .buttonStyle(VintageSmallButtonStyle(
                            isActive: isSelected(s),
                            accent: isSelected(s) ? accentColor : accentColor.opacity(0.7)))
                        .help(gateTooltip(s))
                }
                Spacer(minLength: 0)
            }
        }
    }
}

// MARK: - Quick note picker (Single-Note, für Bulk-Edit)

private struct NotePickerRow: View {
    @Binding var note: Double
    var accentColor: Color
    var track: Track? = nil
    private let noteNames = ["C","C#","D","D#","E","F","F#","G","G#","A","A#","B"]

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 3) {
                let octave = (Int(note) / 12) - 1
                Button("-") { note = max(0, note - 12) }
                    .buttonStyle(VintageSmallButtonStyle(isActive: false, accent: accentColor))
                Text("C\(octave)")
                    .font(VintageTheme.monoSmall).foregroundColor(VintageTheme.textAmber).frame(width: 24)
                Button("+") { note = min(127, note + 12) }
                    .buttonStyle(VintageSmallButtonStyle(isActive: false, accent: accentColor))
                Spacer().frame(width: 8)
                ForEach(0..<12, id: \.self) { semitone in
                    let candidate = (Int(note) / 12) * 12 + semitone
                    let inScale   = track?.noteInScale(candidate) ?? true
                    Button(noteNames[semitone]) {
                        let oct     = Int(note) / 12
                        let raw     = min(127, oct * 12 + semitone)
                        let snapped = track?.quantizedNote(raw) ?? raw
                        note = Double(snapped)
                    }
                    .buttonStyle(VintageSmallButtonStyle(
                        isActive: Int(note) % 12 == semitone,
                        accent: accentColor))
                    .opacity(inScale ? (noteNames[semitone].contains("#") ? 0.75 : 1.0) : 0.22)
                }
            }
            if let t = track, t.scaleIndex > 0 {
                let rootName  = Track.noteNames[t.scaleRoot]
                let scaleName = Track.scales[t.scaleIndex].name
                Text("Tonart: \(rootName) \(scaleName) — ausgegraute Noten außerhalb")
                    .font(.system(size: 8, design: .monospaced))
                    .foregroundColor(VintageTheme.textSecondary)
            }
        }
    }
}
