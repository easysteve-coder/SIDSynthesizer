# Steph Sequencer — Bedienungsanleitung
**Version 0.9 · Prog Rock Edition**

---

## Überblick

Der Steph Sequencer ist ein polyrhythmischer MIDI-Step-Sequencer für macOS. Er sendet MIDI-Noten an beliebige Synthesizer, DAWs oder Hardware. Die App unterstützt bis zu 8 Tracks pro Pattern, 4 Patterns (A–D), individuelle Step-Längen pro Track und polyrhythmische Strechung per Ratio-Modell.

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
- Ungerade Steps werden proportional verzögert
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
- Im Learn-Modus: gewünschten Knob oder Regler anklicken, dann MIDI-CC senden → Zuordnung wird gespeichert

### Steps S / M / L
- Ändert die Darstellungsgröße der Step-Buttons (38 / 46 / 54 px)
- CC-Knöpfe skalieren mit
- Kein Einfluss auf die Wiedergabe

### Dateiname & Unsaved-Indicator
- Unter dem Logo wird der Dateiname des aktuell geladenen Presets angezeigt
- **Orange Punkt + oranger Text**: es gibt ungespeicherte Änderungen
- Beim Schließen oder Laden mit ungespeicherten Änderungen erscheint ein Warndialog

### Tooltips
- Menü **Ansicht → Tooltips anzeigen** (⌘⌥T): Tooltips ein-/ausblenden
- Einstellung wird gespeichert

---

## 2. Track-Header (links)

### Löschen-Button (×)
- Kleines **×** oben links im Track-Header
- Oder **Rechtsklick → Track löschen** (rot markiert)
- Deaktiviert wenn nur ein Track vorhanden

### Track-Name
- Direkt anklicken und tippen
- **Return** oder Klick woanders: Fokus verlassen

### Buttons oben rechts
- **m**: Mute — Track stummschalten
- **s**: Solo — alle anderen Tracks stumm
- **⎘**: Track duplizieren (Kopie landet direkt darunter)

### Direction — Wiedergaberichtung
| Symbol | Bedeutung |
|--------|-----------|
| ▶ | Vorwärts (FWD) |
| ◀ | Rückwärts (REV) |
| ⇌ | Ping-Pong (P–P) |
| ∿ | Zufällig (RND) |

### MIDI-Kanal
- Dropdown-Menü mit Kanälen 1–16
- Kanal 10 ist als **10 ◆** (GM Drums) markiert

### FEEL
- Timing-Offset für den Track (−50 ms bis +50 ms)
- Negative Werte: pushed (vor dem Beat)
- Positive Werte: laid back (nach dem Beat)

### SCL
- Tonart- und Skalenfilter
- Noten werden auf die gewählte Skala quantisiert

### RND / CLR
- **RND**: Steps zufällig einschalten (mit Undo)
- **CLR**: alle Steps ausschalten (mit Undo)

### Rechtsklick-Menü (Kontextmenü)
Rechtsklick auf freie Fläche im Track-Header öffnet:
- **Track darunter einfügen** — neuer leerer Track
- **Track duplizieren** — Kopie mit Suffix " 2"
- **Track löschen** — rot, deaktiviert bei nur einem Track

---

## 3. Step-Lanes (Hauptbereich)

### BPM-Raster
Im Hintergrund liegen feine vertikale Linien — wie Millimeterpapier hinter allen Spuren:
- **Viertelnoten** (alle 4 Steps): schwaches Amber
- Das Raster ist **fix** — es verändert sich nicht beim Strecken von Tracks

### Step-Buttons
- **Klick**: Step an/aus
- **⌥+Klick** (Option+Klick): Step-Detail-Editor öffnen
- **⇧+Klick**: Step zur Auswahl hinzufügen / entfernen
- **Drag** im leeren Bereich unter/hinter den Steps: Rubber-Band-Auswahl aufziehen
- **Escape**: Auswahl aufheben

### Step-Detail-Editor (⌥+Klick)

**Note**: Grundton, Oktave ±2, MIDI-Velocity

**Chord**: Akkordtyp (None, Major, Minor, Dom7, Maj7, Min7, Dim, Aug, Sus2, Sus4, …)

**Gate**: Haltedauer als Notenwert:

| Button | Bedeutung |
|--------|-----------|
| stac | Staccato (sehr kurz) |
| 1/64 | Zweiundsechzigstel |
| 1/32 | Zweiunddreißigstel |
| 1/16 | Sechzehntel (= 1 Step, Legato) |
| 1/16. | Punktierte Sechzehntel |
| 1/8 | Achtelnote |
| 1/8. | Punktierte Achtel |
| 1/4 | Viertelnote |
| 1/4. | Punktierte Viertel |
| 1/2 | Halbe Note |
| 1/2. | Punktierte Halbe |
| 1/1 | Ganze Note (16 Steps) |

**Prob**: Wahrscheinlichkeit 0–100%, mit der der Step gespielt wird

**Ratchet**: Anzahl der Wiederholungen (1–8) innerhalb eines Steps
> Bei Ratchet > 1 wird Gate automatisch auf 1/16 begrenzt

### Multi-Step-Auswahl

Nach Rubber-Band- oder Shift-Auswahl erscheint eine Toolbar:
- **EDIT**: alle markierten Steps gemeinsam bearbeiten
- **COPY / PASTE**: Steps kopieren und einfügen
- **CLR**: markierte Steps löschen
- **✕**: Auswahl aufheben

### CC-Rows
- **▼ / ▲** (Pfeil rechts): CC-Reihen ein-/ausklappen
- Jeder Step hat einen eigenen CC-Knopf für CC1 und CC2
- CC-Knöpfe scrollen synchron mit den Step-Buttons

---

## 4. Polyrhythmik — Stretch-Handle

Am rechten Ende jeder Track-Lane befindet sich der **Stretch-Handle**:

```
[ 4  |  5 ]
  3
```
Links: Step-Längen-Ratio · Rechts: Step-Anzahl

### Step-Länge (links)
- **↑↓ Ziehen**: durch 13 musikalische Ratios scrollen
- **Klick**: Popover mit Schnellwahl öffnen

Die 13 Ratios von schnell nach langsam:

| Name | Ratio | Bedeutung |
|------|-------|-----------|
| 32tel | 1:2 | Halb so lang wie eine Sechzehntel |
| Septole÷ | 4:7 | 7 Noten auf 4 Sechzehntel |
| 16t·Triole | 2:3 | 3 Noten auf 2 Sechzehntel |
| Quartole÷ | 3:4 | 4 Noten auf 3 Sechzehntel |
| Quintole÷ | 4:5 | 5 Noten auf 4 Sechzehntel |
| Nonole÷ | 8:9 | 9 Noten auf 8 Sechzehntel |
| **16tel** | **1:1** | **Referenz — normaler Step** |
| Nonole× | 9:8 | Gedehnte Nonole |
| Quintole× | 5:4 | Gedehnte Quintole |
| 8t·Triole | 4:3 | Achteltriole |
| pkt.16tel | 3:2 | Punktierte Sechzehntel |
| Septole× | 7:4 | Gedehnte Septole |
| 8tel | 2:1 | Achtelnote — doppelt so lang |

> **Polyrhythmus-Beispiel**: Track 1 auf 16tel (1:1), Track 2 auf 16t·Triole (2:3) — ergibt 3 gegen 2.

### Step-Anzahl (rechts)
- **↑↓ Ziehen**: Steps hinzufügen / entfernen
- Bereich: 1–64 Steps
- Ratio bleibt beim Ändern der Step-Anzahl erhalten

---

## 5. Presets / Dateiverwaltung

Presets werden als **JSON-Dateien** gespeichert. Empfohlener Ordner: `Patches/` im Projektverzeichnis.

### Speichern
- **⌘S**: aktuelles Preset speichern (Überschreiben)
- **⌘⇧S**: Speichern unter (neuer Dateiname)

### Laden
- **⌘O**: Preset öffnen
- Bei ungespeicherten Änderungen erscheint ein Warndialog

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
| ⌘⌥T | Tooltips ein-/ausblenden |

---

## 7. MIDI-Einrichtung

1. **Einstellungen** (Zahnrad-Icon oben rechts) → MIDI-Ausgabegerät wählen
2. Pro Track den gewünschten **MIDI-Kanal** im Dropdown setzen
3. Für externe Clock: **Clock → EXT** wählen, dann MIDI-Clock-Quelle in der DAW konfigurieren

---

## 8. Tipps & Workflows

**Polyrhythmischer Groove:**
- Track 1: 16 Steps, 16tel (Grundpuls)
- Track 2: 5 Steps, Quintole÷ (4:5) — 5 gegen 4
- Track 3: 7 Steps, Septole÷ (4:7) — 7 gegen 4

**Lange Flächen:**
- Gate auf `1/2` oder `1/1` für Pad-Sounds
- Mehrere Steps mit gleicher Note erzeugen einen langen Ton

**Zufällige Variationen:**
- Prob auf 50–80% für probabilistische Patterns
- RND-Button für schnellen Zufallsstart

**Groove mit FEEL:**
- Snare-Track: +8ms (laid back)
- Hi-Hat-Track: −5ms (pushed)
- Gibt dem Groove eine menschliche Unsauberkeit

---

*Steph Sequencer ist ein persönliches Instrument — viel Spaß beim Spielen.*
