import Foundation

// MARK: - RatchetCount
enum RatchetCount: Int, CaseIterable, Codable, Identifiable {
    case x1 = 1, x2 = 2, x4 = 4
    var id: Int    { rawValue }
    var label: String { "×\(rawValue)" }
}

struct Step: Identifiable, Codable {
    var id          = UUID()
    var isActive:    Bool         = false
    var notes:       [Int]        = [60]   // Akkord: 1 oder mehr MIDI-Noten
    var velocity:    Int          = 100    // 1–127
    /// Gate-Länge als Vielfaches einer 16tel-Note (1 Step).
    /// < 1.0 = Staccato, 1.0 = Legato, > 1.0 = hält über mehrere Steps (bis 1/1 = 16 Steps).
    var gate:        Double       = 0.5
    var probability: Double       = 1.0   // 0.0–1.0
    var ratchet:     RatchetCount = .x1
    var cc1Value:    Int          = 64     // 0–127
    var cc2Value:    Int          = 64     // 0–127

    // Backward-compat: reads/writes the root note (first of chord)
    var note: Int {
        get { notes.first ?? 60 }
        set { if notes.isEmpty { notes = [newValue] } else { notes[0] = newValue } }
    }

    // Default init — all properties use their default values
    init() {}

    // id wird nicht gespeichert — nur für SwiftUI-Identity
    enum CodingKeys: String, CodingKey {
        case isActive, notes, note, velocity, gate, probability, ratchet, cc1Value, cc2Value
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        isActive    = (try? c.decode(Bool.self,        forKey: .isActive))    ?? false
        // Backward compat: alte Presets haben `note` (Int), neue haben `notes` ([Int])
        if let ns = try? c.decode([Int].self, forKey: .notes) {
            notes = ns
        } else {
            notes = [(try? c.decode(Int.self, forKey: .note)) ?? 60]
        }
        velocity    = (try? c.decode(Int.self,         forKey: .velocity))    ?? 100
        gate        = (try? c.decode(Double.self,       forKey: .gate))        ?? 0.5
        probability = (try? c.decode(Double.self,       forKey: .probability)) ?? 1.0
        ratchet     = (try? c.decode(RatchetCount.self, forKey: .ratchet))    ?? .x1
        cc1Value    = (try? c.decode(Int.self,          forKey: .cc1Value))   ?? 64
        cc2Value    = (try? c.decode(Int.self,          forKey: .cc2Value))   ?? 64
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(isActive,    forKey: .isActive)
        try c.encode(notes,       forKey: .notes)
        try c.encode(velocity,    forKey: .velocity)
        try c.encode(gate,        forKey: .gate)
        try c.encode(probability, forKey: .probability)
        try c.encode(ratchet,     forKey: .ratchet)
        try c.encode(cc1Value,    forKey: .cc1Value)
        try c.encode(cc2Value,    forKey: .cc2Value)
    }

    // MARK: - Gate steps (musikalische Notenwerte, 1.0 = 1/16-Note = 1 Step)

    struct GateStep {
        let value: Double   // Vielfaches eines 16tel-Steps
        let label: String   // Anzeige im UI
    }

    /// Musikalisch sinnvolle Gate-Stufen: staccato bis ganze Note.
    /// Dotted-Werte mit ".", ganze/halbe/viertel als Standard-Notennamen.
    static let gateSteps: [GateStep] = [
        GateStep(value:  0.05, label: "stac"),   // Staccatissimo (~1/320)
        GateStep(value:  0.25, label: "1/64"),   // Staccato     (= 1/64-Note)
        GateStep(value:  0.50, label: "1/32"),   // Kurz         (= 1/32-Note)
        GateStep(value:  1.00, label: "1/16"),   // Legato       (= 1 Step, füllt den Step)
        GateStep(value:  1.50, label: "1/16."),  // Punkt.-16tel (= 3/32-Note)
        GateStep(value:  2.00, label: "1/8"),    // Achtel       (= 2 Steps)
        GateStep(value:  3.00, label: "1/8."),   // Punkt.-Achtel(= 3 Steps)
        GateStep(value:  4.00, label: "1/4"),    // Viertel/Beat (= 4 Steps)
        GateStep(value:  6.00, label: "1/4."),   // Punkt.-Viertel (= 6 Steps)
        GateStep(value:  8.00, label: "1/2"),    // Halbe        (= 8 Steps)
        GateStep(value: 12.00, label: "1/2."),   // Punkt.-Halbe (= 12 Steps)
        GateStep(value: 16.00, label: "1/1"),    // Ganze        (= 16 Steps = 1 Takt)
    ]

    /// Nächstgelegener Gate-Stufenwert für einen rohen Double-Wert.
    static func snapGate(_ raw: Double) -> Double {
        gateSteps.min(by: { abs($0.value - raw) < abs($1.value - raw) })?.value ?? raw
    }

    /// Label des nächstgelegenen Gate-Stufenwerts.
    static func gateLabel(_ gate: Double) -> String {
        gateSteps.min(by: { abs($0.value - gate) < abs($1.value - gate) })?.label ?? "?"
    }

    // Kurzname der Wurzelnote (z.B. "C4")
    var noteName: String {
        let names = ["C","C#","D","D#","E","F","F#","G","G#","A","A#","B"]
        let n = note
        return "\(names[n % 12])\((n / 12) - 1)"
    }

    /// Kurzname ohne Oktave für den Step-Button, z.B. "Cmaj7", "Dm", "G7"
    var shortChordName: String {
        let names = ["C","C#","D","D#","E","F","F#","G","G#","A","A#","B"]
        guard notes.count > 1,
              let analysed = Step.analyzeChord(notes) else {
            return noteName
        }
        // Oktav-Ziffer aus dem analysierten Namen entfernen:
        // "C4maj7" → "Cmaj7", "C#4m7" → "C#m7"
        var chars = Array(analysed)
        var i = 1
        if i < chars.count && chars[i] == "#" { i += 1 }   // Sharp überspringen
        if i < chars.count && chars[i].isNumber { chars.remove(at: i) }
        let _ = names  // silence warning
        return String(chars)
    }

    // Analysierter Akkordname mit Oktave, z.B. "C4maj7" oder "Dm3b5"
    var chordName: String {
        if let analysed = Step.analyzeChord(notes) { return analysed }
        let names = ["C","C#","D","D#","E","F","F#","G","G#","A","A#","B"]
        return notes.sorted().map { "\(names[$0 % 12])\(($0 / 12) - 1)" }.joined(separator: "+")
    }

    // MARK: - Akkord-Analyse

    /// Gibt den Akkordnamen zurück, z.B. "Cmaj7", "Dm7b5", "G9"
    static func analyzeChord(_ notes: [Int]) -> String? {
        guard notes.count >= 2 else { return nil }
        let noteNames = ["C","C#","D","D#","E","F","F#","G","G#","A","A#","B"]

        let pcs = Array(Set(notes.map { $0 % 12 })).sorted()   // Tonklassen ohne Oktave

        // Akkordtypen: (Intervalle vom Grundton, Kürzel) — längere zuerst, damit specifischer gewinnt
        let types: [([Int], String)] = [
            ([0,4,7,11,2,9], "maj13"), ([0,4,7,10,2,9], "13"),  ([0,3,7,10,2,9], "m13"),
            ([0,4,7,11,2],   "maj9"),  ([0,4,7,10,2],   "9"),   ([0,3,7,10,2],   "m9"),
            ([0,4,7,11,6],   "maj7♯11"),
            ([0,4,7,11],     "maj7"),  ([0,4,7,10],     "7"),   ([0,3,7,10],     "m7"),
            ([0,3,6,10],     "m7b5"),  ([0,3,6,9],      "dim7"),([0,4,8,10],     "aug7"),
            ([0,4,7,9],      "6"),     ([0,3,7,9],      "m6"),
            ([0,4,7,2],      "add9"),  ([0,3,7,2],      "madd9"),
            ([0,4,8],        "aug"),   ([0,3,6],        "dim"),
            ([0,4,7],        ""),      ([0,3,7],        "m"),
            ([0,2,7],        "sus2"),  ([0,5,7],        "sus4"),
            ([0,7],          "5"),
        ]

        var best: (root: Int, quality: String, score: Int)?

        for root in 0..<12 {
            let norm = Set(pcs.map { ($0 - root + 12) % 12 })
            for (intervals, quality) in types {
                let chordSet = Set(intervals.map { $0 % 12 })
                guard chordSet.isSubset(of: norm) else { continue }
                let score = chordSet.count * 10 + (norm == chordSet ? 1 : 0)
                if best == nil || score > best!.score { best = (root, quality, score) }
            }
        }

        guard let b = best else { return nil }
        let octave: Int
        if let found = notes.sorted().first(where: { $0 % 12 == b.root }) {
            octave = (found / 12) - 1
        } else { octave = 4 }
        return "\(noteNames[b.root])\(octave)\(b.quality)"
    }
}
