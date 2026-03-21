# Steph Sequencer — Technische Dokumentation
**Version 0.16 · Stand: 2026-03**

---

## Architektur-Überblick

```
VintageSequencerApp.swift       App-Einstieg, AppDelegate, EnvironmentObject
├── Engine/
│   └── SequencerEngine.swift   ObservableObject: Timing, MIDI, State
├── Models/
│   ├── Pattern.swift           Codable: Array von Tracks
│   ├── Track.swift             ObservableObject + Codable: Steps, Timing
│   └── Step.swift              Codable: Note, Gate, Prob, Ratchet, Chord
├── Views/
│   ├── ContentView.swift       Root-Layout: TransportView + TrackScrollView
│   ├── TransportView.swift     Transport-Leiste
│   ├── TrackRowView.swift      Track-Header + Step-Lane + Rubber-Band
│   ├── StepButtonView.swift    Einzelner Step-Button
│   ├── StepDetailView.swift    ⌥+Klick-Editor + MultiStepEditView
│   ├── KnobView.swift          Drehregler-Component
│   └── SettingsView.swift      MIDI-Port-Auswahl
└── Theme/
    └── VintageTheme.swift      Farben, Fonts, Layout-Konstanten
```

**State-Flow**: `SequencerEngine` (ObservableObject) hält alle Patterns als `@Published`. Views abonnieren via `@EnvironmentObject`. `Track` ist `ObservableObject`, wird in Listen per `@ObservedObject` verwendet.

---

## Datenmodell

### Step

```swift
struct Step: Codable, Identifiable {
    var id: UUID
    var isActive: Bool
    var note: Int            // MIDI-Note 0–127
    var octave: Int          // Relativ-Oktave, angewandt auf note
    var velocity: Int        // 0–127
    var gate: Double         // Vielfaches einer 16tel-Note; 1.0 = Legato, 16.0 = Ganze
    var probability: Double  // 0.0–1.0
    var ratchets: Int        // 1–8 Wiederholungen pro Step
    var chord: ChordType     // None | Major | Minor | Dom7 | Maj7 | Min7 | Dim | Aug | Sus2 | Sus4
}
```

**Gate-Semantik**: `gate` ist ein Multiplikator auf die Dauer eines 16tel-Schrittes. Engine-seitig:
```
noteDuration = pulseDuration * track.pulsesPerStep * gate
```
Bei Ratchet > 1:
```
effectiveGate = ratchets > 1 ? min(gate, 1.0) : gate
```

**GateStep** (für die UI):
```swift
struct GateStep { let value: Double; let label: String }
static let gateSteps: [GateStep] = [
    (0.05, "stac"), (0.25, "1/64"), (0.50, "1/32"), (1.00, "1/16"),
    (1.50, "1/16."), (2.00, "1/8"), (3.00, "1/8."), (4.00, "1/4"),
    (6.00, "1/4."), (8.00, "1/2"), (12.00, "1/2."), (16.00, "1/1")
]
```

---

### Track

```swift
class Track: ObservableObject, Codable, Identifiable {
    var id: UUID
    @Published var name: String
    @Published var steps: [Step]
    @Published var stepCount: Int           // Aktive Step-Anzahl (1–64)
    @Published var midiChannel: Int         // 1–16
    @Published var direction: Direction     // forward/backward/pingpong/random/randomOnce
    @Published var isMuted: Bool
    @Published var isSolo: Bool
    @Published var cycleLengthSteps: Int?   // nil = natürlich, Int = Stretch-Ziel

    // Runtime (nicht serialisiert)
    var pulseAccumulator: Double = 0        // Akkumulator für Per-Track-Timing
    var currentStep: Int = 0               // Aktuell gespielter Step-Index
}
```

**Computed Properties:**
```swift
var pulsesPerStep: Double {
    Double((cycleLengthSteps ?? stepCount) * 6) / Double(stepCount)
}
```
Beispiel: 7 Steps, Stretch auf 8 → `8*6/7 = 6.857` Pulse pro Step.

---

### Pattern

```swift
struct Pattern: Codable, Identifiable {
    var id: UUID
    var name: String
    var tracks: [Track]
}
```

---

## Engine: Timing-Architektur

### Pulse-Grundlage
- CoreMIDI-Clock: **24 PPQ** (Pulses Per Quarter Note)
- Interne Auflösung: **6 Pulse pro 16tel-Note** (1 Step = 6 Pulse bei natürlicher Länge)
- `pulseDuration = 60.0 / (bpm * 24.0)` Sekunden pro Puls

### Per-Track Pulse-Akkumulator (seit v0.14)

Jeder Track hat einen eigenen `pulseAccumulator: Double`. Bei jedem MIDI-Puls (24x pro Viertel):

```swift
func advanceSteps() {
    for track in currentPattern.tracks {
        track.pulseAccumulator += 1.0
        guard track.pulseAccumulator >= track.pulsesPerStep else { continue }
        track.pulseAccumulator -= track.pulsesPerStep   // Carry-over — kein Drift
        fireStep(track)
    }
}
```

**Vorteil gegenüber globalem Zähler**: Bresenham-ähnliches Prinzip — der Remainder wird mitgeführt, sodass keine Drift-Fehler entstehen, auch bei nicht-ganzzahligen `pulsesPerStep`-Werten.

### Gate-Berechnung
```swift
let stepDuration = track.pulsesPerStep * pulseDuration
let capturedGate = step.gate
let effectiveGate = ratchets > 1 ? min(capturedGate, 1.0) : capturedGate
let noteDuration = stepDuration * effectiveGate
```

### Swing
```swift
// engine.swing: 50.0 (gerade) … 75.0 (maximaler Swing)
// swingOffset wird auf ungerade Steps (1, 3, 5, …) addiert
let swingOffset = (engine.swing - 50.0) / 50.0 * (stepDuration * 0.5)
```

---

## Preset-Format (v0.16)

### Aktuelles Format
```json
{
  "bpm": 120.0,
  "swing": 50.0,
  "patterns": [
    {
      "id": "...",
      "name": "Pattern A",
      "tracks": [
        {
          "id": "...",
          "name": "Track 1",
          "stepCount": 16,
          "midiChannel": 1,
          "direction": "forward",
          "cycleLengthSteps": null,
          "steps": [
            {
              "id": "...",
              "isActive": true,
              "note": 60,
              "octave": 0,
              "velocity": 100,
              "gate": 1.0,
              "probability": 1.0,
              "ratchets": 1,
              "chord": "none"
            }
          ]
        }
      ]
    }
  ]
}
```

### Backward Compatibility
`loadData()` in `SequencerEngine` versucht zuerst das `PresetFile`-Wrapper-Format. Bei Fehler wird auf direktes `[Pattern]`-Array zurückgefallen (Format vor v0.13).

---

## Views: Wichtige Details

### TrackRowView — Rubber-Band-Selektion

**Problem**: `DragGesture` innerhalb einer `ScrollView` wird vom ScrollView-Gesture abgefangen.

**Lösung**: Gesture lebt auf dem äußeren `GeometryReader` (außerhalb der ScrollView). Scroll-Offset wird via `PreferenceKey` getrackt.

```swift
struct ScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
```

Koordinaten-Mapping:
```swift
// viewX = Position im äußeren GeometryReader
// scrollOffset = negativer Wert beim Scrollen nach rechts
let contentX = viewX - scrollOffset - headerPadding
let stepIndex = Int(contentX / (stretchedStepWidth + stepSpacing))
```

Der GeometryReader hat `.frame(maxHeight: .infinity)` damit Klicks unterhalb der Step-Buttons ebenfalls die Gesture triggern.

### StepButtonView — Stretch-Breite

```swift
struct StepButtonView: View {
    var width: CGFloat? = nil
    // ...
    .frame(width: width ?? size, height: size)
}
```

Bei gestretchten Tracks: `width = stretchedStepWidth = engine.stepDisplaySize * (Double(cycleLengthSteps) / Double(stepCount))`

### GateSelectorView

Ersetzt den alten `KnobView(GATE%)`. Zeigt zwei Reihen von Buttons (kurze Gates ≤ 1.5, lange Gates > 1.5). Aktiver Wert wird highlighted. Beide `StepDetailView` und `MultiStepEditView` verwenden dieselbe Component.

### MIDI-Kanal Picker (seit v0.16)

```swift
Picker("", selection: $track.midiChannel) {
    ForEach(1...16, id: \.self) { ch in
        Text(ch == 10 ? "10 ◆" : "\(ch)").tag(ch)
    }
}
.labelsHidden()
.frame(width: 56)
```

Ersetzt die alte `[-][ch][+]`-UI, die bei zweistelligen Kanal-Nummern zu eng wurde.

---

## Unsaved-Changes-System

`SequencerEngine`:
```swift
@Published var hasUnsavedChanges: Bool = false
@Published var currentPresetURL: URL? = nil
```

`bpm.didSet` und `swing.didSet` setzen `hasUnsavedChanges = true`. Track/Step-Änderungen via `objectWillChange.send()`.

`AppDelegate.applicationShouldTerminate` zeigt NSAlert wenn `hasUnsavedChanges == true`.

`loadPreset()` zeigt NSAlert wenn `hasUnsavedChanges == true` (Ladeschutz).

---

## BPMGridView

`Canvas`-basierte View als ZStack-Hintergrund hinter den Step-Buttons:

```swift
// Beat-Linie (alle 4 Steps) — schwaches Amber
// Takt-Linie (alle 16 Steps) — helleres Amber
for i in 0..<stepCount {
    let x = CGFloat(i) * (stepWidth + stepSpacing)
    if i % 16 == 0 { /* Takt */ }
    else if i % 4 == 0 { /* Beat */ }
}
```

---

## StretchHandleView

```swift
struct StretchHandleView: View {
    @EnvironmentObject var engine: SequencerEngine
    @ObservedObject var track: Track
    @State private var dragBase: Int? = nil

    private func snapCycle(_ raw: Int) -> Int {
        var targets: Set<Int> = []
        let n = track.stepCount
        for v in [2,3,4,5,6,7,8,9,10,12,14,16] { targets.insert(v) }
        for d in -3...3 { targets.insert(n + d) }
        targets.insert(n * 2); targets.insert(max(1, n / 2))
        let lo = max(1, n / 2); let hi = n * 2
        return targets.filter { $0 >= lo && $0 <= hi }
                      .min(by: { abs($0 - raw) < abs($1 - raw) }) ?? raw
    }
}
```

---

## Versionshistorie

| Version | Änderungen |
|---------|-----------|
| 0.16 | MIDI-Ch. Picker, Ordnerstruktur, Docs, 5-against-4-Patch |
| 0.15 | Polyrhythm Stretch-Handle, BPM-Raster, Gate bis 1/1, Rubber-Band-Fix, Tooltips, Escape-Deselect |
| 0.14 | Per-Track Pulse-Akkumulator (polyrhythmisches Timing-Engine), bpm/swing in Presets, Unsaved-Changes-Warnung |
| 0.13 | PresetFile-Wrapper-Format, backward compat |
| 0.12 | Rubber-Band-Selektion (erste Version) |
| 0.10 | Multi-Step-Edit, Copy/Paste |
| 0.08 | Ratchet, Probability |
| 0.06 | Chord-Types, ChordType enum |
| 0.04 | Pattern A–D, MIDI Learn |
| 0.01 | Grundversion: Tracks, Steps, CoreMIDI |

---

## Build & Deployment

- **Xcode**: 15+
- **macOS Deployment Target**: 13.5 (Ventura)
- **Swift**: 5.9+
- **Frameworks**: SwiftUI, CoreMIDI, Combine
- Keine externen Abhängigkeiten / Package Manager

### App aus Xcode bauen
1. Schema `VintageSequencer` → `My Mac` wählen
2. **Product → Archive** für Distribution
3. Oder **⌘R** für lokales Testen

### Git-Einrichtung
```bash
cd "/path/to/Vintage Sequencer App/VintageSequencer"
git init
echo "*.xcuserstate\nxcuserdata/\n.DS_Store\nDerivedData/" > .gitignore
git add .
git commit -m "Initial commit — Steph Sequencer v0.16"
```

---

## Bekannte Einschränkungen

- Rubber-Band-Selektion funktioniert nicht wenn der Mauszeiger auf einem aktiven Step beginnt (dort startet der Step-Toggle-Gesture)
- Bei sehr vielen Steps (> 48) und kleiner Fenstergröße kann die Stretch-Handle-UI abgeschnitten sein
- `cycleLengthSteps` wird pro Pattern gespeichert, aber der Stretch-Handle zeigt keine visuelle Markierung im Step-Grid

---

*Maintainer: Stephan Schmitt*
