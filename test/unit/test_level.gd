# test_level.gd
extends GutTest

func test_level_initialization():
    var width := 64
    var height := 64
    var chunk_size := 32
    var tile_size := 32
    var seed := 12345

    var level := Level.new(width, height, chunk_size, tile_size, seed)

    assert_eq(level.width, width, "Level width should be 64")
    assert_eq(level.height, height, "Level height should be 64")
    assert_eq(level.chunk_size, chunk_size, "Chunk size should be 32")
    assert_eq(level.tile_size, tile_size, "Tile size should be 32")
    assert_eq(level.seed, seed, "Seed should be 12345")

func test_level_generates_chunks():
    var level := Level.new(2, 2, 32, 32, 9999)
    level.generate()
    assert_eq(level.chunks.size(), 2, "Level should have 2 chunks in x direction")
    assert_eq(level.chunks[0].size(), 2, "Each x row should have 2 chunks in y direction")
    assert_ne(level.chunks[0][0], null, "Chunk(0,0) should not be null")

func test_chunk_generation_is_deterministic():
    var level1 := Level.new(1, 1, 32, 32, 7777)
    var level2 := Level.new(1, 1, 32, 32, 7777)
    level1.generate()
    level2.generate()
    assert_eq(level1.chunks[0][0].biome, level2.chunks[0][0].biome, "Biome should be deterministic")

func test_get_chunk_returns_correct_chunk():
    var level := Level.new(3, 3, 32, 32, 5555)
    level.generate()
    var chunk := level.get_chunk(1, 2)
    assert_ne(chunk, null, "Chunk should not be null")
    assert_eq(chunk.x, 1, "Chunk x coordinate should be 1")
    assert_eq(chunk.y, 2, "Chunk y coordinate should be 2")