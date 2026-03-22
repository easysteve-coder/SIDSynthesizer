# Steph Sequencer — Bedienungsanleitung
**Version 0.9 · Prog Rock Edition**

---

## Überblick

Der Steph Sequencer ist ein polyrhythmischer MIDI-Step-Sequencer für macOS. Er sendet MIDI-Noten an beliebige Synthesizer, DAWs oder Hardware-Instrumente über CoreMIDI.

**Was er kann:**
- Bis zu 8 Tracks pro Pattern, jeder mit eigener Step-Anzahl (1–64)
- 4 unabhängige Patterns (A–D), nahtlos umschaltbar
- Polyrhythmik: jeder Track kann in einem anderen Zeitverhältnis laufen (z.B. 7:8, 5:4, Triole)
- Pro Step: Note, Akkord, Gate, Velocity, Wahrscheinlichkeit, Ratchet
- CC-Automation: 2 MIDI-Controller-Kurven pro Track
- Interner und externer MIDI-Clock
- MIDI Learn für alle Regler

---

## 1. Transport-Leiste (oben)

### Play / Stop
- **Play/Stop-Button** startet und stoppt den Sequencer
- Tastaturkürzel: **Leertaste**
- Die amber LED (kleiner Kreis neben dem Button) leuchtet während der Wiedergabe
- Beim Stopp werden alle laufenden MIDI-Noten sofort beendet (Note Off)

### BPM — Tempo
- **Knob** (Maus ziehen, vertikal): BPM im Bereich 20–300
- **▲ / ▼ Pfeile** unter dem Knob: Feineinstellung ±1 BPM
- **TAP-Button**: 2× oder öfter klicken um das Tempo per Tap zu ermitteln. Die letzten Klicks werden gemittelt. Timeout nach 3 Sekunden Pause.
- BPM wird im Preset gespeichert

### Swing
- **Swing-Knob**: 0% = gerade (kein Swing), 100% = maximaler Swing
- Jeder zweite Step (2., 4., 6., …) wird um einen prozentualen Anteil der Step-Dauer verzögert
- Swing wirkt auf alle Tracks gleichzeitig
- Swing wird im Preset gespeichert

### Pattern A–D
- 4 unabhängige Patterns, jedes mit eigenen Tracks und Steps
- Umschalten: Klick auf A/B/C/D, oder **⌘1** bis **⌘4**
- **Queued Switch**: der Wechsel erfolgt nicht sofort, sondern am Ende des aktuellen Zyklus von Track 1 — so gibt es keinen harten Schnitt im Rhythmus
- Beim Warten auf den Wechsel: der Ziel-Button leuchtet **cyan**
- Tracks werden beim Pattern-Wechsel auf Step 1 zurückgesetzt

### Clock
- **INT**: interner Clock — der Sequencer bestimmt das Tempo selbst (BPM-Knob)
- **EXT**: externer MIDI-Clock — der Sequencer folgt dem Clock-Signal einer DAW oder eines anderen Geräts. TAP und BPM-Knob werden ignoriert.

### MIDI Learn
- **ON/OFF-Button**: aktiviert den MIDI-Learn-Modus (Button leuchtet)
- Im Learn-Modus: erst den gewünschten UI-Regler anklicken, dann einen MIDI-CC am Controller bewegen → Zuordnung wird automatisch gespeichert
- Zuordnungen bleiben über App-Neustarts erhalten

### Steps S / M / L
- Ändert die **Darstellungsgröße** der Step-Buttons:
  - **S** = Small: 38 px — mehr Steps sichtbar, kompakter
  - **M** = Medium: 46 px — ausgewogen
  - **L** = Large: 54 px — gut lesbar, empfohlen für Bühne
- CC-Knöpfe skalieren proportional mit
- Kein Einfluss auf die Wiedergabe

### Dateiname & Unsaved-Indicator
- Unter dem Logo: Name des aktuell geladenen Presets (oder „—" wenn neu)
- **Orange Punkt + oranger Text**: es gibt ungespeicherte Änderungen
- Beim Schließen oder Laden erscheint ein Warndialog wenn Änderungen vorhanden sind

### Tooltips
- Menü **Ansicht → Tooltips anzeigen** (⌘⌥T): Tooltips für alle Buttons ein-/ausblenden
- Einstellung wird gespeichert und bleibt über Neustarts erhalten

---

## 2. Track-Header (links)

Jeder Track hat einen festen Header-Bereich links. Alle Einstellungen hier betreffen nur diesen einen Track.

### Löschen-Button (×)
- Kleines **×** oben links im Header
- Alternativ: **Rechtsklick → Track löschen** (rot markiert)
- Deaktiviert wenn nur ein Track vorhanden ist
- Kein Undo — Vorsicht!

### Track-Name
- Direkt anklicken und tippen
- **Return** oder Klick woanders: Fokus verlassen und bestätigen
- Name wird im Preset gespeichert

### Buttons oben rechts
| Button | Funktion |
|--------|----------|
| **m** | Mute — Track stummschalten. Andere Tracks laufen weiter. Der Track läuft intern weiter (Pulse werden gezählt), er sendet nur keine Noten. |
| **s** | Solo — alle anderen Tracks werden stummgeschaltet. Mehrere Tracks können gleichzeitig Solo sein. |
| **⎘** | Track duplizieren — eine exakte Kopie wird direkt darunter eingefügt, in allen 4 Patterns. |

> **Mute + Solo gleichzeitig**: Mute gewinnt immer. Ein Track der sowohl Mute als auch Solo hat, ist stumm.

### Direction — Wiedergaberichtung
| Symbol | Name | Verhalten |
|--------|------|-----------|
| ▶ | Forward | Steps von 1 bis N, dann wieder von vorne |
| ◀ | Reverse | Steps von N bis 1, dann wieder von hinten |
| ⇌ | Ping-Pong | 1→N→1→N… — Step 1 und N werden nicht doppelt gespielt |
| ∿ | Random | Jeder Step wird zufällig gewählt, unabhängig vom letzten |

### MIDI-Kanal
- Dropdown-Menü mit Kanälen 1–16
- **Kanal 10 ◆**: General MIDI Drums — auf den meisten Synthesizern und DAWs ist hier das Schlagzeug
- Verschiedene Tracks können verschiedene MIDI-Kanäle haben → verschiedene Instrumente ansprechen

### FEEL — Timing-Offset
- Verschiebt alle Noten dieses Tracks im Verhältnis zum globalen Beat
- Bereich: −50 ms (pushed, vor dem Beat) bis +50 ms (laid back, nach dem Beat)
- Klick auf FEEL → Popover mit Knopf erscheint
- Typische Werte: Snare +8ms (laid back), Hi-Hat −3ms (pushed)

### SCL — Tonart / Skala
- Filtert die spielbaren Noten auf eine Tonart und Skala
- Noten die nicht in der Skala liegen werden auf den nächsten gültigen Ton quantisiert
- Klick auf SCL → Popover mit Grundton- und Skalenwahl

### RND / CLR
- **RND**: Steps zufällig einschalten (ca. 50% Dichte) — mit **Undo** (⌘Z)
- **CLR**: alle Steps dieses Tracks ausschalten — mit **Undo** (⌘Z)

### Rechtsklick-Kontextmenü
Rechtsklick auf die freie Fläche im Track-Header (nicht auf einen Button):
- **Track darunter einfügen** — neuer leerer Track direkt unter diesem, in allen 4 Patterns
- **Track duplizieren** — Kopie mit Suffix " 2"
- **Track löschen** — rot markiert, nicht rückgängig machbar

---

## 3. Step-Lanes (Hauptbereich)

### BPM-Raster
Im Hintergrund aller Spuren liegen feine vertikale Linien — wie Millimeterpapier:
- **Viertelnoten-Linie** (alle 4 Steps bei 1:1-Ratio): dezentes Amber
- Das Raster ist **fix** — es verschiebt sich nicht wenn ein Track gestretcht wird
- So sieht man sofort wo Steps relativ zum Beat liegen

### Step-Buttons
Jeder Kreis / jedes Rechteck = ein Step.

| Aktion | Funktion |
|--------|----------|
| **Klick** | Step an/aus |
| **⌥+Klick** | Step-Detail-Editor öffnen |
| **⇧+Klick** | Step zur Auswahl hinzufügen / entfernen |
| **Drag** (im leeren Bereich) | Rubber-Band-Auswahl aufziehen |
| **Escape** | Auswahl aufheben |

**Indikatoren auf dem Step-Button:**
- **Farbiger Punkt oben**: Note ist gesetzt (Farbe = Track-Akzentfarbe)
- **Kleiner Text in der Mitte**: Akkordname (z.B. „Dm7") oder Note (z.B. „C4")
- **Prozentangabe**: Wahrscheinlichkeit wenn < 100%
- **Blauer Leuchtrand**: aktuell spielender Step
- **Unterer farbiger Balken**: Gate-Länge (volle Breite = Legato)

### Step-Detail-Editor (⌥+Klick)

Öffnet einen Editor für den einzelnen Step:

#### Note
- **Grundton**: C, C#, D, … H (chromatisch, 12 Töne)
- **Oktave**: −2 bis +2 relativ zur Basis-Oktave
- **Velocity**: 0–127 (Anschlagstärke). 0 = kein Ton, 127 = maximum

#### Chord — Akkord
Zusätzliche Noten die gleichzeitig mit der Grundnote gespielt werden:

| Typ | Intervalle | Klang |
|-----|-----------|-------|
| None | — | nur Grundton |
| Major | +4, +7 | Dur-Dreiklang |
| Minor | +3, +7 | Moll-Dreiklang |
| Dom7 | +4, +7, +10 | Dominantseptakkord |
| Maj7 | +4, +7, +11 | Großer Septakkord |
| Min7 | +3, +7, +10 | Kleiner Septakkord |
| Dim | +3, +6 | Verminderter Dreiklang |
| Aug | +4, +8 | Übermäßiger Dreiklang |
| Sus2 | +2, +7 | Sus2-Akkord |
| Sus4 | +5, +7 | Sus4-Akkord |

#### Gate — Haltedauer
Wie lange die Note klingt, ausgedrückt als Notenwert:

| Button | Ratio-Wert | Bedeutung |
|--------|-----------|-----------|
| stac | 0.05 | Staccato — sehr kurz angeschlagen |
| 1/64 | 0.25 | Zweiundsechzigstel |
| 1/32 | 0.50 | Zweiunddreißigstel |
| 1/16 | 1.00 | Sechzehntel = 1 Step (Legato) |
| 1/16. | 1.50 | Punktierte Sechzehntel |
| 1/8 | 2.00 | Achtelnote |
| 1/8. | 3.00 | Punktierte Achtel |
| 1/4 | 4.00 | Viertelnote |
| 1/4. | 6.00 | Punktierte Viertel |
| 1/2 | 8.00 | Halbe Note |
| 1/2. | 12.00 | Punktierte Halbe |
| 1/1 | 16.00 | Ganze Note — hält 16 Steps lang |

> Gate > 1/16 bedeutet: die Note hält über den aktuellen Step hinaus. Der Sequencer springt weiter, die Note klingt noch.

#### Prob — Wahrscheinlichkeit
- 0–100%: mit dieser Wahrscheinlichkeit wird der Step gespielt
- 100% = immer (Standard)
- 50% = jedes zweite Mal im Durchschnitt
- 0% = niemals (Step ist effektiv deaktiviert)

#### Ratchet
- 1–8: Anzahl der Wiederholungen innerhalb eines Steps
- Ratchet 4 auf einem 1/16-Step = vier 1/64-Noten
- Bei Ratchet > 1 wird Gate automatisch auf maximal 1/16 begrenzt (sonst würden sich die Noten überlappen)

### Multi-Step-Auswahl

Nach Rubber-Band- oder Shift-Auswahl erscheint eine blaue Toolbar über der Lane:

| Button | Funktion |
|--------|----------|
| **N STEPS** | Anzahl markierter Steps |
| **EDIT** | Alle markierten Steps gemeinsam bearbeiten (Note, Gate, Prob, Vel, Ratchet) |
| **COPY** | Steps in die Zwischenablage (⌘C) |
| **PASTE** | Zwischenablage ab erstem markierten Step einfügen (⌘V) |
| **CLR** | Markierte Steps deaktivieren |
| **✕** | Auswahl aufheben |

### CC-Rows — Automation

Jeder Track hat zwei CC-Reihen (CC1 und CC2) die ausgeklappt werden können:
- **▼ rechts außen**: CC-Rows einblenden
- **▲**: CC-Rows ausblenden
- Jeder Step hat einen eigenen Drehknopf für den CC-Wert (0–127)
- CC-Rows scrollen synchron mit den Step-Buttons
- Welcher MIDI-Controller-Parameter gesteuert wird, hängt vom Empfangsgerät ab (CC1 = oft Modulation, CC11 = Expression, etc.)

---

## 4. Polyrhythmik — Stretch-Handle

Am rechten Ende jeder Track-Lane befindet sich der **Stretch-Handle**:

```
┌─────────┐
│  4   7  │
│  ─       │
│  3       │
└─────────┘
  Ratio Steps
```

- **Links**: Step-Längen-Ratio (Bruch)
- **Rechts**: Step-Anzahl

### Step-Länge einstellen (linke Seite)
- **↑ Ziehen**: längere Steps (Track läuft langsamer)
- **↓ Ziehen**: kürzere Steps (Track läuft schneller)
- **Klick**: Popover mit Schnellwahl öffnen

Der Bruch zeigt das Verhältnis: Zähler/Nenner = Länge eines Steps als Bruchteil einer Sechzehntel.

| Schnellwahl | Ratio | Klang-Effekt |
|-------------|-------|-------------|
| 32tel | 1:2 | Doppelt so viele Steps pro Beat |
| Septole÷ | 4:7 | 7 Noten auf 4 Sechzehntel |
| 16t·Triole | 2:3 | 3 Noten auf 2 Sechzehntel |
| Quartole÷ | 3:4 | 4 Noten auf 3 Sechzehntel |
| Quintole÷ | 4:5 | 5 Noten auf 4 Sechzehntel |
| Nonole÷ | 8:9 | 9 Noten auf 8 Sechzehntel |
| **16tel** | **1:1** | **Normal — Referenz** |
| Nonole× | 9:8 | Leicht gedehnt |
| Quintole× | 5:4 | Fünf gegen vier |
| 8t·Triole | 4:3 | Achteltriole |
| pkt.16tel | 3:2 | Punktierte Sechzehntel |
| Septole× | 7:4 | Sieben gegen vier |
| 8tel | 2:1 | Halb so viele Steps pro Beat |

> **Snap beim Loslassen**: nach dem Drag rastet der Wert automatisch auf den nächsten musikalisch sinnvollen Ratio ein.

### Step-Anzahl einstellen (rechte Seite)
- **↑ Ziehen**: mehr Steps (1–64)
- **↓ Ziehen**: weniger Steps
- Die Step-Längen-Ratio bleibt beim Ändern der Step-Anzahl erhalten

### Polyrhythmus-Beispiele

| Track | Steps | Ratio | Ergebnis |
|-------|-------|-------|---------|
| Drums | 16 | 1:1 | Grundpuls, 1 Takt |
| Bass | 5 | Quintole÷ (4:5) | 5 gegen 4 — 5 Noten pro Beat-Gruppe |
| Chord | 4 | 1:1 | 1 Akkord pro Viertel |
| Lead | 7 | Septole÷ (4:7) | 7 gegen 4 — Septole |

---

## 5. Undo / Rückgängig

Der Steph Sequencer verwendet den macOS-Standard **Undo-Stack** (NSUndoManager).

**Undo: ⌘Z** — letzten Schritt rückgängig machen
**Redo: ⌘⇧Z** — rückgängig gemachten Schritt wiederholen

Derzeit im Undo-Stack registriert:
| Aktion | Undo |
|--------|------|
| **RND** (Steps randomisieren) | ✅ |
| **CLR** (Track leeren) | ✅ |
| Einzelne Step-Änderungen | ⚠️ geplant für v1.0 |
| Step-Anzahl per Drag | ⚠️ geplant |
| Track-Name | ⚠️ geplant |

---

## 6. Presets / Dateiverwaltung

Presets werden als **JSON-Dateien** gespeichert. Empfohlener Ordner: `Patches/` im Projektverzeichnis.

Ein Preset enthält: BPM, Swing, alle 4 Patterns mit allen Tracks, Steps, CC-Werten und Einstellungen.

### Speichern
- **⌘S**: aktuelles Preset überschreiben (schnelles Speichern)
- **⌘⇧S**: Speichern unter — neuer Dateiname wählen

### Laden
- **⌘O**: Preset öffnen
- Bei ungespeicherten Änderungen erscheint ein Warndialog mit Option zum Abbrechen

### Namensanzeige
- Unterhalb des Logos: aktueller Dateiname
- **Orange Punkt**: ungespeicherte Änderungen vorhanden

---

## 7. Tastaturkürzel

| Kürzel | Funktion |
|--------|----------|
| **Leertaste** | Play / Stop |
| **⌘Z** | Undo — letzten Schritt rückgängig |
| **⌘⇧Z** | Redo |
| **⌘1–⌘4** | Pattern A–D wechseln |
| **⌘S** | Preset speichern |
| **⌘⇧S** | Speichern unter |
| **⌘O** | Preset laden |
| **Escape** | Step-Auswahl aufheben |
| **⌥+Klick** | Step-Detail-Editor öffnen |
| **⇧+Klick** | Step zur Auswahl hinzufügen |
| **⌘⌥T** | Tooltips ein-/ausblenden |

---

## 8. MIDI-Einrichtung

1. **Einstellungen** (Zahnrad-Icon oben rechts) → MIDI-Ausgabegerät wählen
2. Pro Track den gewünschten **MIDI-Kanal** im Dropdown setzen
3. Für externe Clock: **Clock → EXT** wählen, dann MIDI-Clock-Quelle in der DAW aktivieren (Logic: Einstellungen → MIDI → Sync; Ableton: Preferences → Link/Tempo/MIDI)

**Kanal-Empfehlung:**
- Kanal 10: GM Drums (kompatibel mit allen GM-Geräten)
- Kanäle 1–9, 11–16: melodische Instrumente

---

## 9. Tipps & Workflows

**Einfacher polyrhythmischer Groove:**
- Track 1: 16 Steps, 1:1 — Kick/Snare Grundgerüst
- Track 2: 3 Steps, 16t·Triole (2:3) — Triolen-Bass gegen den Beat
- Track 3: 5 Steps, Quintole÷ (4:5) — Quintolen-Melodie

**Lange Akkord-Flächen:**
- Gate auf `1/2` oder `1/1` setzen
- Wenige Steps, hohe Velocity
- Mehrere Tracks mit gleicher Note aber verschiedenen Akkordtypen für dichte Texturen

**Probabilistische Patterns:**
- Einzelne Steps auf 50–75% Wahrscheinlichkeit setzen
- Jeder Durchlauf klingt leicht anders
- Ratchet auf 2–4 für Fills

**Groove mit FEEL:**
- Snare-Track: +8 ms (laid back — wirkt entspannter)
- Hi-Hat-Track: −4 ms (pushed — treibender)
- Unterschied macht den mechanischen Step-Sequencer menschlicher

**Schneller Workflow:**
1. RND drücken für Ausgangsmaterial
2. Ungewollte Steps per Klick abschalten
3. ⌥+Klick für Noten-Details der wichtigen Steps
4. Stretch-Handle für rhythmische Verschiebung
5. ⌘S zum Speichern

---

## 10. Glossar

**BPM** (Beats Per Minute)
Tempo-Angabe: Anzahl der Viertelnoten pro Minute. 120 BPM = 2 Beats pro Sekunde.

**CC** (Control Change)
MIDI-Nachrichtentyp für kontinuierliche Steuerung: Lautstärke, Modulation, Filter-Cutoff etc. Jeder CC hat eine Nummer (0–127) und einen Wert (0–127).

**Gate**
Die Haltedauer einer Note, ausgedrückt als Bruchteil der Step-Dauer. Gate = 1.0 = Legato (Note hält den gesamten Step). Gate < 1.0 = Staccato.

**Lane**
Der scrollbare Bereich rechts im Track, der die Step-Buttons enthält.

**MIDI** (Musical Instrument Digital Interface)
Protokoll zur Kommunikation zwischen Musikinstrumenten und Computern. Sendet keine Audiodaten, sondern Befehle (Note an/aus, Lautstärke, etc.).

**Note Off**
MIDI-Befehl zum Beenden einer Note. Der Sequencer sendet Note-Off automatisch nach Ablauf der Gate-Zeit.

**Pattern**
Ein vollständiger Satz von Tracks (A, B, C oder D). Jedes Pattern kann komplett andere Inhalte haben.

**Ping-Pong**
Wiedergaberichtung: Steps werden vorwärts und dann rückwärts gespielt (1→N→1→N…).

**Polyrhythmus**
Übereinander liegende Rhythmen in verschiedenen Zeitverhältnissen. Beispiel: 3 gegen 4 bedeutet, dass drei gleichmäßige Schläge in denselben Zeitraum passen wie vier andere.

**PPQ / PPQN** (Pulses Per Quarter Note)
Interne Zeitauflösung. Der Steph Sequencer arbeitet mit 24 PPQ (MIDI-Standard).

**Preset**
Gespeicherter Zustand der App: BPM, Swing, alle 4 Patterns mit allen Tracks und Steps. Wird als JSON-Datei gespeichert.

**Probability / Wahrscheinlichkeit**
Prozentualer Wert, mit dem ein Step gespielt wird. 75% bedeutet: im Durchschnitt 3 von 4 Mal.

**Ratchet**
Mechanismus der einen Step mehrfach wiederholt (2–8×). Klingt wie ein Maschinengewehr-Effekt auf der Note.

**Ratio**
Verhältnis der Step-Länge zur normalen Sechzehntel-Note. 1:1 = normal, 2:3 = Triole (kürzer), 3:2 = punktiert (länger).

**Step**
Ein einzelner Zeitslot im Sequencer. Standard: eine Sechzehntel-Note lang (bei Ratio 1:1).

**Step-Anzahl**
Wie viele Steps ein Track hat (1–64). Alle Steps laufen in Schleife.

**Stretch / Strecken**
Verändern der Step-Länge per Ratio-Modell. Mehr als 1:1 = langsamer, weniger = schneller. Erzeugt Polyrhythmik wenn verschiedene Tracks verschiedene Ratios haben.

**Swing**
Verzögerung jedes zweiten Steps um einen prozentualen Anteil. Macht den Rhythmus "wippend" statt starr.

**Track**
Eine Spur im Sequencer. Hat eigene Steps, MIDI-Kanal, Richtung und Ratio.

**Undo-Stack**
Liste der rückgängig machbaren Aktionen (⌘Z). Jede registrierte Aktion wird auf den Stack gelegt; Undo nimmt die oberste zurück.

**Velocity**
Anschlagstärke einer MIDI-Note (0–127). Beeinflusst typischerweise die Lautstärke und den Klangcharakter.

---

*Steph Sequencer ist ein persönliches Instrument — viel Spaß beim Spielen.*
