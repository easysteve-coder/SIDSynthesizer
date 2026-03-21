# Steph Sequencer — Bedienungsanleitung (Rohfassung)
Version 0.13 | macOS | Stand: März 2026

---

## Was ist der Steph Sequencer?

Der Steph Sequencer ist ein Step Sequencer für macOS. Ein Step Sequencer funktioniert wie eine Schrittmaschine: Man legt im Voraus fest, welche Noten in welcher Reihenfolge gespielt werden sollen, und das Programm spielt diese Sequenz immer wieder ab — im gewählten Tempo, synchron zu anderen Geräten oder einer DAW.

Im Gegensatz zu einfachen Step Sequencern unterstützt der Steph Sequencer:
- Verschiedene Schrittanzahlen pro Spur (Polyrhythmus)
- Ungerade Taktarten (5, 7, 9, 11, 13 Schritte…)
- Detaillierte Steuerung pro Schritt (Note, Velocity, Gate, Wahrscheinlichkeit, Ratchet, zwei CCs)
- Mehrere unabhängige Spuren gleichzeitig

---

## Grundbegriffe

**Step (Schritt):** Ein einzelner Zeitslot in der Sequenz. Jeder Step kann eine Note enthalten oder inaktiv sein. Ein Step hat eine feste Länge abhängig vom Tempo (bei 120 BPM und 16tel-Steps = 125ms pro Step).

**Track (Spur):** Eine Sequenz von Steps, die auf einem MIDI-Kanal abgespielt wird. Jeder Track läuft unabhängig mit eigener Schrittanzahl und Richtung.

**Pattern:** Eine Sammlung von bis zu 8 Tracks. Der Steph Sequencer hat 4 Patterns (A, B, C, D), zwischen denen man live umschalten kann.

**Gate:** Die Länge einer Note als Prozentsatz der Step-Dauer. Gate 100% = die Note klingt bis kurz vor dem nächsten Step (Legato). Gate 10% = kurzer, staccato Schlag mit viel Stille danach.

**Velocity:** Die Anschlagstärke einer Note (1–127). Höhere Werte = lauter/stärker.

**MIDI-Kanal:** MIDI sendet auf 16 unabhängigen Kanälen. Kanal 10 ist per GM-Standard für Schlagzeug reserviert.

---

## Oberfläche im Überblick

Die Benutzeroberfläche ist in drei Bereiche gegliedert:

### 1. Transport-Leiste (oben)
Enthält alle globalen Steuerelemente: Play/Stop, BPM-Regler, Swing, Tap-Tempo, Pattern-Auswahl (A/B/C/D), Clock-Umschalter (INT/EXT).

### 2. Track-Bereich (Mitte)
Hier sind alle Spuren untereinander dargestellt. Jede Spur besteht aus einem Kopfbereich (links) mit den Spur-Einstellungen und einer scrollbaren Step-Reihe (rechts).

### 3. Statusleiste (unten)
Zeigt den aktuellen Zustand: RUNNING/STOPPED, BPM, Clock-Modus, aktives Pattern, gewählter MIDI-Ausgang.

---

## Transport-Leiste

### Play / Stop
Startet und stoppt die Sequenz. Bei Stop werden alle laufenden Noten sofort beendet (All Notes Off pro Kanal).

**Tastaturkürzel:** Leertaste

### BPM (Tempo)
Steuert das Tempo in Beats per Minute (BPM). Bereich: 20–300 BPM. Bedienung:
- Drehregler: Maus nach oben/unten ziehen (140px = voller Bereich)
- Pfeiltasten ▲▼ neben der Anzeige: Feinjustierung ±0.1 BPM
- Doppelklick auf den Regler: Reset auf Mittelwert

### Tap Tempo
Mit mehrmaligem Klicken auf TAP wird das Tempo aus dem Taktabstand ermittelt. Mindestens 2 Klicks nötig, ab 3 Klicks wird gemittelt.

### Swing
Verschiebt jeden zweiten Step (ungerade Schritte) leicht nach hinten. Dadurch entsteht ein Groove-Feeling statt maschineller Präzision.
- 0% = alle Steps genau auf dem Raster (gerade)
- 100% = maximaler Swing (Triolen-Feeling)
- 50% = mittelstarker Swing

Swing wirkt auf alle Tracks gleichzeitig.

### Pattern A / B / C / D
Vier unabhängige Pattern-Speicher. Jedes Pattern hat seine eigenen Tracks, Steps und Einstellungen. Umschalten ist auch während der Wiedergabe möglich — der Wechsel erfolgt am Ende des aktuellen Durchlaufs.

**Tastaturkürzel:** ⌘A, ⌘B, ⌘C, ⌘D

**Pattern kopieren:** ⌘⌥C (kopiert das aktuelle Pattern)
**Pattern einfügen:** ⌘⌥V (fügt in das aktuelle Pattern ein)

Typischer Workflow: Pattern A als Grundlage programmieren → zu Pattern B wechseln → ⌘⌥V → leicht abwandeln → Live zwischen A und B umschalten.

### Clock INT / EXT
- **INT:** Der Steph Sequencer ist der Taktgeber. Er sendet MIDI Clock an alle verbundenen Geräte.
- **EXT:** Der Steph Sequencer empfängt MIDI Clock von einer DAW oder einem externen Gerät. Start/Stop werden ebenfalls von extern gesteuert. Der interne BPM-Regler ist in diesem Modus inaktiv.

---

## Tracks

### Track hinzufügen
Unterhalb aller Tracks befindet sich der Button "+ ADD TRACK". Jeder neue Track bekommt automatisch den nächsten freien MIDI-Kanal. Es gibt kein hartes Limit für die Anzahl der Tracks — die praktische Grenze ist die eigene Übersicht.

### Track-Kopfbereich (links)
Jeder Track hat links einen Kopfbereich mit folgenden Elementen:

**Track-Name:** Klicken zum Bearbeiten. Enter oder Klick außerhalb bestätigt und verlässt das Textfeld.

**m (Mute):** Schaltet die Spur stumm. Noten werden nicht gesendet, CC-Werte ebenfalls nicht. Der Sequencer läuft intern weiter.

**s (Solo):** Soliert diese Spur. Alle anderen Spuren werden stumm geschaltet. Mehrere Spuren können gleichzeitig soliert sein.

**Richtung (FWD / REV / P-P / RND):**
- FWD (Forward): Steps werden von links nach rechts gespielt (Standard)
- REV (Reverse): Steps werden von rechts nach links gespielt
- P-P (Ping-Pong): Erst vorwärts bis zum letzten Step, dann rückwärts, dann wieder vorwärts
- RND (Random): Der nächste Step wird zufällig gewählt — jede Wiederholung klingt anders

**Step-Anzahl (− Zahl +):** Anzahl der Steps dieser Spur (1–32). Spuren mit verschiedenen Schrittanzahlen erzeugen automatisch Polyrhythmus — sie laufen unabhängig und treffen sich erst nach dem kleinsten gemeinsamen Vielfachen wieder synchron.

**CH (MIDI-Kanal):** Auf welchem MIDI-Kanal diese Spur sendet (1–16). Kanal 10 aktiviert den Drum-Modus (GM-Schlagzeug-Mapping).

**⎘ (Duplizieren):** Erstellt eine exakte Kopie dieser Spur in allen 4 Patterns gleichzeitig. Nützlich um eine Variation einer bestehenden Spur zu erstellen.

**× (Löschen):** Löscht die Spur aus allen 4 Patterns. Kann nicht rückgängig gemacht werden.

**RND:** Randomisiert alle Steps dieser Spur — zufällige Noten, Velocity-Werte und Wahrscheinlichkeiten. Guter Ausgangspunkt für neue Ideen.

**CLR:** Löscht alle Steps dieser Spur (alle inaktiv, Werte auf Standard).

**FEEL (Timing Offset):** Verschiebt alle Noten dieser Spur leicht im Zeit:
- Positiver Wert (z.B. +15ms): Laid Back — die Spur spielt leicht hinter dem Beat (Jazz-Bass-Feeling)
- Negativer Wert (z.B. -10ms): Pushed — die Spur spielt leicht vor dem Beat (drückender Drummer)
- 0: Genau auf dem Raster

---

## Steps

### Step aktivieren/deaktivieren
Einfacher Klick auf einen Step-Button schaltet ihn ein oder aus. Aktive Steps leuchten in der Spurfarbe, inaktive Steps sind dunkel.

### Step bearbeiten (Step-Edit Popover)
**⌥+Klick** (Option-Taste gedrückt halten + Klick) öffnet das Bearbeitungsfenster für diesen Step. Alternativ: Rechtsklick → "Edit Step…"

Das Step-Edit-Fenster schließt sich mit **Enter** oder Klick außerhalb.

Im Step-Edit-Fenster:

**ACTIVE:** Schaltet den Step an oder aus (gleich wie direkter Klick).

**NOTE (0–127):** Die MIDI-Notennummer. Der Drehregler deckt den vollen Bereich ab. Darunter der **Quick Note Picker**: Oktave wählen mit − und +, dann eine der 12 Halbtöne anklicken. Auf Kanal 10 erscheint stattdessen der **Drum Sound Picker** mit den GM-Schlagzeug-Instrumenten in Gruppen (Kick/Snare, Hi-Hat, Toms, Cymbal).

**VEL (Velocity, 1–127):** Anschlagstärke der Note. Niedrig = leise/weich, hoch = laut/hart. Im Step-Button wird die Velocity als kleiner Balken am unteren Rand angezeigt.

**GATE% (1–100):** Wie lang die Note klingt, als Prozentsatz der Step-Dauer. 100% = Legato (Note klingt bis fast zum nächsten Step), 10% = Staccato. Typische Werte: 40–70% für normale Spielweise.

**PROB% (Probability/Wahrscheinlichkeit, 0–100):** Mit welcher Wahrscheinlichkeit dieser Step beim nächsten Durchlauf spielt. 100% = immer, 50% = jedes zweite Mal (zufällig), 0% = nie. Erzeugt organische, lebendige Grooves ohne Humanizing.

**CC1 / CC2:** Zwei frei konfigurierbare MIDI-Controller-Werte (0–127). Die zugehörigen CC-Nummern und Beschriftungen werden in den Einstellungen pro Spur festgelegt. Diese Werte werden auf jedem Step gesendet, unabhängig davon ob die Note aktiv ist — eine Spur kann also als reiner Automations-Track dienen.

**RATCHET (×1 / ×2 / ×4):** Wie oft die Note innerhalb eines Steps gespielt wird:
- ×1: einmal (normal)
- ×2: zweimal (Note klingt zweimal in der Zeit eines Steps — wie eine Triole)
- ×4: viermal (sehr schnelle Wiederholung — Drum-Roll, Tremolo-Effekt)

Die Gate-Zeit wird automatisch auf die Sub-Step-Länge angepasst.

---

## CC-Regler (Modulationsreihe)

Jede Spur kann durch Klick auf das Expand-Symbol (▶) eine oder zwei Reihen von Drehreglern unterhalb der Steps einblenden. Jeder Drehregler entspricht dem CC1- bzw. CC2-Wert des zugehörigen Steps.

Diese Regler senden ihren Wert auf jedem Step, auch wenn der Step keine aktive Note hat. Damit können z.B. Filter-Sweeps oder Expressions-Kurven programmiert werden, die unabhängig von den Noten laufen.

Die Beschriftung der Regler (z.B. "Filter", "Expr") wird in den Einstellungen festgelegt.

---

## Mehrere Steps gleichzeitig bearbeiten (Multi-Select)

**Shift+Klick** auf einen Step markiert ihn (blau hervorgehoben). Weitere Shift+Klicks fügen der Auswahl weitere Steps hinzu.

Bei aktiver Auswahl erscheint eine Aktionsleiste oberhalb der Steps:
- **EDIT:** Öffnet das Bulk-Edit-Fenster für alle markierten Steps gleichzeitig
- **COPY:** Kopiert die markierten Steps in den Zwischenspeicher
- **PASTE:** Fügt den Zwischenspeicher in die markierten Steps ein (zyklisch, falls Quelle und Ziel unterschiedlich groß)
- **CLR:** Löscht alle markierten Steps (auf inaktiv, Werte zurückgesetzt)
- **✕:** Auswahl aufheben

Im Bulk-Edit-Fenster können Note/Drum-Sound, Velocity, Gate und Probability für alle markierten Steps gleichzeitig gesetzt werden. "ALLE AN" / "ALLE AUS" schaltet alle markierten Steps auf einmal ein oder aus.

Typischer Workflow: Alle Hi-Hat-Steps per Shift+Klick markieren → EDIT → "HH Cls" im Drum-Picker wählen → alle Steps haben jetzt Hi Hat Closed.

---

## Steps verschieben (Drag & Drop)

Steps können per Drag & Drop innerhalb einer Spur verschoben werden:
- **Einfaches Ziehen:** Schiebt den Step an die neue Position (Tausch)
- **⌥ gedrückt halten + Ziehen:** Kopiert den Step an die neue Position (Original bleibt)

Der Quell-Step wird beim Ziehen leicht transparent dargestellt. Der Ziel-Step wird mit einem weißen Rahmen markiert.

---

## MIDI Learn

Der MIDI-Learn-Modus erlaubt es, Notes direkt von einem angeschlossenen MIDI-Keyboard in die Steps einzuspielen.

1. **LEARN** Button im Transport drücken (leuchtet auf)
2. Den ersten zu befüllenden Step anklicken (weißer Rahmen erscheint)
3. Auf dem MIDI-Keyboard die gewünschte Note spielen → Note wird in den Step übernommen, der Cursor springt automatisch zum nächsten Step
4. Weiter spielen bis alle gewünschten Steps befüllt sind — LEARN deaktiviert sich automatisch am Ende der Spur
5. Oder: LEARN nochmals drücken zum vorzeitigen Beenden

---

## Drum-Modus (MIDI-Kanal 10)

Wird einer Spur der MIDI-Kanal 10 zugewiesen, aktiviert sich automatisch der Drum-Modus:
- Im Step-Button werden statt Notennamen die GM-Schlagzeug-Instrument-Namen angezeigt (z.B. "Kick", "HH Cls", "Snare")
- Im Step-Edit-Fenster erscheint statt des chromatischen Note-Pickers ein **Drum Sound Picker** mit den Instrumenten in Gruppen: Kick/Snare, Hi-Hat, Toms, Cymbal
- Im Bulk-Edit-Fenster ebenfalls

Standard GM-Zuordnungen (Auswahl):
- Note 36: Kick
- Note 38: Snare
- Note 42: Hi Hat Closed
- Note 44: Hi Hat Pedal
- Note 46: Hi Hat Open
- Note 49: Crash
- Note 51: Ride
- Note 45/47/48/50: Toms

---

## Polyrhythmus

Verschiedene Spuren können unterschiedliche Schrittanzahlen haben. Da alle Spuren gleichzeitig und unabhängig laufen, entstehen komplexe rhythmische Überlagerungen:

- Spur 1: 7 Steps → Spur 2: 5 Steps → Spur 3: 9 Steps → Spur 4: 4 Steps
- Die Spuren treffen sich erst nach dem kleinsten gemeinsamen Vielfachen (7×5×9×4 = 1260 Steps!) wieder exakt synchron
- Klingt komplex, entsteht aber aus einfachen Mustern

Für Prog-Rock typische Kombinationen:
- 7 gegen 4 (7/8 gegen 4/4)
- 5 gegen 3 (5/4 gegen 3/4)
- 11 gegen 7 (sehr komplex)

---

## Einstellungen

Aufruf über das Zahnrad-Symbol oder Menü → Settings.

**Anzahl der Spuren:** Kann hier ebenfalls angepasst werden (zusätzlich zu den +/- Buttons im Hauptfenster).

**MIDI-Ausgang:** Welches Gerät oder welche App MIDI-Daten empfängt. Der Steph Sequencer erstellt außerdem einen virtuellen MIDI-Port namens "Steph Sequencer Out", der in jeder DAW als Eingang erscheint.

**MIDI-Eingang:** Welches Gerät MIDI Clock und CC-Daten sendet. Wird für EXT-Clock und MIDI-Learn benötigt.

**CC-Einstellungen pro Spur:**
- CC1-Nummer: Welcher MIDI-Controller von den Knobs in Reihe 1 gesteuert wird (z.B. 74 = Cutoff-Filter)
- CC1-Beschriftung: Der Name, der im Interface angezeigt wird (z.B. "Filter")
- CC2-Nummer und CC2-Beschriftung entsprechend für die zweite Knob-Reihe

**CC Remote Control (Pattern-Wechsel):** Ein MIDI-CC-Wert kann zugewiesen werden, mit dem Pattern A/B/C/D von extern umgeschaltet wird. Werte 0–31=A, 32–63=B, 64–95=C, 96–127=D.

**Mute per CC:** Pro Spur kann ein CC zugewiesen werden, mit dem die Spur per MIDI gemuted/ungemuted wird. Wert ≥64 = gemuted.

---

## Presets speichern und laden

**Datei → Save Preset… (⌘S):** Speichert alle 4 Patterns inklusive aller Track- und Step-Daten als JSON-Datei. Es wird ein Standard-Speicherdialog geöffnet.

**Datei → Open Preset… (⌘O):** Lädt eine gespeicherte JSON-Datei. Die aktuelle Sequenz wird gestoppt und ersetzt.

Das JSON-Format ist offen lesbar und kann von Hand oder mit KI-Hilfe bearbeitet werden. Damit lassen sich Presets automatisch generieren, z.B. durch eine KI mit dem Auftrag: "Erstelle einen 7/8-Groove im Stil von Tool".

---

## Tastaturkürzel — Übersicht

| Kürzel | Funktion |
|--------|----------|
| Leertaste | Play / Stop |
| ⌘A | Pattern A auswählen |
| ⌘B | Pattern B auswählen |
| ⌘C | Pattern C auswählen |
| ⌘D | Pattern D auswählen |
| ⌘⌥C | Aktuelles Pattern kopieren |
| ⌘⌥V | Pattern einfügen |
| ⌘S | Preset speichern |
| ⌘O | Preset laden |
| ⌥+Klick | Step-Edit öffnen |
| Shift+Klick | Step markieren/abwählen |
| Enter | Step-Edit-Fenster schließen |
| Rechtsklick auf Step | Kontextmenü (Edit, Clear, Max Velocity…) |

---

## MIDI-Ausgabe — was wird wann gesendet?

- **Note On / Note Off:** Wird gesendet wenn ein Step aktiv ist und die Probability-Prüfung besteht
- **CC-Werte:** Werden auf jedem Step gesendet, unabhängig von isActive — auch auf inaktiven Steps
- **MIDI Clock (0xF8):** Wird im INT-Modus gesendet (24 Pulse pro Viertelnote)
- **MIDI Start (0xFA):** Beim Drücken von Play
- **MIDI Stop (0xFC):** Beim Drücken von Stop
- **All Notes Off:** Beim Stop-Befehl auf jedem verwendeten Kanal
- **Ratcheting:** Mehrere Note On/Off innerhalb eines Steps, zeitlich gleichmäßig aufgeteilt

---

## Tipps für den Live-Einsatz

- **Pattern-Wechsel:** Patterns wechseln synchron am Ende des aktuellen Durchlaufs — kein abrupter Schnitt
- **Mute als Performance-Tool:** Spuren während der Wiedergabe muten/unmuten für Breaks und Buildups
- **Probability live ändern:** Step-Edit öffnen, Prob-Regler drehen — wirkt sofort auf den nächsten Durchlauf
- **CLK EXT:** Wenn Logic oder eine andere DAW als Taktgeber dient, auf EXT stellen — Start/Stop kommen dann von der DAW
- **FEEL für Groove:** Bass-Spur auf +15ms, Hi-Hat auf -5ms → sofort lebendigeres Feeling als reines Raster
- **RND-Richtung für Pads:** Eine Akkord-Spur auf RANDOM stellen — die Noten kommen in unvorhersehbarer Reihenfolge, klingt wie ein Arpeggiator mit Persönlichkeit

---

*Steph Sequencer — entwickelt mit Claude (Anthropic) | Prog Rock Edition*
*Für Fragen, Bugs und Feature-Ideen: iterativ weiterentwickeln*
