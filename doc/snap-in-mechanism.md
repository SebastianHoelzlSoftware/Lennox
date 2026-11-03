# Mecanismo de Encaje (Snap-In) para Lennox

## 📌 Estado: **Planificado (LEN-23 / LEN-27)** 📋

El mecanismo de encaje (*Snap-In*) es la **mecánica educativa central** del juego **Lennox**. Permite a los niños combinar letras o sílabas mediante arrastrar y soltar (*Drag & Drop*) para formar palabras asociadas a los iconos y encuentros con compañeros NPC (como la burbuja de diálogo con el corazón y la palabra `AMOR`).

**Estado de implementación:**
- ✅ Visualización de icono + bloques de letras de colores en la burbuja de diálogo NPC (`scenes/npc_dialog_bubble.gd`)
- ⏳ Lógica interactiva de *Snap-In* (arrastrar, encajar en la casilla correcta y reiniciar si no coincide)
- ⏳ Modo de sílabas (piezas de rompecabezas por sílabas además de letras individuales)
- ⏳ Soporte de audio fonético (reproducción de cada letra, sílaba y palabra completa en español e inglés)

---

## Descripción General

### Funcionamiento
1. **Arrastrar y soltar (*Drag & Drop*):** El jugador arrastra bloques de letras o sílabas hacia las casillas vacías de la palabra.
2. **Encaje (*Snap-In*):** La pieza encaja automáticamente cuando se acerca a su casilla correcta y reproduce su sonido fonético.
3. **Reinicio suave:** Si una pieza se suelta en una posición incorrecta, regresa suavemente a su posición inicial.
4. **Palabra completada:** Al encajar todas las piezas en orden, se reproduce el audio de la palabra completa y una animación de celebración.

### Modos de Aprendizaje
| Modo | Piezas del Rompecabezas | Ejemplo | Público Objetivo |
|-------|-------------|----------|------------|
| **Modo Letras** | Letras individuales | `A`, `M`, `O`, `R` → `AMOR` | Principiantes |
| **Modo Sílabas** | Sílabas | `MA`, `MA` → `MAMA` / `MAN`, `ZA`, `NA` → `MANZANA` | Intermedios / Avanzados |

---

## Diseño Técnico

### 1. Clase de Pieza (`PuzzlePiece`)

```gdscript
# puzzle_piece.gd
class_name PuzzlePiece

enum PieceType { LETTER, SYLLABLE }

var type: PieceType = PieceType.LETTER
var value: String = ""          # "A", "M", "MA", etc.
var audio_path: String = ""     # Ruta al archivo de audio fonético
var is_snapped: bool = false    # ¿Está encajada en su casilla?
var correct_position: Vector2   # Posición objetivo del slot
var current_position: Vector2   # Posición actual
var start_position: Vector2     # Posición inicial para reinicio

func snap_in() -> void:
	"""Encaja la pieza en la posición correcta y reproduce su sonido."""
	current_position = correct_position
	is_snapped = true
	play_audio()

func reset() -> void:
	"""Devuelve la pieza a su posición inicial."""
	current_position = start_position
	is_snapped = false

func play_audio() -> void:
	"""Reproduce el archivo de audio asociado a la letra o sílaba."""
	if audio_path != "":
		var audio := load(audio_path)
		if audio:
			audio.play()
```

### 2. Gestor de Encaje (`SnapInManager`)

```gdscript
# snap_in_manager.gd
class_name SnapInManager

const SNAP_RADIUS := 18.0

var puzzle_pieces: Array[PuzzlePiece] = []
var target_word: String = ""
var placed_pieces: Array[PuzzlePiece] = []

func check_snap(p_piece: PuzzlePiece, p_position: Vector2) -> bool:
	"""Verifica si una pieza debe encajar en su casilla objetivo."""
	if p_position.distance_to(p_piece.correct_position) < SNAP_RADIUS:
		p_piece.snap_in()
		placed_pieces.append(p_piece)
		check_completion()
		return true
	return false

func check_completion() -> bool:
	"""Comprueba si todas las piezas de la palabra han sido colocadas."""
	if placed_pieces.size() == puzzle_pieces.size():
		play_complete_audio()
		return true
	return false

func play_complete_audio() -> void:
	"""Reproduce el audio de la palabra completa."""
	var word := ""
	for piece in placed_pieces:
		word += piece.value
	var audio_path := "res://audio/words/" + word.to_lower() + ".ogg"
	var audio := load(audio_path)
	if audio:
		audio.play()

func reset_all() -> void:
	"""Reinicia todas las piezas del rompecabezas."""
	for piece in puzzle_pieces:
		piece.reset()
	placed_pieces.clear()
```

### 3. Generador de Sílabas (`SyllableGenerator`)

```gdscript
# syllable_generator.gd
class_name SyllableGenerator

var syllable_dictionary: Dictionary = {
	"AMOR": ["A", "MOR"],
	"MAMA": ["MA", "MA"],
	"PAPA": ["PA", "PA"],
	"CASA": ["CA", "SA"],
	"AGUA": ["A", "GUA"],
	"ARBOL": ["AR", "BOL"],
	"MANZANA": ["MAN", "ZA", "NA"],
}

func get_syllables_for_word(p_word: String) -> Array:
	var upper := p_word.to_upper()
	if syllable_dictionary.has(upper):
		return syllable_dictionary[upper]
	var syllables := []
	for i in range(upper.length()):
		syllables.append(upper[i])
	return syllables
```

---

## Soporte de Audio Bilingüe (Español e Inglés)

### Estructura de Archivos Propuesta
```
res://audio/
├── es/
│   ├── letters/    # a.ogg, b.ogg, c.ogg...
│   ├── syllables/  # ma.ogg, pa.ogg, man.ogg...
│   └── words/      # amor.ogg, manzana.ogg...
└── en/
    ├── letters/    # a.ogg, b.ogg, c.ogg...
    └── words/      # love.ogg, apple.ogg...
```

### Formato Recomendado
- **Formato:** OGG Vorbis (comprimido, ideal para dispositivos móviles)
- **Frecuencia de muestreo:** 44.1 kHz o 48 kHz
- **Duración:** 0.5–1.5 segundos por letra/sílaba

---

## Retroalimentación Visual y Niveles de Dificultad

| Nivel | Modo | Longitud de Palabra | Ejemplo |
|-------|------|---------------------|---------|
| **1–5** | Letras | 3–4 letras | `SOL`, `AMOR`, `LOVE` |
| **6–10** | Letras | 5–6 letras | `APPLE`, `ARBOL` |
| **11–15** | Sílabas | 2 sílabas | `MA-MA`, `CA-SA` |
| **16–20** | Sílabas | 3–4 sílabas | `MAN-ZA-NA` |

---

## Próximos Pasos

1. **Conectar `NpcDialogBubble`** con casillas interactivas para arrastrar letras hacia la palabra mostrada (`AMOR` / `LOVE`).
2. **Implementar `PuzzlePiece` y `SnapInManager`** en `src/core/` con pruebas unitarias en `test/unit/test_snap_in.gd`.
3. **Añadir pronunciación fonética** al tocar cada bloque de letra o completar la palabra.

---

## Enlaces de Referencia

- [Manejo de Entrada en Godot](https://docs.godotengine.org/es/stable/tutorials/inputs/input_examples.html)
- [Arrastrar y Soltar en Godot](https://docs.godotengine.org/es/stable/tutorials/ui/drag_and_drop.html)
- [AudioStreamPlayer en Godot](https://docs.godotengine.org/es/stable/classes/class_audiostreamplayer.html)
