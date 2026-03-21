# Steph Sequencer — Bedienungsanleitung
**Version 0.16 · Prog Rock Edition**

---

## Überblick

Der Steph Sequencer ist ein polyrhythmischer MIDI-Step-Sequencer für macOS. Er sendet MIDI-Noten an beliebige Synthesizer, DAWs oder Hardware. Die App unterstützt bis zu 8 Tracks pro Pattern, 4 Patterns (A–D), individuelle Steplängen pro Track und polyrhythmische Strechung.

---

## 1. Transport-Leiste (oben)

### Play / Stop
- **Play/Stop-Button** startet und stoppt den Sequencer
- Tastaturkürzel: **Leertaste**
- Die amber LED leuchtet während der Wiedergabe

### BPM
- **Knob** (drehen mit der Maus / Trackpad): BPM im Bereich 20–300
- **▲ / ▼ Buttons**: Feineinstellung ±1 BPM
- **TAP**: 2× oder öfter klicken, um das Tempo per Tap zu ermitteln (innerhalb von 3 Sekunden)

### Swing
- **Swing-Knob**: 0% = gerade, 100% = maximaler Swing
- Ungerade Steps (2., 4., 6., …) werden proportional verzögert
- Swing und BPM werden im Preset gespeichert

### Pattern A–D
- 4 unabhängige Patterns, umschaltbar per Klick oder **⌘1–⌘4**
- Der Wechsel erfolgt am Ende von Track 1 (kein harter Schnitt)
- Beim Warten auf den Wechsel leuchtet der Ziel-Button **cyan**

### Clock
- **INT**: interner Clock (BPM-gesteuert)
- **EXT**: externer MIDI-Clock (Tap/BPM werden ignoriert)

### MIDI Learn
- **ON/OFF**: aktiviert den MIDI-Learn-Modus
- Im Learn-Modus: gewünschten Knob oder Regler anklicken, dann MIDI-CC senden → die Zuordnung wird gespeichert

### Steps S / M / L
- Ändert die Darstellungsgröße der Step-Buttons (38 / 46 / 54 px)
- Kein Einfluss auf die Wiedergabe

### Dateiname & Unsaved-Indicator
- Unter dem Logo wird der Dateiname des aktuell geladenen Presets angezeigt
- **Orange Punkt + oranger Text**: es gibt ungespeicherte Änderungen
- Beim Schließen oder Laden mit ungespeicherten Änderungen erscheint ein Warndialog

---

## 2. Step-Lanes (Hauptbereich)

Jeder Track besteht aus einem **Track-Header** (links) und einer **Step-Lane** (scrollbar rechts).

### BPM-Raster
Im Hintergrund der Step-Lane sind feine Rasterlinien sichtbar:
- **Viertelnoten** (alle 4 Steps): schwaches amber
- **Taktstriche** (alle 16 Steps): helleres amber

### Step-Buttons
- **Klick**: Step an/aus schalten
- **⌥+Klick (Option+Klick)**: Step-Detail-Editor öffnen
- **⇧+Klick**: Step zur Auswahl hinzufügen / entfernen
- **Drag** im leeren Bereich (unter/hinter den Steps): Rubber-Band-Auswahl aufziehen
- **Escape**: Auswahl aufheben

### Step-Detail-Editor (⌥+Klick)

**Note**: Grundton, Oktave ±2, MIDI-Velocity
**Chord**: Akkordtyp (None, Major, Minor, Dom7, Maj7, Min7, Dim, Aug, Sus2, Sus4, …)
**Gate**: Haltedauer als Notenwert (siehe unten)
**Prob**: Wahrscheinlichkeit 0–100%, mit der der Step gespielt wird
**Ratchet**: Anzahl der Wiederholungen (1–8) innerhalb eines Steps

#### Gate-Werte (v0.16)

| Button | Wert | Bedeutung |
|--------|------|-----------|
| stac | 0.05 | Staccato (sehr kurz) |
| 1/64 | 0.25 | 64tel-Note |
| 1/32 | 0.50 | 32tel-Note |
| 1/16 | 1.00 | 16tel-Note (= 1 Step, Legato) |
| 1/16. | 1.50 | punktierte 16tel |
| 1/8 | 2.00 | Achtelnote |
| 1/8. | 3.00 | punktierte Achtel |
| 1/4 | 4.00 | Viertelnote |
| 1/4. | 6.00 | punktierte Viertel |
| 1/2 | 8.00 | Halbe Note |
| 1/2. | 12.00 | punktierte Halbe |
| 1/1 | 16.00 | Ganze Note (16 Steps) |

> **Hinweis**: Bei Ratchet > 1 wird Gate automatisch auf maximal 1/16 begrenzt, damit sich die Wiederholungen nicht überlappen.

### Multi-Step-Auswahl

Nach einer Rubber-Band- oder Shift-Auswahl erscheint eine Toolbar über der Lane:
- **Note**: gemeinsame Note setzen
- **Gate**: gemeinsames Gate setzen
- **Prob**: gemeinsame Wahrscheinlichkeit
- **Vel**: gemeinsame Velocity
- **Ratchet**: gemeinsamer Ratchet-Wert
- **✓ All / ✗ None**: alle Steps an/aus
- **Auswahl invertieren** (⊕)
- **Copy / Paste**

---

## 3. Track-Header (links)

### Track-Name
- Doppelklick zum Umbenennen

### MIDI-Kanal
- Dropdown-Menü (Picker) mit Kanälen 1–16
- Kanal 10 ist als **10 ◆** (GM Drums) markiert

### Stimmung / Direction
| Symbol | Verhalten |
|--------|-----------|
| → | vorwärts |
| ← | rückwärts |
| ↔ | Pendel (Ping-Pong) |
| ↑ | zufällig |
| ↕ | zufällig einmalig pro Zyklus |

### Mute / Solo
- **M**: Track stummschalten (LED = gedämpft)
- **S**: Solo — alle anderen Tracks werden stummgeschaltet

### Step-Anzahl
- **+/-** Buttons: Steps hinzufügen oder entfernen (1–64)

### RND / CLR
- **RND**: zufällige Steps einschalten (50% Wahrscheinlichkeit)
- **CLR**: alle Steps ausschalten

---

## 4. Polyrhythmik — Stretch-Handle

Am rechten Ende jedes Tracks befindet sich ein **orangefarbener Stretch-Handle**.

### Funktionsweise
- Handle nach rechts oder links **ziehen**
- Der Track-Zyklus wird auf eine andere Anzahl von 16tel-Schritten gestreckt
- Beispiel: Track mit 7 Steps, Stretch auf 8 → die 7 Steps laufen in der Zeit von 8 → **7:8-Polyrhythmus**

### Snap-Werte
Der Handle rastet auf musikalisch sinnvolle Werte ein:
`2, 3, 4, 5, 6, 7, 8, 9, 10, 12, 14, 16` sowie benachbarte Werte ±3

### Verhältnis-Anzeige
Beim Ziehen wird das Verhältnis angezeigt, z.B. `7:8` oder `5:4`

### Zurücksetzen
- **↺-Button** neben dem Handle: Stretch aufheben (natürliche Länge)

### Häufige Verhältnisse
| Steps | Stretch auf | Verhältnis | Klang |
|-------|-------------|------------|-------|
| 5 | 4 | 5:4 | Quintole gegen Viertel |
| 7 | 8 | 7:8 | Septole gegen Achtel |
| 3 | 4 | 3:4 | Triole gegen Viertel |
| 5 | 6 | 5:6 | gegen punktierte Viertel |

---

## 5. Presets / Dateiverwaltung

Presets werden als **JSON-Dateien** gespeichert. Empfohlener Ordner: `Patches/` im Projektverzeichnis.

### Speichern
- **⌘S**: aktuelles Preset speichern (Überschreiben)
- **⌘⇧S**: Speichern unter (neuer Dateiname)

### Laden
- **⌘O**: Preset öffnen
- Bei ungespeicherten Änderungen erscheint ein Warndialog

### Preset-Format (v0.16)
```json
{
  "bpm": 108.0,
  "swing": 50.0,
  "patterns": [ ... ]
}
```
Ältere Presets ohne `bpm`/`swing`-Wrapper werden automatisch erkannt und geladen.

---

## 6. Tastaturkürzel

| Kürzel | Funktion |
|--------|----------|
| Leertaste | Play / Stop |
| ⌘1–⌘4 | Pattern A–D wechseln |
| ⌘S | Preset speichern |
| ⌘⇧S | Speichern unter |
| ⌘O | Preset laden |
| Escape | Auswahl aufheben |
| ⌥+Klick | Step-Detail öffnen |
| ⇧+Klick | Step zur Auswahl hinzufügen |

---

## 7. MIDI-Einrichtung

1. In den **Einstellungen** (Zahnrad-Icon, oben rechts) MIDI-Ausgabegerät wählen
2. Pro Track den gewünschten **MIDI-Kanal** im Dropdown setzen
3. Für externe Clock: **Clock → EXT** wählen, dann MIDI-Clock-Quelle in der DAW konfigurieren

---

## 8. Tipps & Workflows

**Polyrhythmischer Groove:**
- Track 1: 16 Steps, kein Stretch (Grundpuls)
- Track 2: 5 Steps, Stretch auf 4 (5:4 gegen den Beat)
- Track 3: 7 Steps, Stretch auf 8 (7:8 — Septole)
- Pattern-Wechsel erfolgt immer synchron am Ende von Track 1

**Lange Flächen:**
- Gate auf `1/2` oder `1/1` für Pad-Sounds
- Mehrere Steps mit gleicher Note und `1/1` Gate erzeugen einen langen Ton über mehrere Steps

**Zufällige Variationen:**
- Prob auf 50–80% für probabilistische Patterns
- RND-Button für schnellen Zufallsstart

---

*Steph Sequencer ist ein persönliches Instrument — viel Spaß beim Spielen.*
