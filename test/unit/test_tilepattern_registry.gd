extends GutTest

func test_registry_gets_values():
	var pattern_name = "Upper Left Corner (High Plateau Rocks)"
	
	var upper_left_pattern = [
		Vector2i(2, 2),
	]
	
	var tile_index = TilePatternRegistry.get_pattern_index(pattern_name)
	var tile_pattern = TilePatternRegistry.get_pattern(pattern_name)
	var tile_is_corner = TilePatternRegistry.is_corner(pattern_name)
	var tile_is_atomic = TilePatternRegistry.is_atomic(pattern_name)

	assert_not_null(tile_index)
	assert_not_null(tile_pattern)
	assert_ne(tile_pattern, [])
	assert_not_null(tile_is_corner)
	assert_not_null(tile_is_atomic)
	if tile_index != null:
		assert_eq(tile_index, 1)
	if tile_pattern != null:
		assert_eq(tile_pattern, upper_left_pattern)
		

func test_registry_has_correct_keys():
	var dict = TilePatternRegistry.dictionary
	for key in dict:
		assert_eq(dict[key].keys(), ["index", "pattern", "is_corner", "corner_type", "is_atomic"])


func test_registry_has_unique_incremental_indices():
	var indices = []
	var dict = TilePatternRegistry.dictionary
	var count = 1
	for key in dict.keys():
		var index = dict[key]["index"]
		assert_true(index not in indices)
		assert_eq(index, count)
		indices.append(index)
		count += 1
	