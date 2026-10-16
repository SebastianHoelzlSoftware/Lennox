# opening.gd
class_name Opening

# Tipos de apertura
enum OpeningType { STEPS, DOOR, FORD, PASS }

# Propiedades
var type: OpeningType = OpeningType.PASS
var position: Vector2 = Vector2.ZERO
var width: int = 1
var is_interactive: bool = false
var biome: String = ""

func _init(p_type: OpeningType, p_position: Vector2, p_width: int, p_is_interactive: bool = false, p_biome: String = ""):
	type = p_type
	position = p_position
	width = p_width
	is_interactive = p_is_interactive
	biome = p_biome


func get_type_name() -> String:
	"""Devuelve el nombre del tipo de apertura."""
	match type:
		OpeningType.STEPS: return "Steps"
		OpeningType.DOOR: return "Door"
		OpeningType.FORD: return "Ford"
		OpeningType.PASS: return "Pass"
	return "Unknown"


func is_passable() -> bool:
	"""Devuelve si la apertura es transitable."""
	return not is_interactive or is_interactive and is_open


# Para aperturas interactivas (por ejemplo, puertas)
var is_open: bool = false


func open() -> void:
	"""Abre la apertura interactiva."""
	if is_interactive:
		is_open = true


func close() -> void:
	"""Cierra la apertura interactiva."""
	if is_interactive:
		is_open = false
