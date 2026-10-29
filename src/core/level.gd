# level.gd
class_name Level
extends RefCounted

const CliffAutotiler = preload("res://src/core/cliff_autotiler.gd")
const ObjectCatalog = preload("res://src/core/object_catalog.gd")

var width: int
var height: int
var chunk_size: int
var tile_size: int
var world_seed: int

var chunks: Array = []
var biome_map: Array = []

var _global_plateau_cells: Dictionary = {}
var _elev_noise: FastNoiseLite = null
var _canyon_noise: FastNoiseLite = null
var _warp_noise: FastNoiseLite = null


func _init(p_width: int, p_height: int, p_chunk_size: int, p_tile_size: int, p_world_seed: int):
	width = p_width
	height = p_height
	chunk_size = p_chunk_size
	tile_size = p_tile_size
	world_seed = p_world_seed


func _init_noise() -> void:
	if _elev_noise != null:
		return

	# Ruido base de elevacion continental (FBM simplex suave)
	_elev_noise = FastNoiseLite.new()
	_elev_noise.seed = world_seed
	_elev_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_elev_noise.frequency = 0.038
	_elev_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	_elev_noise.fractal_octaves = 3
	_elev_noise.fractal_lacunarity = 2.0
	_elev_noise.fractal_gain = 0.5

	# Ruido de tallado de cañones y pasos de desfiladero
	_canyon_noise = FastNoiseLite.new()
	_canyon_noise.seed = (world_seed * 31 + 1013) % 2147483647
	_canyon_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_canyon_noise.frequency = 0.045
	_canyon_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	_canyon_noise.fractal_octaves = 2

	# Perturbacion de dominio para bordes organicos de cuento de hadas
	_warp_noise = FastNoiseLite.new()
	_warp_noise.seed = (world_seed * 17 + 2029) % 2147483647
	_warp_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_warp_noise.frequency = 0.07


func _get_plateau_threshold_for_biome(biome: BiomeType.Type) -> float:
	match biome:
		BiomeType.ROCKS: return 0.06
		BiomeType.CAVE: return 0.08
		BiomeType.DESERT: return 0.09
		BiomeType.FOREST: return 0.10
		BiomeType.GRASSLAND: return 0.11
		BiomeType.ROCKS_AND_WATER: return 0.12
		BiomeType.SWAMP: return 0.13
		BiomeType.SEABED: return 0.14
		_: return 0.10


func _eval_macro_cell_solid(world_mx: int, world_my: int) -> bool:
	var max_mx := width * 16
	var max_my := height * 16

	# Mantener borde exterior de 1 celda del mundo como valle abierto
	if world_mx <= 0 or world_mx >= max_mx - 1 or world_my <= 0 or world_my >= max_my - 1:
		return false

	_init_noise()

	# Perturbacion sutil para bordes sinuosos y naturales
	var warp_x: float = _warp_noise.get_noise_2d(float(world_mx), float(world_my)) * 2.2
	var warp_y: float = _warp_noise.get_noise_2d(float(world_mx) + 43.0, float(world_my) + 43.0) * 2.2

	var sample_x: float = float(world_mx) + warp_x
	var sample_y: float = float(world_my) + warp_y

	var elev: float = _elev_noise.get_noise_2d(sample_x, sample_y)
	var canyon: float = _canyon_noise.get_noise_2d(sample_x, sample_y)

	# Tallado de cañones: donde |canyon| es estrecho, se talla una garganta transitable
	if absf(canyon) < 0.085:
		return false

	var chunk_x := clampi(int(world_mx / 16), 0, maxi(width - 1, 0))
	var chunk_y := clampi(int(world_my / 16), 0, maxi(height - 1, 0))
	var biome := _get_biome_for_chunk(chunk_x, chunk_y)
	var threshold := _get_plateau_threshold_for_biome(biome)

	return elev > threshold


func is_macro_cell_solid(world_mx: int, world_my: int) -> bool:
	var key := Vector2i(world_mx, world_my)
	if _global_plateau_cells.has(key):
		return _global_plateau_cells[key]
	return _eval_macro_cell_solid(world_mx, world_my)


func generate() -> void:
	"""Genera el mundo continuo con biomas, mesetas chunkübergreifend y ecologia densa."""
	chunks.clear()
	_global_plateau_cells.clear()
	_init_noise()
	biome_map = BiomeGenerator.generate_biome_map(world_seed, width, height)

	# 1. Precalcular campo continuo global de mesetas a traves de todos los chunks
	var max_mx := width * 16
	var max_my := height * 16
	for gmx in range(max_mx):
		for gmy in range(max_my):
			var solid := _eval_macro_cell_solid(gmx, gmy)
			_global_plateau_cells[Vector2i(gmx, gmy)] = solid

	# 2. Pase de jugabilidad: Garantizar que ningun chunk sea 100% meseta para preservar valles
	for cx in range(width):
		for cy in range(height):
			var solid_count := 0
			for ly in range(16):
				for lx in range(16):
					if _global_plateau_cells.get(Vector2i(cx * 16 + lx, cy * 16 + ly), false):
						solid_count += 1
			# Si el chunk esta casi completamente cubierto (>190 de 256 celdas), abrir paso central
			if solid_count > 190:
				for ly in range(6, 11):
					for lx in range(6, 11):
						_global_plateau_cells[Vector2i(cx * 16 + lx, cy * 16 + ly)] = false

	# 3. Generar chunks
	for x in range(width):
		chunks.append([])
		for y in range(height):
			chunks[x].append(generate_chunk(x, y))


func generate_chunk(p_x: int, p_y: int) -> Chunk:
	"""Genera un chunk completo con terreno base, plataformas continuas segun el bioma y objetos."""
	var chunk := Chunk.new(p_x, p_y)

	var biome_type := _get_biome_for_chunk(p_x, p_y)
	chunk.biome = biome_type
	chunk.fill_tiles(get_tile_type_from_biome(biome_type))

	# 1. Generar formaciones y plataformas continuas chunkübergreifend
	var barriers := generate_barriers_for_chunk(p_x, p_y, biome_type)
	for barrier in barriers:
		chunk.barriers.append(barrier)

	# 2. Aplicar las barreras a las baldosas
	chunk.apply_barriers_to_tiles()

	# 3. Poblar el chunk con densa vegetacion, ruinas y detalles en mesetas y valles
	_populate_chunk_objects(chunk)

	return chunk


func _get_biome_for_chunk(p_x: int, p_y: int) -> BiomeType.Type:
	if p_x >= 0 and p_x < biome_map.size() and p_y >= 0 and p_y < biome_map[p_x].size():
		return biome_map[p_x][p_y]

	var hash_val := hash([p_x, p_y, world_seed])
	var biome_index : int = abs(hash_val) % 8
	match biome_index:
		0: return BiomeType.CAVE
		1: return BiomeType.DESERT
		2: return BiomeType.FOREST
		3: return BiomeType.GRASSLAND
		4: return BiomeType.ROCKS
		5: return BiomeType.ROCKS_AND_WATER
		6: return BiomeType.SWAMP
		7: return BiomeType.SEABED
		_: return BiomeType.GRASSLAND


func get_chunk(p_x: int, p_y: int) -> Chunk:
	if p_x >= 0 and p_x < width and p_y >= 0 and p_y < height:
		return chunks[p_x][p_y]
	return null


func get_tile_type_from_biome(p_biome: BiomeType.Type) -> TileType.Type:
	match p_biome:
		BiomeType.CAVE: return TileType.ROCK
		BiomeType.DESERT: return TileType.SAND
		BiomeType.FOREST: return TileType.GRASS
		BiomeType.GRASSLAND: return TileType.GRASS
		BiomeType.ROCKS: return TileType.ROCK
		BiomeType.ROCKS_AND_WATER: return TileType.WATER
		BiomeType.SWAMP: return TileType.WATER
		BiomeType.SEABED: return TileType.WATER
		_: return TileType.GRASS


func get_barrier_tile_type_from_biome(p_biome: BiomeType.Type) -> TileType.Type:
	match p_biome:
		BiomeType.CAVE: return TileType.ROCK
		BiomeType.DESERT: return TileType.SAND
		BiomeType.FOREST: return TileType.TREE
		BiomeType.GRASSLAND: return TileType.ROCK
		BiomeType.ROCKS: return TileType.ROCK
		BiomeType.ROCKS_AND_WATER: return TileType.ROCK
		BiomeType.SWAMP: return TileType.TREE
		BiomeType.SEABED: return TileType.ROCK
		_: return TileType.ROCK


func hash(arr: Array) -> int:
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
	"""Genera plataformas continuas que atraviesan las fronteras entre chunks."""
	var barriers := []
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([p_x, p_y, world_seed, "chunk_barriers"])

	# Recolectar macro-celdas de la plataforma en este chunk desde el campo continuo
	var local_cells: Array[Vector2i] = []
	for ly in range(16):
		for lx in range(16):
			var gmx := p_x * 16 + lx
			var gmy := p_y * 16 + ly
			if is_macro_cell_solid(gmx, gmy):
				local_cells.append(Vector2i(lx, ly))

	# Si el campo continuo no genero celdas en este chunk (o llamada directa en tests),
	# generar una meseta local escenica para dotar al chunk de verticalidad
	if local_cells.is_empty():
		var ox := rng.randi_range(3, 5)
		var oy := rng.randi_range(3, 5)
		var fw := rng.randi_range(5, 7)
		var fh := rng.randi_range(5, 7)
		for ly in range(oy, oy + fh):
			for lx in range(ox, ox + fw):
				var cell := Vector2i(lx, ly)
				local_cells.append(cell)
				_global_plateau_cells[Vector2i(p_x * 16 + lx, p_y * 16 + ly)] = true

	var barrier := Barrier.new()
	barrier.biome = p_biome
	barrier.cells = local_cells
	barrier.polygon = _build_polygon_for_cells(local_cells, rng)

	# Crear apertura / paso natural a traves de la plataforma
	var biome_params := _get_biome_params_for_chunk(p_x, p_y, p_biome)
	var opening_types: Array = biome_params.get("opening_types", [Opening.OpeningType.PASS])
	var op_type: int = opening_types[rng.randi_range(0, opening_types.size() - 1)]
	var op_width := _get_opening_width(op_type, rng)

	# Ubicar apertura en un punto seguro de paso dentro del poligono
	var raw_op_pos: Vector2 = barrier.polygon[rng.randi_range(0, barrier.polygon.size() - 1)]
	var op_pos := Vector2(
		clampf(raw_op_pos.x, 2.0, 29.0),
		clampf(raw_op_pos.y, 2.0, 29.0)
	)

	var opening := Opening.new(
		op_type,
		op_pos,
		op_width,
		op_type == Opening.OpeningType.DOOR,
		p_biome
	)
	barrier.add_opening(opening)
	barriers.append(barrier)

	return barriers


func _build_polygon_for_cells(cells: Array[Vector2i], _rng: RandomNumberGenerator) -> Array[Vector2]:
	"""Construye un poligono convexo cerrado alrededor de las celdas, estrictamente contenido en [1.0, 30.0]."""
	var points := PackedVector2Array()
	for cell in cells:
		var tx := float(cell.x * 2)
		var ty := float(cell.y * 2)
		points.append(Vector2(tx + 0.2, ty + 0.2))
		points.append(Vector2(tx + 1.8, ty + 0.2))
		points.append(Vector2(tx + 1.8, ty + 1.8))
		points.append(Vector2(tx + 0.2, ty + 1.8))

	var hull := Geometry2D.convex_hull(points)
	var polygon: Array[Vector2] = []
	for pt in hull:
		polygon.append(Vector2(
			clampf(pt.x, 1.0, 30.0),
			clampf(pt.y, 1.0, 30.0)
		))

	# Garantizar que tenga al menos 3 vertices cerrados
	if polygon.size() < 3:
		polygon = [
			Vector2(4.0, 4.0),
			Vector2(26.0, 4.0),
			Vector2(26.0, 26.0),
			Vector2(4.0, 26.0),
			Vector2(4.0, 4.0),
		]
	elif polygon[0].distance_to(polygon[-1]) > 0.001:
		polygon.append(polygon[0])

	return polygon


func _get_opening_width(p_opening_type: int, p_rng: RandomNumberGenerator) -> int:
	var width_range := BiomeConfig.get_opening_width_range(p_opening_type)
	return p_rng.randi_range(width_range.x, width_range.y)


func _populate_chunk_objects(chunk: Chunk) -> void:
	"""Puebla el chunk ricamente con ruinas en las cumbres y frondosa vegetacion en valles."""
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([chunk.x, chunk.y, world_seed, "chunk_objects"])

	# Determinar celdas ocupadas por mesetas para situar objetos tematicamente
	var plateau_cells: Dictionary = {}
	for barrier: Barrier in chunk.barriers:
		for cell: Vector2i in barrier.cells:
			plateau_cells[cell] = true

	# 1. Objetos sobre la meseta (Ruinas ancestrales, monolitos, gemas y cristales magicos)
	if not plateau_cells.is_empty():
		var cell_keys := plateau_cells.keys()

		# Colocar ruinas o santuarios en las cumbres
		var num_ruins := rng.randi_range(1, 2)
		for r_idx in range(num_ruins):
			var rand_macro: Vector2i = cell_keys[rng.randi_range(0, cell_keys.size() - 1)]
			var ruin_path := ObjectCatalog.get_random_common_object("ruins", rng)
			if ruin_path != "":
				chunk.add_placed_object(ruin_path, rand_macro * 2, "plateau_ruin")

		# Cristales y flora magica del bioma sobre la meseta
		var num_plateau_flora := rng.randi_range(4, 8)
		for i in range(num_plateau_flora):
			var rand_macro: Vector2i = cell_keys[rng.randi_range(0, cell_keys.size() - 1)]
			var item_path := ObjectCatalog.get_random_biome_object(chunk.biome, rng)
			if item_path != "":
				var sub_offset := Vector2i(rng.randi_range(0, 1), rng.randi_range(0, 1))
				chunk.add_placed_object(item_path, rand_macro * 2 + sub_offset, "plateau_flora")

	# 2. Objetos en el valle / piso inferior (arboles de cuento de hadas, arbustos, troncos y rocas)
	var num_valley_trees := rng.randi_range(5, 8)
	for i in range(num_valley_trees):
		var rx := rng.randi_range(1, chunk_size - 2)
		var ry := rng.randi_range(1, chunk_size - 2)
		var macro := Vector2i(int(rx / 2), int(ry / 2))
		if not plateau_cells.has(macro):
			var tree_path := ObjectCatalog.get_random_common_object("trees", rng)
			if tree_path != "":
				chunk.add_placed_object(tree_path, Vector2i(rx, ry), "valley_tree")

	var num_valley_bushes := rng.randi_range(6, 9)
	for i in range(num_valley_bushes):
		var rx := rng.randi_range(1, chunk_size - 2)
		var ry := rng.randi_range(1, chunk_size - 2)
		var macro := Vector2i(int(rx / 2), int(ry / 2))
		if not plateau_cells.has(macro):
			var bush_path := ObjectCatalog.get_random_common_object("bushes", rng)
			if bush_path != "":
				chunk.add_placed_object(bush_path, Vector2i(rx, ry), "valley_bush")

	var num_valley_specials := rng.randi_range(3, 5)
	for i in range(num_valley_specials):
		var rx := rng.randi_range(1, chunk_size - 2)
		var ry := rng.randi_range(1, chunk_size - 2)
		var macro := Vector2i(int(rx / 2), int(ry / 2))
		if not plateau_cells.has(macro):
			var item_path := ObjectCatalog.get_random_biome_object(chunk.biome, rng)
			if item_path != "":
				chunk.add_placed_object(item_path, Vector2i(rx, ry), "valley_flora")
