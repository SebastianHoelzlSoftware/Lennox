extends GutTest

func test_create_tilepattern():
	var upper_left_pattern = [
		Vector2i(0, 0),
		Vector2i(1, 0),
		Vector2i(0, 1),
		Vector2i(1, 1)
	]

	var p1 = TilePattern.new(
		"Upper Left Corner (High Plateau)",
		1,
		true,
		upper_left_pattern
	)
	 
	assert_eq(p1.name, "Upper Left Corner (High Plateau)")
	assert_eq(p1.pattern, upper_left_pattern)
