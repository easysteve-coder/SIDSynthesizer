import Foundation
import Combine
import AppKit
import UniformTypeIdentifiers

class SequencerEngine: ObservableObject {

    @Published var isPlaying:           Bool      = false
    @Published var bpm:                 Double    = 120.0 {
        didSet {
            if isPlaying && clockMode == .internal { restartClock() }
            hasUnsavedChanges = true
        }
    }
    @Published var swing:               Double    = 50.0 {   // 50 = straight, up to ~66 for triplet
        didSet { hasUnsavedChanges = true }
    }
    @Published var clockMode:           ClockMode = .internal
    @Published var patterns:            [Pattern] = ["A","B","C","D"].map { Pattern(name: $0) }
    @Published var currentPatternIndex: Int       = 0
    @Published var queuedPatternIndex:  Int?      = nil
    @Published var numTracks:           Int       = 4
    /// Darstellungsgröße der Step-Buttons in Pixeln (38 = S, 46 = M, 54 = L)
    @Published var stepDisplaySize: Double = {
        let v = UserDefaults.standard.double(forKey: "stepDisplaySize")
        return v > 0 ? v : 54
    }() {
        didSet { UserDefaults.standard.set(stepDisplaySize, forKey: "stepDisplaySize") }
    }
    // CC remote control (-1 = disabled)
    @Published var patternSwitchCC:     Int       = -1
    @Published var trackMuteCCs:        [Int]     = [-1, -1, -1, -1, -1, -1, -1, -1]
    // MIDI Learn
    @Published var learnMode:           Bool      = false
    var learnTarget: (track: Int, step: Int)?     = nil

    var midi = MIDIManager()

    private var timer:        DispatchSourceTimer?
    private var cancellables: Set<AnyCancellable> = []
    // pulsesPerStep ist jetzt per-Track in Track.pulsesPerStep definiert (24 PPQ ÷ 4 = 6 für normalen 16tel).
    // Kein globaler pulseCount mehr — jeder Track zählt selbst via pulseAccumulator.

    var currentPattern: Pattern { patterns[currentPatternIndex] }

    init() {
        midi.setup()
        midi.onClockPulse = { [weak self] in self?.tick() }
        midi.onStart      = { [weak self] in self?.startFromExternal() }
        midi.onStop       = { [weak self] in self?.stop() }
        midi.onContinue   = { [weak self] in self?.startFromExternal() }
        midi.onCC         = { [weak self] _, num, val in self?.handleIncomingCC(num, val) }
        midi.onNoteOn     = { [weak self] _, note, _ in self?.handleLearnNoteOn(note) }
        // Forward MIDIManager's @Published changes → SettingsView updates live
        midi.objectWillChange
            .sink { [weak self] in self?.objectWillChange.send() }
            .store(in: &cancellables)
    }

    // MARK: - Transport

    func play() {
        guard !isPlaying else { return }
        currentPattern.tracks.forEach { $0.reset() }  // resets pulseAccumulator too
        isPlaying = true
        midi.start()
        if clockMode == .internal { startClock() }
    }

    func stop() {
        isPlaying = false
        timer?.cancel()
        timer = nil
        midi.stop()
        queuedPatternIndex = nil
        for track in currentPattern.tracks {
            track.lastFiredNotes.forEach { midi.noteOff(channel: track.midiChannel, note: $0) }
            track.lastFiredNotes = []
            midi.allNotesOff(channel: track.midiChannel)
        }
        DispatchQueue.main.async { self.objectWillChange.send() }
    }

    /// Wechselt das Pattern quantisiert (am Ende des Track-1-Zyklus) oder sofort wenn gestoppt.
    func switchPattern(_ idx: Int) {
        guard (0..<patterns.count).contains(idx) else { return }
        if isPlaying {
            queuedPatternIndex = idx   // wird in advanceSteps() angewendet
        } else {
            applyPatternSwitch(idx)
        }
    }

    private func applyPatternSwitch(_ idx: Int) {
        for track in currentPattern.tracks {
            track.lastFiredNotes.forEach { midi.noteOff(channel: track.midiChannel, note: $0) }
            track.lastFiredNotes = []
        }
        currentPatternIndex = idx
        // Neue Pattern-Tracks frisch starten
        patterns[idx].tracks.forEach { $0.pulseAccumulator = 0; $0.currentStep = 0 }
    }

    // MARK: - Internal clock

    private func startClock() {
        let interval = 60.0 / (bpm * 24.0)
        let t = DispatchSource.makeTimerSource(queue: DispatchQueue.global(qos: .userInteractive))
        t.schedule(deadline: .now(), repeating: interval, leeway: .microseconds(100))
        t.setEventHandler { [weak self] in self?.tick() }
        t.resume()
        timer = t
    }

    private func restartClock() {
        timer?.cancel()
        timer = nil
        if isPlaying { startClock() }
    }

    private func startFromExternal() {
        guard clockMode == .external else { return }
        currentPattern.tracks.forEach { $0.reset() }
        isPlaying = true
        DispatchQueue.main.async { self.objectWillChange.send() }
    }

    private func tick() {
        guard isPlaying else { return }
        if clockMode == .internal { midi.clock() }
        advanceSteps()  // every MIDI pulse — each track decides itself when to step
    }

    // MARK: - Step sequencing

    private func advanceSteps() {
        // Called every MIDI pulse (24 PPQ). Each track accumulates pulses and steps
        // when its own threshold is reached — enabling independent polyrhythmic timing.
        let hasSolo       = currentPattern.tracks.contains { $0.isSolo }
        let pulseDuration = 60.0 / (bpm * 24.0)   // one MIDI pulse in seconds
        var track0Wrapped = false

        for (trackIdx, track) in currentPattern.tracks.enumerated() {
            // Accumulate one pulse for this track
            track.pulseAccumulator += 1.0
            guard track.pulseAccumulator >= track.pulsesPerStep else { continue }
            track.pulseAccumulator -= track.pulsesPerStep   // carry remainder → no drift

            let stepIdx = track.advanceStep()

            // Track 0 cycle complete → queued pattern switch
            if trackIdx == 0 && stepIdx == 0 { track0Wrapped = true }

            // Note off previous — independent of mute
            track.lastFiredNotes.forEach { midi.noteOff(channel: track.midiChannel, note: $0) }
            track.lastFiredNotes = []

            DispatchQueue.main.async {
                self.currentPattern.tracks[trackIdx].displayStep = stepIdx
            }

            let effectiveMute = track.isMuted || (hasSolo && !track.isSolo)
            guard !effectiveMute else { continue }

            let step = track.steps[stepIdx]

            midi.cc(channel: track.midiChannel, number: track.cc1Number, value: step.cc1Value)
            midi.cc(channel: track.midiChannel, number: track.cc2Number, value: step.cc2Value)

            guard step.isActive else { continue }
            guard Double.random(in: 0...1) <= step.probability else { continue }

            // Step duration for THIS track (accounts for stretch)
            let stepDuration   = track.pulsesPerStep * pulseDuration
            let isOddStep      = (stepIdx % 2 == 1)
            let swingDelay     = isOddStep
                ? stepDuration * ((swing / 100.0) - 0.5) * 0.66
                : 0.0

            let ratchets       = step.ratchet.rawValue
            let rInterval      = stepDuration / Double(ratchets)
            let capturedNotes  = step.notes
            let capturedVel    = step.velocity
            let capturedCh     = track.midiChannel
            let capturedGate   = step.gate
            let capturedOffset = track.timingOffset

            for r in 0..<ratchets {
                let onDelay  = max(0, swingDelay + capturedOffset + Double(r) * rInterval)
                // Bei Ratchet > 1: Gate auf max. 1 Ratchet-Slot begrenzen (kein Notenüberlapp).
                // Bei Ratchet = 1: Gate kann > 1 sein (langes Sustain über mehrere Steps).
                let effectiveGate = ratchets > 1 ? min(capturedGate, 1.0) : capturedGate
                let offDelay = onDelay + max(0.010, rInterval * effectiveGate)

                DispatchQueue.global(qos: .userInteractive)
                    .asyncAfter(deadline: .now() + onDelay) { [weak self] in
                        guard let self, self.isPlaying else { return }
                        capturedNotes.forEach {
                            self.midi.noteOn(channel: capturedCh, note: $0, velocity: capturedVel)
                        }
                        if r == ratchets - 1 { track.lastFiredNotes = capturedNotes }
                    }

                DispatchQueue.global(qos: .userInteractive)
                    .asyncAfter(deadline: .now() + offDelay) { [weak self] in
                        guard let self else { return }
                        capturedNotes.forEach { self.midi.noteOff(channel: capturedCh, note: $0) }
                        if r == ratchets - 1 { track.lastFiredNotes = [] }
                    }
            }
        }

        if track0Wrapped, let next = queuedPatternIndex {
            DispatchQueue.main.async {
                self.applyPatternSwitch(next)
                self.queuedPatternIndex = nil
            }
        }
    }

    // MARK: - Track management

    func addTrack() {
        for pattern in patterns {
            let n = pattern.tracks.count + 1
            let t = Track(name: "Track \(n)", midiChannel: min(n, 16))
            pattern.tracks.append(t)
        }
        numTracks = currentPattern.tracks.count
    }

    /// Inserts a new empty track directly after `index` in all patterns.
    func insertTrack(after index: Int) {
        for pattern in patterns {
            let n = pattern.tracks.count + 1
            let t = Track(name: "Track \(n)", midiChannel: min(n, 16))
            let insertAt = min(index + 1, pattern.tracks.count)
            pattern.tracks.insert(t, at: insertAt)
        }
        numTracks = currentPattern.tracks.count
        hasUnsavedChanges = true
    }

    func duplicateTrack(at index: Int) {
        for pattern in patterns {
            guard index < pattern.tracks.count,
                  let data = try? JSONEncoder().encode(pattern.tracks[index]),
                  let copy = try? JSONDecoder().decode(Track.self, from: data)
            else { continue }
            copy.name = pattern.tracks[index].name + " 2"
            pattern.tracks.insert(copy, at: index + 1)
        }
        numTracks = currentPattern.tracks.count
    }

    func removeTrack(at index: Int) {
        guard currentPattern.tracks.count > 1 else { return }
        for pattern in patterns {
            guard index < pattern.tracks.count else { continue }
            let track = pattern.tracks[index]
            track.lastFiredNotes.forEach { midi.noteOff(channel: track.midiChannel, note: $0) }
            pattern.tracks.remove(at: index)
        }
        numTracks = currentPattern.tracks.count
    }

    // MARK: - Incoming CC

    private func handleIncomingCC(_ number: Int, _ value: Int) {
        // Pattern switch
        if patternSwitchCC >= 0, number == patternSwitchCC {
            let idx = min(value / 32, 3)   // 0-31=A, 32-63=B, 64-95=C, 96-127=D
            switchPattern(idx)
        }
        // Track mute toggle
        for (i, ccNum) in trackMuteCCs.enumerated() {
            guard ccNum >= 0, number == ccNum else { continue }
            guard i < currentPattern.tracks.count else { continue }
            currentPattern.tracks[i].isMuted = value >= 64
        }
    }

    // MARK: - MIDI Learn

    func setLearnTarget(track: Int, step: Int) {
        guard learnMode else { return }
        learnTarget = (track, step)
    }

    private func handleLearnNoteOn(_ note: Int) {
        guard learnMode, let target = learnTarget else { return }
        let patterns = self.patterns
        for pattern in patterns {
            guard target.track < pattern.tracks.count else { continue }
            let track = pattern.tracks[target.track]
            guard target.step < track.steps.count else { continue }
            // Quantize to track's scale if active
            let quantized = track.quantizedNote(note)
            var steps = track.steps
            steps[target.step].note = quantized
            track.steps = steps
        }
        // Advance to next step automatically
        let nextStep = target.step + 1
        let trackObj = currentPattern.tracks[target.track]
        if nextStep < trackObj.stepCount {
            learnTarget = (target.track, nextStep)
        } else {
            learnTarget = nil
            learnMode  = false
        }
    }

    // MARK: - Randomize

    func randomize(track: Track, lockNotes: Bool = false) {
        track.objectWillChange.send()
        for i in 0..<track.stepCount {
            track.steps[i].isActive    = Bool.random()
            if !lockNotes {
                track.steps[i].note    = Int.random(in: 36...84)
            }
            track.steps[i].velocity    = Int.random(in: 60...120)
            track.steps[i].gate        = Double.random(in: 0.2...0.9)
            track.steps[i].probability = [1.0, 1.0, 1.0, 0.75, 0.5].randomElement()!
            track.steps[i].cc1Value    = Int.random(in: 0...127)
            track.steps[i].cc2Value    = Int.random(in: 0...127)
        }
    }

    // MARK: - Save / Load

    /// Published so TransportView can display the filename.
    @Published var currentPresetURL: URL? = nil
    /// True whenever patterns/bpm/swing have changed since last save/load.
    @Published var hasUnsavedChanges: Bool = false

    /// Wrapper that includes engine-level settings alongside the pattern data.
    private struct PresetFile: Codable {
        var bpm:      Double
        var swing:    Double
        var patterns: [Pattern]
    }

    func saveData() -> Data? {
        let file = PresetFile(bpm: bpm, swing: swing, patterns: patterns)
        return try? JSONEncoder().encode(file)
    }

    func loadData(_ data: Data) {
        // Try new wrapper format first, fall back to legacy [Pattern] array.
        if let file = try? JSONDecoder().decode(PresetFile.self, from: data) {
            stop()
            bpm      = file.bpm
            swing    = file.swing
            patterns = file.patterns
        } else if let loaded = try? JSONDecoder().decode([Pattern].self, from: data) {
            stop()
            patterns = loaded
        }
        hasUnsavedChanges = false
    }

    func savePreset() {
        guard let data = saveData() else { return }
        let panel = NSSavePanel()
        panel.title = "Save Preset"
        panel.allowedContentTypes = [UTType.json]
        panel.nameFieldStringValue = currentPresetURL?.lastPathComponent ?? "MyPreset.json"
        if panel.runModal() == .OK, let url = panel.url {
            try? data.write(to: url)
            currentPresetURL  = url
            hasUnsavedChanges = false
        }
    }

    func loadPreset() {
        if hasUnsavedChanges {
            let alert = NSAlert()
            alert.messageText    = "Ungespeicherte Änderungen"
            alert.informativeText = "Soll das aktuelle Preset gespeichert werden?"
            alert.addButton(withTitle: "Speichern")
            alert.addButton(withTitle: "Verwerfen")
            alert.addButton(withTitle: "Abbrechen")
            switch alert.runModal() {
            case .alertFirstButtonReturn:  savePreset()
            case .alertSecondButtonReturn: break   // discard
            default: return                        // cancel → abort load
            }
        }

        let panel = NSOpenPanel()
        panel.title = "Load Preset"
        panel.allowedContentTypes = [UTType.json]
        panel.allowsMultipleSelection = false
        if panel.runModal() == .OK,
           let url = panel.url,
           let data = try? Data(contentsOf: url) {
            loadData(data)
            currentPresetURL = url
        }
    }

    // MARK: - Copy / Paste Pattern

    @Published var clipboard:     Pattern? = nil
    @Published var stepClipboard: [Step]   = []

    func copySteps(from track: Track, at indices: [Int]) {
        stepClipboard = indices.sorted().map { track.steps[$0] }
    }

    func pasteSteps(to track: Track, at indices: [Int]) {
        guard !stepClipboard.isEmpty else { return }
        var steps = track.steps
        for (offset, idx) in indices.sorted().enumerated() {
            steps[idx] = stepClipboard[offset % stepClipboard.count]
        }
        track.steps = steps
    }

    func copyCurrentPattern() {
        guard let data = try? JSONEncoder().encode(currentPattern),
              let copy = try? JSONDecoder().decode(Pattern.self, from: data) else { return }
        clipboard = copy
    }

    func pasteToCurrentPattern() {
        guard let src = clipboard,
              let data = try? JSONEncoder().encode(src),
              let copy = try? JSONDecoder().decode(Pattern.self, from: data) else { return }
        copy.name = currentPattern.name   // Namen A/B/C/D behalten
        patterns[currentPatternIndex] = copy
    }
}
