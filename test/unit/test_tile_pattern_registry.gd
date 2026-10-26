extends GutTest

func test_registry_gets_values():
	var pattern_name = "Upper Left Corner (High Plateau)"
	
	var upper_left_pattern = [
		Vector2i(0, 0),
		Vector2i(0, 1),
		Vector2i(1, 0),
		Vector2i(1, 1)
	]
	
	var tile_index = TilePatternRegistry.get_pattern_index(pattern_name)
	var tile_pattern = TilePatternRegistry.get_pattern(pattern_name)
	var tile_is_corner = TilePatternRegistry.is_corner(pattern_name)

	assert_not_null(tile_index)
	assert_not_null(tile_pattern)
	assert_ne(tile_pattern, [])
	assert_not_null(tile_is_corner)
	if tile_index != null:
		assert_eq(tile_index, 1)
	if tile_pattern != null:
		assert_eq(tile_pattern, upper_left_pattern)
		
