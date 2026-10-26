extends GutTest

func test_create_tilepattern():
	var upper_left_pattern = [
		Vector2i(2, 2),
	]

	var p1 = TilePattern.new(
		"Upper Left Corner (High Plateau)",
		1,
		true,
		true,
		upper_left_pattern
	)
	 
	assert_eq(p1.name, "Upper Left Corner (High Plateau)")
	assert_eq(p1.pattern, upper_left_pattern)
