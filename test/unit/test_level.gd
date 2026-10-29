extends GutTest

func test_level_initialization():
	var width := 64
	var height := 64
	var chunk_size := 32
	var tile_size := 16
	var world_seed := 12345

	var level := Level.new(width, height, chunk_size, tile_size, world_seed)

	assert_eq(level.width, width, "El ancho del nivel debe ser 64")
	assert_eq(level.height, height, "La altura del nivel debe ser 64")
	assert_eq(level.chunk_size, chunk_size, "El tamano del chunk debe ser 32")
	assert_eq(level.tile_size, tile_size, "El tamano de la baldosa debe ser 16")
	assert_eq(level.world_seed, world_seed, "La semilla del mundo debe ser 12345")


func test_level_generates_chunks():
	var level := Level.new(2, 2, 32, 32, 9999)
	level.generate()
	assert_eq(level.chunks.size(), 2, "El nivel debe tener 2 chunks en direccion x")
	assert_eq(level.chunks[0].size(), 2, "Cada fila x debe tener 2 chunks en direccion y")
	assert_ne(level.chunks[0][0], null, "El chunk (0,0) no debe ser null")


func test_chunk_generation_is_deterministic():
	var level1 := Level.new(1, 1, 32, 32, 7777)
	var level2 := Level.new(1, 1, 32, 32, 7777)
	level1.generate()
	level2.generate()
	assert_eq(level1.chunks[0][0].biome, level2.chunks[0][0].biome, "Los biomas deben ser deterministas")


func test_get_chunk_returns_correct_chunk():
	var level := Level.new(3, 3, 32, 32, 5555)
	level.generate()
	var chunk := level.get_chunk(1, 2)
	assert_ne(chunk, null, "El chunk no debe ser null")
	assert_eq(chunk.x, 1, "La coordenada x del chunk debe ser 1")
	assert_eq(chunk.y, 2, "La coordenada y del chunk debe ser 2")


func test_level_generates_with_barriers():
	var world_seed := -1
	for candidate_seed in range(100):
		var candidate_map := BiomeGenerator.generate_biome_map(candidate_seed, 2, 2)
		if candidate_map[0][0] == BiomeType.ROCKS:
			world_seed = candidate_seed
			break
	assert_gte(world_seed, 0, "Es sollte ein Seed mit Felsbiom gefunden werden")

	var level := Level.new(2, 2, 32, 32, world_seed)
	level.generate()
	
	var total_barriers := 0
	for x in range(level.width):
		for y in range(level.height):
			var chunk := level.get_chunk(x, y)
			assert_not_null(chunk, "El chunk no debe ser null")
			total_barriers += chunk.barriers.size()
			for barrier in chunk.barriers:
				assert_gt(barrier.polygon.size(), 2, "El poligono de la barrera debe tener al menos 3 vertices")
				assert_eq(barrier.biome, chunk.biome, "El bioma de la barrera debe coincidir con el bioma del chunk")
	
	assert_gt(total_barriers, 0, "El nivel debe haber generado al menos una barrera entre los chunks")


func test_level_uses_seeded_biome_map():
	var world_seed := 24680
	var expected_biome_map := BiomeGenerator.generate_biome_map(world_seed, 12, 12)
	var level := Level.new(12, 12, 32, 32, world_seed)
	level.generate()

	assert_eq(level.biome_map, expected_biome_map, "El nivel debe conservar el mapa de biomas generado")
	for x in range(level.width):
		for y in range(level.height):
			assert_eq(
				level.get_chunk(x, y).biome,
				expected_biome_map[x][y],
				"Cada chunk debe usar el bioma de la tarjeta"
			)


func test_generated_chunks_use_biome_terrain_as_base():
	for biome: BiomeType.Type in BiomeType.Type.values():
		var level := Level.new(1, 1, 32, 32, 12345)
		level.biome_map = [[biome]]
		var chunk := level.generate_chunk(0, 0)
		var expected_tile := level.get_tile_type_from_biome(biome)
		var found_base_tile := false

		for tile_x in range(32):
			for tile_y in range(32):
				if not chunk.is_barrier(tile_x, tile_y):
					assert_eq(chunk.get_tile(tile_x, tile_y), expected_tile)
					found_base_tile = true

		assert_true(found_base_tile, "Cada chunk debe conservar baldosa de terreno fuera de sus barreras")


func test_hash_supports_string_seed_components():
	var level := Level.new(1, 1, 32, 32, 13579)
	var values := [1, 1, level.world_seed, "barriers"]

	assert_eq(level.hash(values), level.hash(values), "Der Hash mit einem String-Seedbestandteil muss deterministisch sein")


"""
func test_barrier_generation_uses_biome_parameters():
	var level := Level.new(2, 2, 32, 32, 13579)
	var params := level._get_biome_params_for_chunk(1, 1, BiomeType.ROCKS)

	var barriers := level.generate_barriers_for_chunk(1, 1, BiomeType.ROCKS)

	assert_eq(barriers.size(), params["barrier_count"], "Die Barrierenanzahl muss aus den Biome-Parametern stammen")
	for barrier: Barrier in barriers:
		var min_x := INF
		var max_x := -INF
		var min_y := INF
		var max_y := -INF
		for vertex: Vector2 in barrier.polygon:
			min_x = minf(min_x, vertex.x)
			max_x = maxf(max_x, vertex.x)
			min_y = minf(min_y, vertex.y)
			max_y = maxf(max_y, vertex.y)
		var max_expected_size := float(params["barrier_size"] + 2)
		assert_lte(max_x - min_x, max_expected_size, "Die Barrierengröße muss die Biome-Parameter berücksichtigen")
		assert_lte(max_y - min_y, max_expected_size, "Die Barrierengröße muss die Biome-Parameter berücksichtigen")
"""

func test_natural_formation_generation_within_chunk():
	var level := Level.new(1, 1, 32, 32, 12345)
	var formations := level.generate_barriers_for_chunk(0, 0, BiomeType.ROCKS)

	assert_gt(formations.size(), 0, "Debe generar al menos una formacion natural para el bioma rocoso")
	for barrier: Barrier in formations:
		assert_gte(barrier.polygon.size(), 3, "El poligono natural debe tener al menos 3 vertices")
		for pt: Vector2 in barrier.polygon:
			assert_gte(pt.x, 0.0, "Las coordenadas deben estar dentro del chunk")
			assert_lte(pt.x, 32.0, "Las coordenadas deben estar dentro del chunk")
			assert_gte(pt.y, 0.0, "Las coordenadas deben estar dentro del chunk")
			assert_lte(pt.y, 32.0, "Las coordenadas deben estar dentro del chunk")


func test_chunk_object_population_rich_and_deterministic():
	var level1 := Level.new(1, 1, 32, 32, 9876)
	var chunk1 := level1.generate_chunk(0, 0)

	var level2 := Level.new(1, 1, 32, 32, 9876)
	var chunk2 := level2.generate_chunk(0, 0)

	assert_gt(chunk1.placed_objects.size(), 10, "El chunk debe poblarse ricamente con mas de 10 objetos")
	assert_eq(chunk1.placed_objects.size(), chunk2.placed_objects.size(), "La cantidad de objetos debe ser determinista")

	for i in range(chunk1.placed_objects.size()):
		var o1 = chunk1.placed_objects[i]
		var o2 = chunk2.placed_objects[i]
		assert_eq(o1["path"], o2["path"], "El tipo de objeto debe coincidir exactamente")
		assert_eq(o1["pos"], o2["pos"], "La posicion del objeto debe coincidir exactamente")


"""
func test_barriers_deterministic_with_seed():
	var level1 := Level.new(2, 2, 32, 32, 424242)
	var level2 := Level.new(2, 2, 32, 32, 424242)
	level1.generate()
	level2.generate()

	for x in range(2):
		for y in range(2):
			var chunk1 := level1.get_chunk(x, y)
			var chunk2 := level2.get_chunk(x, y)
			assert_eq(chunk1.biome, chunk2.biome, "Los biomas de los chunks deben coincidir")
			assert_eq(chunk1.barriers.size(), chunk2.barriers.size(), "La cantidad de barreras debe coincidir")
			
			for b in range(chunk1.barriers.size()):
				var b1: Barrier = chunk1.barriers[b]
				var b2: Barrier = chunk2.barriers[b]
				assert_eq(b1.biome, b2.biome, "Los biomas de las barreras deben coincidir")
				assert_eq(b1.polygon.size(), b2.polygon.size(), "La cantidad de vertices del poligono debe coincidir")
				for p in range(b1.polygon.size()):
					assert_eq(b1.polygon[b], b2.polygon[b], "Los vertices del poligono deben coincidir exactamente")
			
			for tx in range(32):
				for ty in range(32):
					assert_eq(chunk1.tiles[tx][ty], chunk2.tiles[tx][ty], "Las baldosas deben coincidir exactamente")
"""

func test_get_barrier_tile_type_from_biome():
	var level := Level.new(1, 1, 32, 32, 1)
	assert_eq(level.get_barrier_tile_type_from_biome(BiomeType.CAVE), TileType.ROCK)
	assert_eq(level.get_barrier_tile_type_from_biome(BiomeType.DESERT), TileType.SAND)
	assert_eq(level.get_barrier_tile_type_from_biome(BiomeType.FOREST), TileType.TREE)
	assert_eq(level.get_barrier_tile_type_from_biome(BiomeType.GRASSLAND), TileType.ROCK)
	assert_eq(level.get_barrier_tile_type_from_biome(BiomeType.ROCKS), TileType.ROCK)
	assert_eq(level.get_barrier_tile_type_from_biome(BiomeType.ROCKS_AND_WATER), TileType.ROCK)
	assert_eq(level.get_barrier_tile_type_from_biome(BiomeType.SWAMP), TileType.TREE)
	assert_eq(level.get_barrier_tile_type_from_biome(BiomeType.SEABED), TileType.ROCK)
