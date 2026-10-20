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
var biome_map: Array = []

func _init(p_width: int, p_height: int, p_chunk_size: int, p_tile_size: int, p_world_seed: int):
	width = p_width
	height = p_height
	chunk_size = p_chunk_size
	tile_size = p_tile_size
	world_seed = p_world_seed


func generate() -> void:
	"""Genera todos los chunks del nivel."""
	chunks.clear()
	biome_map = BiomeGenerator.generate_biome_map(world_seed, width, height)

	for x in range(width):
		chunks.append([])
		for y in range(height):
			chunks[x].append(generate_chunk(x, y))


func generate_chunk(p_x: int, p_y: int) -> Chunk:
	"""Genera un solo chunk."""
	var chunk := Chunk.new(p_x, p_y)

	# Generar bioma para el chunk (simplificado para prototipo)
	var biome_type := _get_biome_for_chunk(p_x, p_y)
	chunk.biome = biome_type

	# Generar barreras para el chunk
	var barriers := generate_barriers_for_chunk(p_x, p_y, biome_type)
	for barrier in barriers:
		chunk.barriers.append(barrier)
	
	# Aplicar barreras a las baldosas
	chunk.apply_barriers_to_tiles()

	return chunk


func _get_biome_for_chunk(p_x: int, p_y: int) -> BiomeType.Type:
	"""Devuelve el bioma de la tarjeta generada, o un fallback determinista."""
	if p_x >= 0 and p_x < biome_map.size() and p_y >= 0 and p_y < biome_map[p_x].size():
		return biome_map[p_x][p_y]

	# Deterministico basado en semilla + coordenadas
	var hash_val := hash([p_x, p_y, world_seed])
	var biome_index : int = abs(hash_val) % 5
	match biome_index:
		0: return BiomeType.GRASSLAND
		1: return BiomeType.WOOD
		2: return BiomeType.ROCKS
		3: return BiomeType.WATER
		4: return BiomeType.SAND
		_: return BiomeType.GRASSLAND


func get_chunk(p_x: int, p_y: int) -> Chunk:
	"""Devuelve el chunk en la posicion (x, y)."""
	if p_x >= 0 and p_x < width and p_y >= 0 and p_y < height:
		return chunks[p_x][p_y]
	return null


func get_tile_type_from_biome(p_biome: BiomeType.Type) -> TileType.Type:
	"""Devuelve el tipo de baldosa base para un bioma."""
	match p_biome:
		BiomeType.GRASSLAND: return TileType.GRASS
		BiomeType.WOOD: return TileType.GRASS
		BiomeType.ROCKS: return TileType.ROCK
		BiomeType.WATER: return TileType.WATER
		BiomeType.SAND: return TileType.SAND
		_: return TileType.GRASS


func get_barrier_tile_type_from_biome(p_biome: BiomeType.Type) -> TileType.Type:
	"""Devuelve el tipo de baldosa para una barrera basado en el bioma."""
	match p_biome:
		BiomeType.ROCKS: return TileType.ROCK
		BiomeType.WOOD: return TileType.TREE
		BiomeType.WATER: return TileType.WATER
		BiomeType.SAND: return TileType.SAND
		_: return TileType.ROCK


func hash(arr: Array) -> int:
	"""Funcion hash simple para determinismo."""
	var result := 0
	for item in arr:
		var item_hash := int(item) if typeof(item) != TYPE_STRING else String(item).hash()
		result = (result * 31 + item_hash) % 2147483647
	return result


func _get_biome_params_for_chunk(p_x: int, p_y: int, p_biome: BiomeType.Type) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([p_x, p_y, world_seed, "barriers"])
	return BiomeGenerator.get_biome_params(p_biome, rng)


func generate_barriers_for_chunk(p_x: int, p_y: int, p_biome: BiomeType.Type) -> Array:
	"""Genera barreras reproducibles para un chunk según su bioma y sus coordenadas."""
	var barriers := []
	
	# Los parámetros y la distribución usan secuencias distintas, pero ambas dependen
	# de las coordenadas y de la semilla del mundo: regenerar el chunk da el mismo resultado.
	var biome_params := _get_biome_params_for_chunk(p_x, p_y, p_biome)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([p_x, p_y, world_seed, "barrier-layout"])
	var num_barriers: int = biome_params["barrier_count"]
	
	# Cada barrera se construye a partir de puntos aleatorios y su envolvente convexa.
	for i in range(num_barriers):
		var hull := []
		# Puede que los puntos no formen una envolvente válida; se vuelve a intentar
		# hasta diez veces antes de recurrir a una forma triangular mínima.
		for attempt in range(10):
			var points := _generate_random_points(
				p_biome,
				chunk_size,
				int(biome_params["barrier_size"]),
				rng
			)
			if points.size() >= 3:
				hull = _compute_convex_hull(points)
				if hull.size() >= 3:
					break

		if hull.size() < 3:
			# Evita descartar la barrera si los intentos aleatorios no dieron una forma válida.
			var fallback_center := Vector2(
				rng.randi_range(3, chunk_size - 4),
				rng.randi_range(3, chunk_size - 4)
			)
			hull = _compute_convex_hull([
				fallback_center + Vector2(-1, -1),
				fallback_center + Vector2(1, -1),
				fallback_center + Vector2(0, 1)
			])

		# Desplaza ligeramente los vértices para evitar formas demasiado geométricas.
		hull = _perturb_hull(hull, 1, rng)
		
		# El bioma determina cuántas aperturas se intentan y qué tipos pueden aparecer.
		var num_openings: int = biome_params["opening_count"]
		var opening_types: Array = biome_params["opening_types"]
		
		for j in range(num_openings):
			# Elige el tipo y el ancho de la apertura, busca un punto de inserción
			# en la envolvente y modifica el polígono para representar el paso.
			var opening_type: int = opening_types[rng.randi_range(0, opening_types.size() - 1)]
			var opening_width := _get_opening_width(opening_type, rng)
			
			var opening_pos := _find_opening_position(hull, rng)
			if opening_pos != null:
				hull = _place_opening_in_hull(hull, opening_pos, opening_width)
		
		# Guarda el polígono final junto con su bioma para que el chunk pueda aplicarlo.
		var barrier := Barrier.new()
		barrier.polygon = hull
		barrier.biome = p_biome
		barriers.append(barrier)
	
	return barriers


func _get_opening_width(p_opening_type: int, p_rng: RandomNumberGenerator) -> int:
	"""Devuelve el ancho de una apertura basado en el tipo."""
	var width_range := BiomeConfig.get_opening_width_range(p_opening_type)
	return p_rng.randi_range(width_range.x, width_range.y)


func _generate_random_points(
	p_biome: BiomeType.Type,
	p_chunk_size: int,
	p_barrier_size: int,
	p_rng: RandomNumberGenerator
) -> Array:
	"""Genera puntos aleatorios para la generacion de barreras."""
	var points := []
	var point_count_range: Vector2i = BiomeConfig.get_biome_profile(p_biome)["point_count"]
	var num_points := p_rng.randi_range(point_count_range.x, point_count_range.y)
	
	# Generar puntos en el area interior (no en el borde)
	var margin := 2
	var radius := maxi(2, int(p_barrier_size / 2.0))
	var center_x := p_rng.randi_range(margin, p_chunk_size - margin - 1)
	var center_y := p_rng.randi_range(margin, p_chunk_size - margin - 1)
	
	for i in range(num_points):
		var x := p_rng.randi_range(maxi(margin, center_x - radius), mini(p_chunk_size - margin - 1, center_x + radius))
		var y := p_rng.randi_range(maxi(margin, center_y - radius), mini(p_chunk_size - margin - 1, center_y + radius))
		
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


func _perturb_hull(
	p_hull: Array,
	p_perturbation: int = 1,
	p_rng: RandomNumberGenerator = null
) -> Array:
	"""Desplaza ligeramente los puntos de la envolvente convexa para formas mas organicas."""
	var rng := p_rng
	if rng == null:
		rng = RandomNumberGenerator.new()
		rng.randomize()

	var perturbed_hull := []
	
	for point in p_hull:
		var x_offset := rng.randi_range(-p_perturbation, p_perturbation)
		var y_offset := rng.randi_range(-p_perturbation, p_perturbation)
		perturbed_hull.append(Vector2(point.x + x_offset, point.y + y_offset))
	
	return perturbed_hull


func _find_opening_position(p_hull: Array, p_rng: RandomNumberGenerator) -> Vector2:
	"""Encuentra una posicion valida para una apertura en la barrera."""
	var valid_edges := _find_valid_edges(p_hull)
	
	if valid_edges.size() == 0:
		return Vector2.ZERO
	
	# Seleccionar borde aleatorio
	var edge_idx := p_rng.randi_range(0, valid_edges.size() - 1)
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
