# barrier.gd
class_name Barrier

# Polygon (lista de puntos)
var polygon: Array = []

# Bioma de la barrera (usa BiomeType enum)
var biome: BiomeType.Type = BiomeType.GRASSLAND

# Aperturas en esta barrera
var openings: Array = []


func is_polygon_closed() -> bool:
	"""Comprueba si el poligono esta cerrado (primer punto = ultimo punto)."""
	if polygon.size() < 3:
		return false
	var first_point: Vector2 = polygon[0]
	var last_point: Vector2 = polygon[-1]
	return first_point.distance_to(last_point) < 0.001


func add_opening(p_opening: Opening) -> void:
	"""Agrega una apertura a la barrera."""
	openings.append(p_opening)


func has_interactive_openings() -> bool:
	"""Comprueba si la barrera tiene aperturas interactivas."""
	for opening_item in openings:
		var opening: Opening = opening_item
		if opening.is_interactive:
			return true
	return false


func get_passable_points(chunk_size: int = 32) -> Array[Vector2]:
	"""Devuelve todos los puntos transitables de la barrera (aperturas)."""
	var passable_points: Array[Vector2] = []
	
	for opening_item in openings:
		var opening: Opening = opening_item
		if opening.is_passable():
			var start_x := int(opening.position.x - opening.width / 2.0)
			var end_x := int(opening.position.x + opening.width / 2.0)
			var y := int(opening.position.y)
			
			for x in range(start_x, end_x + 1):
				if x >= 0 and x < chunk_size and y >= 0 and y < chunk_size:
					passable_points.append(Vector2(x, y))
	
	return passable_points


func contains_point(p_point: Vector2) -> bool:
	"""Comprueba si un punto esta dentro del poligono (Ray-Casting).
	
	Tambien considera aperturas - los puntos en aperturas NO se consideran dentro de la barrera.
	"""
	# Primero comprueba si el punto esta en una apertura
	for opening_item in openings:
		var opening: Opening = opening_item
		if opening.is_passable():
			var start_x := int(opening.position.x - opening.width / 2.0)
			var end_x := int(opening.position.x + opening.width / 2.0)
			var y := int(opening.position.y)
			
			if p_point.x >= start_x and p_point.x <= end_x and p_point.y >= y - 0.5 and p_point.y <= y + 0.5:
				return false
	
	# Algoritmo estandar de Ray-Casting
	var inside := false
	var n := polygon.size()

	for i in range(n):
		var j := (i + 1) % n
		var point_i: Vector2 = polygon[i]
		var point_j: Vector2 = polygon[j]
		var xi := point_i.x
		var yi := point_i.y
		var xj := point_j.x
		var yj := point_j.y

		# Comprueba si el rayo (desde el punto hacia la derecha) intersecta el borde
		var intersect := ((yi > p_point.y) != (yj > p_point.y)) and \
			(p_point.x < (xj - xi) * (p_point.y - yi) / (yj - yi) + xi)
		if intersect:
			inside = not inside

	return inside
