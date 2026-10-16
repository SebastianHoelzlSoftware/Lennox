# chunk.gd
class_name Chunk

var x: int
var y: int
var biome: String = "Grasland"
var tiles: Array = []
var barriers: Array = []

func _init(p_x: int, p_y: int):
	x = p_x
	y = p_y
	_init_tiles()

func _init_tiles():
	"""Initializes the 32x32 tile array with standard tiles"""
	tiles = []
	for i in range(32):
		tiles.append([])
		for j in range(32):
			tiles[i].append("Gras") # Standard Kachel

func add_barrier(polygon: Array) -> void:
	"""Fügt eine neue Barriere hinzu."""
	print("BARRIERS ADDED!")
	var barrier = Barrier.new()
	barrier.polygon = polygon
	barriers.append(barrier)

func set_tile(p_x: int, p_y: int, tile_type: String) -> void:
	"""Setzt eine Kachel an der Position (x, y)."""
	if p_x >= 0 and p_x < 32 and p_y >= 0 and p_y < 32:
		tiles[p_x][p_y] = tile_type

func get_tile(p_x: int, p_y: int) -> String:
	"""Gibt den Kachel-Typ an der Position (x, y) zurück."""
	if p_x >= 0 and p_x < 32 and p_y >= 0 and p_y < 32:
		return tiles[p_x][p_y]
	return ""

# --- Barrieren-Integration (LEN-5) ---

func apply_barriers_to_tiles() -> void:
	"""Wendet alle Barrieren auf die Kacheln an.
	
	Alle Kacheln innerhalb von Barrieren-Polygonen werden zu Barrieren-Kacheln.
	"""
	for barrier in barriers:
		_apply_barrier_to_tiles(barrier)


func _apply_barrier_to_tiles(p_barrier: Barrier) -> void:
	"""Wendet eine einzelne Barriere auf die Kacheln an."""
	var barrier_tile_type := _get_barrier_tile_type(p_barrier.biome)
	
	for _x in range(32):
		for _y in range(32):
			var point := Vector2(_x, _y)
			
			# Prüfe, ob der Punkt in der Barriere liegt
			if p_barrier.contains_point(point):
				# Setze die Kachel auf den Barrieren-Typ
				tiles[_x][_y] = barrier_tile_type


func _get_barrier_tile_type(p_biome: String) -> String:
	"""Gibt den Kachel-Typ für eine Barriere basierend auf dem Biom zurück."""
	match p_biome:
		"Fels": return "Fels"
		"Wald": return "Baum"
		"Wasser": return "Wasser"
		"Sand": return "Sand"
		_: return "Fels"  # Standard für Grasland und andere


func is_barrier(p_x: int, p_y: int) -> bool:
	"""Prüft, ob eine Kachel eine Barriere ist."""
	for barrier in barriers:
		if barrier.contains_point(Vector2(p_x, p_y)):
			return true
	return false


func get_barrier_at(p_x: int, p_y: int) -> Barrier:
	"""Gibt die Barriere an der Position (x, y) zurück oder null."""
	for barrier in barriers:
		if barrier.contains_point(Vector2(p_x, p_y)):
			return barrier
	return null