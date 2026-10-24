extends GutTest


func test_main_scene_starts_in_decorated_grass_biome():
	var scene := load("res://scenes/main.tscn") as PackedScene
	var main := scene.instantiate() as Node2D
	add_child(main)
	autofree(main)
	await get_tree().process_frame

	var object_tilemap := main.get_node("ObjectTileMap") as TileMapLayer
	var player := main.get_node("CharacterBody2D") as CharacterBody2D
	var level_tilemap := main.get_node("LevelTileMap") as TileMapLayer
	var start_chunk: Vector2i = main.start_cell / 32
	var object_cells := object_tilemap.get_used_cells()
	assert_false(main.start_biome_chunks.is_empty())
	assert_eq(main.start_biome_type, BiomeType.GRASSLAND)
	assert_true(main.start_biome_chunks.has(start_chunk))
	assert_gt(object_cells.size(), 200)
	assert_eq(level_tilemap.local_to_map(player.position), main.start_cell)
	var ground_source := level_tilemap.tile_set.get_source(
		level_tilemap.get_cell_source_id(main.start_cell)
	) as TileSetAtlasSource
	var start_tile_data := ground_source.get_tile_data(
		level_tilemap.get_cell_atlas_coords(main.start_cell),
		0
	)
	assert_eq(start_tile_data.get_collision_polygons_count(0), 0)
	var generated_level := Level.new(12, 12, 32, 16, 12345)
	generated_level.generate()
	var grassland_chunks: Dictionary = {}
	var decorated_chunks: Dictionary = {}
	var placed_atlas_coords: Dictionary = {}
	for chunk_x in range(generated_level.width):
		for chunk_y in range(generated_level.height):
			if generated_level.biome_map[chunk_x][chunk_y] == BiomeType.GRASSLAND:
				grassland_chunks[Vector2i(chunk_x, chunk_y)] = true

	for cell: Vector2i in object_cells:
		var chunk_position: Vector2i = cell / generated_level.chunk_size
		var local_cell := cell % generated_level.chunk_size
		var chunk := generated_level.get_chunk(chunk_position.x, chunk_position.y)
		assert_eq(chunk.biome, BiomeType.GRASSLAND)
		assert_eq(chunk.get_tile(local_cell.x, local_cell.y), TileType.GRASS)
		decorated_chunks[chunk_position] = true
		var source := object_tilemap.tile_set.get_source(
			object_tilemap.get_cell_source_id(cell)
		)
		assert_eq(StringName(source.resource_name), &"Objects")
		placed_atlas_coords[object_tilemap.get_cell_atlas_coords(cell)] = true
		assert_false(
			absi(cell.x - main.start_cell.x) <= 2 and absi(cell.y - main.start_cell.y) <= 2,
			"Keep a small clear space around the player spawn."
		)
	assert_eq(decorated_chunks.size(), grassland_chunks.size())
	assert_gt(placed_atlas_coords.size(), 20)
