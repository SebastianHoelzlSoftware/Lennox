extends GutTest


func test_named_rock_barrier_variants_load_and_render():
	var library := load("res://assets/tiles/rocks/tile_object_library.tres") as TileObjectLibrary
	var tile_map := _new_tile_map()

	assert_not_null(library)
	var pattern := library.get_pattern(&"rock_barrier")
	assert_not_null(pattern)
	assert_eq(pattern.variants.size(), 6)

	var occupied: Dictionary = {}
	assert_true(pattern.try_place(tile_map, Vector2i(2, 2), Vector2i(10, 10), occupied))
	assert_true(occupied.has(Vector2i(2, 2)))
	var placed_coords := tile_map.get_cell_atlas_coords(Vector2i(2, 2))
	var matches_variant := false
	for variant: TileObjectCell in pattern.variants:
		if variant.atlas_source_name == &"Ground_rocks" and variant.atlas_coords == placed_coords:
			matches_variant = true
			break
	assert_true(matches_variant)


func test_object_pattern_rejects_overlapping_or_out_of_bounds_placement():
	var library := load("res://assets/tiles/rocks/tile_object_library.tres") as TileObjectLibrary
	var pattern := library.get_pattern(&"rock_barrier")
	var tile_map := _new_tile_map()
	var occupied: Dictionary = {Vector2i(3, 3): true}

	assert_false(pattern.try_place(tile_map, Vector2i(3, 3), Vector2i(10, 10), occupied))
	assert_false(pattern.try_place(tile_map, Vector2i(10, 3), Vector2i(10, 10), occupied))
	assert_eq(tile_map.get_cell_source_id(Vector2i(3, 3)), -1)


func test_object_pattern_places_all_cells_and_marks_its_footprint():
	var pattern := TileObjectPattern.new()
	pattern.pattern_name = &"test_two_cell_object"
	pattern.footprint = [Vector2i.ZERO, Vector2i.RIGHT]
	pattern.cells = [
		_new_object_cell(Vector2i(8, 3), Vector2i.ZERO),
		_new_object_cell(Vector2i(9, 3), Vector2i.RIGHT),
	]
	var tile_map := _new_tile_map()
	var occupied: Dictionary = {}

	assert_true(pattern.try_place(tile_map, Vector2i(4, 5), Vector2i(10, 10), occupied))
	assert_ne(tile_map.get_cell_source_id(Vector2i(4, 5)), -1)
	assert_ne(tile_map.get_cell_source_id(Vector2i(5, 5)), -1)
	assert_true(occupied.has(Vector2i(4, 5)))
	assert_true(occupied.has(Vector2i(5, 5)))


func test_saved_multicell_pattern_uses_object_atlas_cells():
	var library := load("res://assets/tiles/rocks/tile_object_library.tres") as TileObjectLibrary
	var pattern := library.get_pattern(&"bone_fragment")
	var tile_map := _new_tile_map()
	var occupied: Dictionary = {}
	var terrain := {
		Vector2i(4, 5): TileType.GRASS,
		Vector2i(5, 5): TileType.GRASS,
		Vector2i(4, 6): TileType.GRASS,
		Vector2i(5, 6): TileType.GRASS,
		Vector2i(4, 7): TileType.GRASS,
		Vector2i(5, 7): TileType.GRASS,
	}

	assert_not_null(pattern)
	assert_eq(pattern.cells.size(), 6)
	assert_true(
		pattern.try_place(tile_map, Vector2i(4, 5), Vector2i(10, 10), occupied, terrain)
	)
	assert_ne(tile_map.get_cell_source_id(Vector2i(4, 5)), -1)
	assert_ne(tile_map.get_cell_source_id(Vector2i(5, 7)), -1)
	assert_eq(occupied.size(), 6)


func test_object_pattern_checks_all_footprint_cells_against_terrain():
	var pattern := TileObjectPattern.new()
	pattern.pattern_name = &"grassland_object"
	pattern.footprint = [Vector2i.ZERO, Vector2i.RIGHT]
	pattern.allowed_terrain_types = [TileType.GRASS]
	var tile_map := _new_tile_map()
	var occupied: Dictionary = {}
	var terrain := {
		Vector2i(1, 1): TileType.GRASS,
		Vector2i(2, 1): TileType.SAND,
	}

	assert_false(
		pattern.try_place(
			tile_map,
			Vector2i(1, 1),
			Vector2i(10, 10),
			occupied,
			terrain
		)
	)
	assert_true(occupied.is_empty())


func _new_tile_map() -> TileMapLayer:
	var tile_map := TileMapLayer.new()
	tile_map.tile_set = load("res://assets/tiles/rocks/rocks_16x16.tres") as TileSet
	autofree(tile_map)
	return tile_map


func _new_object_cell(p_atlas_coords: Vector2i, p_local_position: Vector2i) -> TileObjectCell:
	var object_cell := TileObjectCell.new()
	object_cell.atlas_source_name = &"Ground_rocks"
	object_cell.atlas_coords = p_atlas_coords
	object_cell.local_position = p_local_position
	return object_cell
