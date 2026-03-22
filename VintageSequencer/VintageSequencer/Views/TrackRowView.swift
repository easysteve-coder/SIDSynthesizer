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

    // MARK: - Layout helpers

    /// Height of the step row.
    private var stepRowHeight: CGFloat {
        max(90, CGFloat(engine.stepDisplaySize) + 12)
    }

    /// Height of each CC row — shared between left label column and scroll content.
    private var ccRowH: CGFloat {
        CCKnobRowView.rowHeight(stepDisplaySize: engine.stepDisplaySize)
    }

    /// Total height of the right scrollable column (step + CC rows when expanded).
    private var totalScrollHeight: CGFloat {
        guard track.isExpanded else { return stepRowHeight }
        return stepRowHeight + 1 + ccRowH + 1 + ccRowH   // 2 × 1px separators
    }

    /// Step width adjusted for step-length ratio.
    /// Formula accounts for inter-step spacing so that N steps at ratio p/q
    /// occupy exactly the same horizontal space as N×p/q normal steps.
    private var stretchedStepWidth: CGFloat {
        let base    = CGFloat(engine.stepDisplaySize)
        let spacing = VintageTheme.stepSpacing
        return (base + spacing)
            * CGFloat(track.stepLengthNumerator)
            / CGFloat(track.stepLengthDenominator)
            - spacing
    }

    // MARK: - Body

    var body: some View {
        HStack(spacing: 0) {

            // ── LEFT: fixed column ────────────────────────────────────────
            // Header occupies the step-row height; CC labels appear below
            // when expanded, exactly matching the CC rows on the right.
            VStack(spacing: 0) {
                TrackHeaderView(track: track,
                                accentColor: accentColor,
                                onRandomize: onRandomize,
                                onClear: onClear,
                                onDelete: onDelete,
                                onDuplicate: onDuplicate)
                    .frame(height: stepRowHeight)
                    .contextMenu {
                        Button {
                            engine.insertTrack(after: trackIndex)
                        } label: {
                            Label("Track darunter einfügen", systemImage: "plus")
                        }

                        Button {
                            engine.duplicateTrack(at: trackIndex)
                        } label: {
                            Label("Track duplizieren", systemImage: "plus.square.on.square")
                        }

                        Divider()

                        Button(role: .destructive) {
                            engine.removeTrack(at: trackIndex)
                        } label: {
                            Label("Track löschen", systemImage: "trash")
                        }
                        .disabled(engine.currentPattern.tracks.count <= 1)
                    }

                if track.isExpanded {
                    Rectangle()
                        .fill(VintageTheme.panelBorder)
                        .frame(height: 1)

                    Text(track.cc1Label)
                        .font(VintageTheme.monoSmall)
                        .foregroundColor(VintageTheme.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading, 10)
                        .frame(height: ccRowH)

                    Rectangle()
                        .fill(VintageTheme.panelBorder)
                        .frame(height: 1)

                    Text(track.cc2Label)
                        .font(VintageTheme.monoSmall)
                        .foregroundColor(VintageTheme.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading, 10)
                        .frame(height: ccRowH)
                }
            }
            .frame(width: VintageTheme.trackHeaderWidth)

            // Thin separator
            Rectangle()
                .fill(VintageTheme.panelBorder)
                .frame(width: 1)

            // ── RIGHT: step grid VStack ───────────────────────────────────
            VStack(spacing: 0) {

                // Selection action bar (lives OUTSIDE the ScrollView so it
                // doesn't scroll horizontally with the step content).
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
                // Escape key clears selection
                Button("") { selectedSteps = [] }
                    .keyboardShortcut(.escape, modifiers: [])
                    .frame(width: 0, height: 0)
                    .opacity(0)
                    .disabled(selectedSteps.isEmpty)

                // ── Scroll area + Stretch handle ──────────────────────────
                HStack(spacing: 0) {

                    // GeometryReader for rubber-band overlay positioning
                    GeometryReader { _ in
                        ZStack(alignment: .topLeading) {

                            // ── SINGLE shared ScrollView ─────────────────
                            // Steps and CC rows in one VStack → they scroll
                            // in perfect sync, no linking needed.
                            // Tapping anywhere in the scroll area dismisses
                            // any focused track-name text field.
                            ScrollView(.horizontal, showsIndicators: false) {
                                VStack(spacing: 0) {

                                    // Step buttons row
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
                                    .frame(height: stepRowHeight)

                                    // CC knob rows — inside same ScrollView = auto-synced
                                    if track.isExpanded {
                                        Rectangle()
                                            .fill(VintageTheme.panelBorder)
                                            .frame(height: 1)

                                        CCKnobRowView(track: track, ccSlot: 1,
                                                      accentColor: accentColor)

                                        Rectangle()
                                            .fill(VintageTheme.panelBorder)
                                            .frame(height: 1)

                                        CCKnobRowView(track: track, ccSlot: 2,
                                                      accentColor: accentColor)
                                    }
                                }
                                // Scroll offset tracking (for rubber-band)
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

                            // Rubber-band selection rectangle
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
                        // Rubber-band gesture on the ZStack — guards against
                        // firing over CC rows (y >= stepRowHeight).
                        .gesture(
                            DragGesture(minimumDistance: 8, coordinateSpace: .local)
                                .onChanged { value in
                                    guard value.startLocation.y < stepRowHeight else { return }
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
                    // GeometryReader height = total scroll column height.
                    // Grows when CC rows are expanded.
                    .frame(height: totalScrollHeight)
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())

                    // Stretch handle spans the full scroll height
                    StretchHandleView(track: track,
                                      accentColor: accentColor,
                                      baseStepWidth: CGFloat(engine.stepDisplaySize))
                        .frame(width: 80)
                        .frame(height: totalScrollHeight)
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
        .animation(.easeInOut(duration: 0.15), value: track.isExpanded)
        .background(VintageTheme.panel)
        .clipShape(RoundedRectangle(cornerRadius: 7))
        .overlay(
            RoundedRectangle(cornerRadius: 7)
                .stroke(VintageTheme.panelBorder, lineWidth: 1)
        )
    }
}
