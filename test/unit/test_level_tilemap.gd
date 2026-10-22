extends GutTest


func test_load_level_draws_tiles_from_tile_types():
	var tile_map := _new_tile_map()
	var level := Level.new(2, 1, 32, 32, 12345)
	level.generate()
	level.get_chunk(0, 0).set_tile(5, 6, TileType.ROCK)

	tile_map.load_level(level)

	var grass_source_ids := _get_source_ids(tile_map.tile_set, [&"gras_01", &"gras_02"])
	var rock_source_ids := _get_source_ids(tile_map.tile_set, [&"rock_01", &"rock_02"])
	assert_true(
		grass_source_ids.has(tile_map.get_cell_source_id(Vector2i(0, 0))),
		"GRASS debe usar una de las fuentes atlas de hierba"
	)
	assert_true(
		rock_source_ids.has(tile_map.get_cell_source_id(Vector2i(5, 6))),
		"ROCK debe usar una de las fuentes atlas de roca"
	)
	assert_eq(
		tile_map.get_cell_atlas_coords(Vector2i(5, 6)),
		Vector2i.ZERO,
		"Las texturas individuales deben usar la coordenada atlas (0, 0)"
	)
	assert_true(
		grass_source_ids.has(tile_map.get_cell_source_id(Vector2i(32, 0))),
		"El segundo chunk debe dibujarse desplazado por chunk_size"
	)


func test_load_level_clears_cells_from_previous_level():
	var tile_map := _new_tile_map()
	var larger_level := Level.new(2, 1, 32, 32, 12345)
	larger_level.generate()
	tile_map.load_level(larger_level)
	assert_ne(tile_map.get_cell_source_id(Vector2i(32, 0)), -1)

	var smaller_level := Level.new(1, 1, 32, 32, 54321)
	smaller_level.generate()
	tile_map.load_level(smaller_level)

	assert_eq(
		tile_map.get_cell_source_id(Vector2i(32, 0)),
		-1,
		"load_level debe borrar las celdas que no pertenecen al nuevo nivel"
	)


func _new_tile_map() -> TileMapLayer:
	var tile_map_script := load("res://scenes/level.gd") as GDScript
	var tile_map := tile_map_script.new() as TileMapLayer
	tile_map.tile_set = load("res://assets/tileset.tres") as TileSet
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
