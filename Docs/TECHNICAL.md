# Steph Sequencer — Technische Dokumentation
**Version 0.9 · Stand: 2026-03**

---

## Architektur-Überblick

```
VintageSequencerApp.swift       App-Einstieg, AppDelegate, EnvironmentObject
├── Engine/
│   ├── SequencerEngine.swift   ObservableObject: Timing, MIDI, State
│   └── MIDIManager.swift       CoreMIDI-Wrapper
├── Models/
│   ├── Pattern.swift           Codable: Array von Tracks
│   ├── Track.swift             ObservableObject + Codable: Steps, Timing, Ratio
│   └── Step.swift              Codable: Note, Gate, Prob, Ratchet, Chord
├── Views/
│   ├── MainView.swift          Root-Layout + globales BPM-Raster
│   ├── TransportView.swift     Transport-Leiste
│   ├── TrackRowView.swift      Container: Header + ScrollView + Handle
│   ├── TrackHeaderView.swift   Linke Kopfzeile (Name, CH, Direction, FEEL, SCL)
│   ├── StepLaneView.swift      ScrollView: Steps + CC-Rows synchron
│   ├── BPMGridView.swift       Globaler Canvas-Hintergrund (beat grid)
│   ├── StretchHandleView.swift Ratio + Step-Count Handle
│   ├── CCRowView.swift         CC-Automation-Reihen
│   ├── StepButtonView.swift    Einzelner Step-Button
│   ├── StepDetailView.swift    ⌥+Klick-Editor + MultiStepEditView
│   ├── KnobView.swift          Drehregler-Component
│   └── SettingsView.swift      MIDI-Port-Auswahl
└── Theme/
    └── VintageTheme.swift      Farben, Fonts, Layout-Konstanten
```

**State-Flow**: `SequencerEngine` (ObservableObject) hält alle Patterns als `@Published`. Views abonnieren via `@EnvironmentObject`. `Track` ist `ObservableObject`, wird per `@ObservedObject` in Listen verwendet.

---

## Datenmodell

### Step

```swift
struct Step: Codable, Identifiable {
    var id: UUID
    var isActive: Bool
    var note: Int            // MIDI-Note 0–127
    var octave: Int          // Relativ-Oktave
    var velocity: Int        // 0–127
    var gate: Double         // Vielfaches einer 16tel-Note; 1.0 = Legato, 16.0 = Ganze
    var probability: Double  // 0.0–1.0
    var ratchets: Int        // 1–8 Wiederholungen pro Step
    var chord: ChordType
    var cc1Value: Int        // 0–127
    var cc2Value: Int        // 0–127
}
```

**Gate-Semantik**: `gate` ist Multiplikator auf die Dauer eines 16tel-Schrittes:
```
noteDuration = pulseDuration * track.pulsesPerStep * gate
effectiveGate = ratchets > 1 ? min(gate, 1.0) : gate
```

---

### Track

```swift
class Track: ObservableObject, Codable, Identifiable {
    var id: UUID
    @Published var name: String
    @Published var steps: [Step]         // immer 64 Slots, stepCount.didSet wächst mit
    @Published var stepCount: Int        // aktive Steps (1–64)
    @Published var midiChannel: Int      // 1–16
    @Published var direction: PlayDirection
    @Published var isMuted: Bool
    @Published var isSolo: Bool
    @Published var timingOffset: Double  // FEEL: −0.05 … +0.05 Sekunden
    @Published var scaleRoot: Int        // 0–11
    @Published var scaleIndex: Int       // 0 = keine Skala

    // Ratio-Modell (seit v0.9, ersetzt cycleLengthSteps)
    @Published var stepLengthNumerator:   Int = 1
    @Published var stepLengthDenominator: Int = 1

    // Runtime (nicht serialisiert)
    var pulseAccumulator: Double = 0
    var currentStep: Int = 0
}
```

**Ratio-Modell** (seit v0.9):

`stepLengthNumerator / stepLengthDenominator` beschreibt die Länge eines Steps als Bruchteil einer 16tel-Note:

| Ratio | pulsesPerStep | Bedeutung |
|-------|---------------|-----------|
| 1/1 | 6.0 | normaler 16tel-Step |
| 2/3 | 4.0 | Triolen-Step (schneller) |
| 3/2 | 9.0 | punktierter Step (langsamer) |
| 1/2 | 3.0 | 32tel-Step |
| 2/1 | 12.0 | Achtel-Step |

```swift
var pulsesPerStep: Double {
    6.0 * Double(stepLengthNumerator) / Double(stepLengthDenominator)
}
```

**stepCount.didSet**: erweitert `steps`-Array automatisch wenn stepCount wächst:
```swift
didSet {
    while steps.count < stepCount { steps.append(Step()) }
}
```

**Migration von cycleLengthSteps** (alte Presets vor v0.9):
```swift
// Beim Laden: cycle=9, stepCount=6 → GCD(9,6)=3 → num=3, den=2 → "3:2"
let g = gcd(cycle, stepCount)
stepLengthNumerator   = cycle    / g
stepLengthDenominator = stepCount / g
```

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
- CoreMIDI-Clock: **24 PPQ**
- Interne Auflösung: **6 Pulse pro 16tel-Note** bei 1:1-Ratio
- `pulseDuration = 60.0 / (bpm * 24.0)` Sekunden pro Puls

### Per-Track Pulse-Akkumulator

Jeder Track hat einen eigenen `pulseAccumulator: Double`. Bei jedem MIDI-Puls:

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

Bresenham-Prinzip: Remainder wird mitgeführt → kein Drift bei nicht-ganzzahligen Werten.

### Gate-Berechnung
```swift
let stepDuration   = track.pulsesPerStep * pulseDuration
let effectiveGate  = ratchets > 1 ? min(gate, 1.0) : gate
let noteDuration   = stepDuration * effectiveGate
```

### Swing
```swift
// swing: 0.0 (gerade) … 1.0 (maximaler Swing)
// swingOffset auf ungerade Steps addiert
let swingOffset = engine.swing * stepDuration * 0.5
```

### Mute/Solo-Logik
```swift
let effectiveMute = track.isMuted || (hasSolo && !track.isSolo)
```
Mute gewinnt immer — identisch mit Logic Pro.

---

## Preset-Format (v0.9)

```json
{
  "bpm": 120.0,
  "swing": 0.0,
  "patterns": [
    {
      "id": "...",
      "name": "Pattern A",
      "tracks": [
        {
          "id": "...",
          "name": "Track 1",
          "stepCount": 7,
          "midiChannel": 1,
          "direction": "forward",
          "stepLengthNumerator": 4,
          "stepLengthDenominator": 3,
          "timingOffset": 0.0,
          "scaleRoot": 0,
          "scaleIndex": 0,
          "steps": [ ... ]
        }
      ]
    }
  ]
}
```

**Backward Compatibility**:
- Altes `cycleLengthSteps`-Feld wird beim Laden automatisch zu `stepLengthNumerator/Denominator` migriert
- Altes `[Pattern]`-Array-Format (vor v0.13) wird ebenfalls erkannt

---

## Views: Wichtige Details

### BPMGridView (global, seit v0.9)

Liegt einmal als `.overlay` auf dem äußeren Container in `MainView` — **nicht** pro Track. Scrollt nicht mit. Zeichnet Viertelnoten-Linien (alle 4 Steps) als fixen Hintergrund:

```swift
struct BPMGridView: View {
    @EnvironmentObject var engine: SequencerEngine

    private var stepAreaX: CGFloat {
        12 + VintageTheme.trackHeaderWidth + 1 + 8   // outerPad + header + separator + hstackPad
    }

    private var naturalStepWidth: CGFloat {
        CGFloat(engine.stepDisplaySize) + VintageTheme.stepSpacing
    }
    // Canvas: Beat-Linien alle 4 * naturalStepWidth Pixel ab stepAreaX
    // .allowsHitTesting(false) — empfängt keine Klicks
}
```

### StretchHandleView

Kompaktes Widget rechts neben der Lane. Horizontales Layout:

```
[ Bruch-Anzeige | Step-Count ]
```

- **Links**: Drag (↑↓, 24px/Schritt) durch 13 musikalische Ratios; Klick → Popover
- **Rechts**: Drag (↑↓, 18px/Schritt) für Step-Anzahl (1–64)
- **Drag-Fix**: `dragStartY` wird beim ersten Event eingefroren, Delta = `-(moved / sensitivity).rounded()` → kein initialer Sprung

```swift
// Beim ersten onChanged-Event:
dragStartY    = value.translation.height   // aktuellen Wert als Basis einfrieren
dragBaseIndex = currentRatioIndex

// In jedem Event:
let moved = value.translation.height - dragStartY!
let delta = -Int((moved / 24.0).rounded())
```

Die 13 Ratios (sortiert nach Schrittlänge, aufsteigend):
```swift
[(1,2), (4,7), (2,3), (3,4), (4,5), (8,9), (1,1),
 (9,8), (5,4), (4,3), (3,2), (7,4), (2,1)]
```

### CCRowView

- Skaliert mit `engine.stepDisplaySize`: `kSize = max(20, stepDisplaySize - 16)`
- Knob-Frame-Breite = `stretchedStepWidth` (folgt dem Stretch des Tracks)
- Scrollt synchron mit Steps (gemeinsamer ScrollView in TrackRowView)
- Zeilenhöhe: `CCKnobRowView.rowHeight(stepDisplaySize:)` als statische Methode — einzige Wahrheitsquelle

### TrackHeaderView

- Direction-Buttons: SF Symbols (`play.fill`, `backward.end.fill`, `arrow.left.arrow.right`, `waveform`)
- Löschen-Button: kleines `×` oben links
- Rechtsklick-Kontextmenü auf freier Fläche (Buttons haben leeres `.contextMenu {}` zur Unterdrückung)
- TextField-Fokus: globaler `NSEvent`-Monitor im AppDelegate, `makeFirstResponder(nil)` bei Klick auf Nicht-TextField

### Rubber-Band-Selektion

DragGesture lebt auf dem äußeren GeometryReader (außerhalb ScrollView). Scroll-Offset via PreferenceKey:

```swift
let contentX = viewX - scrollOffset - headerPadding
let stepIndex = Int(contentX / (stretchedStepWidth + stepSpacing))
```

Guard: `value.startLocation.y < stepRowHeight` — verhindert Aktivierung in der CC-Zone.

### Tooltip-System

```swift
@AppStorage("showTooltips") var showTooltips: Bool = true

func tip(_ text: String) -> String {
    showTooltips ? text : ""
}

// Verwendung:
Button(...).help(tip("Erklärungstext"))
```

Menüeintrag: **Ansicht → Tooltips anzeigen** (⌘⌥T)

---

## Unsaved-Changes-System

```swift
// SequencerEngine:
@Published var hasUnsavedChanges: Bool = false
@Published var currentPresetURL: URL? = nil
```

- `bpm.didSet` / `swing.didSet` → `hasUnsavedChanges = true`
- `AppDelegate.applicationShouldTerminate` → NSAlert bei ungespeicherten Änderungen
- `loadPreset()` → NSAlert als Ladeschutz

---

## Technisches Glossar

Präzise Definitionen der Fachbegriffe, die in Codebase und Dokumentation verwendet werden.

---

### @AppStorage
SwiftUI-Property-Wrapper, der einen Wert direkt in `UserDefaults` speichert und bei Änderung die View automatisch aktualisiert. Wird im Tooltip-System verwendet: `@AppStorage("showTooltips") var showTooltips: Bool = true`.

---

### @EnvironmentObject
SwiftUI-Mechanismus, mit dem ein `ObservableObject` (z. B. `SequencerEngine`) im View-Baum nach unten weitergegeben wird, ohne es an jede View manuell zu übergeben. Views abonnieren Änderungen automatisch.

---

### @ObservedObject
SwiftUI-Property-Wrapper für ein `ObservableObject`, das von außen übergeben wird (z. B. ein einzelner `Track` in `TrackRowView`). Die View rendert neu, wenn sich `@Published`-Properties des Objekts ändern.

---

### @Published
Combine-Property-Wrapper: löst `objectWillChange` aus, wenn sich der Wert ändert. Alle UI-relevanten Properties in `Track` und `SequencerEngine` sind `@Published`.

---

### Bresenham-Prinzip
Algorithmus aus der Computergrafik (Linienrasterung), hier übertragen auf die Timing-Engine: Der Restbetrag nach jedem Schritt wird akkumuliert statt verworfen (`pulseAccumulator -= pulsesPerStep`). Dadurch entsteht kein Drift bei nicht-ganzzahligen `pulsesPerStep`-Werten (z. B. 4.0 bei Triolen).

---

### Codable
Swift-Protokoll (zusammengesetzt aus `Encodable` + `Decodable`). Ermöglicht automatische JSON-Serialisierung. `Step`, `Pattern` und `Track` konformieren zu `Codable` — deshalb können Presets als `.json`-Dateien gespeichert und geladen werden.

---

### CoreMIDI
Apple-Framework für MIDI-I/O auf macOS. Liefert den externen MIDI-Clock (24 PPQ), empfängt und sendet MIDI-Nachrichten auf Hardware-Ebene. Im Sequencer via `MIDIManager.swift` gekapselt.

---

### cycleLengthSteps (deprecated)
Altes Feld (vor v0.9): absolute Anzahl von 16tel-Pulsen pro Step-Zyklus. Wurde durch das Ratio-Modell (`stepLengthNumerator / stepLengthDenominator`) ersetzt. Beim Laden alter Presets wird der Wert via GCD automatisch migriert.

---

### didSet
Swift-Property-Observer: Code-Block, der nach jeder Wertänderung ausgeführt wird. Im Sequencer z. B. bei `stepCount.didSet` (Array erweitern) und `bpm.didSet` (hasUnsavedChanges setzen).

---

### EnvironmentObject → *siehe @EnvironmentObject*

---

### GCD (Greatest Common Divisor)
Größter gemeinsamer Teiler — mathematische Funktion, die beim Migrations-Algorithmus den alten `cycleLengthSteps`-Wert in einen reduzierten Bruch (num/den) umrechnet. Implementiert rekursiv: `func gcd(_ a: Int, _ b: Int) -> Int { b == 0 ? a : gcd(b, a % b) }`.

---

### NSAlert
AppKit-Klasse für modale Dialoge (Fehlermeldungen, Bestätigungen). Wird im Sequencer für „Ungespeicherte Änderungen"-Warnungen beim Beenden und vor dem Laden eines neuen Presets verwendet.

---

### NSEvent-Monitor
AppKit-API (`NSEvent.addLocalMonitorForEvents(matching:)`), die alle System-Events des Fensters abfängt. Im AppDelegate registriert, um TextField-Fokus zu entfernen (`makeFirstResponder(nil)`), wenn der Nutzer irgendwo außerhalb eines Textfelds klickt.

---

### NSUndoManager
AppKit-Klasse für den Undo/Redo-Stack. Verwaltet eine Liste von Rückgängig-Aktionen. Im Sequencer für bestimmte destruktive Operationen (RND, CLR) registriert. Step-Toggles und Drag-Änderungen sind in v0.9 **noch nicht** im Undo-Stack.

---

### ObservableObject
Combine-Protokoll: Objekte, die `objectWillChange` publizieren. `SequencerEngine` und `Track` sind `ObservableObject`. SwiftUI-Views reagieren automatisch auf Änderungen.

---

### PPQ (Pulses Per Quarter Note)
Auflösung einer MIDI-Clock. Standard: **24 PPQ** (24 Pulse pro Viertelnote). Der Sequencer empfängt diese Pulse über CoreMIDI und zählt pro Track in `pulseAccumulator` hoch.

---

### PreferenceKey
SwiftUI-Mechanismus, mit dem Child-Views Werte nach oben an Parent-Views kommunizieren (entgegen dem normalen Datenfluss). Im Sequencer für den Scroll-Offset der Lane-ScrollView verwendet, damit die Rubber-Band-Selektion im äußeren GeometryReader korrekte Step-Indizes berechnen kann.

---

### pulsesPerStep
Berechnete Property in `Track`: gibt an, wie viele MIDI-Pulse ein Step dauert.
```swift
var pulsesPerStep: Double {
    6.0 * Double(stepLengthNumerator) / Double(stepLengthDenominator)
}
```
Bei 1:1-Ratio = 6.0 (sechs 24-PPQ-Pulse = eine 16tel-Note). Bei Triolen (2:3) = 4.0 (schneller). Bei Achteln (2:1) = 12.0 (langsamer).

---

### pulseAccumulator
Laufzeit-Variable in `Track` (nicht serialisiert). Wird bei jedem MIDI-Puls um 1.0 erhöht. Sobald `pulseAccumulator >= pulsesPerStep`, wird der nächste Step gefeuert und der Restbetrag weitergetragen (Bresenham-Prinzip).

---

### Ratio-Modell
Seit v0.9: Beschreibt die Step-Länge als reduzierter Bruch `stepLengthNumerator : stepLengthDenominator` (relativ zur normalen 16tel-Note). Erlaubt Polyrhythmus, Triolen, punktierte Noten etc. unabhängig von der absoluten Step-Anzahl.

---

### stretchedStepWidth
Berechnete Breite eines Step-Buttons unter Berücksichtigung des Ratios:
```
stretchedStepWidth = (baseStepWidth + stepSpacing) * (num / den) - stepSpacing
```
Wird in `CCRowView` und der Rubber-Band-Berechnung verwendet, damit CC-Knöpfe und Selektion mit der visuellen Step-Breite übereinstimmen.

---

### UUID (Universally Unique Identifier)
128-Bit-Zufalls-ID, in Swift via `UUID()` erzeugt. Alle Datenmodelle (`Step`, `Track`, `Pattern`) verwenden `UUID` als stabilen Identifier — wichtig für `ForEach`-Identifikation in SwiftUI und JSON-Serialisierung.

---

## Versionshistorie

| Version | Änderungen |
|---------|-----------|
| 0.9 | Ratio-Modell (stepLengthNumerator/Denominator), globales BPM-Raster, File-Split, StretchHandle-Redesign, Tooltip-System, Rechtsklick-Kontextmenü, Direction-Symbole, globaler TextField-Fokus-Monitor, CC-Row-Scroll-Sync |
| 0.17/0.18 | File-Split (TrackRowView → 5 Dateien), Drag-Fix (Basis einfrieren), CC-Skalierung |
| 0.16 | MIDI-Ch. Picker, Ordnerstruktur, Docs, 5-against-4-Patch |
| 0.15 | Polyrhythm Stretch-Handle, BPM-Raster, Gate bis 1/1, Rubber-Band-Fix, Tooltips, Escape-Deselect |
| 0.14 | Per-Track Pulse-Akkumulator, bpm/swing in Presets, Unsaved-Changes-Warnung |
| 0.13 | PresetFile-Wrapper-Format, backward compat |
| 0.12 | Rubber-Band-Selektion |
| 0.10 | Multi-Step-Edit, Copy/Paste |
| 0.08 | Ratchet, Probability |
| 0.06 | Chord-Types |
| 0.04 | Pattern A–D, MIDI Learn |
| 0.01 | Grundversion |

---

## Build & Deployment

- **Xcode**: 15+
- **macOS Deployment Target**: 13.5 (Ventura)
- **Swift**: 5.9+
- **Frameworks**: SwiftUI, CoreMIDI, Combine
- Keine externen Abhängigkeiten

### Git-Workflow
```bash
cd "/Users/stephanschmitt/Library/Mobile Documents/com~apple~CloudDocs/Mainstage etc/Gamepad-MIDI/Vintage Sequencer App"
git add .
git commit -m "v0.9 – Beschreibung"
git push https://easysteve-coder:TOKEN@github.com/easysteve-coder/Steph-Sequenzer.git main
```

---

*Maintainer: Stephan Schmitt*
