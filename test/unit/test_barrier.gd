extends GutTest


func test_barrier_with_polygon():
	var polygon := [Vector2(0, 0), Vector2(10, 0), Vector2(10, 10), Vector2(0, 10)]
	
	var barrier := Barrier.new()
	barrier.polygon = polygon
	
	assert_eq(barrier.polygon.size(), 4, "El poligono debe tener 4 puntos")
	assert_true(barrier.contains_point(Vector2(5, 5)), "El punto (5,5) debe estar en la barrera")
	assert_false(barrier.contains_point(Vector2(20, 20)), "El punto (20,20) no debe estar en la barrera")


func test_barrier_with_biome():
	var barrier := Barrier.new()
	barrier.biome = "Rocks"
	
	assert_eq(barrier.biome, "Rocks", "El bioma debe ser Rocks")


func test_point_in_polygon_ray_casting():
	var polygon := [
		Vector2(0, 0),
		Vector2(10, 0),
		Vector2(10, 10),
		Vector2(0, 10)
	]
	
	var barrier := Barrier.new()
	barrier.polygon = polygon
	
	assert_true(barrier.contains_point(Vector2(5, 5)), "El punto (5,5) debe estar dentro")
	assert_true(barrier.contains_point(Vector2(1, 1)), "El punto (1,1) debe estar dentro")
	assert_true(barrier.contains_point(Vector2(9, 9)), "El punto (9,9) debe estar dentro")
	
	assert_false(barrier.contains_point(Vector2(15, 5)), "El punto (15,5) debe estar fuera")
	assert_false(barrier.contains_point(Vector2(5, 15)), "El punto (5,15) debe estar fuera")
	assert_false(barrier.contains_point(Vector2(-1, 5)), "El punto (-1,5) debe estar fuera")


func test_point_on_edge():
	var polygon := [
		Vector2(0, 0),
		Vector2(10, 0),
		Vector2(10, 10),
		Vector2(0, 10)
	]
	
	var barrier := Barrier.new()
	barrier.polygon = polygon
	
	assert_true(barrier.contains_point(Vector2(5, 0)), "El punto en el borde debe estar dentro")
	assert_true(barrier.contains_point(Vector2(0, 5)), "El punto en el borde debe estar dentro")


func test_polygon_closed():
	var closed_polygon := [
		Vector2(0, 0),
		Vector2(10, 0),
		Vector2(10, 10),
		Vector2(0, 10),
		Vector2(0, 0)
	]
	
	var barrier := Barrier.new()
	barrier.polygon = closed_polygon
	
	assert_true(barrier.is_polygon_closed(), "El poligono cerrado debe ser reconocido")


func test_polygon_not_closed():
	var open_polygon := [
		Vector2(0, 0),
		Vector2(10, 0),
		Vector2(10, 10),
		Vector2(0, 10)
	]
	
	var barrier := Barrier.new()
	barrier.polygon = open_polygon
	
	assert_false(barrier.is_polygon_closed(), "El poligono abierto debe ser reconocido")


func test_barrier_with_opening():
	var barrier := Barrier.new()
	var opening := Opening.new(Opening.OpeningType.PASS, Vector2(5, 5), 3, false, "Rocks")
	
	barrier.add_opening(opening)
	
	assert_eq(barrier.openings.size(), 1, "La barrera debe tener 1 apertura")
	assert_eq(barrier.openings[0].type, Opening.OpeningType.PASS, "El tipo de apertura debe ser PASS")


func test_barrier_with_interactive_opening():
	var barrier := Barrier.new()
	var opening := Opening.new(Opening.OpeningType.DOOR, Vector2(5, 5), 1, true, "Wood")
	
	barrier.add_opening(opening)
	
	assert_true(barrier.has_interactive_openings(), "La barrera debe tener apertura interactiva")


func test_barrier_without_interactive_openings():
	var barrier := Barrier.new()
	var opening := Opening.new(Opening.OpeningType.PASS, Vector2(5, 5), 3, false, "Rocks")
	
	barrier.add_opening(opening)
	
	assert_false(barrier.has_interactive_openings(), "La barrera no debe tener aperturas interactivas")


func test_point_in_opening_not_in_barrier():
	var barrier := Barrier.new()
	barrier.polygon = [
		Vector2(0, 0),
		Vector2(10, 0),
		Vector2(10, 10),
		Vector2(0, 10)
	]
	
	var opening := Opening.new(Opening.OpeningType.PASS, Vector2(5, 5), 3, false, "Rocks")
	barrier.add_opening(opening)
	
	assert_false(barrier.contains_point(Vector2(5, 5)), "El punto en la apertura no debe estar en la barrera")
	assert_false(barrier.contains_point(Vector2(4, 5)), "El punto en la apertura no debe estar en la barrera")
	assert_false(barrier.contains_point(Vector2(6, 5)), "El punto en la apertura no debe estar en la barrera")
	
	assert_true(barrier.contains_point(Vector2(2, 5)), "El punto fuera de la apertura debe estar en la barrera")


func test_opening_open_close():
	var opening := Opening.new(Opening.OpeningType.DOOR, Vector2(5, 5), 1, true, "Wood")
	
	assert_false(opening.is_open, "La puerta debe estar cerrada inicialmente")
	assert_false(opening.is_passable(), "La puerta cerrada no debe ser transitable")
	
	opening.open()
	assert_true(opening.is_open, "La puerta debe estar abierta")
	assert_true(opening.is_passable(), "La puerta abierta debe ser transitable")
	
	opening.close()
	assert_false(opening.is_open, "La puerta debe estar cerrada de nuevo")
	assert_false(opening.is_passable(), "La puerta cerrada no debe ser transitable")


func test_non_interactive_opening_always_passable():
	var opening := Opening.new(Opening.OpeningType.PASS, Vector2(5, 5), 3, false, "Rocks")
	
	assert_true(opening.is_passable(), "La apertura no interactiva siempre debe ser transitable")
	
	opening.open()
	assert_true(opening.is_passable(), "La apertura no interactiva sigue siendo transitable")
