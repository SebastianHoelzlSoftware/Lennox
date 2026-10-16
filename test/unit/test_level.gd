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
