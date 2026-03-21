import SwiftUI

struct MainView: View {
    @EnvironmentObject var engine: SequencerEngine

    var body: some View {
        VStack(spacing: 0) {

            // ── Transport bar ────────────────────────────────────────────
            TransportView()

            // ── Track grid ───────────────────────────────────────────────
            ScrollView(.vertical, showsIndicators: true) {
                VStack(spacing: 8) {
                    ForEach(
                        Array(engine.currentPattern.tracks.enumerated()),
                        id: \.element.id
                    ) { idx, track in
                        TrackRowView(
                            track:       track,
                            accentColor: VintageTheme.trackColors[idx % VintageTheme.trackColors.count],
                            trackIndex:  idx,
                            onRandomize: { engine.randomize(track: track) },
                            onClear: {
                                var cleared = track.steps
                                for i in 0..<track.stepCount { cleared[i] = Step() }
                                track.steps = cleared
                            },
                            onDelete: engine.currentPattern.tracks.count > 1
                                ? { engine.removeTrack(at: idx) }
                                : nil,
                            onDuplicate: { engine.duplicateTrack(at: idx) }
                        )
                    }

                    // Add track button — kein hartes Limit
                    Button {
                        engine.addTrack()
                    } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "plus.circle")
                                Text("ADD TRACK")
                            }
                            .font(VintageTheme.monoSmall)
                            .foregroundColor(VintageTheme.textSecondary)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 14)
                            .background(VintageTheme.panel)
                            .clipShape(RoundedRectangle(cornerRadius: 7))
                            .overlay(RoundedRectangle(cornerRadius: 7)
                                .stroke(VintageTheme.panelBorder.opacity(0.6), lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(12)
            }
            // Grid as overlay: covers full viewport, draws over panels
            // Canvas has transparent bg — only lines are visible
            .overlay(alignment: .topLeading) {
                BPMGridView()
                    .padding(.top, 12)  // flush with first track row
            }
            .background(VintageTheme.background)

            // ── Status bar ───────────────────────────────────────────────
            StatusBar()
        }
        .background(VintageTheme.background)
        .frame(minWidth: 920, minHeight: 540)
        .onDisappear {
            engine.stop()
            engine.midi.cleanup()
        }
    }
}

// MARK: - Status bar

private struct StatusBar: View {
    @EnvironmentObject var engine: SequencerEngine

    var body: some View {
        HStack(spacing: 14) {
            // Play indicator LED
            Circle()
                .fill(engine.isPlaying ? VintageTheme.amberBright : VintageTheme.amberDim)
                .frame(width: 6, height: 6)
                .shadow(color: VintageTheme.amber.opacity(engine.isPlaying ? 0.8 : 0), radius: 4)

            Text(engine.isPlaying ? "RUNNING" : "STOPPED")
                .font(VintageTheme.monoSmall)
                .foregroundColor(engine.isPlaying ? VintageTheme.textAmber : VintageTheme.textSecondary)

            Text("•")
                .foregroundColor(VintageTheme.textDim)

            Text("BPM \(String(format: "%.1f", engine.bpm))")
                .font(VintageTheme.monoSmall)
                .foregroundColor(VintageTheme.textSecondary)
                .monospacedDigit()

            Text("•")
                .foregroundColor(VintageTheme.textDim)

            Text("CLK \(engine.clockMode.rawValue)")
                .font(VintageTheme.monoSmall)
                .foregroundColor(VintageTheme.textSecondary)

            Text("•")
                .foregroundColor(VintageTheme.textDim)

            Text("PATTERN \(["A","B","C","D"][engine.currentPatternIndex])")
                .font(VintageTheme.monoSmall)
                .foregroundColor(VintageTheme.textSecondary)

            Spacer()

            // MIDI out name (if selected)
            if let out = engine.midi.outputs
                .first(where: { $0.ref == engine.midi.selectedOutput }) {
                Text("OUT: \(out.name)")
                    .font(VintageTheme.monoSmall)
                    .foregroundColor(VintageTheme.textSecondary)
                    .lineLimit(1)
            } else {
                Text("No MIDI output selected")
                    .font(VintageTheme.monoSmall)
                    .foregroundColor(VintageTheme.textDim)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 5)
        .background(VintageTheme.panelDark)
        .overlay(
            Rectangle()
                .fill(VintageTheme.panelBorder)
                .frame(height: 1),
            alignment: .top
        )
    }
}
