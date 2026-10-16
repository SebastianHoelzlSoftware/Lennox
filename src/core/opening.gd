# opening.gd
class_name Opening

# Öffnungstypen
enum OpeningType { TREPPE, TUER, FURT, PASS }

# Eigenschaften
var type: OpeningType = OpeningType.PASS
var position: Vector2 = Vector2.ZERO
var width: int = 1
var is_interactive: bool = false
var biome: String = ""

# --- Initialisierung ---
func _init(p_type: OpeningType, p_position: Vector2, p_width: int, p_is_interactive: bool = false, p_biome: String = ""):
    type = p_type
    position = p_position
    width = p_width
    is_interactive = p_is_interactive
    biome = p_biome

# --- Hilfsfunktionen ---
func get_type_name() -> String:
    """Gibt den Namen des Öffnungstyps zurück."""
    match type:
        OpeningType.TREPPE: return "Treppe"
        OpeningType.TUER: return "Tuer"
        OpeningType.FURT: return "Furt"
        OpeningType.PASS: return "Pass"
    return "Unknown"

func is_passable() -> bool:
    """Gibt zurück, ob die Öffnung passierbar ist."""
    return not is_interactive or is_interactive and is_open

# Für interaktive Öffnungen (z.B. Türen)
var is_open: bool = false

func open() -> void:
    """Öffnet die interaktive Öffnung."""
    if is_interactive:
        is_open = true

func close() -> void:
    """Schließt die interaktive Öffnung."""
    if is_interactive:
        is_open = false
