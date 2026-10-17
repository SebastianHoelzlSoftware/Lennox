extends GutTest


func test_barrier_with_polygon():
	var polygon := [Vector2(0, 0), Vector2(10, 0), Vector2(10, 10), Vector2(0, 10)]
	
	var barrier := Barrier.new()
	barrier.polygon = polygon
	barrier.biome = BiomeType.ROCKS
	
	assert_eq(barrier.polygon.size(), 4, "El poligono debe tener 4 puntos")
	assert_true(barrier.contains_point(Vector2(5, 5)), "El punto (5,5) debe estar en la barrera")
	assert_false(barrier.contains_point(Vector2(20, 20)), "El punto (20,20) no debe estar en la barrera")


func test_barrier_with_biome():
	var barrier := Barrier.new()
	barrier.biome = BiomeType.ROCKS
	
	assert_eq(barrier.biome, BiomeType.ROCKS, "El bioma debe ser ROCKS")


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
	var opening := Opening.new(Opening.OpeningType.PASS, Vector2(5, 5), 3, false, BiomeType.ROCKS)
	
	barrier.add_opening(opening)
	
	assert_eq(barrier.openings.size(), 1, "La barrera debe tener 1 apertura")
	assert_eq(barrier.openings[0].type, Opening.OpeningType.PASS, "El tipo de apertura debe ser PASS")


func test_barrier_with_interactive_opening():
	var barrier := Barrier.new()
	var opening := Opening.new(Opening.OpeningType.DOOR, Vector2(5, 5), 1, true, BiomeType.WOOD)
	
	barrier.add_opening(opening)
	
	assert_true(barrier.has_interactive_openings(), "La barrera debe tener apertura interactiva")


func test_barrier_without_interactive_openings():
	var barrier := Barrier.new()
	var opening := Opening.new(Opening.OpeningType.PASS, Vector2(5, 5), 3, false, BiomeType.ROCKS)
	
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
	
	var opening := Opening.new(Opening.OpeningType.PASS, Vector2(5, 5), 3, false, BiomeType.ROCKS)
	barrier.add_opening(opening)
	
	assert_false(barrier.contains_point(Vector2(5, 5)), "El punto en la apertura no debe estar en la barrera")
	assert_false(barrier.contains_point(Vector2(4, 5)), "El punto en la apertura no debe estar en la barrera")
	assert_false(barrier.contains_point(Vector2(6, 5)), "El punto en la apertura no debe estar en la barrera")
	
	assert_true(barrier.contains_point(Vector2(2, 5)), "El punto fuera de la apertura debe estar en la barrera")


func test_opening_open_close():
	var opening := Opening.new(Opening.OpeningType.DOOR, Vector2(5, 5), 1, true, BiomeType.WOOD)
	
	assert_false(opening.is_open, "La puerta debe estar cerrada inicialmente")
	assert_false(opening.is_passable(), "La puerta cerrada no debe ser transitable")
	
	opening.open()
	assert_true(opening.is_open, "La puerta debe estar abierta")
	assert_true(opening.is_passable(), "La puerta abierta debe ser transitable")
	
	opening.close()
	assert_false(opening.is_open, "La puerta debe estar cerrada de nuevo")
	assert_false(opening.is_passable(), "La puerta cerrada no debe ser transitable")


func test_non_interactive_opening_always_passable():
	var opening := Opening.new(Opening.OpeningType.PASS, Vector2(5, 5), 3, false, BiomeType.ROCKS)
	
	assert_true(opening.is_passable(), "La apertura no interactiva siempre debe ser transitable")
	
	opening.open()
	assert_true(opening.is_passable(), "La apertura no interactiva sigue siendo transitable")


func test_get_passable_points_basic():
	var barrier := Barrier.new()
	var opening := Opening.new(Opening.OpeningType.PASS, Vector2(10, 5), 2, false, BiomeType.ROCKS)
	barrier.add_opening(opening)
	
	var points := barrier.get_passable_points(32)
	assert_eq(points.size(), 3, "Se deben generar 3 puntos transitables")
	assert_has(points, Vector2(9, 5), "El punto (9, 5) debe estar incluido")
	assert_has(points, Vector2(10, 5), "El punto (10, 5) debe estar incluido")
	assert_has(points, Vector2(11, 5), "El punto (11, 5) debe estar incluido")


func test_get_passable_points_with_chunk_size():
	var barrier := Barrier.new()
	var opening_left := Opening.new(Opening.OpeningType.PASS, Vector2(0, 5), 3, false, BiomeType.ROCKS)
	barrier.add_opening(opening_left)
	
	var opening_right := Opening.new(Opening.OpeningType.PASS, Vector2(31, 5), 3, false, BiomeType.ROCKS)
	barrier.add_opening(opening_right)
	
	var points := barrier.get_passable_points(32)
	for pt in points:
		assert_true(pt.x >= 0 and pt.x < 32, "El punto X debe estar dentro de [0, 31]")
		assert_true(pt.y >= 0 and pt.y < 32, "El punto Y debe estar dentro de [0, 31]")
	
	var small_points := barrier.get_passable_points(10)
	for pt in small_points:
		assert_true(pt.x >= 0 and pt.x < 10, "El punto X debe estar dentro de [0, 9] con chunk_size=10")


func test_point_in_interactive_opening_respects_open_state():
	var barrier := Barrier.new()
	barrier.polygon = [
		Vector2(0, 0),
		Vector2(10, 0),
		Vector2(10, 10),
		Vector2(0, 10)
	]
	var door := Opening.new(Opening.OpeningType.DOOR, Vector2(5, 5), 2, true, BiomeType.WOOD)
	barrier.add_opening(door)
	
	assert_false(door.is_passable(), "La puerta cerrada no debe ser transitable")
	assert_true(barrier.contains_point(Vector2(5, 5)), "Con la puerta cerrada el punto debe estar dentro de la barrera")
	
	door.open()
	assert_true(door.is_passable(), "La puerta abierta debe ser transitable")
	assert_false(barrier.contains_point(Vector2(5, 5)), "Con la puerta abierta el punto no debe estar dentro de la barrera")
	
	door.close()
	assert_false(door.is_passable(), "La puerta cerrada de nuevo no debe ser transitable")
	assert_true(barrier.contains_point(Vector2(5, 5)), "Despues de cerrar el punto debe volver a estar dentro de la barrera")

