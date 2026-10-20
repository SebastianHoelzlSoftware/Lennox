extends GutTest

func test_level_initialization():
	var width := 64
	var height := 64
	var chunk_size := 32
	var tile_size := 32
	var world_seed := 12345

	var level := Level.new(width, height, chunk_size, tile_size, world_seed)

	assert_eq(level.width, width, "El ancho del nivel debe ser 64")
	assert_eq(level.height, height, "La altura del nivel debe ser 64")
	assert_eq(level.chunk_size, chunk_size, "El tamano del chunk debe ser 32")
	assert_eq(level.tile_size, tile_size, "El tamano de la baldosa debe ser 32")
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
	var level := Level.new(2, 2, 32, 32, 12345)
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


func test_convex_hull_contains_outer_points_and_excludes_inner_points():
	var level := Level.new(1, 1, 32, 32, 12345)
	var points := [
		Vector2(0, 0),
		Vector2(2, 0),
		Vector2(1, 2),
		Vector2(1, 1)
	]

	var hull := level._compute_convex_hull(points)

	assert_eq(hull.size(), 3, "La envolvente convexa debe excluir el punto interior")
	for point in [Vector2(0, 0), Vector2(2, 0), Vector2(1, 2)]:
		assert_has(hull, point, "La envolvente convexa debe conservar los puntos exteriores")

	var barrier := Barrier.new()
	barrier.polygon = hull
	assert_true(barrier.contains_point(Vector2(1, 1)), "La envolvente debe cerrar implicitamente el poligono")


func test_perturb_hull_preserves_vertex_count_and_polygon():
	var level := Level.new(1, 1, 32, 32, 12345)
	var hull := [Vector2(0, 0), Vector2(20, 0), Vector2(10, 20)]

	seed(12345)
	var perturbed_hull := level._perturb_hull(hull, 1)

	assert_eq(perturbed_hull.size(), hull.size(), "La perturbacion debe conservar la cantidad de vertices")
	for index in range(hull.size()):
		var offset: Vector2 = perturbed_hull[index] - hull[index]
		assert_true(abs(offset.x) <= 1 and abs(offset.y) <= 1, "Cada vertice solo debe desplazarse dentro del limite configurado")

	var barrier := Barrier.new()
	barrier.polygon = perturbed_hull
	assert_true(barrier.contains_point(Vector2(10, 10)), "El poligono perturbado debe seguir conteniendo su interior")


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
					assert_eq(b1.polygon[p], b2.polygon[p], "Los vertices del poligono deben coincidir exactamente")
			
			for tx in range(32):
				for ty in range(32):
					assert_eq(chunk1.tiles[tx][ty], chunk2.tiles[tx][ty], "Las baldosas deben coincidir exactamente")


func test_get_barrier_tile_type_from_biome():
	var level := Level.new(1, 1, 32, 32, 1)
	assert_eq(level.get_barrier_tile_type_from_biome(BiomeType.ROCKS), TileType.ROCK, "El bioma ROCKS debe mapear a baldosa de barrera ROCK")
	assert_eq(level.get_barrier_tile_type_from_biome(BiomeType.WOOD), TileType.TREE, "El bioma WOOD debe mapear a baldosa de barrera TREE")
	assert_eq(level.get_barrier_tile_type_from_biome(BiomeType.WATER), TileType.WATER, "El bioma WATER debe mapear a baldosa de barrera WATER")
	assert_eq(level.get_barrier_tile_type_from_biome(BiomeType.SAND), TileType.SAND, "El bioma SAND debe mapear a baldosa de barrera SAND")
	assert_eq(level.get_barrier_tile_type_from_biome(BiomeType.GRASSLAND), TileType.ROCK, "El bioma GRASSLAND por defecto debe mapear a baldosa de barrera ROCK")

