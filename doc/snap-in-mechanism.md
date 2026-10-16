# Snap-In-Mechanismus für Lennox

## 📌 Status: **Geplant (LEN-4)** 📋

Der Snap-In-Mechanismus ist der **Kernmechanismus** für das Lernspiel Lennox. Er ermöglicht es Spielern, Buchstaben oder Silben durch Drag & Drop zu kombinieren, um Wörter zu bilden.

**Implementierungsstatus:**
- ⏳ Snap-In-Logik (Drag & Drop, Einrasten, Rücksetzen)
- ⏳ Silbenmodus (Puzzleteile = Silben statt Buchstaben)
- ⏳ Audiounterstützung (phonetisches Abspielen von Buchstaben/Silben)

---

## Übersicht

### Mechanismus
1. **Drag & Drop:** Spieler zieht Puzzleteile (Buchstaben oder Silben) auf freie Felder
2. **Snap-In:** Teile rasten ein, wenn sie an der richtigen Position sind
3. **Rücksetzen:** Falsch platzierte Teile kehren zum Start zurück
4. **Fertigstellung:** Bei korrekter Kombination wird das Wort/Silbenwort abgespielt

### Modi
| Modus | Puzzleteile | Beispiel | Zielgruppe |
|-------|-------------|----------|------------|
| **Buchstabenmodus** | Einzelne Buchstaben | M, A, M, A → MAMA | Anfänger |
| **Silbenmodus** | Silben | Ma, ma → Mama | Fortgeschrittene |

---

## Technische Anforderungen

### 1. Puzzleteil-Klasse

```gdscript
# puzzle_piece.gd
class_name PuzzlePiece

# Typ: Buchstabe oder Silbe
enum PieceType { LETTER, SYLLABLE }

var type: PieceType = PieceType.LETTER
var value: String = ""          # "A", "B", "Ma", "ma" etc.
var audio_path: String = ""    # Pfad zur Audiodatei
var is_snapped: bool = false    # Ist das Teil eingerastet?
var correct_position: Vector2   # Zielposition für Snap-In
var current_position: Vector2   # Aktuelle Position
var start_position: Vector2     # Startposition (für Rücksetzen)

# --- Methoden ---
func snap_in() -> void:
    """Rastet das Teil an der korrekten Position ein."""
    current_position = correct_position
    is_snapped = true
    play_audio()

func reset() -> void:
    """Setzt das Teil auf die Startposition zurück."""
    current_position = start_position
    is_snapped = false

func play_audio() -> void:
    """Spielt die Audiodatei ab."""
    if audio_path != "":
        var audio := load(audio_path)
        if audio:
            audio.play()
```

### 2. Snap-In-Logik

```gdscript
# snap_in_manager.gd
class_name SnapInManager

# Alle Puzzleteile
var puzzle_pieces: Array[PuzzlePiece] = []

# Zielwort (für Validierung)
var target_word: String = ""

# Aktuell platzierte Teile
var placed_pieces: Array[PuzzlePiece] = []

# --- Methoden ---
func check_snap(p_piece: PuzzlePiece, p_position: Vector2) -> bool:
    """Prüft, ob ein Puzzleteil an der Position einrasten soll."""
    # Prüfe, ob die Position der korrekten Position des Teils entspricht
    if p_position.distance_to(p_piece.correct_position) < SNAP_RADIUS:
        p_piece.snap_in()
        placed_pieces.append(p_piece)
        check_completion()
        return true
    return false

func check_completion() -> bool:
    """Prüft, ob alle Teile korrekt platziert sind."""
    if placed_pieces.size() == puzzle_pieces.size():
        # Alle Teile platziert - Wort ist fertig
        play_complete_audio()
        return true
    return false

func play_complete_audio() -> void:
    """Spielt das vollständige Wort ab."""
    # Kombiniere alle platzierten Teile
    var word := ""
    for piece in placed_pieces:
        word += piece.value
    
    # Spiele die Audiodatei für das vollständige Wort ab
    var audio_path := "res://audio/words/" + word.to_lower() + ".ogg"
    var audio := load(audio_path)
    if audio:
        audio.play()

func reset_all() -> void:
    """Setzt alle Puzzleteile zurück."""
    for piece in puzzle_pieces:
        piece.reset()
    placed_pieces.clear()
```

### 3. Silbenmodus

#### Silben-Generierung

```gdscript
# syllable_generator.gd
class_name SyllableGenerator

# Wörterbuch: Wort → Silben
var syllable_dictionary: Dictionary = {
    "Mama": ["Ma", "ma"],
    "Papa": ["Pa", "pa"],
    "Ball": ["Ba", "ll"],
    "Haus": ["Hau", "s"],
    "Baum": ["Bau", "m"],
    "Wasser": ["Was", "ser"],
    "Buch": ["Bu", "ch"],
    "Schule": ["Schu", "le"],
    "Apfel": ["Ap", "fel"],
    "Banane": ["Ba", "na", "ne"]
}

func get_syllables_for_word(p_word: String) -> Array:
    """Gibt die Silben für ein Wort zurück."""
    if syllable_dictionary.has(p_word):
        return syllable_dictionary[p_word]
    
    # Fallback: Zerlege das Wort in einzelne Buchstaben
    var syllables := []
    for i in range(p_word.length()):
        syllables.append(p_word[i])
    return syllables

func generate_puzzle_pieces(p_word: String, p_mode: int) -> Array[PuzzlePiece]:
    """Generiert Puzzleteile für ein Wort im angegebenen Modus.
    
    Args:
        p_word: Das Zielwort
        p_mode: PieceType.LETTER oder PieceType.SYLLABLE
    """
    var pieces := []
    var parts := []
    
    if p_mode == PieceType.SYLLABLE:
        parts = get_syllables_for_word(p_word)
    else:
        # Buchstabenmodus
        for i in range(p_word.length()):
            parts.append(p_word[i])
    
    # Erstelle Puzzleteile für jeden Teil
    var x_offset := 0
    for part in parts:
        var piece := PuzzlePiece.new()
        piece.type = p_mode
        piece.value = part
        piece.audio_path = "res://audio/" + ("syllables/" if p_mode == PieceType.SYLLABLE else "letters/") + part.to_lower() + ".ogg"
        piece.correct_position = Vector2(x_offset, 0)
        piece.start_position = Vector2(x_offset, -100)  # Oberhalb des Bildschirms
        piece.current_position = piece.start_position
        
        pieces.append(piece)
        x_offset += 50  # Abstand zwischen den Teilen
    
    return pieces
```

---

## Audiounterstützung

### Dateistruktur
```
res/
├── audio/
│   ├── letters/
│   │   ├── a.ogg
│   │   ├── b.ogg
│   │   ├── c.ogg
│   │   └── ...
│   ├── syllables/
│   │   ├── ma.ogg
│   │   ├── ba.ogg
│   │   ├── ll.ogg
│   │   └── ...
│   └── words/
│       ├── mama.ogg
│       ├── papa.ogg
│       ├── ball.ogg
│       └── ...
```

### Audio-Format
- **Format:** OGG Vorbis (komprimiert, gut für Mobile)
- **Sample Rate:** 44.1 kHz oder 48 kHz
- **Bitrate:** 128 kbps (ausreichend für Sprachaufnahmen)
- **Dauer:** 0.5–1.5 Sekunden pro Buchstabe/Silbe

### Audio-Aufnahme
- **Buchstaben:** Einzelne Buchstaben phonetisch (z. B. "A" wie in "Ameise")
- **Silben:** Natürlich ausgesprochen (z. B. "Ma" wie in "Mama")
- **Wörter:** Komplettes Wort (z. B. "Mama")

---

## Spiel-Integration

### Szene-Struktur
```
SnapInScene (Node2D)
├── PuzzlePiece_1 (PuzzlePiece)
├── PuzzlePiece_2 (PuzzlePiece)
├── PuzzlePiece_3 (PuzzlePiece)
├── ...
├── TargetSlots (Node2D)
│   ├── Slot_1 (Area2D)
│   ├── Slot_2 (Area2D)
│   └── ...
└── SnapInManager (SnapInManager)
```

### Input-Handling

```gdscript
# In der Hauptszene
func _input(event):
    if event is InputEventMouseButton and event.pressed:
        if event.button_index == MOUSE_BUTTON_LEFT:
            # Starte Drag
            var piece := get_piece_under_mouse()
            if piece:
                drag_start(piece, event.position)
    
    elif event is InputEventMouseButton and not event.pressed:
        if event.button_index == MOUSE_BUTTON_LEFT:
            # Beende Drag
            drag_end()
    
    elif event is InputEventMouseMotion and is_dragging:
        # Bewege das gezogene Teil
        drag_move(event.position)

func drag_start(p_piece: PuzzlePiece, p_position: Vector2) -> void:
    current_drag_piece = p_piece
    drag_offset = p_piece.current_position - p_position

func drag_move(p_position: Vector2) -> void:
    if current_drag_piece:
        current_drag_piece.current_position = p_position + drag_offset
        
        # Prüfe Snap-In
        snap_in_manager.check_snap(current_drag_piece, current_drag_piece.current_position)

func drag_end() -> void:
    if current_drag_piece:
        # Prüfe, ob das Teil nicht eingrastet ist
        if not current_drag_piece.is_snapped:
            current_drag_piece.reset()
        current_drag_piece = null
```

---

## Modus-Umschaltung

### UI-Element für Modus-Auswahl

```gdscript
# In den Einstellungen oder Level-Auswahl
var current_mode: int = PieceType.LETTER

func set_mode(p_mode: int) -> void:
    current_mode = p_mode
    # Aktualisiere UI
    update_mode_ui()
    # Lade neue Puzzles
    load_puzzles_for_mode()

func update_mode_ui() -> void:
    mode_button.text = "Modus: " + ("Buchstaben" if current_mode == PieceType.LETTER else "Silben")
```

---

## Fortgeschrittene Features

### 1. Visuelles Feedback
- **Einrasten:** Animation (z. B. kurzes Aufleuchten)
- **Falsche Platzierung:** Rotes Aufleuchten, dann Rücksetzen
- **Fertigstellung:** Konfetti-Effekt oder Sternchen

### 2. Schwierigkeitsgrade
| Level | Modus | Wortlänge | Silbenkomplexität |
|-------|-------|-----------|-------------------|
| 1–5   | Buchstaben | 3–4 | – |
| 6–10  | Buchstaben | 5–6 | – |
| 11–15 | Silben | 2–3 Silben | Einfache Silben (Ma, Pa) |
| 16–20 | Silben | 3–4 Silben | Komplexe Silben (Schu, ng) |

### 3. Highscore & Fortschritt
- **Punkte:** Pro korrekt gelöstem Wort
- **Zeitbonus:** Schnelleres Lösen gibt mehr Punkte
- **Fehlerzähler:** Zu viele Fehler reduzieren die Punkte

---

## Beispiele

### Beispiel 1: Buchstabenmodus
- **Wort:** "MAMA"
- **Puzzleteile:** ["M", "A", "M", "A"]
- **Zielpositionen:** [0, 50, 100, 150]
- **Audioreihenfolge:** "M" → "A" → "M" → "A" → "MAMA"

### Beispiel 2: Silbenmodus
- **Wort:** "MAMA"
- **Puzzleteile:** ["Ma", "ma"]
- **Zielpositionen:** [0, 100]
- **Audioreihenfolge:** "Ma" → "ma" → "Mama"

### Beispiel 3: Komplexes Wort
- **Wort:** "BANANE"
- **Silbenmodus:** ["Ba", "na", "ne"]
- **Buchstabenmodus:** ["B", "A", "N", "A", "N", "E"]

---

## Abhängigkeiten

- **Godot 4.x:** Für Node2D, Area2D, Input-Handling
- **Audio-Dateien:** Müssen erstellt/aufgenommen werden
- **Wörterbuch:** Für Silbenzerlegung (kann erweitert werden)

---

## Nächste Schritte

1. **PuzzlePiece-Klasse implementieren** (`src/core/puzzle_piece.gd`)
2. **SnapInManager implementieren** (`src/core/snap_in_manager.gd`)
3. **SyllableGenerator implementieren** (`src/core/syllable_generator.gd`)
4. **UI für Modus-Auswahl erstellen**
5. **Audio-Dateien erstellen/beschaffen**
6. **Tests schreiben** (`test/unit/test_snap_in.gd`)

---

## Links

- [Godot Input Handling](https://docs.godotengine.org/en/stable/tutorials/inputs/input_examples.html)
- [Godot Drag & Drop](https://docs.godotengine.org/en/stable/tutorials/ui/drag_and_drop.html)
- [Godot AudioStreamPlayer](https://docs.godotengine.org/en/stable/classes/class_audiostreamplayer.html)
