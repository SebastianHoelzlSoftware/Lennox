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
	var furthest_object_distance := 0.0
	var placed_atlas_coords: Dictionary = {}
	for cell: Vector2i in object_cells:
		var chunk_position: Vector2i = cell / generated_level.chunk_size
		var local_cell := cell % generated_level.chunk_size
		var chunk := generated_level.get_chunk(chunk_position.x, chunk_position.y)
		assert_eq(chunk.get_tile(local_cell.x, local_cell.y), TileType.GRASS)
		furthest_object_distance = maxf(
			furthest_object_distance,
			Vector2(cell).distance_to(Vector2(main.start_cell))
		)
		var source := object_tilemap.tile_set.get_source(
			object_tilemap.get_cell_source_id(cell)
		)
		assert_eq(StringName(source.resource_name), &"Objects")
		placed_atlas_coords[object_tilemap.get_cell_atlas_coords(cell)] = true
	assert_gt(furthest_object_distance, 25.0)
	assert_lt(furthest_object_distance, 42.0)

	var library := load("res://assets/tiles/rocks/tile_object_library.tres") as TileObjectLibrary
	for decoration: Dictionary in main.GRASSLAND_DECORATIONS:
		var pattern := library.get_pattern(StringName(decoration["pattern"]))
		var expected_coords: Array[Vector2i] = pattern.atlas_coords.duplicate()
		if not pattern.cells.is_empty():
			expected_coords.clear()
			for object_cell: TileObjectCell in pattern.cells:
				expected_coords.append(object_cell.atlas_coords)
		for atlas_coords: Vector2i in expected_coords:
			assert_true(
				placed_atlas_coords.has(atlas_coords),
				"Decoration %s must be placed." % pattern.pattern_name
			)
