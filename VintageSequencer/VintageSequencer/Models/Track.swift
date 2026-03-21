import Foundation
import Combine

// MARK: - Scale definitions

struct ScaleDefinition {
    let name:      String
    let shortName: String
    let intervals: [Int]   // semitones from root, 0-based
}

// MARK: - Play direction

enum PlayDirection: String, CaseIterable, Codable {
    case forward  = "FWD"
    case reverse  = "REV"
    case pingPong = "P-P"
    case random   = "RND"
}

final class Track: ObservableObject, Identifiable {

    // MARK: - Scale library (shared)
    static let scales: [ScaleDefinition] = [
        ScaleDefinition(name: "Chromatic",      shortName: "—",    intervals: [0,1,2,3,4,5,6,7,8,9,10,11]),
        ScaleDefinition(name: "Major",          shortName: "MAJ",  intervals: [0,2,4,5,7,9,11]),
        ScaleDefinition(name: "Minor",          shortName: "MIN",  intervals: [0,2,3,5,7,8,10]),
        ScaleDefinition(name: "Dorian",         shortName: "DOR",  intervals: [0,2,3,5,7,9,10]),
        ScaleDefinition(name: "Phrygian",       shortName: "PHR",  intervals: [0,1,3,5,7,8,10]),
        ScaleDefinition(name: "Lydian",         shortName: "LYD",  intervals: [0,2,4,6,7,9,11]),
        ScaleDefinition(name: "Mixolydian",     shortName: "MIX",  intervals: [0,2,4,5,7,9,10]),
        ScaleDefinition(name: "Harm. Minor",    shortName: "HRM",  intervals: [0,2,3,5,7,8,11]),
        ScaleDefinition(name: "Penta Major",    shortName: "PM+",  intervals: [0,2,4,7,9]),
        ScaleDefinition(name: "Penta Minor",    shortName: "PM-",  intervals: [0,3,5,7,10]),
        ScaleDefinition(name: "Blues",          shortName: "BLU",  intervals: [0,3,5,6,7,10]),
        ScaleDefinition(name: "Whole Tone",     shortName: "WHL",  intervals: [0,2,4,6,8,10]),
    ]
    static let noteNames = ["C","C#","D","D#","E","F","F#","G","G#","A","A#","B"]
    let id = UUID()

    @Published var name:        String        = "Track"
    @Published var stepCount:   Int           = 16 {
        didSet {
            // Grow steps array if stepCount exceeds current capacity
            while steps.count < stepCount { steps.append(Step()) }
        }
    }
    @Published var steps:       [Step]
    @Published var midiChannel: Int           = 1
    @Published var cc1Number:   Int           = 74
    @Published var cc2Number:   Int           = 71
    @Published var cc1Label:    String        = "CC1"
    @Published var cc2Label:    String        = "CC2"
    @Published var direction:     PlayDirection = .forward
    @Published var isMuted:       Bool          = false
    @Published var isSolo:        Bool          = false
    @Published var isExpanded:    Bool          = false
    /// Timing offset in seconds: negative = ahead (pushed), positive = behind (laid back)
    @Published var timingOffset:  Double        = 0.0
    @Published var scaleRoot:     Int           = 0    // 0=C … 11=B
    @Published var scaleIndex:    Int           = 0    // 0=Chromatic (off)

    /// Step length as a ratio of a 16th note: stepLengthNumerator / stepLengthDenominator.
    /// 1/1 = normal 16th. 3/2 = dotted 16th (slower). 2/3 = triplet 16th (faster).
    /// Fully independent of stepCount.
    @Published var stepLengthNumerator:   Int = 1
    @Published var stepLengthDenominator: Int = 1

    // Audio-thread state — never accessed directly from UI
    var currentStep:       Int    = 0
    var pingPongForward:   Bool   = true
    var lastFiredNotes:    [Int]  = []    // alle aktuell klingenden Akkord-Noten
    /// Akkumuliert MIDI-Pulse; sobald >= pulsesPerStep → Step auslösen.
    var pulseAccumulator:  Double = 0

    /// Wie viele MIDI-Pulse (24 PPQ) dauert ein Step dieses Tracks.
    /// 6 = normaler 16tel-Step. pulsesPerStep = 6 × numerator / denominator.
    var pulsesPerStep: Double {
        6.0 * Double(stepLengthNumerator) / Double(stepLengthDenominator)
    }

    // Display state — only written via DispatchQueue.main
    @Published var displayStep: Int = 0

    init(name: String, stepCount: Int = 16, midiChannel: Int = 1) {
        self.name        = name
        self.stepCount   = stepCount
        self.midiChannel = midiChannel
        self.steps       = (0..<64).map { _ in Step() }
    }

    /// Called from the audio thread. Returns the next step index.
    func advanceStep() -> Int {
        let n = stepCount
        switch direction {
        case .forward:
            currentStep = (currentStep + 1) % n
        case .reverse:
            currentStep = currentStep == 0 ? n - 1 : currentStep - 1
        case .pingPong:
            if pingPongForward {
                if currentStep >= n - 1 { pingPongForward = false; currentStep = max(0, n - 2) }
                else                    { currentStep += 1 }
            } else {
                if currentStep <= 0     { pingPongForward = true;  currentStep = min(1, n - 1) }
                else                    { currentStep -= 1 }
            }
        case .random:
            currentStep = Int.random(in: 0..<n)
        }
        return currentStep
    }

    func reset() {
        currentStep      = 0
        pingPongForward  = true
        pulseAccumulator = 0
        DispatchQueue.main.async { self.displayStep = 0 }
    }

    // MARK: - Scale helpers

    func noteInScale(_ note: Int) -> Bool {
        guard scaleIndex > 0 else { return true }
        let semitone = ((note % 12) - scaleRoot + 12) % 12
        return Track.scales[scaleIndex].intervals.contains(semitone)
    }

    /// Returns the closest in-scale MIDI note to the given note.
    func quantizedNote(_ note: Int) -> Int {
        guard scaleIndex > 0 else { return note }
        let intervals = Track.scales[scaleIndex].intervals
        var best = note
        var bestDist = Int.max
        for candidate in 0...127 {
            let semitone = ((candidate % 12) - scaleRoot + 12) % 12
            if intervals.contains(semitone) {
                let dist = abs(candidate - note)
                if dist < bestDist { bestDist = dist; best = candidate }
            }
        }
        return best
    }
}

// MARK: - Codable

extension Track: Codable {
    enum CodingKeys: String, CodingKey {
        case name, stepCount, steps, midiChannel
        case cc1Number, cc2Number, cc1Label, cc2Label
        case direction, isMuted, timingOffset, scaleRoot, scaleIndex
        case stepLengthNumerator, stepLengthDenominator
        case cycleLengthSteps   // legacy — migration only
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(name,                           forKey: .name)
        try c.encode(stepCount,                      forKey: .stepCount)
        try c.encode(Array(steps.prefix(stepCount)), forKey: .steps)
        try c.encode(midiChannel,                    forKey: .midiChannel)
        try c.encode(cc1Number,                      forKey: .cc1Number)
        try c.encode(cc2Number,                      forKey: .cc2Number)
        try c.encode(cc1Label,                       forKey: .cc1Label)
        try c.encode(cc2Label,                       forKey: .cc2Label)
        try c.encode(direction,                      forKey: .direction)
        try c.encode(isMuted,                        forKey: .isMuted)
        try c.encode(timingOffset,                   forKey: .timingOffset)
        try c.encode(scaleRoot,                      forKey: .scaleRoot)
        try c.encode(scaleIndex,                     forKey: .scaleIndex)
        try c.encode(stepLengthNumerator,            forKey: .stepLengthNumerator)
        try c.encode(stepLengthDenominator,          forKey: .stepLengthDenominator)
    }

    convenience init(from decoder: Decoder) throws {
        let c         = try decoder.container(keyedBy: CodingKeys.self)
        let name      = try c.decode(String.self,        forKey: .name)
        let stepCount = try c.decode(Int.self,           forKey: .stepCount)
        let channel   = try c.decode(Int.self,           forKey: .midiChannel)
        self.init(name: name, stepCount: stepCount, midiChannel: channel)
        var decoded   = try c.decode([Step].self,        forKey: .steps)
        while decoded.count < 64 { decoded.append(Step()) }
        self.steps     = decoded
        self.cc1Number = try c.decode(Int.self,          forKey: .cc1Number)
        self.cc2Number = try c.decode(Int.self,          forKey: .cc2Number)
        self.cc1Label  = try c.decode(String.self,       forKey: .cc1Label)
        self.cc2Label  = try c.decode(String.self,       forKey: .cc2Label)
        self.direction    = try c.decode(PlayDirection.self, forKey: .direction)
        self.isMuted      = try c.decode(Bool.self,         forKey: .isMuted)
        self.timingOffset = (try? c.decode(Double.self, forKey: .timingOffset)) ?? 0.0
        self.scaleRoot    = (try? c.decode(Int.self, forKey: .scaleRoot))    ?? 0
        self.scaleIndex   = (try? c.decode(Int.self, forKey: .scaleIndex))   ?? 0

        // New model — fall back to legacy cycleLengthSteps migration
        if let num = try? c.decode(Int.self, forKey: .stepLengthNumerator),
           let den = try? c.decode(Int.self, forKey: .stepLengthDenominator) {
            self.stepLengthNumerator   = max(1, num)
            self.stepLengthDenominator = max(1, den)
        } else if let legacy = try? c.decode(Int.self, forKey: .cycleLengthSteps),
                  stepCount > 0 {
            // Convert old cycleLengthSteps → ratio: cycle/stepCount, reduced
            func gcd(_ a: Int, _ b: Int) -> Int { b == 0 ? a : gcd(b, a % b) }
            let d = gcd(legacy, stepCount)
            self.stepLengthNumerator   = legacy / d
            self.stepLengthDenominator = stepCount / d
        }
        // else: defaults (1/1) set by init
    }
}
