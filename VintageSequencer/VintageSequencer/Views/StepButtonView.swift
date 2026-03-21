import SwiftUI
import AppKit

struct StepButtonView: View {
    @ObservedObject var track: Track
    let index: Int
    var trackIndex:      Int        = 0
    var isCurrentStep:   Bool       = false
    var isSelected:      Bool       = false
    var accentColor:     Color      = VintageTheme.amber
    var size:            CGFloat    = VintageTheme.stepSize   // Höhe + Basis-Skalierung
    var width:          CGFloat?   = nil                      // falls gesetzt: andere Breite (Stretch)
    var onToggleSelect:  (() -> Void)? = nil

    @EnvironmentObject  private var engine: SequencerEngine
    @Environment(\.undoManager) private var undoManager
    @State private var showDetail = false

    private var isLearnTarget: Bool {
        engine.learnMode &&
        engine.learnTarget?.track == trackIndex &&
        engine.learnTarget?.step  == index
    }

    private var step: Step { track.steps[index] }

    private var noteLabel: String {
        if track.midiChannel == 10,
           let drumName = GMDrumMap.name(for: step.note) { return drumName }
        return step.shortChordName   // Einzelnote: "C4", Akkord: "Cmaj7", "Dm7" etc.
    }

    private var noteLabelFontSize: CGFloat {
        let len = noteLabel.count
        if len <= 3 { return size < 44 ? 9 : 10 }
        if len <= 5 { return size < 44 ? 7 : 8  }
        return size < 44 ? 6 : 7
    }

    // Modify step via @Published array swap + Undo-Registrierung
    private func modifyStep(_ transform: (inout Step) -> Void) {
        let old = track.steps
        var updated = track.steps
        transform(&updated[index])
        undoManager?.registerUndo(withTarget: track) { $0.steps = old }
        undoManager?.setActionName("Step")
        track.steps = updated
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            RoundedRectangle(cornerRadius: 5)
                .fill(bgColor)
                .overlay(RoundedRectangle(cornerRadius: 5)
                    .stroke(borderColor, lineWidth: isCurrentStep ? 1.5 : 0.75))

            VStack(spacing: 2) {
                Circle()
                    .fill(ledColor)
                    .frame(width: 7, height: 7)
                    .shadow(color: ledColor.opacity(ledGlow), radius: ledGlowR)
                    .padding(.top, 5)

                Text(step.isActive ? noteLabel : "·")
                    .font(.system(size: track.midiChannel == 10 ? 8 : noteLabelFontSize,
                                  weight: .medium, design: .monospaced))
                    .foregroundColor(step.isActive ? VintageTheme.textPrimary : VintageTheme.textDim)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                if step.isActive && step.ratchet != .x1 {
                    Text(step.ratchet.label)
                        .font(.system(size: 7, design: .monospaced))
                        .foregroundColor(accentColor.opacity(0.8))
                }

                if step.isActive && step.probability < 1.0 {
                    Text("\(Int(step.probability * 100))%")
                        .font(.system(size: 7, design: .monospaced))
                        .foregroundColor(VintageTheme.textSecondary)
                }

                Spacer(minLength: 0)

                Rectangle()
                    .fill(step.isActive ? accentColor.opacity(0.75) : VintageTheme.stepInactive)
                    .frame(height: step.isActive ? max(2, CGFloat(step.velocity) / 127.0 * (size * 0.22)) : 2)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 4)
                    .padding(.bottom, 4)
            }
        }
        .frame(width: width ?? size, height: size)
        .overlay(
            // MIDI Learn highlight ring
            RoundedRectangle(cornerRadius: 5)
                .stroke(Color.white, lineWidth: isLearnTarget ? 2 : 0)
                .opacity(isLearnTarget ? 0.9 : 0)
        )
        .help("Klick: an/aus · ⌥+Klick: bearbeiten · ⇧+Klick: markieren")
        .onTapGesture {
            let flags  = NSEvent.modifierFlags
            let option = flags.contains(.option)
            let shift  = flags.contains(.shift)
            if option {
                showDetail = true          // ⌥+Klick = Edit
            } else if shift {
                onToggleSelect?()          // ⇧+Klick = Markieren
            } else if engine.learnMode {
                engine.setLearnTarget(track: trackIndex, step: index)
            } else if isSelected {
                onToggleSelect?()
            } else {
                modifyStep { $0.isActive.toggle() }
            }
        }
        .popover(isPresented: $showDetail, arrowEdge: .bottom) {
            StepDetailView(track: track, index: index, accentColor: accentColor)
        }
        .contextMenu {
            Button("Edit Step…")   { showDetail = true }
            Divider()
            Button("Clear Step")   { modifyStep { $0 = Step() } }
            Button("Max Velocity") { modifyStep { $0.velocity = 127 } }
            Button("Gate: Full")   { modifyStep { $0.gate = 0.95 } }
            Button("Gate: Short")  { modifyStep { $0.gate = 0.15 } }
        }
    }

    private var bgColor: Color {
        if isLearnTarget                  { return Color.white.opacity(0.12) }
        if isSelected                     { return Color(red:0.15,green:0.35,blue:0.65).opacity(0.45) }
        if isCurrentStep && step.isActive { return accentColor.opacity(0.18) }
        if isCurrentStep                  { return VintageTheme.stepInactive.opacity(1.5) }
        if step.isActive                  { return accentColor.opacity(0.07) }
        return VintageTheme.stepInactive
    }
    private var borderColor: Color {
        if isLearnTarget  { return Color.white.opacity(0.8) }
        if isSelected     { return Color(red: 0.3, green: 0.6, blue: 1.0) }
        if isCurrentStep  { return accentColor.opacity(0.85) }
        if step.isActive  { return accentColor.opacity(0.35) }
        return VintageTheme.stepBorder
    }
    private var ledColor: Color {
        if isCurrentStep { return VintageTheme.amberBright }
        if step.isActive { return accentColor }
        return VintageTheme.amberDim.opacity(0.4)
    }
    private var ledGlow:  Double  { isCurrentStep ? 1.0 : (step.isActive ? 0.5 : 0) }
    private var ledGlowR: CGFloat { isCurrentStep ? 8 : 4 }
}
