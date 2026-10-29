extends GutTest

const CliffAutotiler = preload("res://src/core/cliff_autotiler.gd")
const PieceType = CliffAutotiler.PieceType


func test_all_pattern_names_exist_in_registry():
	var all_biomes = [
		BiomeType.Type.ROCKS,
		BiomeType.Type.GRASSLAND,
		BiomeType.Type.FOREST,
		BiomeType.Type.DESERT,
		BiomeType.Type.CAVE,
		BiomeType.Type.SWAMP,
		BiomeType.Type.SEABED,
		BiomeType.Type.ROCKS_AND_WATER
	]
	var pieces = [
		PieceType.UPPER_LEFT_CORNER,
		PieceType.UPPER_RIGHT_CORNER,
		PieceType.LOWER_LEFT_CORNER,
		PieceType.LOWER_RIGHT_CORNER,
		PieceType.TOP_EDGE,
		PieceType.BOTTOM_EDGE,
		PieceType.LEFT_EDGE,
		PieceType.RIGHT_EDGE,
		PieceType.CENTER_FILL
	]

	for biome_val in all_biomes:
		for piece_val in pieces:
			var pat_name := CliffAutotiler.get_pattern_name(piece_val, biome_val)
			assert_ne(pat_name, "", "Pattern name should not be empty")
			assert_true(
				TilePatternRegistry.dictionary.has(pat_name),
				"Pattern '%s' must exist in TilePatternRegistry.dictionary" % pat_name
			)


func test_determine_corners():
	var is_in_3x3 := func(c: int, r: int) -> bool:
		return c >= 0 and c < 3 and r >= 0 and r < 3

	# Corners
	assert_eq(CliffAutotiler.determine_piece_type(0, 0, is_in_3x3), PieceType.UPPER_LEFT_CORNER)
	assert_eq(CliffAutotiler.determine_piece_type(2, 0, is_in_3x3), PieceType.UPPER_RIGHT_CORNER)
	assert_eq(CliffAutotiler.determine_piece_type(0, 2, is_in_3x3), PieceType.LOWER_LEFT_CORNER)
	assert_eq(CliffAutotiler.determine_piece_type(2, 2, is_in_3x3), PieceType.LOWER_RIGHT_CORNER)


func test_determine_edges_and_center():
	var is_in_3x3 := func(c: int, r: int) -> bool:
		return c >= 0 and c < 3 and r >= 0 and r < 3

	# Edges
	assert_eq(CliffAutotiler.determine_piece_type(1, 0, is_in_3x3), PieceType.TOP_EDGE)
	assert_eq(CliffAutotiler.determine_piece_type(1, 2, is_in_3x3), PieceType.BOTTOM_EDGE)
	assert_eq(CliffAutotiler.determine_piece_type(0, 1, is_in_3x3), PieceType.LEFT_EDGE)
	assert_eq(CliffAutotiler.determine_piece_type(2, 1, is_in_3x3), PieceType.RIGHT_EDGE)

	# Center
	assert_eq(CliffAutotiler.determine_piece_type(1, 1, is_in_3x3), PieceType.CENTER_FILL)


func test_determine_isolated():
	var single_cell := func(c: int, r: int) -> bool:
		return c == 0 and r == 0

	assert_eq(CliffAutotiler.determine_piece_type(0, 0, single_cell), PieceType.ISOLATED)


func test_draw_plateau_rect_on_tilemap():
	var scene := load("res://scenes/main.tscn") as PackedScene
	var main := scene.instantiate() as Node2D
	add_child(main)
	autofree(main)
	await get_tree().process_frame

	var level_tilemap := main.get_node("LevelTileMap") as TileMapLayer
	var tile_mapper := TileMapper.new(level_tilemap)
	var origin := Vector2i(20, 20)

	# Draw a 3x3 macro cell plateau (6x6 tiles)
	CliffAutotiler.draw_plateau_rect(tile_mapper, origin, 3, 3)

	# Verify top-left cell has the expected atlas coords from Upper Left Corner
	var expected_ul_coords: Vector2i = TilePatternRegistry.dictionary["Upper Left Corner (High Plateau Rocks)"]["atlas_coords"][0]
	var actual_ul_coords := level_tilemap.get_cell_atlas_coords(origin)
	assert_eq(actual_ul_coords, expected_ul_coords, "Top-left tile should match Upper Left Corner")

	# Verify top-right cell at origin + (2 * 2, 0)
	var expected_ur_coords: Vector2i = TilePatternRegistry.dictionary["Upper Right Corner (High Plateau Rocks)"]["atlas_coords"][0]
	var actual_ur_coords := level_tilemap.get_cell_atlas_coords(origin + Vector2i(4, 0))
	assert_eq(actual_ur_coords, expected_ur_coords, "Top-right tile should match Upper Right Corner")


func test_draw_plateau_cells_on_tilemap():
	var scene := load("res://scenes/main.tscn") as PackedScene
	var main := scene.instantiate() as Node2D
	add_child(main)
	autofree(main)
	await get_tree().process_frame

	var level_tilemap := main.get_node("LevelTileMap") as TileMapLayer
	var tile_mapper := TileMapper.new(level_tilemap)
	var origin := Vector2i(40, 40)

	var cells: Array[Vector2i] = [
		Vector2i(0, 0), Vector2i(1, 0),
		Vector2i(0, 1), Vector2i(1, 1),
	]
	CliffAutotiler.draw_plateau_cells(tile_mapper, origin, cells)

	var expected_ul_coords: Vector2i = TilePatternRegistry.dictionary["Upper Left Corner (High Plateau Rocks)"]["atlas_coords"][0]
	var actual_ul_coords := level_tilemap.get_cell_atlas_coords(origin)
	assert_eq(actual_ul_coords, expected_ul_coords, "Top-left cell should match Upper Left Corner")


func test_draw_plateau_cells_with_solid_override_spanning_chunks():
	# Test that when is_solid_override reports an east neighbor (16, 0) is solid across chunk border,
	# cell (15, 0) with a west neighbor (14, 0) evaluates to TOP_EDGE instead of UPPER_RIGHT_CORNER
	var without_override := func(c: int, r: int) -> bool:
		# Without chunk spanning, only within-chunk cells (14, y) and (15, y) are known
		return (c == 14 or c == 15) and (r == 0 or r == 1)

	var with_override := func(c: int, r: int) -> bool:
		# With chunk spanning, neighbor cell (16, y) in adjacent chunk is also visible
		return (c == 14 or c == 15 or c == 16) and (r == 0 or r == 1)

	var piece_isolated_chunk := CliffAutotiler.determine_piece_type(15, 0, without_override)
	assert_eq(piece_isolated_chunk, PieceType.UPPER_RIGHT_CORNER, "Without override, border cell is UPPER_RIGHT_CORNER")

	var piece_spanning_chunk := CliffAutotiler.determine_piece_type(15, 0, with_override)
	assert_eq(piece_spanning_chunk, PieceType.TOP_EDGE, "With override, continuous border cell continues as TOP_EDGE")
