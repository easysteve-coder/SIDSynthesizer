// KeyboardView.swift
// Two-octave piano keyboard. Click/tap to trigger notes on the SID engine.

import SwiftUI

struct KeyboardView: View {
    @ObservedObject var engine: SIDEngine

    // White key layout for one octave (C D E F G A B)
    private let whiteNotes  = [0, 2, 4, 5, 7, 9, 11]
    // Black key offsets (nil = no black key after that white key)
    private let blackAfter  = [true, true, false, true, true, true, false]

    private let keyWidth:  CGFloat = 28
    private let keyHeight: CGFloat = 80
    private let blackH:    CGFloat = 50
    private let blackW:    CGFloat = 18

    var body: some View {
        HStack(spacing: 0) {
            // Octave down/up buttons
            VStack(spacing: 4) {
                Button("◀") { engine.currentOctave = max(1, engine.currentOctave - 1) }
                    .font(.c64Label).foregroundColor(.c64Light)
                Text("OCT\n\(engine.currentOctave)")
                    .font(.c64Small).foregroundColor(.c64Dim).multilineTextAlignment(.center)
                Button("▶") { engine.currentOctave = min(7, engine.currentOctave + 1) }
                    .font(.c64Label).foregroundColor(.c64Light)
            }
            .frame(width: 44)

            // Two-octave keyboard
            ZStack(alignment: .topLeading) {
                // White keys
                HStack(spacing: 1) {
                    ForEach(0 ..< 2, id: \.self) { oct in
                        ForEach(0 ..< 7, id: \.self) { w in
                            let midi = midiNote(octave: oct, whiteIndex: w)
                            whiteKey(midiNote: midi)
                        }
                    }
                }
                // Black keys (positioned over the white keys)
                blackKeysRow()
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(Color.c64Dark)
    }

    // MARK: - White key

    private func whiteKey(midiNote note: Int) -> some View {
        let playing = engine.playingNotes.contains(note)
        return RoundedRectangle(cornerRadius: 3)
            .fill(playing ? Color.c64Blue : Color(white: 0.85))
            .overlay(
                RoundedRectangle(cornerRadius: 3)
                    .stroke(Color.c64Border, lineWidth: 1)
            )
            .frame(width: keyWidth, height: keyHeight)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if !engine.playingNotes.contains(note) { engine.noteOn(midiNote: note) }
                    }
                    .onEnded { _ in engine.noteOff(midiNote: note) }
            )
    }

    // MARK: - Black keys row

    private func blackKeysRow() -> some View {
        HStack(spacing: 0) {
            ForEach(0 ..< 2, id: \.self) { oct in
                ForEach(0 ..< 7, id: \.self) { w in
                    if blackAfter[w] {
                        let midi = midiNote(octave: oct, whiteIndex: w) + 1
                        ZStack {
                            // Spacer to align over white keys
                            Color.clear.frame(width: keyWidth + 1, height: blackH)
                            let playing = engine.playingNotes.contains(midi)
                            RoundedRectangle(cornerRadius: 2)
                                .fill(playing ? Color.c64Cyan : Color.c64Dark)
                                .frame(width: blackW, height: blackH)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 2)
                                        .stroke(Color.c64Border, lineWidth: 1)
                                )
                                .gesture(
                                    DragGesture(minimumDistance: 0)
                                        .onChanged { _ in
                                            if !engine.playingNotes.contains(midi) {
                                                engine.noteOn(midiNote: midi)
                                            }
                                        }
                                        .onEnded { _ in engine.noteOff(midiNote: midi) }
                                )
                                .offset(x: keyWidth / 2)
                        }
                    } else {
                        Color.clear.frame(width: keyWidth + 1, height: blackH)
                    }
                }
            }
        }
        .offset(x: -((keyWidth + 1) / 2))
    }

    // MARK: - MIDI note calculation

    private func midiNote(octave relOctave: Int, whiteIndex: Int) -> Int {
        let baseOctave = engine.currentOctave + relOctave
        return (baseOctave + 1) * 12 + whiteNotes[whiteIndex]
    }
}
