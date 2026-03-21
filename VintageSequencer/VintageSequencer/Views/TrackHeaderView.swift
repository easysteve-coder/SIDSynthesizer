import SwiftUI

// MARK: - Track header (left panel)

struct TrackHeaderView: View {
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

            // ── Row 1: ● Name  ·  m · s · ⎘ · × ────────────────────────
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

            // ── Row 2: Direction buttons · CH ──────────────────────────
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

                Text("CH").font(VintageTheme.monoSmall).foregroundColor(VintageTheme.textSecondary)
                    .padding(.trailing, 2)
                Picker("", selection: $track.midiChannel) {
                    ForEach(1...16, id: \.self) { ch in
                        Text(ch == 10 ? "10 ◆" : "\(ch)")
                            .font(VintageTheme.monoSmall)
                            .tag(ch)
                    }
                }
                .labelsHidden()
                .controlSize(.small)
                .font(VintageTheme.monoSmall)
                .frame(width: 58)
                .help("MIDI-Kanal · 10 ◆ = GM Drums")
            }

            // ── Row 3: FEEL · SCL  ·  RND · CLR ─────────────────────────
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

// MARK: - Feel popover

fileprivate struct FeelPopover: View {
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

// MARK: - Scale picker popover

fileprivate struct ScalePickerPopover: View {
    @ObservedObject var track: Track
    var accentColor: Color
    private let rootNames = ["C","C#","D","D#","E","F","F#","G","G#","A","A#","B"]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("TONART / SCALE")
                .font(VintageTheme.monoBold)
                .foregroundColor(VintageTheme.textAmber)

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
