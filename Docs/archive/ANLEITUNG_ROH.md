# Steph Sequencer — Benutzerhandbuch (Rohfassung)

---

## 1. Einleitung: Was ist der Steph Sequencer?

Der Steph Sequencer ist ein Step Sequencer für macOS, entwickelt speziell für Musiker im Bereich Prog Rock, experimentelle Elektronik und alle, die komplexe rhythmische Strukturen mit minimalem Aufwand erstellen wollen. Die Oberfläche ist bewusst im Vintage-Stil gehalten — angelehnt an klassische Hardwaresequencer der 70er und 80er Jahre.

**Kernideen:**

- **Polyrhythmus:** Jeder Track kann eine eigene Anzahl von Steps haben. Wenn Track 1 sieben Steps hat und Track 2 vier Steps, entsteht automatisch ein 7:4-Polyrhythmus. Keine komplizierten Einstellungen nötig — einfach die Step-Anzahl pro Track unterschiedlich wählen.
- **Vintage GUI:** Warme Farben, analoge Knobs, ein Look der an alte Sequencer-Hardware erinnert.
- **MIDI-Integration:** Der Sequencer arbeitet als virtuelles MIDI-Gerät unter macOS und kommuniziert mit DAWs wie Logic Pro, Ableton Live oder mit Hardware-Synthesizern über einen MIDI-Interface.
- **Flexibilität:** Vier Pattern-Speicher (A/B/C/D), bis zu acht Tracks pro Pattern, bis zu 32 Steps pro Track, MIDI CC-Automation pro Step, Drum-Modus für Kanal 10.

---

## 2. Installation und Starten

1. Die App liegt als `.app`-Bundle vor. Einfach in den Programme-Ordner ziehen oder direkt aus dem Projektordner starten.
2. Beim ersten Start erscheint möglicherweise eine macOS-Sicherheitsmeldung. In den Systemeinstellungen unter Datenschutz & Sicherheit die App freigeben.
3. In der DAW (z.B. Logic Pro) ein MIDI-Instrument anlegen und als MIDI-Eingang **"Steph Sequencer"** (virtuelles MIDI-Gerät) wählen.
4. Alternativ: externen MIDI-Clock aus der DAW an den Steph Sequencer senden — dazu in der App **CLK EXT** aktivieren.

---

## 3. Oberfläche: Transport-Bereich

Der Transport-Bereich befindet sich oben in der App.

### BPM
- Großer Knob für das Tempo. Durch Ziehen (vertikal) einstellen.
- Feinere Anpassung mit den kleinen **▲▼**-Buttons neben dem BPM-Wert.
- **TAP Tempo:** Mehrfach auf den TAP-Button tippen, um das Tempo einzuspielen. Nach drei Taps wird der Durchschnitt berechnet.

### Swing
- Regler von 0 bis 100 %.
- **0 %** = gerade, maschinelle 16tel-Noten.
- **100 %** = maximaler Triplet-Swing — jede zweite 16tel wird nach hinten verschoben, ergibt den klassischen Shuffle-Groove.
- Werte um 60–70 % sind ein typischer Jazz- oder Funk-Swing.

### Play / Stop
- **Space-Taste** oder der Play/Stop-Button startet und stoppt die Sequenz.
- Im EXT-Clock-Modus reagiert die App auf Start/Stop-Signale der DAW.

### Pattern A / B / C / D
- Vier unabhängige Pattern-Speicher. Umschalten per Klick auf den jeweiligen Button oder per Tastatur: **⌘A**, **⌘B**, **⌘C**, **⌘D**.
- Pattern-Wechsel kann auch per MIDI CC gesteuert werden (siehe Einstellungen).
- **Pattern kopieren:** ⌘⌥C — kopiert das aktuelle Pattern in die Zwischenablage.
- **Pattern einfügen:** ⌘⌥V — fügt das kopierte Pattern in das aktuell ausgewählte Pattern ein.

### CLK INT / CLK EXT
- **INT:** Der interne Clock-Generator ist aktiv. Der Sequencer sendet MIDI-Clock an die DAW (24 Pulse per Quarter Note, kurz PPQ).
- **EXT:** Der Sequencer empfängt MIDI-Clock von der DAW. BPM wird von der DAW bestimmt. Start/Stop der DAW startet/stoppt auch den Sequencer.

### LEARN-Button
- Aktiviert den MIDI-Learn-Modus für schnelle Note-Zuweisung (siehe Abschnitt "MIDI Learn").

---

## 4. Tracks: Aufbau und Bedienung

Jeder Track repräsentiert eine Stimme — zum Beispiel eine Basslinie, ein Lead-Synth oder eine Drum-Spur.

### Track-Header (von links nach rechts):

| Element | Beschreibung |
|---|---|
| **Name** | Klick zum Editieren, Enter zum Bestätigen |
| **Direction** | Abspielrichtung (FWD / REV / P-P / RND) |
| **Steps** | Anzahl der Steps (1–32) |
| **Channel** | MIDI-Kanal (1–16; Kanal 10 = Drum-Modus) |
| **SCL —** | Scale Filter — Tonarten-Raster aktivieren (siehe Abschnitt 5) |
| **m** (Mute) | Track stummschalten |
| **s** (Solo) | Nur diesen Track hören |
| **RND** | Alle Steps des Tracks randomisieren |
| **CLR** | Alle Steps löschen (auf inaktiv setzen) |
| **⎘** (Duplicate) | Track duplizieren |
| **×** (Delete) | Track löschen |

### Direction — Abspielrichtung:

- **FWD** (Forward): Klassisch von links nach rechts.
- **REV** (Reverse): Von rechts nach links.
- **P-P** (Ping-Pong): Hin und zurück — erst FWD, dann REV.
- **RND** (Random): Jeder nächste Step wird zufällig gewählt.

### Timing-Offset (FEEL-Regler):

Jeder Track hat einen FEEL-Regler:
- **Positiver Wert (+):** Track spielt leicht verzögert — "laid back", entspannt, hinterm Beat.
- **Negativer Wert (−):** Track spielt leicht vorgezogen — "pushed", vor dem Beat.

Das ermöglicht subtile Groove-Unterschiede zwischen den Tracks, ohne den globalen Swing zu verändern.

---

## 5. Scale Filter / Tonarten-Raster (v0.14)

Jeder Track verfügt über einen eigenen Scale Filter, der eingespielte und programmierte Noten auf eine gewählte Tonart beschränkt bzw. quantisiert.

### Aktivierung

- Im Track-Header befindet sich der **SCL —** Button.
- Ein Klick auf den Button öffnet ein Popover mit zwei Bereichen:

**GRUNDTON** — 12 Buttons zur Wahl des Grundtons:

> C · C# · D · D# · E · F · F# · G · G# · A · A# · B

**MODUS** — Wahl des Tonleitermodus:

| Modus | Beschreibung |
|---|---|
| **Chromatic** | Filter deaktiviert (alle 12 Halbtöne erlaubt) |
| **Major** | Durtonleiter |
| **Minor** | Natürliches Moll |
| **Dorian** | Dorisch (Moll mit erhöhter Sexte) |
| **Phrygian** | Phrygisch (Moll mit erniedrigter Sekunde) |
| **Lydian** | Lydisch (Dur mit erhöhter Quarte) |
| **Mixolydian** | Mixolydisch (Dur mit erniedrigter Septime) |
| **Harm. Minor** | Harmonisches Moll (erhöhte Septime) |
| **Penta Major** | Pentatonik Dur (5-Ton-Skala) |
| **Penta Minor** | Pentatonik Moll (5-Ton-Skala) |
| **Blues** | Blues-Skala (Pentatonik Moll + Blue Note) |
| **Whole Tone** | Ganztonleiter (6 Töne, symmetrisch) |

### Anzeige im Track-Header

- Wenn ein Scale Filter aktiv ist, zeigt der Button die gewählte Kombination an — z.B. **"A MIN"** für A Minor oder **"D DOR"** für D Dorian.
- Das **✕** rechts neben dem Button deaktiviert den Filter sofort, ohne das Popover zu öffnen.
- Bei inaktivem Filter (Chromatic) zeigt der Button **"SCL —"**.

### Verhalten im Step-Edit-Fenster (Quick Note Picker)

- Noten, die außerhalb der gewählten Tonart liegen, werden **ausgegraut** dargestellt.
- Ein Klick auf eine ausgegraute Note springt automatisch zur **nächstgelegenen In-Scale-Note** (nach oben oder unten, je nachdem was näher liegt).
- Unterhalb des Pickers erscheint ein Hinweistext, z.B.: *"Scale: A Minor — ausgegraute Noten außerhalb der Tonart"*

### MIDI Learn mit Scale Filter

- Wenn MIDI Learn aktiv ist und ein Scale Filter für den Track eingestellt wurde, werden eingespielte Noten **automatisch auf die nächste In-Scale-Note quantisiert**, bevor sie dem Step zugewiesen werden.
- Das ermöglicht ein natürliches Einspielen auf der Klaviatur, ohne jede Note exakt treffen zu müssen.

### Mehrere Tracks, mehrere Tonarten

- Jeder Track kann eine **eigene Tonart** haben — z.B. Track 1 in A Minor, Track 2 in D Dorian, Track 3 ohne Filter.
- Tonarten werden beim Speichern als Teil des Presets gesichert und beim Laden wiederhergestellt.

---

## 6. Steps: Grundlagen

### Was ist ein Step?

Ein Step ist eine einzelne rhythmische Einheit innerhalb eines Tracks. Bei 16 Steps und 120 BPM entspricht jeder Step einer 16tel-Note.

### Aktiv / Inaktiv

- **Einfacher Klick** auf einen Step: Step ein- oder ausschalten (aktiv = leuchtet auf, inaktiv = dunkel).
- Aktive Steps spielen ihre zugewiesene Note ab. Inaktive Steps sind stumm.

### Step-Editor öffnen

- **⌥ + Klick** (Option-Taste gedrückt halten, dann klicken): Öffnet das Step-Edit-Fenster für diesen einen Step.

### Mehrfachauswahl

- **⇧ + Klick** (Shift-Taste gedrückt halten, dann klicken): Step zur Auswahl hinzufügen oder daraus entfernen.
- Mehrere Steps markieren, dann über die Toolbar oben bearbeiten, kopieren oder löschen.

---

## 7. Step-Edit-Fenster

Das Step-Edit-Fenster öffnet sich per ⌥+Klick auf einen Step. Hier werden alle detaillierten Eigenschaften eines Steps eingestellt.

### Parameter im Überblick:

| Parameter | Bereich | Beschreibung |
|---|---|---|
| **Note** | 0–127 | MIDI-Notennummer (60 = C4, mittleres C) |
| **Velocity** | 1–127 | Anschlagstärke — laut (127) oder leise (1) |
| **Gate %** | 1–100 % | Länge der Note relativ zur Step-Dauer |
| **Probability %** | 1–100 % | Wahrscheinlichkeit, dass der Step spielt |
| **CC1** | 0–127 | Wert für CC-Kanal 1 dieses Steps |
| **CC2** | 0–127 | Wert für CC-Kanal 2 dieses Steps |
| **Ratchet** | ×1 / ×2 / ×4 | Mehrfaches Triggern innerhalb des Steps |
| **ACTIVE** | Toggle | Step aktivieren / deaktivieren |

### Quick Note / Drum Sound Picker

- Auf einem normalen Track: eine visuelle Piano-Tastatur zur schnellen Notenwahl.
- Wenn ein Scale Filter aktiv ist: Noten außerhalb der Tonart werden ausgegraut; Klick auf eine ausgegraute Note springt zur nächstgelegenen In-Scale-Note.
- Auf Kanal 10 (Drum-Modus): ein Raster mit den Standard-GM-Drumsound-Namen (Kick, Snare, Hi-Hat usw.). Per Klick wird die entsprechende Note automatisch gesetzt.

### Schließen

- **Enter-Taste** schließt das Step-Edit-Fenster.
- Alternativ: Klick außerhalb des Fensters.

---

## 8. Erklärungen zu Schlüsselparametern

### Gate %

Der Gate-Wert bestimmt, wie lange die Note klingt, bevor sie abgeschaltet wird (Note-Off). Er wird als Prozentsatz der Step-Dauer angegeben.

- **100 %** = Legato — die Note klingt bis kurz vor dem nächsten Step. Fließende, gebundene Melodien.
- **50 %** = Normal — Standard-Länge, Note und Pause halten sich ungefähr die Waage.
- **10 %** = Staccato — sehr kurzer, knapper Schlag. Perkussive Bassläufe, aggressive Synthesizer.

### Probability %

Die Wahrscheinlichkeit bestimmt, ob ein aktiver Step bei jedem Durchlauf wirklich spielt.

- **100 %** = Der Step spielt immer (deterministisch).
- **75 %** = Der Step spielt meistens, aber nicht bei jedem Durchlauf. Bringt lebendige Variation.
- **50 %** = Coin-Flip — ungefähr die Hälfte der Zeit.
- **25 %** = Spielt selten, taucht aber gelegentlich überraschend auf.

**Typischer Einsatz:** Hi-Hat mit 75 % Probability wirkt organischer als eine perfekt gleichmäßige Maschinenspur.

### Ratchet

Ratchet lässt einen Step innerhalb seiner Dauer mehrfach triggern — ähnlich einem Flam oder Tremolo-Effekt.

- **×1** = Normal — Step triggert einmal.
- **×2** = Zwei Trigger innerhalb des Steps. Aus einer 16tel werden zwei 32tel-Noten.
- **×4** = Vier Trigger innerhalb des Steps. Sehr schnelles, maschinengewehrähnliches Retriggering.

**Typischer Einsatz:** Ein einzelner Hi-Hat-Step mit ×4 Ratchet erzeugt einen klassischen Drum-Roll-Effekt. Ein Basssynth mit ×2 auf betonten Zählzeiten klingt nach Arpeggio.

---

## 9. CC-Reihen

Jeder Track kann zwei MIDI CC-Werte pro Step senden — zum Beispiel Filter-Cutoff und Resonanz.

- Im Track-Header: kleiner Pfeil-Button klappt die CC-Reihen aus und ein.
- Wenn aufgeklappt: Für jeden Step erscheinen zwei Knobs (CC1 und CC2).
- Die CC-Nummern werden im Track-Header eingestellt (Standard z.B. CC1 = 74 für Filter).
- CCs werden **immer** gesendet, auch wenn ein Step inaktiv ist — so können Automation-Kurven auch über stumme Steps laufen.

---

## 10. Drum-Modus (Kanal 10)

Wird einem Track der MIDI-Kanal 10 zugewiesen, aktiviert sich automatisch der Drum-Modus:

- Die Note-Anzeige in jedem Step zeigt statt einer Notenbezeichnung (C4, D#3) den entsprechenden GM-Drumsound-Namen: **Kick**, **Snare**, **HH Cls** (Hi-Hat geschlossen), **HH Opn** (Hi-Hat offen), **Crash**, **Ride**, usw.
- Im Step-Edit-Fenster erscheint der Drum-Sound-Picker anstelle der Piano-Tastatur.
- Praktisch: Ein Track pro Sound (Track 1 = Kick, Track 2 = Snare, Track 3 = Hi-Hat) oder einen Track für alle Drums mit unterschiedlichen Noten pro Step.

---

## 11. Mehrfachauswahl und Bulk-Editing

### Auswählen

- ⇧+Klick auf einzelne Steps fügt sie der Auswahl hinzu.
- Erneuter ⇧+Klick entfernt sie aus der Auswahl.

### Toolbar bei aktiver Auswahl

Sind Steps markiert, erscheint eine Toolbar oberhalb des Tracks:

| Button | Funktion |
|---|---|
| **EDIT** | Öffnet den Bulk-Editor — ein Step-Edit-Fenster, das alle markierten Steps gleichzeitig bearbeitet |
| **COPY** | Kopiert die markierten Steps in die Zwischenablage |
| **PASTE** | Fügt kopierte Steps ab der ersten Markierung ein |
| **CLR** | Setzt alle markierten Steps auf inaktiv |

**Bulk-Edit:** Im Multi-Step-Edit-Fenster gelten Änderungen an Velocity, Gate, Probability, Ratchet etc. für alle markierten Steps gleichzeitig. Ideal um z.B. einer ganzen Snare-Reihe dieselbe Velocity zu geben.

---

## 12. Drag & Drop

- **Step ziehen:** Einen Step anklicken und an eine andere Position im selben Track ziehen — die Steps tauschen die Plätze.
- **⌥ + Drag (Option):** Kopiert den Step an die Zielposition, anstatt ihn zu verschieben.

---

## 13. MIDI Learn

Der MIDI-Learn-Modus ermöglicht das schnelle Zuweisen von Noten zu Steps direkt über ein MIDI-Keyboard.

**Ablauf:**
1. **LEARN-Button** im Transport-Bereich drücken (leuchtet auf).
2. Im gewünschten Track einen Step anklicken — dieser wird als Lernziel markiert.
3. Die gewünschte Note auf dem MIDI-Keyboard spielen — sie wird automatisch dem Step zugewiesen.
4. Ist für den Track ein Scale Filter aktiv, wird die eingespielte Note automatisch auf die nächstgelegene In-Scale-Note quantisiert.
5. Der Fokus springt automatisch zum nächsten Step im Track.
6. Weitere Noten spielen, bis die Sequenz komplett ist.
7. **LEARN-Button** erneut drücken oder **Escape** zum Beenden.

---

## 14. Transport und Tempo

### BPM-Steuerung
- **Knob ziehen:** Vertikal nach oben = schneller, nach unten = langsamer.
- **▲▼ Buttons:** Feinkorrektur um jeweils 0,5 BPM.
- **TAP Tempo:** Mehrfach tippen, der Sequencer berechnet das Durchschnittstempo.

### Swing
- 0 % = gerade (kein Swing)
- 100 % = maximaler Triplet-Swing
- Empfehlung für Funk/Hip-Hop: 60–65 %
- Empfehlung für Jazz: 65–75 %

---

## 15. Pattern-Verwaltung

- **4 Pattern-Speicher (A/B/C/D)** — vollständig unabhängige Sequenzen mit eigenen Tracks.
- **Umschalten:** Klick auf den Buchstaben oder ⌘A / ⌘B / ⌘C / ⌘D.
- **Kopieren:** ⌘⌥C kopiert das aktuelle Pattern.
- **Einfügen:** ⌘⌥V fügt es in das ausgewählte Pattern ein.
- **MIDI CC-Steuerung:** In den Einstellungen kann eine CC-Nummer für Pattern-Wechsel definiert werden — ideal für Live-Performances.

---

## 16. MIDI Clock-Modi

### INT (Intern)
- Der Steph Sequencer ist Master.
- Er sendet MIDI-Clock (24 PPQ) an alle verbundenen Geräte und die DAW.
- BPM wird im Sequencer eingestellt.

### EXT (Extern)
- Die DAW oder ein anderes Gerät ist Master.
- Der Steph Sequencer empfängt Clock und synchronisiert sich.
- Start/Stop der DAW steuert den Sequencer mit.
- Der BPM-Knob im Sequencer hat in diesem Modus keinen Effekt.

---

## 17. Datei-Verwaltung

### Preset speichern
- **Datei-Menü → Save Preset** (oder **⌘S**)
- Speichert alle vier Pattern mit allen Tracks und Steps als JSON-Datei.
- Scale-Filter-Einstellungen pro Track werden ebenfalls gespeichert.
- Die JSON-Datei kann geteilt, in Versionskontrolle gespeichert oder mit KI-Tools bearbeitet werden.

### Preset laden
- **Datei-Menü → Open Preset** (oder **⌘O**)
- Lädt eine JSON-Preset-Datei und ersetzt alle aktuellen Pattern inklusive Scale-Filter-Einstellungen.

### KI-generierte Presets
- Das JSON-Format ist einfach genug, dass KI-Assistenten (ChatGPT, Claude) direkt Presets erstellen können — z.B. "erstelle einen Acid-Bassline-Preset für Kanal 1 mit 16 Steps".

---

## 18. Einstellungen

Die Einstellungen sind über das Zahnrad-Symbol oder das App-Menü erreichbar.

- **MIDI-Ausgang wählen:** Welches virtuelle oder physische MIDI-Gerät der Sequencer ansteuert.
- **MIDI-Eingang wählen:** Für MIDI Clock (EXT) und MIDI Learn.
- **CC für Pattern-Wechsel:** Eine CC-Nummer definieren, mit der extern zwischen Pattern A–D geschaltet werden kann.
- **CC für Track-Mute:** Pro Track kann eine CC-Nummer für Remote-Muting vergeben werden.

---

## 19. Tastatur-Shortcuts

| Shortcut | Funktion |
|---|---|
| **Space** | Play / Stop |
| **⌘A** | Pattern A auswählen |
| **⌘B** | Pattern B auswählen |
| **⌘C** | Pattern C auswählen |
| **⌘D** | Pattern D auswählen |
| **⌘⌥C** | Aktuelles Pattern kopieren |
| **⌘⌥V** | Pattern einfügen |
| **⌘S** | Preset speichern |
| **⌘O** | Preset öffnen |
| **⌥1** | Track 1 muten / unmuten |
| **⌥2** | Track 2 muten / unmuten |
| **⌥3** | Track 3 muten / unmuten |
| **⌥4** | Track 4 muten / unmuten |
| **⌥ + Klick** | Step-Edit-Fenster öffnen |
| **⇧ + Klick** | Step zur Mehrfachauswahl hinzufügen |
| **Enter** | Step-Edit-Fenster schließen |

---

## 20. Tipps für Polyrhythmus

Der Steph Sequencer ist ein natürliches Werkzeug für Polyrhythmus, weil jeder Track völlig unabhängig ist.

**Beispiel 7:4:**
- Track 1 = 7 Steps (Basslinie)
- Track 2 = 4 Steps (Lead-Synth)
- Beide Tracks laufen gleichzeitig. Der Zyklus wiederholt sich erst nach 28 Steps (lcm von 7 und 4).

**Weitere Kombinationen:**
- 3:4 — klassischer Latin-Groove
- 5:4 — Prog-Rock-Feeling
- 7:8 — maximale rhythmische Spannung
- 16:12 — subtiler Swing durch ungleiche Schleifenlängen

**Tipp:** Alle Tracks auf dasselbe MIDI-Instrument routen und unterschiedliche Tonhöhen vergeben — so entsteht ein selbst-harmonisierender polyrhythmischer Arpeggiator.

---

## 21. Tipps für Probability und Ratchet

**Lebendige Hi-Hat:**
- Hi-Hat-Track auf 16 Steps, alle aktiv.
- Probability auf 75–80 %.
- Einzelne Steps mit ×2 Ratchet.
- Ergebnis: Keine zwei Durchläufe klingen gleich — organischer, gespielter Eindruck.

**Snare-Variation:**
- Snare auf Zählzeit 2 und 4, Probability 100 %.
- Zusätzliche "Ghost Notes" (sehr leise Snares, Velocity 20–40) auf anderen Steps mit Probability 40–60 %.
- Ergebnis: Der Groove atmet.

**Bassline mit Ratchet:**
- Step auf Zählzeit 1 mit ×4 Ratchet und kurzem Gate (15 %) — simuliert einen schnellen Bassriff-Auftakt.

---

## 22. Tipps für Drum-Tracks

1. Kanal 10 für den Track wählen — Drum-Modus aktiviert sich automatisch.
2. Im Step-Edit-Fenster Drum-Sound-Picker nutzen (Kick, Snare, HH Cls usw.).
3. Velocity variieren: Kick immer 100–110, HH zwischen 60–90 für natürliche Dynamik.
4. CC1 auf Filter-Cutoff (CC 74) legen — mit steigendem CC-Wert pro Step entsteht ein Filter-Sweep über den Beat.
5. Gate bei Kick und Snare ca. 80 %, bei HH ca. 30–50 % für kurze, perkussive Sounds.

---

## 23. Tipps für den Scale Filter

**Melodische Basslinien ohne Falschnoten:**
- Scale Filter auf A Minor setzen, dann im MIDI-Learn-Modus frei auf der Klaviatur spielen — alle Noten landen automatisch in der Tonart.

**Modale Färbung durch verschiedene Tracks:**
- Track 1 (Bassline) in A Minor, Track 2 (Lead) in A Dorian — die erhöhte Sexte im Dorian-Track erzeugt eine subtil andere Stimmung über derselben Grundharmonie.

**Blues-Rock-Groove:**
- Scale Filter auf E Blues — alle Steps bleiben automatisch in der Blues-Pentatonik. Ratchet ×2 auf betonten Zählzeiten für das typische Blues-Feeling.

**Exotische Skalen:**
- Whole Tone (Ganztonleiter) für schwebende, ambige Texturen — kein klares Dur oder Moll, typisch für impressionistische Klangwelten.

---

*Rohfassung v0.14 — zur Formatierung in Word (ChatGPT)*
