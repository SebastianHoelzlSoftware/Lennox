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


func _init(p_width: int, p_height: int, p_chunk_size: int, p_tile_size: int, p_world_seed: int):
	width = p_width
	height = p_height
	chunk_size = p_chunk_size
	tile_size = p_tile_size
	world_seed = p_world_seed


func generate() -> void:
	"""Genera el mundo continuo con biomas, plataformas irregulares y ecologia densa."""
	chunks.clear()
	biome_map = BiomeGenerator.generate_biome_map(world_seed, width, height)

	for x in range(width):
		chunks.append([])
		for y in range(height):
			chunks[x].append(generate_chunk(x, y))


func generate_chunk(p_x: int, p_y: int) -> Chunk:
	"""Genera un chunk completo con terreno base, plataformas irregulares segun el bioma y objetos."""
	var chunk := Chunk.new(p_x, p_y)

	var biome_type := _get_biome_for_chunk(p_x, p_y)
	chunk.biome = biome_type
	chunk.fill_tiles(get_tile_type_from_biome(biome_type))

	# 1. Generar formaciones y plataformas irregulares dependientes del bioma
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
	"""Genera plataformas y barreras irregulares y organicas con gran variedad segun el bioma."""
	var barriers := []
	var biome_params := _get_biome_params_for_chunk(p_x, p_y, p_biome)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([p_x, p_y, world_seed, "irregular_platforms"])

	# Cada bioma genera su arquetipo caracteristico de formacion
	var formation_data: Dictionary
	match p_biome:
		BiomeType.ROCKS, BiomeType.CAVE:
			# Arquetipo 1: Cañon con puente/paso vertical y foso central (como en el screenshot)
			formation_data = _generate_canyon_platform(rng)
		BiomeType.DESERT, BiomeType.GRASSLAND:
			# Arquetipo 2: Mesas escalonadas con espolones redondeados y terrazas
			formation_data = _generate_stepped_mesa_platform(rng)
		BiomeType.FOREST:
			# Arquetipo 3: Cresta montañosa serpenteante con arboledas sagradas
			formation_data = _generate_ridge_platform(rng)
		BiomeType.ROCKS_AND_WATER, BiomeType.SEABED, BiomeType.SWAMP:
			# Arquetipo 4: Atolones y archipielagos con bahia/laguna interior
			formation_data = _generate_atoll_platform(rng)
		_:
			formation_data = _generate_canyon_platform(rng)

	var cells: Array[Vector2i] = formation_data.get("cells", [])
	var polygon: Array[Vector2] = formation_data.get("polygon", [])

	if cells.is_empty() or polygon.size() < 3:
		return barriers

	# Asegurar que todos los vertices del poligono esten estrictamente dentro del chunk [1.0, 30.0]
	for idx in range(polygon.size()):
		polygon[idx] = Vector2(
			clampf(polygon[idx].x, 1.0, 30.0),
			clampf(polygon[idx].y, 1.0, 30.0)
		)

	var barrier := Barrier.new()
	barrier.polygon = polygon
	barrier.biome = p_biome
	barrier.cells = cells

	# Crear apertura / paso natural a traves de la plataforma
	var opening_types: Array = biome_params.get("opening_types", [Opening.OpeningType.PASS])
	var op_type: int = opening_types[rng.randi_range(0, opening_types.size() - 1)]
	var op_width := _get_opening_width(op_type, rng)
	var raw_op_pos: Vector2 = formation_data.get("opening_pos", Vector2(16.0, 16.0))
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


func _generate_canyon_platform(rng: RandomNumberGenerator) -> Dictionary:
	"""Genera una plataforma como la del screenshot: meseta norte, puente vertical, dos alas sur y cañon central."""
	var cells: Array[Vector2i] = []
	var cell_set: Dictionary = {}

	# Desplazamiento sutil dentro del chunk (en macro-celdas de 2x2)
	var ox := rng.randi_range(1, 2)
	var oy := rng.randi_range(1, 2)

	# 1. Meseta Norte Principal (ancho: 11-13 macro-celdas, alto: 3-4)
	var north_w := rng.randi_range(10, 12)
	var north_h := 3
	for cx in range(ox, ox + north_w):
		for cy in range(oy, oy + north_h):
			var cell := Vector2i(cx, cy)
			cells.append(cell)
			cell_set[cell] = true

	# 2. Steg / Puente vertical que conecta hacia el sur (ancho: 2 macro-celdas = 4 baldosas)
	var bridge_x := ox + rng.randi_range(2, 4)
	var bridge_h := rng.randi_range(4, 5)
	for cx in range(bridge_x, bridge_x + 2):
		for cy in range(oy + north_h, oy + north_h + bridge_h):
			var cell := Vector2i(cx, cy)
			if not cell_set.has(cell):
				cells.append(cell)
				cell_set[cell] = true

	# 3. Ala Suroeste (ancho: 4-5, alto: 3-4)
	var sw_y := oy + north_h + bridge_h - 1
	var sw_w := rng.randi_range(4, 5)
	for cx in range(ox, ox + sw_w):
		for cy in range(sw_y, sw_y + 3):
			var cell := Vector2i(cx, cy)
			if not cell_set.has(cell):
				cells.append(cell)
				cell_set[cell] = true

	# 4. Ala Sureste (ancho: 4-5, alto: 3-4) dejando el cañon en medio
	var se_x := ox + north_w - rng.randi_range(4, 5)
	for cx in range(se_x, ox + north_w):
		for cy in range(sw_y, sw_y + 3):
			var cell := Vector2i(cx, cy)
			if not cell_set.has(cell):
				cells.append(cell)
				cell_set[cell] = true

	# 5. Pasarela o ala diagonal hacia el este
	var east_bridge_x := ox + north_w - 2
	for cy in range(oy + north_h, sw_y + 1):
		for cx in range(east_bridge_x, east_bridge_x + 2):
			var cell := Vector2i(cx, cy)
			if not cell_set.has(cell):
				cells.append(cell)
				cell_set[cell] = true

	# Construir poligono delimitador para calculo de colisiones y pruebas
	var polygon: Array[Vector2] = [
		Vector2(float(ox * 2), float(oy * 2)),
		Vector2(float((ox + north_w) * 2), float(oy * 2)),
		Vector2(float((ox + north_w) * 2), float((sw_y + 3) * 2)),
		Vector2(float(se_x * 2), float((sw_y + 3) * 2)),
		Vector2(float(se_x * 2), float(sw_y * 2)),
		Vector2(float((bridge_x + 2) * 2), float(sw_y * 2)),
		Vector2(float((bridge_x + 2) * 2), float((sw_y + 3) * 2)),
		Vector2(float(ox * 2), float((sw_y + 3) * 2)),
	]

	var opening_pos := Vector2(float(bridge_x * 2 + 2), float((oy + north_h + 2) * 2))
	return {"cells": cells, "polygon": polygon, "opening_pos": opening_pos}


func _generate_stepped_mesa_platform(rng: RandomNumberGenerator) -> Dictionary:
	"""Genera una gran mesa escalonada con terrazas y espolones para desierto y pradera."""
	var cells: Array[Vector2i] = []
	var cell_set: Dictionary = {}

	var ox := rng.randi_range(2, 3)
	var oy := rng.randi_range(2, 3)
	var w := rng.randi_range(9, 11)
	var h := rng.randi_range(7, 9)

	# Cuerpo principal con esquinas suavemente recortadas
	for cx in range(ox, ox + w):
		for cy in range(oy, oy + h):
			# Recortar esquinas para contorno organico
			if (cx == ox and cy == oy) or (cx == ox + w - 1 and cy == oy):
				continue
			if (cx == ox and cy == oy + h - 1) or (cx == ox + w - 1 and cy == oy + h - 1):
				continue
			var cell := Vector2i(cx, cy)
			cells.append(cell)
			cell_set[cell] = true

	# Terraza o espolon saliente al este
	var spur_y := oy + 2
	for cx in range(ox + w, mini(15, ox + w + 3)):
		for cy in range(spur_y, spur_y + 3):
			var cell := Vector2i(cx, cy)
			cells.append(cell)
			cell_set[cell] = true

	var polygon: Array[Vector2] = [
		Vector2(float(ox * 2 + 1), float(oy * 2)),
		Vector2(float((ox + w - 1) * 2), float(oy * 2)),
		Vector2(float((ox + w) * 2), float((oy + 2) * 2)),
		Vector2(float((ox + w + 2) * 2), float((oy + 2) * 2)),
		Vector2(float((ox + w + 2) * 2), float((oy + 5) * 2)),
		Vector2(float((ox + w) * 2), float((oy + 5) * 2)),
		Vector2(float((ox + w - 1) * 2), float((oy + h) * 2)),
		Vector2(float(ox * 2 + 1), float((oy + h) * 2)),
		Vector2(float(ox * 2), float((oy + h - 1) * 2)),
		Vector2(float(ox * 2), float((oy + 1) * 2)),
	]

	var opening_pos := Vector2(float((ox + 4) * 2), float((oy + 2) * 2))
	return {"cells": cells, "polygon": polygon, "opening_pos": opening_pos}


func _generate_ridge_platform(rng: RandomNumberGenerator) -> Dictionary:
	"""Genera una cresta o espina dorsal montañosa curvada que serpentea por el chunk."""
	var cells: Array[Vector2i] = []
	var cell_set: Dictionary = {}

	var start_x := rng.randi_range(2, 4)
	var cur_x := start_x
	for cy in range(2, 14):
		# Serpenteo suave
		cur_x = clampi(cur_x + rng.randi_range(-1, 1), 2, 11)
		# Ancho de la cresta: 3 macro-celdas = 6 baldosas
		for cx in range(cur_x, cur_x + 3):
			var cell := Vector2i(cx, cy)
			if not cell_set.has(cell):
				cells.append(cell)
				cell_set[cell] = true

	var polygon: Array[Vector2] = [
		Vector2(float(start_x * 2), 4.0),
		Vector2(float((start_x + 3) * 2), 4.0),
		Vector2(float((cur_x + 3) * 2), 26.0),
		Vector2(float(cur_x * 2), 26.0),
	]

	var opening_pos := Vector2(float((start_x + 1) * 2), 16.0)
	return {"cells": cells, "polygon": polygon, "opening_pos": opening_pos}


func _generate_atoll_platform(rng: RandomNumberGenerator) -> Dictionary:
	"""Genera un atolón o arrecife anular con una laguna / cuenca central (ideal para agua y ciénaga)."""
	var cells: Array[Vector2i] = []
	var center_x := rng.randi_range(6, 9)
	var center_y := rng.randi_range(6, 9)
	var outer_r := rng.randi_range(4, 5)
	var inner_r := 2

	for cx in range(center_x - outer_r, center_x + outer_r + 1):
		for cy in range(center_y - outer_r, center_y + outer_r + 1):
			var dx := cx - center_x
			var dy := cy - center_y
			var dist := sqrt(float(dx * dx + dy * dy))
			if dist <= float(outer_r) and dist >= float(inner_r):
				if cx >= 1 and cx <= 14 and cy >= 1 and cy <= 14:
					cells.append(Vector2i(cx, cy))

	var polygon: Array[Vector2] = [
		Vector2(float((center_x - outer_r) * 2), float(center_y * 2)),
		Vector2(float(center_x * 2), float((center_y - outer_r) * 2)),
		Vector2(float((center_x + outer_r) * 2), float(center_y * 2)),
		Vector2(float(center_x * 2), float((center_y + outer_r) * 2)),
	]

	var opening_pos := Vector2(float(center_x * 2), float((center_y - inner_r) * 2))
	return {"cells": cells, "polygon": polygon, "opening_pos": opening_pos}


func _get_opening_width(p_opening_type: int, p_rng: RandomNumberGenerator) -> int:
	var width_range := BiomeConfig.get_opening_width_range(p_opening_type)
	return p_rng.randi_range(width_range.x, width_range.y)


func _populate_chunk_objects(chunk: Chunk) -> void:
	"""Puebla el chunk colocando objetos tanto sobre las mesetas como abajo en los valles/cañones."""
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([chunk.x, chunk.y, world_seed, "chunk_objects"])

	# Determinar celdas ocupadas por mesetas para situar objetos tematicamente
	var plateau_cells: Dictionary = {}
	for barrier: Barrier in chunk.barriers:
		for cell: Vector2i in barrier.cells:
			plateau_cells[cell] = true

	# 1. Objetos sobre la meseta (Ruinas, Cristales sagrados, Monumentos)
	if not plateau_cells.is_empty():
		var cell_keys := plateau_cells.keys()
		# Colocar ruina o monumento en la cumbre
		if rng.randf() < 0.6:
			var rand_macro: Vector2i = cell_keys[rng.randi_range(0, cell_keys.size() - 1)]
			var ruin_path := ObjectCatalog.get_random_common_object("ruins", rng)
			if ruin_path != "":
				chunk.add_placed_object(ruin_path, rand_macro * 2, "plateau_ruin")

		# Colocar detalles del bioma en la meseta (como los cristales mintgrün del screenshot)
		for i in range(rng.randi_range(3, 6)):
			var rand_macro: Vector2i = cell_keys[rng.randi_range(0, cell_keys.size() - 1)]
			var item_path := ObjectCatalog.get_random_biome_object(chunk.biome, rng)
			if item_path != "":
				chunk.add_placed_object(item_path, rand_macro * 2 + Vector2i(rng.randi_range(0, 1), rng.randi_range(0, 1)), "plateau_flora")

	# 2. Objetos en el valle / piso inferior (troncos caidos, esqueletos, rocas como en el screenshot)
	var num_valley_items := rng.randi_range(8, 14)
	for i in range(num_valley_items):
		var rx := rng.randi_range(2, chunk_size - 3)
		var ry := rng.randi_range(2, chunk_size - 3)
		var macro := Vector2i(int(rx / 2), int(ry / 2))
		# Solo colocar en el valle / suelo bajo (donde NO hay meseta)
		if not plateau_cells.has(macro):
			var category_roll := rng.randf()
			var obj_path := ""
			if category_roll < 0.35:
				obj_path = ObjectCatalog.get_random_common_object("trees", rng)
			elif category_roll < 0.65:
				obj_path = ObjectCatalog.get_random_common_object("bushes", rng)
			else:
				obj_path = ObjectCatalog.get_random_biome_object(chunk.biome, rng)

			if obj_path != "":
				chunk.add_placed_object(obj_path, Vector2i(rx, ry), "valley_object")
