# level.gd
class_name Level

# Parametros del nivel
var width: int
var height: int
var chunk_size: int
var tile_size: int
var world_seed: int

# Chunks (array 2D)
var chunks: Array = []

func _init(p_width: int, p_height: int, p_chunk_size: int, p_tile_size: int, p_world_seed: int):
	width = p_width
	height = p_height
	chunk_size = p_chunk_size
	tile_size = p_tile_size
	world_seed = p_world_seed


func generate() -> void:
	"""Genera todos los chunks del nivel."""
	# Establecer semilla para determinismo
	seed_random(world_seed)

	for x in range(width):
		chunks.append([])
		for y in range(height):
			chunks[x].append(generate_chunk(x, y))


func generate_chunk(p_x: int, p_y: int) -> Chunk:
	"""Genera un solo chunk."""
	var chunk := Chunk.new(p_x, p_y)

	# Generar bioma para el chunk (simplificado para prototipo)
	chunk.biome = _get_biome_for_chunk(p_x, p_y)

	# Generar barreras para el chunk
	var barriers := generate_barriers_for_chunk(p_x, p_y, chunk.biome)
	for barrier in barriers:
		chunk.barriers.append(barrier)
	
	# Aplicar barreras a las baldosas
	chunk.apply_barriers_to_tiles()

	return chunk


func _get_biome_for_chunk(p_x: int, p_y: int) -> String:
	"""Devuelve un bioma para el chunk (simplificado para prototipo)."""
	# Deterministico basado en semilla + coordenadas
	var hash_val := hash([p_x, p_y, world_seed])
	var biome_index : int = abs(hash_val) % 5
	var biomes := ["Grassland", "Wood", "Rocks", "Water", "Sand"]
	return biomes[biome_index]


func get_chunk(p_x: int, p_y: int) -> Chunk:
	"""Devuelve el chunk en la posicion (x, y)."""
	if p_x >= 0 and p_x < width and p_y >= 0 and p_y < height:
		return chunks[p_x][p_y]
	return null


func hash(arr: Array) -> int:
	"""Funcion hash simple para determinismo."""
	var result := 0
	for item in arr:
		result = (result * 31 + item) % 2147483647
	return result


func seed_random(p_world_seed: int) -> void:
	randomize()
	seed(p_world_seed)


func generate_barriers_for_chunk(p_x: int, p_y: int, p_biome: String) -> Array:
	"""Genera barreras para un chunk basado en bioma y semilla."""
	var barriers := []
	
	# Establecer semilla para este chunk (deterministico)
	var chunk_seed := hash([p_x, p_y, world_seed, "barriers"])
	seed_random(chunk_seed)
	
	# Cantidad de barreras por bioma
	var num_barriers := _get_barrier_count_for_biome(p_biome)
	
	for i in range(num_barriers):
		# 1. Generar puntos aleatorios
		var points := _generate_random_points(p_biome, self.chunk_size)
		
		if points.size() < 3:
			continue
		
		# 2. Calcular Convex Hull
		var hull := _compute_convex_hull(points)
		
		if hull.size() < 3:
			continue
		
		# 3. Perturbacion para formas organicas
		hull = _perturb_hull(hull)
		
		# 4. Colocar aperturas
		var num_openings := _get_opening_count_for_biome(p_biome)
		
		for j in range(num_openings):
			var opening_type := _get_random_opening_type(p_biome)
			var opening_width := _get_opening_width(opening_type)
			var _is_interactive := opening_type == Opening.OpeningType.DOOR
			
			var opening_pos := _find_opening_position(hull)
			if opening_pos != null:
				hull = _place_opening_in_hull(hull, opening_pos, opening_width)
		
		# 5. Crear barrera
		var barrier := Barrier.new()
		barrier.polygon = hull
		barrier.biome = p_biome
		barriers.append(barrier)
	
	return barriers


func _get_barrier_count_for_biome(p_biome: String) -> int:
	"""Devuelve la cantidad de barreras para un bioma."""
	match p_biome:
		"Grassland": return randi_range(1, 2)
		"Wood": return randi_range(3, 5)
		"Rocks": return randi_range(5, 8)
		"Water": return randi_range(0, 1)
		"Sand": return randi_range(1, 2)
		_: return randi_range(1, 3)


func _get_opening_count_for_biome(p_biome: String) -> int:
	"""Devuelve la cantidad de aperturas por barrera para un bioma."""
	match p_biome:
		"Grassland": return randi_range(1, 3)
		"Wood": return randi_range(1, 2)
		"Rocks": return randi_range(0, 1)
		"Water": return 1
		"Sand": return randi_range(1, 3)
		_: return randi_range(1, 2)


func _get_random_opening_type(p_biome: String) -> int:
	"""Devuelve un tipo de apertura aleatorio para un bioma."""
	var opening_types := []
	
	match p_biome:
		"Grassland":
			opening_types = [Opening.OpeningType.FORD, Opening.OpeningType.FORD, 
						   Opening.OpeningType.PASS, Opening.OpeningType.PASS, 
						   Opening.OpeningType.STEPS]
		"Wood":
			opening_types = [Opening.OpeningType.PASS, Opening.OpeningType.PASS, 
						   Opening.OpeningType.PASS, Opening.OpeningType.FORD, 
						   Opening.OpeningType.DOOR]
		"Rocks":
			opening_types = [Opening.OpeningType.PASS, Opening.OpeningType.PASS, 
						   Opening.OpeningType.PASS, Opening.OpeningType.STEPS, 
						   Opening.OpeningType.STEPS]
		"Water":
			opening_types = [Opening.OpeningType.FORD]
		"Sand":
			opening_types = [Opening.OpeningType.PASS, Opening.OpeningType.PASS, 
						   Opening.OpeningType.PASS, Opening.OpeningType.PASS, 
						   Opening.OpeningType.FORD]
		_:
			opening_types = [Opening.OpeningType.PASS]
	
	return opening_types[randi() % opening_types.size()]


func _get_opening_width(p_opening_type: int) -> int:
	"""Devuelve el ancho de una apertura basado en el tipo."""
	match p_opening_type:
		Opening.OpeningType.STEPS: return randi_range(2, 3)
		Opening.OpeningType.DOOR: return 1
		Opening.OpeningType.FORD: return randi_range(2, 4)
		Opening.OpeningType.PASS: return randi_range(3, 5)
		_: return 1


func _generate_random_points(p_biome: String, p_chunk_size: int = 32) -> Array:
	"""Genera puntos aleatorios para la generacion de barreras."""
	var points := []
	var num_points := 0
	
	# Cantidad de puntos dependiente del bioma
	match p_biome:
		"Grassland": num_points = randi_range(5, 8)
		"Wood": num_points = randi_range(8, 12)
		"Rocks": num_points = randi_range(10, 15)
		"Water": num_points = randi_range(5, 10)
		"Sand": num_points = randi_range(5, 8)
		_: num_points = randi_range(5, 10)
	
	# Generar puntos en el area interior (no en el borde)
	var margin := 2
	
	for i in range(num_points):
		var x := randi_range(margin, p_chunk_size - margin - 1)
		var y := randi_range(margin, p_chunk_size - margin - 1)
		
		# Verificar distancia minima a otros puntos
		var valid := true
		for point in points:
			if point.distance_to(Vector2(x, y)) < 2:
				valid = false
				break
		
		if valid:
			points.append(Vector2(x, y))
	
	return points


func _compute_convex_hull(p_points: Array) -> Array:
	"""Calcula la envolvente convexa de un conjunto de puntos (Graham-Scan)."""
	if p_points.size() <= 2:
		return p_points.duplicate()
	
	# 1. Encuentra el punto con la coordenada y mas baja (y mas a la izquierda en caso de empate)
	var p0 = p_points[0]
	for point in p_points:
		if point.y < p0.y or (point.y == p0.y and point.x < p0.x):
			p0 = point
	
	# 2. Ordena puntos por angulo polar respecto a p0
	var sorted_points := []
	for point in p_points:
		if point != p0:
			sorted_points.append(point)
	
	sorted_points.sort_custom(func(a, b):
		var angle_a := atan2(a.y - p0.y, a.x - p0.x)
		var angle_b := atan2(b.y - p0.y, b.x - p0.x)
		if angle_a < angle_b:
			return true
		elif angle_a > angle_b:
			return false
		else:
			return a.distance_to(p0) < b.distance_to(p0)
	)
	
	# 3. Graham-Scan
	var hull := [p0, sorted_points[0], sorted_points[1]]
	
	for i in range(2, sorted_points.size()):
		var p = sorted_points[i]
		while hull.size() >= 2:
			var top = hull[-1]
			var next_to_top = hull[-2]
			
			# Calcula el angulo entre next_to_top -> top -> p
			var cross = (top.x - next_to_top.x) * (p.y - top.y) - (top.y - next_to_top.y) * (p.x - top.x)
			if cross > 0:
				break
			else:
				hull.pop_back()
		hull.append(p)
	
	return hull


func _perturb_hull(p_hull: Array, p_perturbation: int = 1) -> Array:
	"""Desplaza ligeramente los puntos de la envolvente convexa para formas mas organicas."""
	var perturbed_hull := []
	
	for point in p_hull:
		var x_offset := randi_range(-p_perturbation, p_perturbation)
		var y_offset := randi_range(-p_perturbation, p_perturbation)
		perturbed_hull.append(Vector2(point.x + x_offset, point.y + y_offset))
	
	return perturbed_hull


func _find_opening_position(p_hull: Array) -> Vector2:
	"""Encuentra una posicion valida para una apertura en la barrera."""
	var valid_edges := _find_valid_edges(p_hull)
	
	if valid_edges.size() == 0:
		return Vector2.ZERO
	
	# Seleccionar borde aleatorio
	var edge_idx := randi() % valid_edges.size()
	var edge = valid_edges[edge_idx]
	var p1 = edge[0]
	var p2 = edge[1]
	
	# Punto medio del borde
	return Vector2((p1.x + p2.x) / 2.0, (p1.y + p2.y) / 2.0)


func _find_valid_edges(p_hull: Array, p_chunk_size: int = 32) -> Array:
	"""Encuentra bordes validos para aperturas (que no esten en los limites del chunk)."""
	var valid_edges := []
	var n := p_hull.size()
	
	for i in range(n):
		var j := (i + 1) % n
		var edge := [p_hull[i], p_hull[j]]
		
		# Comprueba si el borde esta en un limite del chunk
		var is_at_border := false
		for point in edge:
			if point.x <= 0 or point.x >= p_chunk_size - 1 or point.y <= 0 or point.y >= p_chunk_size - 1:
				is_at_border = true
				break
		
		if not is_at_border:
			valid_edges.append(edge)
	
	return valid_edges


func _place_opening_in_hull(p_hull: Array, p_midpoint: Vector2, p_width: int) -> Array:
	"""Coloca una apertura en el casco eliminando puntos."""
	var new_hull := []
	
	for point in p_hull:
		# Comprueba si el punto esta cerca del punto medio
		var distance = point.distance_to(p_midpoint)
		if distance < p_width * 0.5 + 0.5:
			continue
		new_hull.append(point)
	
	# Si el casco es muy pequeño, devuelve el original
	if new_hull.size() < 3:
		return p_hull
	
	return new_hull
