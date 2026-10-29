# level.gd
class_name Level
extends RefCounted

# Parametros del nivel
var width: int
var height: int
var chunk_size: int
var tile_size: int
var world_seed: int

# Chunks (array 2D) y mapa de biomas
var chunks: Array = []
var biome_map: Array = []


func _init(p_width: int, p_height: int, p_chunk_size: int, p_tile_size: int, p_world_seed: int):
	width = p_width
	height = p_height
	chunk_size = p_chunk_size
	tile_size = p_tile_size
	world_seed = p_world_seed


func generate() -> void:
	"""Genera todos los chunks del nivel mediante el generador organico de mundos de cuento de hadas."""
	chunks.clear()
	biome_map = BiomeGenerator.generate_biome_map(world_seed, width, height)

	for x in range(width):
		chunks.append([])
		for y in range(height):
			chunks[x].append(generate_chunk(x, y))


func generate_chunk(p_x: int, p_y: int) -> Chunk:
	"""Genera un chunk completo con terreno organico, barreras naturales y rica vegetacion/objetos."""
	var chunk := Chunk.new(p_x, p_y)

	var biome_type := _get_biome_for_chunk(p_x, p_y)
	chunk.biome = biome_type
	chunk.fill_tiles(get_tile_type_from_biome(biome_type))

	# Generar formaciones naturales organicas (mesas, crestas rocosas, islas)
	var barriers := generate_barriers_for_chunk(p_x, p_y, biome_type)
	for barrier in barriers:
		chunk.barriers.append(barrier)

	# Aplicar las formaciones al mapa de baldosas
	chunk.apply_barriers_to_tiles()

	# Poblar el chunk con densa decoracion ecologica (arboles, ruinas, flores, rocas)
	_populate_chunk_objects(chunk)

	return chunk


func _get_biome_for_chunk(p_x: int, p_y: int) -> BiomeType.Type:
	"""Devuelve el bioma de la tarjeta generada, o un fallback determinista."""
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
	"""Devuelve el chunk en la posicion (x, y)."""
	if p_x >= 0 and p_x < width and p_y >= 0 and p_y < height:
		return chunks[p_x][p_y]
	return null


func get_tile_type_from_biome(p_biome: BiomeType.Type) -> TileType.Type:
	"""Devuelve el tipo de baldosa base para un bioma."""
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
	"""Devuelve el tipo de baldosa para una barrera basado en el bioma."""
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
	"""Funcion hash determinista para arrays heterogeneos."""
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
	"""Genera formaciones naturales y organicas (mesas, riscos, arrecifes) con contornos suaves."""
	var barriers := []
	var biome_params := _get_biome_params_for_chunk(p_x, p_y, p_biome)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([p_x, p_y, world_seed, "natural-layout"])

	var num_formations: int = biome_params.get("barrier_count", 1)
	if num_formations <= 0:
		return barriers

	# Limitar a 1 o 2 formaciones principales majestuosas por chunk de 32x32 para que tengan escala natural
	var actual_formations := mini(num_formations, 2)
	var margin := 4

	for f_idx in range(actual_formations):
		# Centro de la formacion dentro del chunk
		var center_x := rng.randf_range(margin + 6, chunk_size - margin - 6)
		var center_y := rng.randf_range(margin + 6, chunk_size - margin - 6)
		var base_radius := rng.randf_range(4.5, 7.5)

		# Generar contorno organico mediante deformacion armonica radial
		var num_vertices := 12
		var polygon: Array[Vector2] = []
		var angle_step := (PI * 2.0) / float(num_vertices)

		# Frecuencias y fases armonicas para bordes naturalmente sinuosos
		var freq1 := float(rng.randi_range(2, 3))
		var phase1 := rng.randf_range(0.0, PI)
		var amp1 := rng.randf_range(0.8, 1.8)

		for i in range(num_vertices):
			var theta := float(i) * angle_step
			var r := base_radius + amp1 * sin(theta * freq1 + phase1)
			# Anadir perturbacion suave
			r += rng.randf_range(-0.5, 0.5)
			r = clampf(r, 3.0, 10.5)

			var px := clampf(center_x + r * cos(theta), 2.0, float(chunk_size - 3))
			var py := clampf(center_y + r * sin(theta), 2.0, float(chunk_size - 3))
			polygon.append(Vector2(px, py))

		if polygon.size() < 3:
			continue

		# Crear apertura / paso natural a traves de la formacion
		var barrier := Barrier.new()
		barrier.polygon = polygon
		barrier.biome = p_biome

		var opening_types: Array = biome_params.get("opening_types", [Opening.OpeningType.PASS])
		var op_type: int = opening_types[rng.randi_range(0, opening_types.size() - 1)]
		var op_width := _get_opening_width(op_type, rng)
		var op_pos := Vector2(center_x, center_y)

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


func _get_opening_width(p_opening_type: int, p_rng: RandomNumberGenerator) -> int:
	"""Devuelve el ancho de un paso natural basado en el tipo de apertura."""
	var width_range := BiomeConfig.get_opening_width_range(p_opening_type)
	return p_rng.randi_range(width_range.x, width_range.y)


func _populate_chunk_objects(chunk: Chunk) -> void:
	"""Puebla el chunk con objetos ecologicos (arboles, ruinas, flores, rocas) segun las reglas de cuento de hadas."""
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([chunk.x, chunk.y, world_seed, "chunk_objects"])

	# 1. Hito / Ruina antigua (probabilidad del 50% por chunk para dar identidad narrativa)
	if rng.randf() < 0.5:
		var ruin_x := rng.randi_range(6, chunk_size - 7)
		var ruin_y := rng.randi_range(6, chunk_size - 7)
		var ruin_path := ObjectCatalog.get_random_common_object("ruins", rng)
		if ruin_path != "":
			chunk.add_placed_object(ruin_path, Vector2i(ruin_x, ruin_y), "ruin")

	# 2. Arboledas y arboles (agrupados en bosquecillos naturales)
	var tree_clusters := rng.randi_range(1, 3)
	for c in range(tree_clusters):
		var cluster_x := rng.randi_range(4, chunk_size - 5)
		var cluster_y := rng.randi_range(4, chunk_size - 5)
		var trees_in_grove := rng.randi_range(2, 5)
		for t in range(trees_in_grove):
			var tx := clampi(cluster_x + rng.randi_range(-2, 2), 2, chunk_size - 3)
			var ty := clampi(cluster_y + rng.randi_range(-2, 2), 2, chunk_size - 3)
			var tree_path := ObjectCatalog.get_random_common_object("trees", rng)
			if tree_path != "":
				chunk.add_placed_object(tree_path, Vector2i(tx, ty), "tree")

	# 3. Arbustos y maleza
	var num_bushes := rng.randi_range(4, 8)
	for b in range(num_bushes):
		var bx := rng.randi_range(2, chunk_size - 3)
		var by := rng.randi_range(2, chunk_size - 3)
		var bush_path := ObjectCatalog.get_random_common_object("bushes", rng)
		if bush_path != "":
			chunk.add_placed_object(bush_path, Vector2i(bx, by), "bush")

	# 4. Objetos y detalles tematicos del bioma (flores, cristales, rocas, conchas, setas)
	var num_biome_items := rng.randi_range(8, 16)
	for i in range(num_biome_items):
		var ix := rng.randi_range(1, chunk_size - 2)
		var iy := rng.randi_range(1, chunk_size - 2)
		var item_path := ObjectCatalog.get_random_biome_object(chunk.biome, rng)
		if item_path != "":
			chunk.add_placed_object(item_path, Vector2i(ix, iy), "biome_detail")
