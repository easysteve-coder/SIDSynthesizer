import SwiftUI
import Combine
import AppKit

// MARK: - Scroll offset tracking

private struct ScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
}

// MARK: - TrackRowView

struct TrackRowView: View {
    @ObservedObject var track: Track
    var accentColor:  Color      = VintageTheme.amber
    var trackIndex:   Int        = 0
    var onRandomize:  (() -> Void)?
    var onClear:      (() -> Void)?
    var onDelete:     (() -> Void)?
    var onDuplicate:  (() -> Void)?

    @EnvironmentObject private var engine: SequencerEngine
    @State private var selectedSteps:  Set<Int> = []
    @State private var showMultiEdit              = false
    @State private var dragSourceIndex: Int?      = nil
    @State private var dragTargetIndex: Int?      = nil
    // Rubber-band selection
    @State private var rubberStart:   CGFloat?    = nil
    @State private var rubberEnd:     CGFloat?    = nil
    @State private var scrollOffset:  CGFloat     = 0

    // Polyrhythm stretch handle
    @State private var stretchDragBase: Int?      = nil   // cycleLengthSteps when drag started

    // Stretched step width for this track
    private var stretchedStepWidth: CGFloat {
        let base   = CGFloat(engine.stepDisplaySize)
        let ratio  = Double(track.cycleLengthSteps ?? track.stepCount) / Double(track.stepCount)
        return base * CGFloat(ratio)
    }
    private var stretchRatioLabel: String? {
        guard let cl = track.cycleLengthSteps, cl != track.stepCount else { return nil }
        return "\(track.stepCount):\(cl)"
    }

    var body: some View {
        VStack(spacing: 0) {
            // ── Main row: header + steps + expand toggle ────────────────
            HStack(spacing: 0) {
                TrackHeaderView(track: track,
                                accentColor: accentColor,
                                onRandomize: onRandomize,
                                onClear: onClear,
                                onDelete: onDelete,
                                onDuplicate: onDuplicate)
                    .frame(width: VintageTheme.trackHeaderWidth)

                // Thin separator
                Rectangle()
                    .fill(VintageTheme.panelBorder)
                    .frame(width: 1)
                    .padding(.vertical, 4)

                // Step grid with optional selection toolbar
                VStack(spacing: 0) {
                    // Selection action bar (shown when steps are selected)
                    if !selectedSteps.isEmpty {
                        HStack(spacing: 6) {
                            Text("\(selectedSteps.count) STEPS")
                                .font(VintageTheme.monoSmall)
                                .foregroundColor(Color(red: 0.3, green: 0.6, blue: 1.0))
                            Button("EDIT") { showMultiEdit = true }
                                .buttonStyle(VintageSmallButtonStyle(isActive: true,
                                    accent: Color(red: 0.3, green: 0.6, blue: 1.0)))
                                .help("Markierte Steps gemeinsam bearbeiten")
                            Button("COPY") { engine.copySteps(from: track, at: Array(selectedSteps)) }
                                .buttonStyle(VintageSmallButtonStyle(isActive: false, accent: accentColor))
                                .keyboardShortcut("c", modifiers: .command)
                                .help("Markierte Steps kopieren (⌘C)")
                            if !engine.stepClipboard.isEmpty {
                                Button("PASTE") {
                                    engine.pasteSteps(to: track, at: Array(selectedSteps).sorted())
                                    selectedSteps = []
                                }
                                .buttonStyle(VintageSmallButtonStyle(isActive: false, accent: accentColor))
                                .keyboardShortcut("v", modifiers: .command)
                                .help("Steps aus Zwischenablage einfügen (⌘V)")
                            }
                            Button("CLR") {
                                var steps = track.steps
                                for i in selectedSteps { steps[i] = Step() }
                                track.steps = steps
                                selectedSteps = []
                            }
                            .buttonStyle(VintageSmallButtonStyle(isActive: false, accent: .red))
                            .help("Markierte Steps löschen")
                            Spacer()
                            Button("✕") { selectedSteps = [] }
                                .buttonStyle(VintageSmallButtonStyle(isActive: false, accent: .gray))
                                .help("Auswahl aufheben (Esc)")
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color(red: 0.10, green: 0.14, blue: 0.22))
                    }
                    // Escape-Taste hebt Auswahl auf
                    Button("") { selectedSteps = [] }
                        .keyboardShortcut(.escape, modifiers: [])
                        .frame(width: 0, height: 0)
                        .opacity(0)
                        .disabled(selectedSteps.isEmpty)

                    HStack(spacing: 0) {
                        // ── GeometryReader für Rubber-Band (außerhalb ScrollView) ──────
                        GeometryReader { _ in
                            ZStack(alignment: .topLeading) {
                                // ScrollView — enthält NUR Step-Buttons + BPM-Raster
                                ScrollView(.horizontal, showsIndicators: false) {
                                    ZStack(alignment: .topLeading) {
                                        // Step-Buttons — BPM-Raster liegt als echtes Background darunter
                                        HStack(spacing: VintageTheme.stepSpacing) {
                                                ForEach(0..<track.stepCount, id: \.self) { i in
                                                    let isSource = dragSourceIndex == i
                                                    let isTarget = dragTargetIndex == i
                                                                  && dragSourceIndex != nil
                                                                  && dragSourceIndex != i

                                                    StepButtonView(track: track,
                                                                   index: i,
                                                                   trackIndex: trackIndex,
                                                                   isCurrentStep: i == track.displayStep,
                                                                   isSelected: selectedSteps.contains(i),
                                                                   accentColor: accentColor,
                                                                   size: CGFloat(engine.stepDisplaySize),
                                                                   width: stretchedStepWidth,
                                                                   onToggleSelect: {
                                                                       if selectedSteps.contains(i) {
                                                                           selectedSteps.remove(i)
                                                                       } else {
                                                                           selectedSteps.insert(i)
                                                                       }
                                                                   })
                                                    .opacity(isSource ? 0.35 : 1.0)
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 6)
                                                            .stroke(Color.white.opacity(0.85), lineWidth: 2)
                                                            .opacity(isTarget ? 1 : 0)
                                                    )
                                                    .simultaneousGesture(
                                                        DragGesture(minimumDistance: 8)
                                                            .onChanged { value in
                                                                if dragSourceIndex == nil { dragSourceIndex = i }
                                                                rubberStart = nil; rubberEnd = nil
                                                                let sw = stretchedStepWidth + VintageTheme.stepSpacing
                                                                let delta = Int(round(value.translation.width / sw))
                                                                dragTargetIndex = max(0, min(
                                                                    track.stepCount - 1,
                                                                    (dragSourceIndex ?? i) + delta))
                                                            }
                                                            .onEnded { _ in
                                                                defer {
                                                                    dragSourceIndex = nil
                                                                    dragTargetIndex = nil
                                                                }
                                                                guard let src = dragSourceIndex,
                                                                      let tgt = dragTargetIndex,
                                                                      src != tgt else { return }
                                                                let copy = NSEvent.modifierFlags.contains(.option)
                                                                var steps = track.steps
                                                                if copy { steps[tgt] = steps[src] }
                                                                else    { steps.swapAt(src, tgt)  }
                                                                track.steps = steps
                                                            }
                                                    )
                                                }
                                            }
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 6)
                                            .background(
                                                BPMGridView(
                                                    naturalStepWidth: CGFloat(engine.stepDisplaySize) + VintageTheme.stepSpacing)
                                            )
                                    }
                                    .background(
                                        GeometryReader { inner in
                                            Color.clear.preference(
                                                key: ScrollOffsetKey.self,
                                                value: inner.frame(in: .named("stepScroll")).minX)
                                        }
                                    )
                                }
                                .coordinateSpace(name: "stepScroll")
                                .onPreferenceChange(ScrollOffsetKey.self) { scrollOffset = $0 }

                                // Rubber-band Rechteck
                                if let x1 = rubberStart, let x2 = rubberEnd {
                                    let left  = min(x1, x2)
                                    let width = max(4, abs(x2 - x1))
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(Color(red: 0.2, green: 0.5, blue: 1.0).opacity(0.15))
                                        .overlay(RoundedRectangle(cornerRadius: 3)
                                            .stroke(Color(red: 0.3, green: 0.6, blue: 1.0).opacity(0.65),
                                                    lineWidth: 1))
                                        .frame(width: width, height: CGFloat(engine.stepDisplaySize))
                                        .offset(x: left, y: 6)
                                        .allowsHitTesting(false)
                                }
                            }
                            .gesture(
                                DragGesture(minimumDistance: 8, coordinateSpace: .local)
                                    .onChanged { value in
                                        guard dragSourceIndex == nil else { return }
                                        if rubberStart == nil {
                                            selectedSteps = []
                                            rubberStart = value.startLocation.x
                                        }
                                        rubberEnd = value.location.x
                                        let padding: CGFloat = 8
                                        let stepW = stretchedStepWidth + VintageTheme.stepSpacing
                                        let contentX1 = min(rubberStart!, rubberEnd!) - padding + (-scrollOffset)
                                        let contentX2 = max(rubberStart!, rubberEnd!) - padding + (-scrollOffset)
                                        let s = max(0, Int(contentX1 / stepW))
                                        let e = min(track.stepCount - 1, Int(contentX2 / stepW))
                                        if s <= e { selectedSteps = Set(s...e) }
                                    }
                                    .onEnded { _ in rubberStart = nil; rubberEnd = nil }
                            )
                        }
                        // Explizite Höhe = Anker für GeometryReader.
                        // Rubber-band greift dank contentShape auch unterhalb der Step-Buttons.
                        .frame(height: CGFloat(engine.stepDisplaySize) + 12)
                        .frame(maxWidth: .infinity)
                        .contentShape(Rectangle())

                        // ── Stretch+Step Handle — AUSSERHALB der ScrollView ──────────
                        // Kein Gesture-Konflikt mit ScrollView → kein Springen beim Drag.
                        StretchHandleView(track: track,
                                          accentColor: accentColor,
                                          baseStepWidth: CGFloat(engine.stepDisplaySize))
                            .frame(width: 32)
                            .frame(height: CGFloat(engine.stepDisplaySize) + 12)
                    }
                }
                .sheet(isPresented: $showMultiEdit) {
                    MultiStepEditView(track: track,
                                      indices: Array(selectedSteps).sorted(),
                                      accentColor: accentColor)
                        .environmentObject(engine)
                        .onDisappear { selectedSteps = [] }
                }

                // Expand / collapse CC rows
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        track.isExpanded.toggle()
                    }
                } label: {
                    Image(systemName: track.isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(
                            track.isExpanded ? accentColor : VintageTheme.textSecondary
                        )
                        .frame(width: 36, height: 54)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .padding(.trailing, 4)
            }

            // ── CC rows (collapsible) ────────────────────────────────────
            if track.isExpanded {
                Rectangle()
                    .fill(VintageTheme.panelBorder)
                    .frame(height: 1)
                    .padding(.leading, VintageTheme.trackHeaderWidth)

                CCRowView(track: track, ccSlot: 1, accentColor: accentColor)

                Rectangle()
                    .fill(VintageTheme.panelBorder)
                    .frame(height: 1)
                    .padding(.leading, VintageTheme.trackHeaderWidth)

                CCRowView(track: track, ccSlot: 2, accentColor: accentColor)
            }
        }
        .background(VintageTheme.panel)
        .clipShape(RoundedRectangle(cornerRadius: 7))
        .overlay(
            RoundedRectangle(cornerRadius: 7)
                .stroke(VintageTheme.panelBorder, lineWidth: 1)
        )
    }
}

// MARK: - Track header (left panel)

private struct TrackHeaderView: View {
    @ObservedObject var track: Track
    var accentColor:   Color
    var onRandomize:   (() -> Void)?
    var onClear:       (() -> Void)?
    var onDelete:      (() -> Void)?
    var onDuplicate:   (() -> Void)?

    @Environment(\.undoManager) private var undoManager
    @FocusState private var nameFocused: Bool
    @State private var showScalePicker = false
    @State private var showFeelPopover = false

    private func directionTooltip(_ dir: PlayDirection) -> String {
        switch dir {
        case .forward:  return "Vorwärts: Step 1 → N"
        case .reverse:  return "Rückwärts: Step N → 1"
        case .pingPong: return "Ping-Pong: 1→N→1→N…"
        case .random:   return "Zufällig: Steps in zufälliger Reihenfolge"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {

            // ── Zeile 1: ● Name  ·  m · s · ⎘ · × ─────────────────────
            HStack(spacing: 4) {
                Circle().fill(accentColor).frame(width: 6, height: 6)

                TextField("Name", text: $track.name)
                    .font(VintageTheme.monoBold)
                    .foregroundColor(accentColor)
                    .textFieldStyle(.plain)
                    .frame(maxWidth: .infinity)
                    .focused($nameFocused)
                    .onSubmit { nameFocused = false }

                Button(track.isMuted ? "M" : "m") { track.isMuted.toggle() }
                    .buttonStyle(VintageSmallButtonStyle(isActive: track.isMuted, accent: .orange))
                    .help(track.isMuted ? "Track stumm (klicken zum Einschalten)" : "Track stummschalten")
                Button(track.isSolo ? "S" : "s") { track.isSolo.toggle() }
                    .buttonStyle(VintageSmallButtonStyle(isActive: track.isSolo,
                        accent: Color(red: 0.9, green: 0.9, blue: 0.1)))
                    .help(track.isSolo ? "Solo aktiv (alle anderen stumm)" : "Nur diesen Track Solo spielen")
                if let onDuplicate {
                    Button("⎘") { onDuplicate() }
                        .font(.system(size: 11)).foregroundColor(VintageTheme.textSecondary)
                        .buttonStyle(.plain).help("Duplicate track")
                }
                if let onDelete {
                    Button("×") { onDelete() }
                        .font(.system(size: 12, weight: .bold)).foregroundColor(VintageTheme.textSecondary)
                        .buttonStyle(.plain).help("Delete track")
                }
            }

            // ── Zeile 2: Direction-Buttons · CH ±──────────────────────
            HStack(spacing: 0) {
                // Segmented direction bar
                HStack(spacing: 0) {
                    ForEach(PlayDirection.allCases, id: \.self) { dir in
                        let isActive = track.direction == dir
                        Button(dir.rawValue) { track.direction = dir }
                            .font(.system(size: 9, weight: isActive ? .bold : .regular,
                                          design: .monospaced))
                            .lineLimit(1)
                            .foregroundColor(isActive ? .black : VintageTheme.textSecondary)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 3)
                            .background(isActive ? accentColor : VintageTheme.stepInactive)
                            .buttonStyle(.plain)
                            .help(directionTooltip(dir))
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .overlay(RoundedRectangle(cornerRadius: 4)
                    .stroke(accentColor.opacity(0.4), lineWidth: 1))

                Spacer()

                // Channel — Popup-Menü
                Text("CH").font(VintageTheme.monoSmall).foregroundColor(VintageTheme.textSecondary)
                    .padding(.trailing, 2)
                Picker("", selection: $track.midiChannel) {
                    ForEach(1...16, id: \.self) { ch in
                        Text(ch == 10 ? "10 ◆" : "\(ch)").tag(ch)
                    }
                }
                .labelsHidden()
                .controlSize(.small)
                .frame(width: 58)
                .help("MIDI-Kanal · 10 ◆ = GM Drums")
            }

            // ── Zeile 3: FEEL · SCL  ·  RND · CLR ──────────────────────
            HStack(spacing: 4) {
                let ms = Int(track.timingOffset * 1000)
                Button {
                    showFeelPopover = true
                } label: {
                    Text(ms == 0 ? "FEEL" : (ms > 0 ? "+\(ms)ms" : "\(ms)ms"))
                        .font(VintageTheme.monoSmall)
                }
                .buttonStyle(VintageSmallButtonStyle(isActive: ms != 0, accent: accentColor))
                .popover(isPresented: $showFeelPopover, arrowEdge: .bottom) {
                    FeelPopover(track: track, accentColor: accentColor)
                }

                let scaleActive = track.scaleIndex > 0
                Button(scaleActive
                    ? "\(Track.noteNames[track.scaleRoot]) \(Track.scales[track.scaleIndex].shortName)"
                    : "SCL") {
                    showScalePicker = true
                }
                .buttonStyle(VintageSmallButtonStyle(isActive: scaleActive, accent: accentColor))
                .popover(isPresented: $showScalePicker, arrowEdge: .bottom) {
                    ScalePickerPopover(track: track, accentColor: accentColor)
                }

                Spacer()

                Button("RND") {
                    let old = track.steps
                    undoManager?.registerUndo(withTarget: track) { $0.steps = old }
                    undoManager?.setActionName("Randomize")
                    onRandomize?()
                }
                .buttonStyle(VintageSmallButtonStyle(isActive: false, accent: accentColor))
                .help("Steps zufällig belegen")
                Button("CLR") {
                    let old = track.steps
                    undoManager?.registerUndo(withTarget: track) { $0.steps = old }
                    undoManager?.setActionName("Clear")
                    onClear?()
                }
                .buttonStyle(VintageSmallButtonStyle(isActive: false, accent: .red))
                .help("Alle Steps dieses Tracks löschen")
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(maxHeight: .infinity)
    }
}

// MARK: - Feel popover (Drehknopf für Timing-Offset)

private struct FeelPopover: View {
    @ObservedObject var track: Track
    var accentColor: Color

    var body: some View {
        VStack(spacing: 10) {
            Text("FEEL")
                .font(VintageTheme.monoBold)
                .foregroundColor(VintageTheme.textAmber)
            KnobView(
                label: "ms",
                value: Binding(
                    get: { track.timingOffset * 1000 },
                    set: { track.timingOffset = max(-0.05, min(0.05, $0 / 1000)) }
                ),
                range: -50...50,
                size: 64,
                accentColor: accentColor
            )
            HStack(spacing: 6) {
                Text("− pushed")
                    .font(.system(size: 8, design: .monospaced))
                    .foregroundColor(VintageTheme.textSecondary)
                Spacer()
                Text("laid back +")
                    .font(.system(size: 8, design: .monospaced))
                    .foregroundColor(VintageTheme.textSecondary)
            }
            Button("RESET") { track.timingOffset = 0 }
                .buttonStyle(VintageSmallButtonStyle(isActive: false, accent: .gray))
        }
        .padding(14)
        .background(VintageTheme.panelDark)
        .frame(width: 140)
        .preferredColorScheme(.dark)
    }
}

// MARK: - CC row (one per CC slot, shown when expanded)

private struct CCRowView: View {
    @ObservedObject var track: Track
    let ccSlot:      Int     // 1 or 2
    var accentColor: Color
    @EnvironmentObject private var engine: SequencerEngine

    private var ccLabel: String { ccSlot == 1 ? track.cc1Label : track.cc2Label }

    var body: some View {
        HStack(spacing: 0) {
            // Label column (aligned with header)
            Text(ccLabel)
                .font(VintageTheme.monoSmall)
                .foregroundColor(VintageTheme.textSecondary)
                .frame(width: VintageTheme.trackHeaderWidth)
                .frame(maxHeight: .infinity, alignment: .center)
                .padding(.leading, 10)

            Rectangle()
                .fill(VintageTheme.panelBorder)
                .frame(width: 1)
                .padding(.vertical, 4)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: VintageTheme.stepSpacing) {
                    ForEach(0..<track.stepCount, id: \.self) { i in
                        let binding = Binding<Double>(
                            get: {
                                Double(ccSlot == 1 ? track.steps[i].cc1Value
                                                   : track.steps[i].cc2Value)
                            },
                            set: { v in
                                var updated = track.steps
                                if ccSlot == 1 { updated[i].cc1Value = Int(v) }
                                else           { updated[i].cc2Value = Int(v) }
                                track.steps = updated
                            }
                        )
                        let kSize = max(20, CGFloat(engine.stepDisplaySize) - 16)
                        KnobView(
                            label: "\(i + 1)",
                            value: binding,
                            range: 0...127,
                            size: kSize,
                            accentColor: accentColor
                        )
                        .frame(width: CGFloat(engine.stepDisplaySize))
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
            }
        }
        .frame(height: VintageTheme.ccRowHeight)
    }
}

// MARK: - Scale picker popover

private struct ScalePickerPopover: View {
    @ObservedObject var track: Track
    var accentColor: Color
    private let rootNames = ["C","C#","D","D#","E","F","F#","G","G#","A","A#","B"]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("TONART / SCALE")
                .font(VintageTheme.monoBold)
                .foregroundColor(VintageTheme.textAmber)

            // Root note
            VStack(alignment: .leading, spacing: 4) {
                Text("GRUNDTON").font(VintageTheme.monoSmall).foregroundColor(VintageTheme.textSecondary)
                HStack(spacing: 3) {
                    ForEach(0..<12, id: \.self) { i in
                        Button(rootNames[i]) { track.scaleRoot = i }
                            .buttonStyle(VintageSmallButtonStyle(
                                isActive: track.scaleRoot == i, accent: accentColor))
                            .opacity(rootNames[i].contains("#") ? 0.75 : 1.0)
                    }
                }
            }

            // Scale type
            VStack(alignment: .leading, spacing: 4) {
                Text("MODUS").font(VintageTheme.monoSmall).foregroundColor(VintageTheme.textSecondary)
                let cols = [GridItem(.adaptive(minimum: 90))]
                LazyVGrid(columns: cols, alignment: .leading, spacing: 4) {
                    ForEach(Track.scales.indices, id: \.self) { i in
                        Button(Track.scales[i].name) {
                            track.scaleIndex = i
                        }
                        .buttonStyle(VintageSmallButtonStyle(
                            isActive: track.scaleIndex == i, accent: accentColor))
                    }
                }
            }
        }
        .padding(14)
        .background(VintageTheme.panelDark)
        .frame(width: 300)
        .preferredColorScheme(.dark)
    }
}

// MARK: - BPM Grid

/// Zeichnet ein Viertelnoten-Raster als Hintergrund für eine Step-Lane.
/// naturalStepWidth = ungestreckter Step (16tel-Note).
/// Zeichnet ein festes Viertelnoten-Raster als Background der Step-Lane.
/// · Liegt als .background() hinter dem Step-HStack → keine Geometrie-Konflikte
/// · size.width kommt vom Canvas (= HStack-Breite inkl. Padding) → kein eigenes frame(width:)
/// · xOffset = horizontales Padding der Step-HStack → Linien fluchten mit Step-Grenzen
/// · Linien gehen bis ans Ende der Canvas-Breite, auch bei >16 Steps oder Polyrhythmus
private struct BPMGridView: View {
    var naturalStepWidth: CGFloat  // (stepDisplaySize + stepSpacing) — ungestreckt, fix

    var body: some View {
        Canvas { ctx, size in
            // Die Step-HStack hat .padding(.horizontal, 8) — diesen Offset übernehmen wir,
            // damit die Beat-Linien exakt an den Step-Grenzen liegen.
            let xOffset: CGFloat = 8

            var i = 1
            while true {
                // Linie nach Step i: am rechten Rand von Step i
                let x = xOffset + naturalStepWidth * CGFloat(i) - VintageTheme.stepSpacing / 2
                guard x < size.width else { break }

                let isBar  = i % 16 == 0
                let isBeat = i % 4  == 0

                let lineColor: Color
                let lineWidth: CGFloat
                if isBar {
                    lineColor = Color(red: 0.70, green: 0.55, blue: 0.25).opacity(0.85)
                    lineWidth = 1.5
                } else if isBeat {
                    lineColor = Color(red: 0.50, green: 0.38, blue: 0.18).opacity(0.70)
                    lineWidth = 1.0
                } else {
                    i += 1
                    continue
                }

                var path = Path()
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: size.height))
                ctx.stroke(path, with: .color(lineColor),
                           style: StrokeStyle(lineWidth: lineWidth))
                i += 1
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Stretch + Step-Count Handle (kombiniert)

/// Zweigeteilter Handle rechts neben der Lane (außerhalb ScrollView):
/// · Obere Hälfte: vertikaler Drag (↑ mehr, ↓ weniger) → Polyrhythmus (cycleLengthSteps)
/// · Untere Hälfte: vertikaler Drag (↑ mehr, ↓ weniger) → Anzahl Steps
///
/// Außerhalb der ScrollView → kein Gesture-Konflikt, kein Springen.
/// Basis beim ersten onChanged-Event einfrieren → initiale Translation herausgerechnet.
private struct StretchHandleView: View {
    @ObservedObject var track: Track
    var accentColor:    Color
    var baseStepWidth:  CGFloat
    @EnvironmentObject private var engine: SequencerEngine

    // Drag-State Stretch — wird beim Drag-Start eingefroren
    @State private var dragBaseSteps: Int?    = nil
    @State private var dragBaseWidth: CGFloat? = nil
    // Drag-State Step-Count
    @State private var stepDragBase:  Int?    = nil

    private var isStretched: Bool { track.cycleLengthSteps != nil }

    var body: some View {
        VStack(spacing: 0) {

            // ── Obere Hälfte: Stretch ────────────────────────────────────
            VStack(spacing: 2) {
                Spacer(minLength: 0)

                if let label = ratioLabel {
                    Text(label)
                        .font(.system(size: 7, weight: .bold, design: .monospaced))
                        .foregroundColor(accentColor)
                        .lineLimit(1)
                }

                // Griffleiste
                RoundedRectangle(cornerRadius: 2)
                    .fill(isStretched ? accentColor : VintageTheme.textDim.opacity(0.5))
                    .frame(width: 5, height: 22)
                    .overlay(
                        VStack(spacing: 4) {
                            ForEach(0..<3, id: \.self) { _ in
                                RoundedRectangle(cornerRadius: 1)
                                    .fill(Color.black.opacity(0.35))
                                    .frame(width: 5, height: 1)
                            }
                        }
                    )

                if isStretched {
                    Button("↺") {
                        track.cycleLengthSteps = nil
                        engine.hasUnsavedChanges = true
                    }
                    .font(.system(size: 8))
                    .foregroundColor(VintageTheme.textSecondary)
                    .buttonStyle(.plain)
                    .help("Stretch zurücksetzen (1:1)")
                }

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 2)
                    .onChanged { value in
                        // Vertikaler Drag: hoch = mehr, runter = weniger.
                        // Sensitivität: 18px pro Schritt.
                        // Basis beim ersten Event einfrieren um Sprung zu vermeiden.
                        let sensitivity: CGFloat = 18
                        if dragBaseSteps == nil {
                            dragBaseWidth = sensitivity
                            let initialDelta = -Int((value.translation.height / sensitivity).rounded())
                            dragBaseSteps = (track.cycleLengthSteps ?? track.stepCount) - initialDelta
                        }
                        let delta = -Int((value.translation.height / dragBaseWidth!).rounded())
                        let raw   = max(1, dragBaseSteps! + delta)
                        track.cycleLengthSteps = raw == track.stepCount ? nil : raw
                        engine.hasUnsavedChanges = true
                    }
                    .onEnded { _ in
                        // Snap auf musikalisch sinnvollen Wert erst beim Loslassen
                        if let c = track.cycleLengthSteps {
                            let snapped = snapCycle(c)
                            track.cycleLengthSteps = snapped == track.stepCount ? nil : snapped
                        }
                        dragBaseSteps = nil
                        dragBaseWidth = nil
                    }
            )
            .help(isStretched
                  ? "Polyrhythmus \(ratioLabel ?? "") — ↑↓ ziehen zum Anpassen · ↺ = 1:1"
                  : "↑ ziehen: Cycle verlängern (z.B. 7:8, 5:4) · ↓ kürzen · Rastet beim Loslassen ein")

            // ── Trennlinie ───────────────────────────────────────────────
            Rectangle()
                .fill(VintageTheme.panelBorder)
                .frame(height: 1)
                .padding(.horizontal, 3)

            // ── Untere Hälfte: Step-Anzahl ───────────────────────────────
            VStack(spacing: 0) {
                Button("+") { if track.stepCount < 64 { track.stepCount += 1 } }
                    .buttonStyle(.plain)
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(VintageTheme.textSecondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .help("Step hinzufügen · oder ↑ ziehen")

                Text("\(track.stepCount)")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(VintageTheme.textAmber)
                    .monospacedDigit()

                Button("−") { if track.stepCount > 1 { track.stepCount -= 1 } }
                    .buttonStyle(.plain)
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(VintageTheme.textSecondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .help("Step entfernen · oder ↓ ziehen")
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 4)
                    .onChanged { value in
                        // Vertikaler Drag: hoch = mehr Steps, runter = weniger.
                        let sensitivity: CGFloat = 18
                        if stepDragBase == nil {
                            let init_ = -Int((value.translation.height / sensitivity).rounded())
                            stepDragBase = track.stepCount - init_
                        }
                        let delta = -Int((value.translation.height / sensitivity).rounded())
                        track.stepCount = min(64, max(1, stepDragBase! + delta))
                        engine.hasUnsavedChanges = true
                    }
                    .onEnded { _ in stepDragBase = nil }
            )
        }
        .frame(width: 28)
    }

    /// Snap auf musikalisch sinnvolle Werte — wird nur auf onEnded angewendet.
    private func snapCycle(_ raw: Int) -> Int {
        let n = track.stepCount
        var targets = Set<Int>([n])
        for d in -3...3 { targets.insert(n + d) }
        for v in [2, 3, 4, 5, 6, 7, 8, 9, 10, 12, 14, 16] { targets.insert(v) }
        targets.insert(n * 2)
        if n % 2 == 0 { targets.insert(n / 2) }
        let lo = max(1, n / 2)
        let hi = n * 2
        let valid = targets.filter { $0 >= lo && $0 <= hi }
        return valid.min(by: { abs($0 - raw) < abs($1 - raw) }) ?? n
    }

    private var ratioLabel: String? {
        guard let cl = track.cycleLengthSteps, cl != track.stepCount else { return nil }
        return "\(track.stepCount):\(cl)"
    }
}
