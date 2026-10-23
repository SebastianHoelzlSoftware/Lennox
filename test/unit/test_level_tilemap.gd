extends GutTest


func test_load_level_draws_tiles_from_tile_types():
	var tile_map := _new_tile_map()
	var level := Level.new(2, 1, 32, 16, 12345)
	level.generate()
	var first_chunk := level.get_chunk(0, 0)
	first_chunk.set_tile(0, 0, TileType.GRASS)
	first_chunk.set_tile(5, 6, TileType.ROCK)

	tile_map.load_level(level)

	var ground_source_id := _get_source_ids(tile_map.tile_set, [&"Ground_rocks"])[0]
	var ground_source := tile_map.tile_set.get_source(ground_source_id) as TileSetAtlasSource
	var grass_coords := tile_map.get_cell_atlas_coords(Vector2i(0, 0))
	var rock_coords := tile_map.get_cell_atlas_coords(Vector2i(5, 6))
	assert_eq(tile_map.tile_set.tile_size, Vector2i(16, 16))
	assert_eq(tile_map.get_cell_source_id(Vector2i(0, 0)), ground_source_id)
	assert_eq(tile_map.get_cell_source_id(Vector2i(5, 6)), ground_source_id)
	assert_true(ground_source.has_tile(grass_coords), "GRASS debe usar una baldosa valida de roca")
	assert_true(ground_source.has_tile(rock_coords), "ROCK debe usar una baldosa valida de roca")
	assert_ne(grass_coords, rock_coords, "El suelo y las barreras deben tener aspecto distinto")
	var floor_data := ground_source.get_tile_data(grass_coords, 0)
	var wall_data := ground_source.get_tile_data(rock_coords, 0)
	assert_eq(floor_data.get_collision_polygons_count(0), 0, "El suelo debe seguir siendo transitable")
	assert_gt(wall_data.get_collision_polygons_count(0), 0, "Las paredes de roca deben bloquear el paso")
	assert_true(
		ground_source_id == tile_map.get_cell_source_id(Vector2i(32, 0)),
		"El segundo chunk debe dibujarse desplazado por chunk_size"
	)


func test_load_level_clears_cells_from_previous_level():
	var tile_map := _new_tile_map()
	var larger_level := Level.new(2, 1, 32, 16, 12345)
	larger_level.generate()
	tile_map.load_level(larger_level)
	assert_ne(tile_map.get_cell_source_id(Vector2i(32, 0)), -1)

	var smaller_level := Level.new(1, 1, 32, 16, 54321)
	smaller_level.generate()
	tile_map.load_level(smaller_level)

	assert_eq(
		tile_map.get_cell_source_id(Vector2i(32, 0)),
		-1,
		"load_level debe borrar las celdas que no pertenecen al nuevo nivel"
	)


func test_per_sheet_rock_tilesets_use_16px_atlases():
	var atlas_names := [
		"details",
		"Ground_rocks",
		"Objects",
		"Objects_animated",
		"Objects_animated2",
		"Objects_animated3",
		"water_coasts",
		"water_detilazation",
		"water_detilazation_v2",
	]

	for atlas_name in atlas_names:
		var path := "res://assets/tiles/rocks/tilesets/%s_tileset.tres" % atlas_name
		var atlas_tileset := load(path) as TileSet
		assert_not_null(atlas_tileset, "Debe existir el TileSet de %s" % atlas_name)
		if atlas_tileset == null:
			continue

		assert_eq(atlas_tileset.tile_size, Vector2i(16, 16), atlas_name)
		assert_eq(atlas_tileset.get_source_count(), 1, atlas_name)
		var source_id := atlas_tileset.get_source_id(0)
		var source := atlas_tileset.get_source(source_id) as TileSetAtlasSource
		assert_not_null(source, "El TileSet de %s debe usar un atlas" % atlas_name)
		if source != null:
			assert_eq(source.texture_region_size, Vector2i(16, 16), atlas_name)


func _new_tile_map() -> TileMapLayer:
	var tile_map_script := load("res://scenes/level.gd") as GDScript
	var tile_map := tile_map_script.new() as TileMapLayer
	tile_map.tile_set = load("res://assets/tiles/rocks/rocks_16x16.tres") as TileSet
	autofree(tile_map)
	return tile_map


func _get_source_ids(p_tile_set: TileSet, p_names: Array[StringName]) -> Array[int]:
	var source_ids: Array[int] = []
	for source_index in range(p_tile_set.get_source_count()):
		var source_id := p_tile_set.get_source_id(source_index)
		var source: TileSetSource = p_tile_set.get_source(source_id)
		if StringName(source.resource_name) in p_names:
			source_ids.append(source_id)
	return source_ids
