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

	assert_eq(chunk.biome, Level.BiomeType.GRASSLAND, "El bioma por defecto debe ser GRASSLAND")


func test_chunk_barriers_list_is_empty():
	var chunk := Chunk.new(0, 0)

	assert_eq(chunk.barriers.size(), 0, "La lista de barreras debe estar vacia")


func test_chunk_tiles_are_empty():
	var chunk := Chunk.new(0, 0)

	for x in range(32):
		for y in range(32):
			assert_eq(chunk.tiles[x][y], Level.TileType.GRASS, "La baldosa por defecto debe ser GRASS")


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
