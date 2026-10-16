# chunk.gd
class_name Chunk

var x: int
var y: int
var biome: String = "Grassland"
var tiles: Array = []
var barriers: Array = []

func _init(p_x: int, p_y: int):
	x = p_x
	y = p_y
	_init_tiles()


func _init_tiles():
	"""Inicializa el array de baldosas de 32x32 con baldosas estandar."""
	tiles = []
	for i in range(32):
		tiles.append([])
		for j in range(32):
			tiles[i].append("Grass")


func add_barrier(polygon: Array) -> void:
	"""Agrega una nueva barrera."""
	var barrier = Barrier.new()
	barrier.polygon = polygon
	barriers.append(barrier)


func set_tile(p_x: int, p_y: int, tile_type: String) -> void:
	"""Establece una baldosa en la posicion (x, y)."""
	if p_x >= 0 and p_x < 32 and p_y >= 0 and p_y < 32:
		tiles[p_x][p_y] = tile_type


func get_tile(p_x: int, p_y: int) -> String:
	"""Devuelve el tipo de baldosa en la posicion (x, y)."""
	if p_x >= 0 and p_x < 32 and p_y >= 0 and p_y < 32:
		return tiles[p_x][p_y]
	return ""


func apply_barriers_to_tiles() -> void:
	"""Aplica todas las barreras a las baldosas.
	
	Todas las baldosas dentro de poligonos de barreras se convierten en baldosas de barrera.
	"""
	for barrier in barriers:
		_apply_barrier_to_tiles(barrier)


func _apply_barrier_to_tiles(p_barrier: Barrier) -> void:
	"""Aplica una sola barrera a las baldosas."""
	var barrier_tile_type := _get_barrier_tile_type(p_barrier.biome)
	
	for _x in range(32):
		for _y in range(32):
			var point := Vector2(_x, _y)
			
			# Comprueba si el punto esta en la barrera
			if p_barrier.contains_point(point):
				# Establece la baldosa al tipo de barrera
				tiles[_x][_y] = barrier_tile_type


func _get_barrier_tile_type(p_biome: String) -> String:
	"""Devuelve el tipo de baldosa para una barrera basado en el bioma."""
	match p_biome:
		"Rocks": return "Rock"
		"Wood": return "Tree"
		"Water": return "Water"
		"Sand": return "Sand"
		_: return "Rock"


func is_barrier(p_x: int, p_y: int) -> bool:
	"""Comprueba si una baldosa es una barrera."""
	for barrier in barriers:
		if barrier.contains_point(Vector2(p_x, p_y)):
			return true
	return false


func get_barrier_at(p_x: int, p_y: int) -> Barrier:
	"""Devuelve la barrera en la posicion (x, y) o null."""
	for barrier in barriers:
		if barrier.contains_point(Vector2(p_x, p_y)):
			return barrier
	return null
