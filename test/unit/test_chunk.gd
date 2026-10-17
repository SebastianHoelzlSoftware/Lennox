extends GutTest

func test_chunk_initialization():
	var x := 5
	var y := 10

	var chunk := Chunk.new(x, y)

	assert_eq(chunk.x, x, "La coordenada X debe ser 5")
	assert_eq(chunk.y, y, "La coordenada Y debe ser 10")
	assert_eq(chunk.tiles.size(), 32, "El chunk debe tener baldosas de 32x32")
	assert_eq(chunk.tiles[0].size(), 32, "Cada fila debe tener 32 baldosas")


func test_chunk_has_default_biome():
	var chunk := Chunk.new(0, 0)

	assert_eq(chunk.biome, BiomeType.GRASSLAND, "El bioma por defecto debe ser GRASSLAND")


func test_chunk_barriers_list_is_empty():
	var chunk := Chunk.new(0, 0)

	assert_eq(chunk.barriers.size(), 0, "La lista de barreras debe estar vacia")


func test_chunk_tiles_are_empty():
	var chunk := Chunk.new(0, 0)

	for x in range(32):
		for y in range(32):
			assert_eq(chunk.tiles[x][y], TileType.GRASS, "La baldosa por defecto debe ser GRASS")


func test_chunk_add_barrier():
	var chunk := Chunk.new(0, 0)
	var polygon: Array[Vector2] = [
		Vector2(0, 0),
		Vector2(10, 0),
		Vector2(10, 10),
		Vector2(0, 10)
	]

	chunk.add_barrier(polygon)

	assert_eq(chunk.barriers.size(), 1, "La lista de barreras debe contener 1 barrera")
	assert_eq(chunk.barriers[0].polygon, polygon, "El poligono de la barrera debe coincidir")
	assert_true(chunk.is_barrier(5, 5), "El punto (5, 5) debe ser reconocido como barrera")
	assert_false(chunk.is_barrier(20, 20), "El punto (20, 20) no debe ser reconocido como barrera")


func test_apply_barriers_to_tiles_single_barrier():
	var chunk := Chunk.new(0, 0)
	chunk.biome = BiomeType.GRASSLAND
	var polygon := [
		Vector2(2, 2),
		Vector2(8, 2),
		Vector2(8, 8),
		Vector2(2, 8)
	]
	chunk.add_barrier(polygon)
	
	assert_eq(chunk.get_tile(5, 5), TileType.GRASS, "Antes de aplicar, la baldosa debe ser la predeterminada")
	chunk.apply_barriers_to_tiles()
	
	assert_eq(chunk.get_tile(5, 5), TileType.ROCK, "Dentro de la barrera debe ser baldosa ROCK")
	assert_eq(chunk.get_tile(15, 15), TileType.GRASS, "Fuera de la barrera debe permanecer GRASS")


func test_apply_barriers_to_tiles_multiple_barriers():
	var chunk := Chunk.new(0, 0)
	
	var barrier1 := Barrier.new()
	barrier1.polygon = [Vector2(2, 2), Vector2(6, 2), Vector2(6, 6), Vector2(2, 6)]
	barrier1.biome = BiomeType.WOOD
	chunk.barriers.append(barrier1)
	
	var barrier2 := Barrier.new()
	barrier2.polygon = [Vector2(12, 12), Vector2(16, 12), Vector2(16, 16), Vector2(12, 16)]
	barrier2.biome = BiomeType.ROCKS
	chunk.barriers.append(barrier2)
	
	chunk.apply_barriers_to_tiles()
	
	assert_eq(chunk.get_tile(4, 4), TileType.TREE, "La barrera 1 (WOOD) debe ser baldosa TREE")
	assert_eq(chunk.get_tile(14, 14), TileType.ROCK, "La barrera 2 (ROCKS) debe ser baldosa ROCK")
	assert_eq(chunk.get_tile(25, 25), TileType.GRASS, "La baldosa fuera debe permanecer GRASS")


func test_get_barrier_tile_type_mapping():
	var biomes = [
		{"biome": BiomeType.GRASSLAND, "expected_tile": TileType.ROCK},
		{"biome": BiomeType.WOOD, "expected_tile": TileType.TREE},
		{"biome": BiomeType.ROCKS, "expected_tile": TileType.ROCK},
		{"biome": BiomeType.WATER, "expected_tile": TileType.WATER},
		{"biome": BiomeType.SAND, "expected_tile": TileType.SAND}
	]
	
	for entry in biomes:
		var chunk := Chunk.new(0, 0)
		var barrier := Barrier.new()
		barrier.polygon = [Vector2(1, 1), Vector2(4, 1), Vector2(4, 4), Vector2(1, 4)]
		barrier.biome = entry["biome"]
		chunk.barriers.append(barrier)
		chunk.apply_barriers_to_tiles()
		assert_eq(chunk.get_tile(2, 2), entry["expected_tile"], "El bioma debe tener el tipo de baldosa de barrera esperado")


func test_get_barrier_at_single():
	var chunk := Chunk.new(0, 0)
	var polygon := [Vector2(2, 2), Vector2(8, 2), Vector2(8, 8), Vector2(2, 8)]
	chunk.add_barrier(polygon)
	
	var found_barrier := chunk.get_barrier_at(5, 5)
	assert_ne(found_barrier, null, "La barrera en el punto (5, 5) debe ser encontrada")
	assert_eq(found_barrier.polygon, polygon, "La barrera encontrada debe tener el poligono correcto")


func test_get_barrier_at_multiple():
	var chunk := Chunk.new(0, 0)
	var poly1 := [Vector2(2, 2), Vector2(6, 2), Vector2(6, 6), Vector2(2, 6)]
	var poly2 := [Vector2(12, 12), Vector2(16, 12), Vector2(16, 16), Vector2(12, 16)]
	
	chunk.add_barrier(poly1)
	chunk.add_barrier(poly2)
	
	var found1 := chunk.get_barrier_at(4, 4)
	var found2 := chunk.get_barrier_at(14, 14)
	
	assert_ne(found1, null, "La barrera 1 debe ser encontrada")
	assert_eq(found1.polygon, poly1, "Debe devolver la barrera 1")
	assert_ne(found2, null, "La barrera 2 debe ser encontrada")
	assert_eq(found2.polygon, poly2, "Debe devolver la barrera 2")


func test_get_barrier_at_none():
	var chunk := Chunk.new(0, 0)
	var polygon := [Vector2(2, 2), Vector2(6, 2), Vector2(6, 6), Vector2(2, 6)]
	chunk.add_barrier(polygon)
	
	var found := chunk.get_barrier_at(20, 20)
	assert_eq(found, null, "Fuera de las barreras get_barrier_at debe devolver null")


