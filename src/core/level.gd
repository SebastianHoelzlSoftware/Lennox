# level.gd
class_name Level
extends RefCounted

const CliffAutotiler = preload("res://src/core/cliff_autotiler.gd")
const ObjectCatalog = preload("res://src/core/object_catalog.gd")
const TerrainStyles = preload("res://src/core/terrain_styles.gd")

# Alto maximo (en baldosas) de una cara de acantilado; usado para detectar caras.
const MAX_FACE_HEIGHT := 3
# Amplitud (en macro-celdas) de la deformacion de las fronteras entre biomas.
const BIOME_BORDER_WARP := 11.0

var width: int
var height: int
var chunk_size: int
var tile_size: int
var world_seed: int

var chunks: Array = []
var biome_map: Array = []

var _global_plateau_cells: Dictionary = {}
var _plateau_style: Dictionary = {}
var _occupied: Dictionary = {}
# Caches planos por macro-celda (se rellenan en generate() para consultas rapidas)
var _macro_w := 0
var _macro_h := 0
var _macro_biome := PackedInt32Array()
var _macro_solid := PackedByteArray()
var _macro_face := PackedByteArray()
var _elev_noise: FastNoiseLite = null
var _canyon_noise: FastNoiseLite = null
var _warp_noise: FastNoiseLite = null
var _biome_warp_noise: FastNoiseLite = null
var _floor_noise: FastNoiseLite = null
var _path_noise: FastNoiseLite = null
var _grove_noise: FastNoiseLite = null

static var _sized_objects_cache: Dictionary = {}


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

	# Deformacion de las fronteras entre biomas (evita lineas rectas de chunk)
	_biome_warp_noise = FastNoiseLite.new()
	_biome_warp_noise.seed = (world_seed * 13 + 3571) % 2147483647
	_biome_warp_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_biome_warp_noise.frequency = 0.06
	_biome_warp_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	_biome_warp_noise.fractal_octaves = 2

	# Manchas de suelo (hierba sobre tierra, oasis, musgo...)
	_floor_noise = FastNoiseLite.new()
	_floor_noise.seed = (world_seed * 7 + 811) % 2147483647
	_floor_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_floor_noise.frequency = 0.09
	_floor_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	_floor_noise.fractal_octaves = 2

	# Senderos serpenteantes (isolineas del ruido)
	_path_noise = FastNoiseLite.new()
	_path_noise.seed = (world_seed * 5 + 4127) % 2147483647
	_path_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_path_noise.frequency = 0.035

	# Densidad de arboledas (agrupa la vegetacion en bosquecillos y claros)
	_grove_noise = FastNoiseLite.new()
	_grove_noise.seed = (world_seed * 3 + 9001) % 2147483647
	_grove_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_grove_noise.frequency = 0.08


func get_macro_per_chunk() -> int:
	@warning_ignore("INTEGER_DIVISION")
	return maxi(chunk_size / 2, 1)


func get_biome_at_macro(mx: int, my: int) -> BiomeType.Type:
	"""Bioma de una macro-celda con fronteras deformadas organicamente."""
	if not _macro_biome.is_empty() and mx >= 0 and my >= 0 and mx < _macro_w and my < _macro_h:
		return _macro_biome[my * _macro_w + mx] as BiomeType.Type
	return _compute_biome_at_macro(mx, my)


func _compute_biome_at_macro(mx: int, my: int) -> BiomeType.Type:
	_init_noise()
	var mpc := float(get_macro_per_chunk())
	var wx: float = _biome_warp_noise.get_noise_2d(float(mx), float(my)) * BIOME_BORDER_WARP
	var wy: float = _biome_warp_noise.get_noise_2d(float(mx) + 517.0, float(my) - 263.0) * BIOME_BORDER_WARP
	# Fleco de alta frecuencia: fronteras dentadas en lugar de tramos rectos
	wx += _warp_noise.get_noise_2d(float(mx) * 2.7, float(my) * 2.7) * 1.5
	wy += _warp_noise.get_noise_2d(float(mx) * 2.7 + 91.0, float(my) * 2.7 - 37.0) * 1.5
	var cx := clampi(floori((float(mx) + wx) / mpc), 0, maxi(width - 1, 0))
	var cy := clampi(floori((float(my) + wy) / mpc), 0, maxi(height - 1, 0))
	return _get_biome_for_chunk(cx, cy)


func get_biome_at_tile(tx: int, ty: int) -> BiomeType.Type:
	return get_biome_at_macro(floori(tx / 2.0), floori(ty / 2.0))


func is_floor_overlay_macro(mx: int, my: int) -> bool:
	"""Indica si la macro-celda lleva mancha de suelo (hierba, oasis...) segun su bioma."""
	_init_noise()
	var style := TerrainStyles.get_biome_style(get_biome_at_macro(mx, my))
	if not style.has("overlay"):
		return false
	if _floor_noise.get_noise_2d(float(mx), float(my)) < float(style.get("cover", 0.0)):
		return false
	var paths: float = style.get("paths", 0.0)
	if paths > 0.0 and absf(_path_noise.get_noise_2d(float(mx), float(my))) < paths:
		return false
	return true


func get_plateau_style(mx: int, my: int) -> String:
	"""Clave de estilo de acantilado (TerrainStyles.CLIFFS) para la meseta de esta macro-celda."""
	var key := Vector2i(mx, my)
	if _plateau_style.has(key):
		return _plateau_style[key]
	return TerrainStyles.get_cliff_key_for_biome(get_biome_at_macro(mx, my))


func is_tile_solid(tx: int, ty: int) -> bool:
	return is_macro_cell_solid(floori(tx / 2.0), floori(ty / 2.0))


func is_tile_cliff_face(tx: int, ty: int) -> bool:
	"""True si la baldosa queda tapada por la cara de roca de una meseta situada encima."""
	if is_tile_solid(tx, ty):
		return false
	for k in range(1, MAX_FACE_HEIGHT + 1):
		if is_tile_solid(tx, ty - k):
			var mx := floori(tx / 2.0)
			var my := floori((ty - k) / 2.0)
			return k <= _get_face_height(mx, my)
	return false


func _get_face_height(mx: int, my: int) -> int:
	if not _macro_face.is_empty() and mx >= 0 and my >= 0 and mx < _macro_w and my < _macro_h:
		return _macro_face[my * _macro_w + mx]
	return (TerrainStyles.get_cliff_style(get_plateau_style(mx, my))["face"] as Array).size()


func find_open_tile_near(p_tile: Vector2i, p_max_radius: int = 40) -> Vector2i:
	"""Busca la baldosa transitable (valle sin cara de roca) mas cercana en espiral."""
	for r in range(p_max_radius):
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				if maxi(absi(dx), absi(dy)) != r:
					continue
				var t := p_tile + Vector2i(dx, dy)
				if _is_open_area(t, 1):
					return t
	return p_tile


func _is_open_area(p_tile: Vector2i, p_radius: int) -> bool:
	for dy in range(-p_radius, p_radius + 1):
		for dx in range(-p_radius, p_radius + 1):
			var t := p_tile + Vector2i(dx, dy)
			if is_tile_solid(t.x, t.y) or is_tile_cliff_face(t.x, t.y):
				return false
	return true


func _get_plateau_threshold_for_biome(biome: BiomeType.Type) -> float:
	match biome:
		BiomeType.ROCKS: return 0.06
		BiomeType.CAVE: return 0.08
		BiomeType.DESERT: return 0.28
		BiomeType.FOREST: return 0.10
		BiomeType.GRASSLAND: return 0.11
		BiomeType.ROCKS_AND_WATER: return -0.15
		BiomeType.SWAMP: return 0.13
		BiomeType.SEABED: return 0.14
		_: return 0.10


func _eval_macro_cell_solid(world_mx: int, world_my: int) -> bool:
	var mpc := get_macro_per_chunk()
	var max_mx := width * mpc
	var max_my := height * mpc

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

	# El umbral sigue la frontera deformada del bioma (sin cortes rectos en los chunks)
	var biome := get_biome_at_macro(world_mx, world_my)
	var threshold := _get_plateau_threshold_for_biome(biome)

	return elev > threshold


func is_macro_cell_solid(world_mx: int, world_my: int) -> bool:
	if not _macro_solid.is_empty():
		if world_mx < 0 or world_my < 0 or world_mx >= _macro_w or world_my >= _macro_h:
			return false
		return _macro_solid[world_my * _macro_w + world_mx] == 1
	var key := Vector2i(world_mx, world_my)
	if _global_plateau_cells.has(key):
		return _global_plateau_cells[key]
	return _eval_macro_cell_solid(world_mx, world_my)


func _set_macro_solid(mx: int, my: int, p_solid: bool) -> void:
	_global_plateau_cells[Vector2i(mx, my)] = p_solid
	if not _macro_solid.is_empty() and mx >= 0 and my >= 0 and mx < _macro_w and my < _macro_h:
		_macro_solid[my * _macro_w + mx] = 1 if p_solid else 0


func generate() -> void:
	"""Genera el mundo continuo con biomas, mesetas chunkübergreifend y ecologia densa."""
	chunks.clear()
	_global_plateau_cells.clear()
	_plateau_style.clear()
	_occupied.clear()
	_macro_biome = PackedInt32Array()
	_macro_solid = PackedByteArray()
	_macro_face = PackedByteArray()
	_init_noise()
	biome_map = BiomeGenerator.generate_biome_map(world_seed, width, height)

	# 0. Cache de biomas por macro-celda (fronteras deformadas)
	var mpc := get_macro_per_chunk()
	var max_mx := width * mpc
	var max_my := height * mpc
	_macro_w = max_mx
	_macro_h = max_my
	var biomes := PackedInt32Array()
	biomes.resize(max_mx * max_my)
	for gmy in range(max_my):
		for gmx in range(max_mx):
			biomes[gmy * max_mx + gmx] = _compute_biome_at_macro(gmx, gmy)
	# Suavizado: las celdas aisladas adoptan el bioma de su vecindario (sin cuadraditos sueltos)
	for _pass in range(2):
		var smoothed := biomes.duplicate()
		for gmy in range(max_my):
			for gmx in range(max_mx):
				var own := biomes[gmy * max_mx + gmx]
				var votes: Dictionary = {}
				var same := 0
				for off: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
					var nx := gmx + off.x
					var ny := gmy + off.y
					if nx < 0 or ny < 0 or nx >= max_mx or ny >= max_my:
						same += 1
						continue
					var nb := biomes[ny * max_mx + nx]
					votes[nb] = int(votes.get(nb, 0)) + 1
					if nb == own:
						same += 1
				if same < 2:
					var best := own
					var best_votes := 0
					for b: int in votes:
						if votes[b] > best_votes:
							best_votes = votes[b]
							best = b
					smoothed[gmy * max_mx + gmx] = best
		biomes = smoothed
	_macro_biome = biomes

	# 1. Precalcular campo continuo global de mesetas a traves de todos los chunks
	for gmx in range(max_mx):
		for gmy in range(max_my):
			var solid := _eval_macro_cell_solid(gmx, gmy)
			_global_plateau_cells[Vector2i(gmx, gmy)] = solid

	# 2. Pase de jugabilidad: Garantizar que ningun chunk sea 100% meseta para preservar valles
	for cx in range(width):
		for cy in range(height):
			var solid_count := 0
			for ly in range(mpc):
				for lx in range(mpc):
					if _global_plateau_cells.get(Vector2i(cx * mpc + lx, cy * mpc + ly), false):
						solid_count += 1
			# Si el chunk esta casi completamente cubierto (>74% de las celdas), abrir paso central
			if solid_count > int(mpc * mpc * 0.74):
				for ly in range(int(mpc * 0.375), int(mpc * 0.69)):
					for lx in range(int(mpc * 0.375), int(mpc * 0.69)):
						_global_plateau_cells[Vector2i(cx * mpc + lx, cy * mpc + ly)] = false
			# Chunks sin relieve reciben una meseta escenica propia
			elif solid_count == 0:
				_add_scenic_plateau(cx, cy)

	# 3. Limpieza geometrica para un autotiling impecable
	_cleanup_plateau_field(max_mx, max_my)

	# 4. Cada meseta conexa recibe un unico estilo de acantilado (el de su bioma dominante)
	_assign_plateau_styles(max_mx, max_my)

	# 5. Caches planos de solidez y altura de cara para consultas rapidas
	var solid_grid := PackedByteArray()
	solid_grid.resize(max_mx * max_my)
	var face_grid := PackedByteArray()
	face_grid.resize(max_mx * max_my)
	for gmy in range(max_my):
		for gmx in range(max_mx):
			var key := Vector2i(gmx, gmy)
			if _global_plateau_cells.get(key, false):
				solid_grid[gmy * max_mx + gmx] = 1
				var style := TerrainStyles.get_cliff_style(_plateau_style.get(key, "grass"))
				face_grid[gmy * max_mx + gmx] = (style["face"] as Array).size()
	_macro_solid = solid_grid
	_macro_face = face_grid

	# 6. Generar chunks
	for x in range(width):
		chunks.append([])
		for y in range(height):
			chunks[x].append(generate_chunk(x, y))


func _add_scenic_plateau(cx: int, cy: int) -> void:
	var mpc := get_macro_per_chunk()
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([cx, cy, world_seed, "scenic_plateau"])
	var ox := rng.randi_range(3, 5)
	var oy := rng.randi_range(3, 5)
	var fw := rng.randi_range(5, 7)
	var fh := rng.randi_range(4, 6)
	for ly in range(oy, mini(oy + fh, mpc - 3)):
		for lx in range(ox, mini(ox + fw, mpc - 2)):
			# Esquinas recortadas para una silueta mas organica
			var corner := (lx == ox or lx == ox + fw - 1) and (ly == oy or ly == oy + fh - 1)
			if corner and rng.randf() < 0.7:
				continue
			_global_plateau_cells[Vector2i(cx * mpc + lx, cy * mpc + ly)] = true


func _cleanup_plateau_field(max_mx: int, max_my: int) -> void:
	"""Reglas de forma que garantizan piezas de autotiling validas:

	1. Sin conexiones solo diagonales (se rellena una celda del codo).
	2. Ningun hueco vertical de 1 celda bajo un borde sur: la cara de roca nunca tapa otra meseta.
	3. Sin celdas sueltas de 1x1.
	"""
	var s := func(x: int, y: int) -> bool:
		return _global_plateau_cells.get(Vector2i(x, y), false)

	for _pass in range(3):
		for my in range(max_my - 1):
			for mx in range(max_mx - 1):
				var a: bool = s.call(mx, my)
				var b: bool = s.call(mx + 1, my)
				var c: bool = s.call(mx, my + 1)
				var d: bool = s.call(mx + 1, my + 1)
				if a and d and not b and not c:
					_global_plateau_cells[Vector2i(mx, my + 1)] = true
				elif b and c and not a and not d:
					_global_plateau_cells[Vector2i(mx + 1, my + 1)] = true

		for mx in range(max_mx):
			for my in range(max_my - 2):
				if s.call(mx, my) and not s.call(mx, my + 1) and s.call(mx, my + 2):
					_global_plateau_cells[Vector2i(mx, my + 1)] = true

	for my in range(max_my):
		for mx in range(max_mx):
			if s.call(mx, my) and not s.call(mx - 1, my) and not s.call(mx + 1, my) \
					and not s.call(mx, my - 1) and not s.call(mx, my + 1):
				_global_plateau_cells[Vector2i(mx, my)] = false


func _assign_plateau_styles(max_mx: int, max_my: int) -> void:
	var visited: Dictionary = {}
	for my in range(max_my):
		for mx in range(max_mx):
			var start := Vector2i(mx, my)
			if visited.has(start) or not _global_plateau_cells.get(start, false):
				continue
			# Flood fill de la meseta conexa
			var component: Array[Vector2i] = []
			var stack: Array[Vector2i] = [start]
			visited[start] = true
			var votes: Dictionary = {}
			while not stack.is_empty():
				var cell: Vector2i = stack.pop_back()
				component.append(cell)
				var key := TerrainStyles.get_cliff_key_for_biome(get_biome_at_macro(cell.x, cell.y))
				votes[key] = int(votes.get(key, 0)) + 1
				for off: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
					var n := cell + off
					if not visited.has(n) and _global_plateau_cells.get(n, false):
						visited[n] = true
						stack.append(n)
			var best_key := ""
			var best_votes := -1
			for key: String in votes:
				if votes[key] > best_votes:
					best_votes = votes[key]
					best_key = key
			for cell in component:
				_plateau_style[cell] = best_key


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
	var mpc := get_macro_per_chunk()
	var local_cells: Array[Vector2i] = []
	for ly in range(mpc):
		for lx in range(mpc):
			var gmx := p_x * mpc + lx
			var gmy := p_y * mpc + ly
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
				_set_macro_solid(p_x * mpc + lx, p_y * mpc + ly, true)

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



# ---------------------------------------------------------------------------
# Poblacion ecologica
# ---------------------------------------------------------------------------
# Recetas por bioma: [fuente, tamano, minimo, maximo, lugar]
#   fuente: "biome" (objetos propios del bioma de la baldosa) o categoria comun
#           ("trees", "bushes", "ruins", "cursed_land")
#   tamano: "huge" | "large" | "medium" | "small" | "any"
#   lugar:  "valley" (suelo bajo) | "plateau" (interior de la meseta)
const POPULATION_RECIPES := {
	BiomeType.Type.GRASSLAND: [
		["ruins", "any", 0, 1, "plateau"],
		["trees", "any", 5, 8, "valley"],
		["biome", "large", 1, 3, "valley"],
		["bushes", "any", 6, 10, "valley"],
		["biome", "medium", 4, 7, "valley"],
		["biome", "small", 10, 16, "valley"],
		["trees", "any", 1, 3, "plateau"],
		["bushes", "any", 2, 4, "plateau"],
		["biome", "small", 3, 6, "plateau"],
	],
	BiomeType.Type.FOREST: [
		["trees", "any", 14, 20, "valley"],
		["bushes", "any", 8, 12, "valley"],
		["biome", "large", 2, 4, "valley"],
		["biome", "medium", 4, 7, "valley"],
		["biome", "small", 10, 14, "valley"],
		["trees", "any", 3, 6, "plateau"],
		["bushes", "any", 2, 4, "plateau"],
		["biome", "small", 2, 4, "plateau"],
	],
	BiomeType.Type.DESERT: [
		["biome", "huge", 0, 1, "plateau"],
		["biome", "huge", 0, 1, "valley"],
		["ruins", "any", 0, 1, "valley"],
		["trees", "any", 2, 4, "valley"],
		["biome", "large", 3, 6, "valley"],
		["bushes", "any", 3, 5, "valley"],
		["biome", "medium", 5, 8, "valley"],
		["biome", "small", 12, 18, "valley"],
		["biome", "large", 2, 4, "plateau"],
		["trees", "any", 1, 2, "plateau"],
		["biome", "medium", 2, 4, "plateau"],
		["biome", "small", 5, 9, "plateau"],
	],
	BiomeType.Type.ROCKS: [
		["biome", "huge", 0, 1, "valley"],
		["biome", "large", 3, 5, "valley"],
		["cursed_land", "any", 2, 4, "valley"],
		["biome", "medium", 4, 7, "valley"],
		["biome", "small", 10, 16, "valley"],
		["ruins", "any", 0, 1, "plateau"],
		["biome", "medium", 1, 3, "plateau"],
		["biome", "small", 3, 6, "plateau"],
	],
	BiomeType.Type.CAVE: [
		["biome", "huge", 0, 1, "valley"],
		["biome", "large", 3, 5, "valley"],
		["cursed_land", "any", 2, 4, "valley"],
		["biome", "medium", 4, 7, "valley"],
		["biome", "small", 12, 18, "valley"],
	],
	BiomeType.Type.SWAMP: [
		["trees", "any", 3, 5, "valley"],
		["biome", "large", 3, 5, "valley"],
		["biome", "medium", 5, 8, "valley"],
		["bushes", "any", 3, 6, "valley"],
		["biome", "small", 12, 16, "valley"],
		["trees", "any", 1, 2, "plateau"],
		["biome", "small", 2, 4, "plateau"],
	],
	BiomeType.Type.SEABED: [
		["biome", "huge", 0, 1, "valley"],
		["biome", "large", 4, 7, "valley"],
		["biome", "medium", 6, 9, "valley"],
		["biome", "small", 14, 20, "valley"],
		["biome", "medium", 1, 3, "plateau"],
		["biome", "small", 2, 4, "plateau"],
	],
	BiomeType.Type.ROCKS_AND_WATER: [
		["biome", "large", 1, 3, "plateau"],
		["trees", "any", 2, 4, "plateau"],
		["bushes", "any", 3, 5, "plateau"],
		["biome", "medium", 3, 5, "plateau"],
		["biome", "small", 5, 9, "plateau"],
		["biome", "medium", 2, 4, "valley"],
		["biome", "small", 4, 8, "valley"],
	],
}

const KIND_BLOCKED := 0
const KIND_VALLEY := 1
const KIND_PLATEAU := 2

# Seleccion tematica de las categorias comunes por bioma (prefijos de nombre de archivo).
# Sin filtro para un bioma/categoria -> esa categoria no se usa en ese bioma.
const COMMON_FILTERS := {
	BiomeType.Type.GRASSLAND: {
		"trees": ["Tree", "Fruit_tree", "Flower_tree"],
		"bushes": ["Bush_", "Fern"],
		"ruins": ["Brown_ruins", "Brown-gray_ruins"],
	},
	BiomeType.Type.FOREST: {
		"trees": ["Tree", "Moss_tree", "Fruit_tree", "Christmas_tree"],
		"bushes": ["Bush_simple", "Fern", "Bush_blue", "Bush_red"],
		"ruins": ["Brown-gray_ruins"],
	},
	BiomeType.Type.DESERT: {
		"trees": ["Palm_tree"],
		"bushes": ["Cactus"],
		"ruins": ["Sand_ruins", "Yellow_ruins"],
	},
	BiomeType.Type.ROCKS: {
		"trees": ["Broken_tree", "Burned_tree"],
		"bushes": ["Broken_tree"],
		"ruins": ["Blue-gray_ruins", "White_ruins"],
		"cursed_land": ["Bones", "Eye_plant", "Jaws_plant"],
	},
	BiomeType.Type.CAVE: {
		"ruins": ["Blue-gray_ruins"],
		"cursed_land": ["Bones", "Eye_plant", "Jaws_plant", "Fetus"],
	},
	BiomeType.Type.SWAMP: {
		"trees": ["Moss_tree", "Broken_tree"],
		"bushes": ["Fern", "Bush_simple"],
		"ruins": ["Brown-gray_ruins"],
	},
	BiomeType.Type.SEABED: {
		"ruins": ["Water_ruins"],
	},
	BiomeType.Type.ROCKS_AND_WATER: {
		"trees": ["Flower_tree", "Tree", "Autumn_tree"],
		"bushes": ["Bush_pink", "Bush_blue", "Bush_simple"],
		"ruins": ["White_ruins"],
	},
}


static func _get_sized_objects(p_key: String, p_paths: Array[String]) -> Dictionary:
	"""Clasifica una lista de sprites por tamano (se cachea)."""
	if _sized_objects_cache.has(p_key):
		return _sized_objects_cache[p_key]
	var out := {"huge": [], "large": [], "medium": [], "small": [], "any": []}
	for path in p_paths:
		var tex := ObjectCatalog.load_texture(path)
		if tex == null:
			continue
		var size := tex.get_size()
		var bucket := "small"
		if size.x > 100.0 or size.y > 100.0:
			bucket = "huge"
		elif size.x > 52.0 or size.y > 52.0:
			bucket = "large"
		elif size.x > 22.0 or size.y > 22.0:
			bucket = "medium"
		(out[bucket] as Array).append(path)
		if bucket != "huge":
			(out["any"] as Array).append(path)
	_sized_objects_cache[p_key] = out
	return out


func _pick_object(p_source: String, p_size: String, p_biome: BiomeType.Type, p_rng: RandomNumberGenerator) -> String:
	var sized: Dictionary
	if p_source == "biome":
		sized = _get_sized_objects("biome_%d" % p_biome, ObjectCatalog.get_biome_objects(p_biome))
	else:
		var filters: Dictionary = COMMON_FILTERS.get(p_biome, {})
		if not filters.has(p_source):
			# Categoria ajena al bioma: se usan sus propios objetos
			return _pick_object("biome", p_size, p_biome, p_rng)
		var prefixes: Array = filters[p_source]
		var filtered: Array[String] = []
		for path in ObjectCatalog.get_common_objects(p_source):
			var file_name := path.get_file()
			for prefix: String in prefixes:
				if file_name.begins_with(prefix):
					filtered.append(path)
					break
		sized = _get_sized_objects("common_%s_%d" % [p_source, p_biome], filtered)
	var list: Array = sized.get(p_size, [])
	if list.is_empty() and p_size != "any":
		list = sized.get("any", [])
	if list.is_empty():
		return ""
	return list[p_rng.randi_range(0, list.size() - 1)]


func _compute_tile_kinds(chunk: Chunk) -> PackedByteArray:
	"""Clasifica cada baldosa del chunk: bloqueada, valle o interior de meseta."""
	var kinds := PackedByteArray()
	kinds.resize(chunk_size * chunk_size)
	var origin := Vector2i(chunk.x * chunk_size, chunk.y * chunk_size)
	for ly in range(chunk_size):
		for lx in range(chunk_size):
			var t := origin + Vector2i(lx, ly)
			var kind := KIND_BLOCKED
			if is_tile_solid(t.x, t.y):
				var interior := true
				for dy in range(-1, 2):
					for dx in range(-1, 2):
						if not is_tile_solid(t.x + dx, t.y + dy):
							interior = false
				# El techo de la cueva es roca negra: no se puebla
				if interior and get_plateau_style(floori(t.x / 2.0), floori(t.y / 2.0)) != "cave":
					kind = KIND_PLATEAU
			elif not is_tile_cliff_face(t.x, t.y) and not is_tile_cliff_face(t.x, t.y - 1):
				kind = KIND_VALLEY
			kinds[ly * chunk_size + lx] = kind
	return kinds


func _try_place_object(
	chunk: Chunk, p_source: String, p_size: String, p_kind: int, p_kinds: PackedByteArray,
	p_occupied: Dictionary, p_rng: RandomNumberGenerator, p_grove: bool, p_category: String
) -> bool:
	var origin := Vector2i(chunk.x * chunk_size, chunk.y * chunk_size)

	for _attempt in range(10):
		var tx := p_rng.randi_range(1, chunk_size - 2)
		var ty := p_rng.randi_range(1, chunk_size - 2)
		if p_kinds[ty * chunk_size + tx] != p_kind:
			continue
		if p_grove:
			# Arboledas: mas probable donde el ruido de bosquecillos es alto
			var g: float = _grove_noise.get_noise_2d(float(origin.x + tx), float(origin.y + ty))
			if p_rng.randf() > clampf(0.45 + g * 1.2, 0.08, 1.0):
				continue
		# El sprite se elige segun el bioma real de la baldosa (fronteras organicas)
		var path := _pick_object(p_source, p_size, get_biome_at_tile(origin.x + tx, origin.y + ty), p_rng)
		if path == "":
			return false
		var tex := ObjectCatalog.load_texture(path)
		var size := tex.get_size() if tex != null else Vector2(16, 16)
		var fw := clampi(ceili(size.x / 16.0 * 0.7), 1, 7)
		var fh := clampi(ceili(size.y / 16.0 * 0.35), 1, 4)
		var pad := 1 if size.y > 52.0 else 0
		@warning_ignore("INTEGER_DIVISION")
		var x0 := tx - fw / 2
		var y0 := ty - fh + 1
		var ok := true
		for fy in range(y0 - pad, ty + 1 + pad):
			for fx in range(x0 - pad, x0 + fw + pad):
				var inside_core := fx >= x0 and fx < x0 + fw and fy >= y0 and fy <= ty
				if fx < 0 or fy < 0 or fx >= chunk_size or fy >= chunk_size:
					if inside_core:
						ok = false
					continue
				if p_occupied.has(Vector2i(fx, fy)):
					ok = false
				elif inside_core and p_kinds[fy * chunk_size + fx] != p_kind:
					ok = false
			if not ok:
				break
		if not ok:
			continue
		for fy in range(y0, ty + 1):
			for fx in range(x0, x0 + fw):
				p_occupied[Vector2i(fx, fy)] = true
		chunk.add_placed_object(path, Vector2i(tx, ty), p_category)
		return true
	return false


func _populate_chunk_objects(chunk: Chunk) -> void:
	"""Puebla el chunk con landmarks en las cumbres y una ecologia densa y agrupada en los valles.

	Reglas:
	  * Nunca sobre caras de acantilado ni justo al pie de ellas.
	  * Los objetos de meseta solo en el interior (a 1 baldosa del borde).
	  * Cada objeto reserva una huella proporcional a su sprite: sin solapes.
	  * Primero lo grande (landmarks, arboles), despues lo mediano y al final los detalles.
	  * Arboles y arbustos se agrupan en bosquecillos dejando claros abiertos.
	"""
	_init_noise()
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([chunk.x, chunk.y, world_seed, "chunk_objects"])
	var kinds := _compute_tile_kinds(chunk)
	var occupied: Dictionary = {}

	var recipe: Array = POPULATION_RECIPES.get(chunk.biome, POPULATION_RECIPES[BiomeType.Type.GRASSLAND])
	for entry: Array in recipe:
		var source: String = entry[0]
		var size: String = entry[1]
		var count := rng.randi_range(entry[2], entry[3])
		var place: String = entry[4]
		var kind := KIND_PLATEAU if place == "plateau" else KIND_VALLEY
		var grove := source == "trees" or source == "bushes"
		for i in range(count):
			_try_place_object(chunk, source, size, kind, kinds, occupied, rng, grove, "%s_%s" % [place, source])
