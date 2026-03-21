# Steph Sequencer — Technische Dokumentation

Entwicklerdokumentation für neue Chat-Sessions. Enthält alles Nötige um sofort mit dem Code arbeiten zu können.

---

## Projektübersicht

| | |
|---|---|
| **Projektname** | Steph Sequencer (früher: Vintage Sequencer) |
| **Aktuelle Version** | 0.13 |
| **Deployment Target** | macOS 13.5 |
| **Framework** | SwiftUI + CoreMIDI + AVFoundation |
| **Sprache** | Swift 5.9+ |

### Xcode Projektpfad

```
/Users/stephanschmitt/Library/Mobile Documents/com~apple~CloudDocs/Mainstage etc/Gamepad-MIDI/Vintage Sequencer App/VintageSequencer/VintageSequencer/
```

> **WICHTIG — Zwei Kopien der Dateien:**
> Es existieren zwei Ordner mit ähnlichem Namen:
> - `/Vintage Sequencer App/VintageSequencer/VintageSequencer/` ← **IMMER HIER EDITIEREN**
> - `/VintageSequencer/` (Original-Ordner ohne "Vintage Sequencer App/") ← **NICHT EDITIEREN**
>
> Xcode kompiliert ausschließlich aus dem Pfad mit "Vintage Sequencer App/". Änderungen im anderen Ordner haben keinen Effekt.

---

## Dateistruktur

### Theme/

**`Theme/VintageTheme.swift`**
- Alle globalen Farben, Fonts, Dimensionen
- `appVersion: String` — aktuelle Versionsnummer
- Zentrale Styling-Konstanten für die gesamte App

### Models/

**`Models/Step.swift`**

Struct mit Codable-Konformanz. Felder:
- `isActive: Bool`
- `note: Int` (0–127)
- `velocity: Int` (1–127)
- `gate: Double` (0.0–1.0, repräsentiert 1–100 %)
- `probability: Double` (0.0–1.0)
- `ratchet: RatchetCount` — Enum: `x1 = 1`, `x2 = 2`, `x4 = 4`
- `cc1Value: Int` (0–127)
- `cc2Value: Int` (0–127)
- `noteName: String` (computed, z.B. "C4")

`GMDrumMap` Enum — entweder hier oder in `GMDrumMap.swift` definiert. **Nur an einer Stelle definieren** — doppelte Definition führt zu Redeclaration-Fehler.

---

**`Models/Track.swift`**

`final class` mit ObservableObject + Codable. Felder:
- `name: String`
- `stepCount: Int` (1–32)
- `steps: [Step]` (@Published)
- `midiChannel: Int` (1–16)
- `cc1Number: Int`, `cc2Number: Int`
- `cc1Label: String`, `cc2Label: String`
- `direction: PlayDirection` — Enum: `fwd`, `rev`, `pingPong`, `random`
- `isMuted: Bool`
- `isSolo: Bool`
- `isExpanded: Bool` (CC-Reihen aufgeklappt)
- `timingOffset: Double` (Sekunden, positiv = laid back, negativ = pushed)
- `displayStep: Int` (aktuell leuchtender Step in der UI)
- `currentStep: Int` (interner Sequencer-Zähler)
- `lastFiredNote: Int?` (für Note-Off Tracking)

Methoden:
- `advanceStep() -> Step?` — gibt nächsten Step zurück entsprechend Direction
- `reset()` — setzt currentStep auf 0

> **`final class` ist zwingend erforderlich.** Codable `convenience init` funktioniert nicht mit regulären Klassen in diesem Kontext.

---

**`Models/Pattern.swift`**

`final class` mit ObservableObject + Codable. Felder:
- `name: String`
- `tracks: [Track]` (@Published)

---

### Engine/

**`Engine/MIDIManager.swift`**

CoreMIDI-Wrapper. Zuständig für:
- `virtSrc`: virtueller MIDI-Ausgang (sichtbar für DAW)
- `virtDst`: virtueller MIDI-Eingang (für Clock/Learn)
- `outPort`, `inPort`

Callbacks (werden von SequencerEngine gesetzt):
- `onClockPulse: (() -> Void)?`
- `onStart: (() -> Void)?`
- `onStop: (() -> Void)?`
- `onContinue: (() -> Void)?`
- `onCC: ((Int, Int) -> Void)?` — (ccNumber, value)
- `onNoteOn: ((Int, Int) -> Void)?` — (note, velocity)

Wichtige Methoden:
- `send(_ data: [UInt8])` — verwendet `MIDISend`, **NICHT** `MIDIOutputPortSend` (existiert nicht)
- `refreshPorts()` — aktualisiert die Port-Liste
- `connectInput(_ endpoint: MIDIEndpointRef)` — verbindet externen Eingang

> **EXC_BAD_ACCESS Fix:** Beim Iterieren eingehender MIDI-Pakete mit `MIDIPacketNext` muss ein Bounds-Check erfolgen. Logic Pro sendet manchmal fehlerhafte Packet-Längen. Die Iteration bricht ab wenn `offset + packetSize > listSize`.

---

**`Engine/SequencerEngine.swift`**

Hauptklasse des Sequencers. ObservableObject. Felder:
- `bpm: Double` (@Published)
- `swing: Double` (@Published, 0.0–1.0)
- `clockMode: ClockMode` (`.internal` / `.external`)
- `patterns: [Pattern]` (@Published, immer 4 Stück)
- `currentPatternIndex: Int` (@Published)
- `numTracks: Int` (Anzahl Tracks im aktuellen Pattern)
- `patternSwitchCC: Int` (CC-Nummer für Pattern-Wechsel)
- `trackMuteCCs: [Int]` (CC-Nummern pro Track für Mute-Toggle)
- `learnMode: Bool` (@Published)
- `learnTarget: (trackIndex: Int, stepIndex: Int)?`
- `clipboard: Pattern?` (für Pattern Copy/Paste)
- `stepClipboard: [Step]?` (für Step-Mehrfachauswahl Copy/Paste)

Timer: `DispatchSourceTimer` mit 24 PPQ (Pulse Per Quarter Note).

Wichtige Implementierungsdetails:

**`advanceSteps()`:**
- CCs werden **vor** dem `guard step.isActive` gesendet — CCs laufen auch wenn Step inaktiv ist (für kontinuierliche Automation-Kurven).
- Ratcheting über `DispatchQueue.main.asyncAfter` — bei ×2 ein zusätzlicher Trigger nach halber Step-Dauer, bei ×4 nach 1/4, 2/4, 3/4 der Step-Dauer.

**Swing-Implementierung:**
- Odd Steps (ungerade Schritte) erhalten einen Timing-Offset.
- Offset = `stepDuration * swing * 0.333` (Triplet-Verhältnis).
- Wird zum nächsten Timer-Intervall addiert.

**`timingOffset` pro Track:**
- Beim Feuern eines Steps: `DispatchQueue.main.asyncAfter(deadline: .now() + max(0, track.timingOffset))` für positive Werte.
- Negative Werte (pushed): werden intern in der Timer-Berechnung als frühere Auslösung implementiert.

---

### Views/

**`Views/KnobView.swift`**
- `DragGesture` — 140 px vertikale Bewegung entspricht dem vollen Wertebereich.
- `KnobArc`: `Path.addArc` mit −90° Offset (12-Uhr-Position = Minimum).
- `RadialGradient` für 3D-Optik.
- `double-tap` setzt Wert auf Default zurück.

---

**`Views/StepButtonView.swift`**
- Props: `isSelected: Bool`, `onToggleSelect: () -> Void`, `isLearnTarget: Bool`
- Tap-Logik:
  - ⌥ gedrückt → Edit-Fenster öffnen
  - ⇧ gedrückt → Mehrfachauswahl togglen (`onToggleSelect()`)
  - Normal → Step aktivieren/deaktivieren
- `DragGesture` für Step-Reorder — **kein** `onDrag`/`onDrop` verwenden (verursacht `+`-Badge und Verzögerung im macOS-System).
- `bgColor` und `borderColor`: computed vars je nach Zustand (aktiv / inaktiv / ausgewählt / learnTarget).

---

**`Views/StepDetailView.swift`**
- **Array-Swap-Pattern für Updates:** `var updated = track.steps; updated[index] = modified; track.steps = updated` — triggert `@Published` automatisch ohne `objectWillChange.send()`.
- `DrumPickerGrid` — private View, erscheint wenn `track.midiChannel == 10`.
- `NotePickerRow` — private View, piano-artige Noten-Auswahl für normale Tracks.
- `MultiStepEditView` — internal View für Bulk-Bearbeitung mehrerer Steps.
- **Enter-Shortcut:** Implementiert über einen hidden `Button` mit `KeyboardShortcut(.return)`.

---

**`Views/TrackRowView.swift`**
- `selectedSteps: Set<Int>` — @State, Indices der markierten Steps.
- `showMultiEdit: Bool` — @State, öffnet MultiStepEditView.
- `dragSourceIndex: Int?` — @State, Track der gerade per Drag bewegt wird.
- **Selection-Toolbar:** Erscheint wenn `selectedSteps.isEmpty == false`. Buttons: EDIT / COPY / PASTE / CLR.
- **`simultaneousGesture`** für Drag — verhindert Konflikt mit Tap-Gesture auf Steps.
- `TrackHeaderView` enthält `@FocusState` für das Name-TextField. `onSubmit` setzt `isNameFocused = false`.

---

**`Views/TransportView.swift`**
- BPM `KnobView` mit `size: 48`.
- `swingBinding`: Remapped — interne Darstellung 0.0–1.0, UI-Darstellung 0–100 %.
- TAP Tempo: Array der letzten Tap-Zeitstempel, Durchschnitt über `Date().timeIntervalSince`.
- LEARN-Button wechselt `engine.learnMode`.

---

**`Views/SettingsView.swift`**
- MIDI Output-Picker und Input-Picker (aus `MIDIManager.refreshPorts()`).
- CC Remote Control: Eingabefeld für `patternSwitchCC`.
- `TrackCCRow`: Pro Track eine Zeile mit CC-Nummer für Mute-Toggle.
- Kein Preset Load/Save mehr in den Settings — das ist ins File-Menü gewandert.

---

**`Views/MainView.swift`**
- `ForEach` über `enumerated()` der Tracks für stabile Indizes.
- `onClear`: Array-Swap-Pattern (kein direktes Mutieren von Steps).
- `onDelete` und `onDuplicate`: Callbacks an SequencerEngine delegiert.

---

**`VintageSequencerApp.swift`**

SwiftUI `App` mit `Commands`:
- **File-Menü:** Save Preset (⌘S), Open Preset (⌘O) — JSON-basiert.
- **Sequencer-Menü:** Pattern Copy (⌘⌥C), Pattern Paste (⌘⌥V), Track Mute ⌥1 bis ⌥4.
- **Space = Play/Stop:** Implementiert über `keyboardShortcut(.space)` auf einem globalen Button oder über `NSEvent.addLocalMonitorForEvents`.

---

## Wichtige Patterns und Fallstricke

### Array-Swap statt objectWillChange

**Falsch:**
```swift
track.steps[index].velocity = 80
track.objectWillChange.send() // erfordert import Combine in View-Dateien
```

**Richtig:**
```swift
var updated = track.steps
updated[index].velocity = 80
track.steps = updated // @Published triggert automatisch
```

Das Array-Swap-Pattern funktioniert in allen View-Dateien ohne `import Combine`.

---

### final class für Modelle

Track und Pattern müssen `final class` sein:
```swift
final class Track: ObservableObject, Codable { ... }
final class Pattern: ObservableObject, Codable { ... }
```
Ohne `final` scheitert der Codable `convenience init` des Swift-Compilers.

---

### MIDI Senden

```swift
// Richtig:
MIDISend(outPort, virtSrc, packetListPtr)

// Falsch (existiert nicht):
MIDIOutputPortSend(...)
```

---

### Neue Dateien und Xcode

Dateien die mit dem Write-Tool (Claude) erstellt werden, sind **nicht automatisch im Xcode-Target**. Manuell hinzufügen:
1. Rechtsklick auf den Zielordner im Xcode-Navigator.
2. "Add Files to VintageSequencer..." wählen.
3. Datei auswählen, "Add to target: VintageSequencer" sicherstellen.

**Bevorzugt:** Code in bestehende Dateien einfügen statt neue Dateien erstellen.

---

### GMDrumMap — Nur einmal definieren

Das `GMDrumMap` Enum darf nur in **einer** Datei existieren:
- Entweder in `Models/Step.swift`
- Oder in `Models/GMDrumMap.swift`

Doppelte Definition führt zu `error: invalid redeclaration of 'GMDrumMap'`.

---

### DerivedData löschen

Wenn Xcode gecachte alte Versionen ausliefert:
```
~/Library/Developer/Xcode/DerivedData/
```
Ordner für VintageSequencer löschen, dann neu kompilieren.

---

## Preset JSON Format

Struktur: Array mit genau 4 Pattern-Objekten.

```json
[
  {
    "name": "Pattern A",
    "tracks": [
      {
        "name": "Bass",
        "stepCount": 16,
        "midiChannel": 1,
        "cc1Number": 74,
        "cc2Number": 71,
        "cc1Label": "Filter",
        "cc2Label": "Res",
        "direction": "fwd",
        "isMuted": false,
        "isSolo": false,
        "timingOffset": 0.0,
        "steps": [
          {
            "isActive": true,
            "note": 36,
            "velocity": 100,
            "gate": 0.8,
            "probability": 1.0,
            "ratchet": 1,
            "cc1Value": 64,
            "cc2Value": 0
          }
        ]
      }
    ]
  }
]
```

**Direction-Werte (String):** `"fwd"`, `"rev"`, `"pingPong"`, `"random"`

**Ratchet-Werte (Int):** `1`, `2`, `4`

**Gate und Probability:** 0.0–1.0 (nicht 0–100)

**Funktionierende Beispiel-Presets:** `prog-7-8-groove.json`, `acid-bassline.json`

---

## Track-Limit

Aktuell ist die Track-Anzahl auf 8 begrenzt. Das `guard`-Statement befindet sich in:
- `addTrack()` in SequencerEngine
- `duplicateTrack()` in SequencerEngine

Um das Limit zu entfernen oder zu erhöhen: die jeweilige `guard`-Zeile anpassen oder entfernen.

---

## Offene Features (Stand v0.13)

| Feature | Komplexität | Beschreibung |
|---|---|---|
| Scale-Filter | Mittel | Tonarten-Raster — Steps nur auf Skalen-Noten snappen |
| Step-Typen ternär/dotted | Groß | 4:3, 5:4 mit unterschiedlichen Step-Dauern pro Track |
| Akkorde pro Step | Groß | `Step.note: Int` → `notes: [Int]`, betrifft alle Layer |
| Pattern Chaining | Mittel | A→B→A→C Sequenz automatisch durchlaufen |
| Humanising | Mittel | Timing/Velocity-Variation per Track (zufälliger Offset) |
| Cross-Track Drag | Mittel | Step von einem Track auf anderen ziehen |
| XCTest Harness | Klein | Stress-Test für Marktreife |

---

## Schnellreferenz: Tastatur-Shortcuts

| Shortcut | Aktion |
|---|---|
| Space | Play / Stop |
| ⌘A / ⌘B / ⌘C / ⌘D | Pattern A–D wählen |
| ⌘⌥C | Aktuelles Pattern kopieren |
| ⌘⌥V | Pattern einfügen |
| ⌘S | Preset speichern (JSON) |
| ⌘O | Preset öffnen (JSON) |
| ⌥1–4 | Track 1–4 muten |
| ⌥+Klick | Step-Edit-Fenster öffnen |
| ⇧+Klick | Step-Mehrfachauswahl |
| Enter | Step-Edit-Fenster schließen |

---

*Technische Dokumentation v0.13 — für neuen Chat-Kontext*
