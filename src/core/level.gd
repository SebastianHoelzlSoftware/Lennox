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
	chunk.fill_tiles(get_tile_type_from_biome(biome_type))

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
	"""Generiert Barrieren für einen Chunk mittels Rectangle-Expansion (min_step = 2)."""
	var barriers := []
	var biome_params := _get_biome_params_for_chunk(p_x, p_y, p_biome)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([p_x, p_y, world_seed, "barrier-layout"])
	var num_barriers: int = biome_params["barrier_count"]
	
	var chunk_grid := []
	for cx in range(chunk_size):
		var col = []
		col.resize(chunk_size)
		col.fill(0)
		chunk_grid.append(col)
	
	var min_step := 2 # <--- Hier von 4 auf 2 geändert
	var spacing := 6  # <--- Mindestabstand angepasst (sollte Vielfaches von min_step sein)
	
	for i in range(num_barriers):
		var rects_in_barrier: Array[Rect2i] = []
		var success := false
		var base_rect: Rect2i
		
		# 1. Finde einen freien Startpunkt (auf 2er-Raster ausgerichtet)
		for attempt in range(15):
			var start_x = rng.randi_range(spacing, chunk_size - (min_step * 2) - spacing)
			start_x = (start_x / min_step) * min_step
			var start_y = rng.randi_range(spacing, chunk_size - (min_step * 2) - spacing)
			start_y = (start_y / min_step) * min_step
			
			base_rect = Rect2i(start_x, start_y, min_step * 2, min_step * 2) # Startet mit einem 4x4 oder 2x2 Basis-Rechteck
			
			if not _is_chunk_area_occupied_with_padding(chunk_grid, base_rect, spacing):
				success = true
				break
		
		if not success:
			continue
			
		var current_rect = base_rect
		rects_in_barrier.append(current_rect)
		_mark_chunk_area(chunk_grid, current_rect, 1)
		
		# 2. Expansions-Schritte (Wachsen in 2er-Schritten)
		var expansion_steps = rng.randi_range(4, 8) # Etwas mehr Schritte, da die Zuwächse kleiner sind
		var directions = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
		
		for step in range(expansion_steps):
			var source_rect = rects_in_barrier.pick_random()
			
			directions.shuffle()
			var dir = directions[0]
			var grow_amount = rng.randi_range(1, 3) * min_step # Wächst um 2, 4 oder 6 Tiles
			var candidate_rect: Rect2i
			
			if dir == Vector2i.RIGHT or dir == Vector2i.LEFT:
				var max_h_steps = max(1, source_rect.size.y / min_step)
				var sub_h_steps = rng.randi_range(1, max_h_steps)
				var sub_h = sub_h_steps * min_step
				
				var max_offset_steps = (source_rect.size.y - sub_h) / min_step
				var offset_steps = rng.randi_range(0, maxi(0, max_offset_steps))
				var offset_y = offset_steps * min_step
				
				if dir == Vector2i.RIGHT:
					candidate_rect = Rect2i(source_rect.end.x, source_rect.position.y + offset_y, grow_amount, sub_h)
				else:
					candidate_rect = Rect2i(source_rect.position.x - grow_amount, source_rect.position.y + offset_y, grow_amount, sub_h)
					
			else: # DOWN oder UP
				var max_w_steps = max(1, source_rect.size.x / min_step)
				var sub_w_steps = rng.randi_range(1, max_w_steps)
				var sub_w = sub_w_steps * min_step
				
				var max_offset_steps = (source_rect.size.x - sub_w) / min_step
				var offset_steps = rng.randi_range(0, maxi(0, max_offset_steps))
				var offset_x = offset_steps * min_step
				
				if dir == Vector2i.DOWN:
					candidate_rect = Rect2i(source_rect.position.x + offset_x, source_rect.end.y, sub_w, grow_amount)
				else:
					candidate_rect = Rect2i(source_rect.position.x + offset_x, source_rect.position.y - grow_amount, sub_w, grow_amount)
			
			if _is_valid_chunk_rect(candidate_rect, chunk_size) and not _is_chunk_area_occupied_strict(chunk_grid, candidate_rect, rects_in_barrier):
				rects_in_barrier.append(candidate_rect)
				_mark_chunk_area(chunk_grid, candidate_rect, 1)
		
		# 3. Umriss-Polygon extrahieren und Barriere erstellen...
		var polygon = _extract_polygon_from_rects(rects_in_barrier, chunk_size)
		if polygon.size() < 3:
			continue
			
		var barrier_openings: Array[Opening] = []
		var num_openings: int = biome_params["opening_count"]
		var opening_types: Array = biome_params["opening_types"]
		
		for j in range(num_openings):
			var opening_type: int = opening_types[rng.randi_range(0, opening_types.size() - 1)]
			var opening_width := _get_opening_width(opening_type, rng)
			var opening_pos: Variant = _find_opening_position(polygon, rng)
			if opening_pos == null:
				continue

			polygon = _place_opening_in_hull(polygon, opening_pos, opening_width)
			var opening := Opening.new(
				opening_type,
				opening_pos,
				opening_width,
				opening_type == Opening.OpeningType.DOOR,
				p_biome
			)
			barrier_openings.append(opening)
		
		var barrier := Barrier.new()
		barrier.polygon = polygon
		barrier.biome = p_biome
		for opening: Opening in barrier_openings:
			barrier.add_opening(opening)
		barriers.append(barrier)
	
	return barriers


func _is_chunk_area_occupied_with_padding(grid: Array, r: Rect2i, padding: int) -> bool:
	"""Prüft, ob ein Bereich inklusive eines Sicherheitsabstands belegt ist."""
	var padded_rect = Rect2i(r.position.x - padding, r.position.y - padding, r.size.x + (padding * 2), r.size.y + (padding * 2))
	for rx in range(padded_rect.position.x, padded_rect.end.x):
		for ry in range(padded_rect.position.y, padded_rect.end.y):
			if rx < 0 or ry < 0 or rx >= grid.size() or ry >= grid[0].size():
				return true
			if grid[rx][ry] == 1:
				return true
	return false

func _is_chunk_area_occupied_strict(grid: Array, candidate: Rect2i, own_rects: Array[Rect2i]) -> bool:
	"""Prüft, ob das Kandidaten-Rechteck mit einer *anderen* Barriere kollidiert."""
	for rx in range(candidate.position.x, candidate.end.x):
		for ry in range(candidate.position.y, candidate.end.y):
			if rx < 0 or ry < 0 or rx >= grid.size() or ry >= grid[0].size():
				return true
			# Wenn die Zelle belegt ist...
			if grid[rx][ry] == 1:
				# Prüfen, ob sie zu dieser *selben* Barriere gehört (dann ist es okay, da sie verschmelzen)
				var belongs_to_self := false
				for r in own_rects:
					if r.has_point(Vector2i(rx, ry)) or Vector2i(rx, ry) == r.end or (rx >= r.position.x and rx < r.end.x and ry >= r.position.y and ry < r.end.y):
						belongs_to_self = true
						break
				if not belongs_to_self:
					return true
	return false

func _mark_chunk_area(grid: Array, r: Rect2i, val: int) -> void:
	for rx in range(r.position.x, r.end.x):
		for ry in range(r.position.y, r.end.y):
			if rx >= 0 and rx < grid.size() and ry >= 0 and ry < grid[0].size():
				grid[rx][ry] = val


func _is_valid_chunk_rect(r: Rect2i, p_chunk_size: int) -> bool:
	return r.position.x >= 1 and r.position.y >= 1 and r.end.x < p_chunk_size - 1 and r.end.y < p_chunk_size - 1


func _is_chunk_area_occupied(grid: Array, r: Rect2i) -> bool:
	for rx in range(r.position.x, r.end.x):
		for ry in range(r.position.y, r.end.y):
			if rx < 0 or ry < 0 or rx >= grid.size() or ry >= grid[0].size():
				return true
			if grid[rx][ry] == 1:
				return true
	return false

func _extract_polygon_from_rects(rects: Array[Rect2i], p_chunk_size: int) -> Array[Vector2]:
	"""Verschmilzt die expandierten Rechtecke über Godots Geometry2D zu einem sauberen Polygon."""
	if rects.is_empty():
		return []
		
	# Starten mit dem ersten Rechteck als Basis-Polygon
	var base_r = rects[0]
	var current_poly = PackedVector2Array([
		Vector2(base_r.position.x, base_r.position.y),
		Vector2(base_r.end.x, base_r.position.y),
		Vector2(base_r.end.x, base_r.end.y),
		Vector2(base_r.position.x, base_r.end.y)
	])
	
	# Alle weiteren Rechtecke nacheinander per Geometry2D verschmelzen
	for i in range(1, rects.size()):
		var r = rects[i]
		var r_poly = PackedVector2Array([
			Vector2(r.position.x, r.position.y),
			Vector2(r.end.x, r.position.y),
			Vector2(r.end.x, r.end.y),
			Vector2(r.position.x, r.end.y)
		])
		
		var merged_results = Geometry2D.merge_polygons(current_poly, r_poly)
		if not merged_results.is_empty():
			# Nimm das größte bzw. hauptsächliche verschmolzene Polygon
			current_poly = merged_results[0]
			
	# Konvertiere das PackedVector2Array zurück in ein normales Array[Vector2] für deine Barrier-Klasse
	var polygon: Array[Vector2] = []
	for pt in current_poly:
		polygon.append(pt)
		
	return polygon
	

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


func _find_opening_position(p_hull: Array, p_rng: RandomNumberGenerator) -> Variant:
	"""Encuentra una posicion valida para una apertura en la barrera."""
	var valid_edges := _find_valid_edges(p_hull)
	
	if valid_edges.size() == 0:
		return null
	
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
