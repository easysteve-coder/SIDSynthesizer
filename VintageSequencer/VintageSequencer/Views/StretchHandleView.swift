import SwiftUI

/// Compact stretch handle — two zones side by side:
///
///   [ratio] │ [stepCount]
///    3           16
///   ─── ▐
///    2
///
/// Left:  drag → step length ratio · tap → StepLengthPopover
/// Right: drag → step count (no popover)
struct StretchHandleView: View {
    @ObservedObject var track: Track
    var accentColor:   Color
    var baseStepWidth: CGFloat
    @EnvironmentObject private var engine: SequencerEngine

    @Environment(\.undoManager) private var undoManager

    @State private var dragStartY:    CGFloat? = nil
    @State private var dragBaseIndex: Int?     = nil
    @State private var isRatioDragging         = false
    @State private var stepStartY:    CGFloat? = nil
    @State private var stepBase:      Int?     = nil
    @State private var showRatioPopover        = false
    @State private var ratioUndoSnapshot: (num: Int, den: Int)? = nil
    @State private var stepCountUndoSnapshot: Int? = nil

    private let stepSensitivity: CGFloat = 18

    // Musical ratios sorted by step-length multiplier (num/den), smallest first.
    // Each entry: (numerator, denominator) of the step-length fraction.
    private let sortedRatios: [(num: Int, den: Int)] = [
        (1,2), (4,7), (2,3), (3,4), (4,5), (8,9), (1,1),
        (9,8), (5,4), (4,3), (3,2), (7,4), (2,1)
    ]

    private var currentRatioIndex: Int {
        sortedRatios.firstIndex(where: {
            $0.num == track.stepLengthNumerator && $0.den == track.stepLengthDenominator
        }) ?? (sortedRatios.count / 2)  // fallback to 1:1 position
    }

    private func gcd(_ a: Int, _ b: Int) -> Int { b == 0 ? a : gcd(b, a % b) }

    private var reducedRatio: (num: Int, den: Int) {
        let n = track.stepLengthNumerator
        let d = track.stepLengthDenominator
        let g = gcd(n, d)
        return (n / g, d / g)
    }

    private var isStretched: Bool {
        track.stepLengthNumerator != 1 || track.stepLengthDenominator != 1
    }

    var body: some View {
        HStack(spacing: 0) {

            // ── Left: Step length ratio ───────────────────────────────────
            Button(action: { showRatioPopover = true }) {
                Group {
                    if isRatioDragging || isStretched {
                        fraction(top: reducedRatio.num, bottom: reducedRatio.den,
                                 topSize: isRatioDragging ? 13 : 12,
                                 bottomSize: isRatioDragging ? 20 : 16)
                    } else {
                        grip()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .popover(isPresented: $showRatioPopover, arrowEdge: .leading) {
                StepLengthPopover(track: track, accentColor: accentColor)
                    .environmentObject(engine)
            }
            .simultaneousGesture(
                DragGesture(minimumDistance: 2)
                    .onChanged { value in
                        isRatioDragging = true
                        if dragStartY == nil {
                            dragStartY    = value.translation.height
                            dragBaseIndex = currentRatioIndex
                            ratioUndoSnapshot = (track.stepLengthNumerator, track.stepLengthDenominator)
                        }
                        let moved = value.translation.height - dragStartY!
                        let delta = -Int((moved / 24.0).rounded())
                        let newIdx = max(0, min(sortedRatios.count - 1, dragBaseIndex! + delta))
                        let r = sortedRatios[newIdx]
                        track.stepLengthNumerator   = r.num
                        track.stepLengthDenominator = r.den
                        engine.hasUnsavedChanges = true
                    }
                    .onEnded { _ in
                        if let snap = ratioUndoSnapshot {
                            let oldNum = snap.num, oldDen = snap.den
                            undoManager?.registerUndo(withTarget: track) { t in
                                t.stepLengthNumerator   = oldNum
                                t.stepLengthDenominator = oldDen
                            }
                            undoManager?.setActionName("Step Ratio")
                        }
                        isRatioDragging    = false
                        dragStartY         = nil
                        dragBaseIndex      = nil
                        ratioUndoSnapshot  = nil
                    }
            )
            .help(isStretched
                  ? "↑↓ ziehen · klicken für Eingabe"
                  : "↑↓ ziehen zum Strecken · klicken für Eingabe")

            // ── Divider ───────────────────────────────────────────────────
            Rectangle()
                .fill(VintageTheme.panelBorder)
                .frame(width: 1)
                .padding(.vertical, 6)

            // ── Right: Step count — drag only ─────────────────────────────
            Text("\(track.stepCount)")
                .font(.system(size: 15, weight: .bold, design: .monospaced))
                .foregroundColor(VintageTheme.textAmber)
                .monospacedDigit()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 2)
                        .onChanged { value in
                            if stepStartY == nil {
                                stepStartY            = value.translation.height
                                stepBase              = track.stepCount
                                stepCountUndoSnapshot = track.stepCount
                            }
                            let moved = value.translation.height - stepStartY!
                            let delta = -Int((moved / stepSensitivity).rounded())
                            track.stepCount = min(64, max(1, stepBase! + delta))
                            engine.hasUnsavedChanges = true
                        }
                        .onEnded { _ in
                            if let old = stepCountUndoSnapshot {
                                undoManager?.registerUndo(withTarget: track) { $0.stepCount = old }
                                undoManager?.setActionName("Step Count")
                            }
                            stepStartY            = nil
                            stepBase              = nil
                            stepCountUndoSnapshot = nil
                        }
                )
                .help("↑↓ ziehen für Step-Anzahl")
        }
        .frame(width: 80)
    }

    // MARK: - Sub-views

    @ViewBuilder
    private func fraction(top: Int, bottom: Int, topSize: CGFloat, bottomSize: CGFloat) -> some View {
        VStack(spacing: 2) {
            Text("\(top)")
                .font(.system(size: topSize, weight: .semibold, design: .monospaced))
                .foregroundColor(accentColor.opacity(0.75))
            Rectangle()
                .fill(accentColor)
                .frame(height: 1)
                .padding(.horizontal, 6)
            Text("\(bottom)")
                .font(.system(size: bottomSize, weight: .bold, design: .monospaced))
                .foregroundColor(accentColor)
        }
    }

    @ViewBuilder
    private func grip() -> some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(VintageTheme.textDim.opacity(0.5))
            .frame(width: 6, height: 26)
            .overlay(
                VStack(spacing: 4) {
                    ForEach(0..<3, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 1)
                            .fill(Color.black.opacity(0.35))
                            .frame(width: 6, height: 1)
                    }
                }
            )
    }
}

// MARK: - Step length popover

private struct StepLengthPopover: View {
    @ObservedObject var track: Track
    var accentColor: Color
    @EnvironmentObject private var engine: SequencerEngine

    private func gcd(_ a: Int, _ b: Int) -> Int { b == 0 ? a : gcd(b, a % b) }

    private var reducedRatio: (num: Int, den: Int) {
        let n = track.stepLengthNumerator
        let d = track.stepLengthDenominator
        let g = gcd(n, d)
        return (n / g, d / g)
    }

    // All musical ratios with labels and tooltips
    // Label = musikalischer Name · Tooltip = Erklärung + Bruch als Referenz
    private let ratioOptions: [(label: String, num: Int, den: Int, tooltip: String)] = [
        ("32tel",       1, 2, "Zweiunddreißigstel — halb so lang wie eine Sechzehntel  (1:2)"),
        ("Septole÷",    4, 7, "Sechzehntelseptole — 7 Noten auf 4 Sechzehntel, Step kürzer  (4:7)"),
        ("16t·Triole",  2, 3, "Sechzehnteltriole — 3 Noten auf den Raum von 2 Sechzehnteln  (2:3)"),
        ("Quartole÷",   3, 4, "Sechzehntelquartole — 4 Noten auf den Raum von 3 Sechzehnteln  (3:4)"),
        ("Quintole÷",   4, 5, "Sechzehntelquintole — 5 Noten auf den Raum von 4 Sechzehnteln  (4:5)"),
        ("Nonole÷",     8, 9, "Sechzehntelnonole — 9 Noten auf den Raum von 8 Sechzehnteln  (8:9)"),
        ("16tel",       1, 1, "Sechzehntel — Referenzwert, normaler Step  (1:1)"),
        ("Nonole×",     9, 8, "Nonole gedehnt — 8 Noten auf den Raum von 9 Sechzehnteln  (9:8)"),
        ("Quintole×",   5, 4, "Quintole gedehnt — 4 Noten auf den Raum von 5 Sechzehnteln  (5:4)"),
        ("8t·Triole",   4, 3, "Achteltriole — 3 Noten auf den Raum von 2 Achteln (= 4 Sechzehntel)  (4:3)"),
        ("pkt.16tel",   3, 2, "Punktierte Sechzehntel — Sechzehntel + Zweiunddreißigstel  (3:2)"),
        ("Septole×",    7, 4, "Septole gedehnt — 4 Noten auf den Raum von 7 Sechzehnteln  (7:4)"),
        ("8tel",        2, 1, "Achtelnote — doppelt so lang wie eine Sechzehntel  (2:1)"),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("STEP-LÄNGE / RATIO")
                .font(VintageTheme.monoBold)
                .foregroundColor(VintageTheme.textAmber)

            // Fraction display
            let r = reducedRatio
            VStack(spacing: 3) {
                Text("\(r.num)")
                    .font(.system(size: 22, weight: .semibold, design: .monospaced))
                    .foregroundColor(accentColor.opacity(0.75))
                Rectangle()
                    .fill(accentColor)
                    .frame(height: 2)
                    .padding(.horizontal, 20)
                Text("\(r.den)")
                    .font(.system(size: 30, weight: .bold, design: .monospaced))
                    .foregroundColor(accentColor)
            }
            .frame(maxWidth: .infinity)

            Text("SCHNELLWAHL")
                .font(VintageTheme.monoSmall)
                .foregroundColor(VintageTheme.textSecondary)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())],
                      alignment: .leading, spacing: 4) {
                ForEach(ratioOptions, id: \.label) { opt in
                    let isCurrent = track.stepLengthNumerator == opt.num
                                 && track.stepLengthDenominator == opt.den
                    Button(opt.label) {
                        track.stepLengthNumerator   = opt.num
                        track.stepLengthDenominator = opt.den
                        engine.hasUnsavedChanges = true
                    }
                    .buttonStyle(VintageSmallButtonStyle(isActive: isCurrent, accent: accentColor))
                    .help(opt.tooltip)
                }
            }

            Button("RESET 1:1") {
                track.stepLengthNumerator   = 1
                track.stepLengthDenominator = 1
                engine.hasUnsavedChanges = true
            }
            .buttonStyle(VintageSmallButtonStyle(isActive: false, accent: .gray))
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(14)
        .frame(width: 260)
        .background(VintageTheme.panelDark)
        .preferredColorScheme(.dark)
    }
}
