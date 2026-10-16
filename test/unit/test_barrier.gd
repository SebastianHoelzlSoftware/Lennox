# test_barrier.gd
extends GutTest

# --- TEST 1: Barriere mit Polygon erstellen ---
func test_barrier_with_polygon():
	# Arrange
	var polygon := [Vector2(0, 0), Vector2(10, 0), Vector2(10, 10), Vector2(0, 10)]
	
	# Act
	var barrier := Barrier.new()
	barrier.polygon = polygon
	
	# Assert
	assert_eq(barrier.polygon.size(), 4, "Polygon sollte 4 Punkte haben")
	assert_true(barrier.contains_point(Vector2(5, 5)), "Punkt (5,5) sollte in der Barriere sein")
	assert_false(barrier.contains_point(Vector2(20, 20)), "Punkt (20,20) sollte nicht in der Barriere sein")


# --- TEST 2: Barriere mit Biom ---
func test_barrier_with_biome():
	# Arrange & Act
	var barrier := Barrier.new()
	barrier.biome = "Fels"
	
	# Assert
	assert_eq(barrier.biome, "Fels", "Biom sollte Fels sein")


# --- TEST 3: Punkt-in-Polygon-Test (Ray-Casting) ---
func test_point_in_polygon_ray_casting():
	# Arrange: Quadratisches Polygon
	var polygon := [
		Vector2(0, 0),
		Vector2(10, 0),
		Vector2(10, 10),
		Vector2(0, 10)
	]
	
	# Act
	var barrier := Barrier.new()
	barrier.polygon = polygon
	
	# Assert: Punkte innerhalb
	assert_true(barrier.contains_point(Vector2(5, 5)), "Punkt (5,5) sollte innerhalb sein")
	assert_true(barrier.contains_point(Vector2(1, 1)), "Punkt (1,1) sollte innerhalb sein")
	assert_true(barrier.contains_point(Vector2(9, 9)), "Punkt (9,9) sollte innerhalb sein")
	
	# Assert: Punkte außerhalb
	assert_false(barrier.contains_point(Vector2(15, 5)), "Punkt (15,5) sollte außerhalb sein")
	assert_false(barrier.contains_point(Vector2(5, 15)), "Punkt (5,15) sollte außerhalb sein")
	assert_false(barrier.contains_point(Vector2(-1, 5)), "Punkt (-1,5) sollte außerhalb sein")


# --- TEST 4: Punkt auf der Kante ---
func test_point_on_edge():
	# Arrange: Polygon mit Kante von (0,0) bis (10,0)
	var polygon := [
		Vector2(0, 0),
		Vector2(10, 0),
		Vector2(10, 10),
		Vector2(0, 10)
	]
	
	# Act
	var barrier := Barrier.new()
	barrier.polygon = polygon
	
	# Assert: Punkte auf der Kante gelten als innerhalb
	assert_true(barrier.contains_point(Vector2(5, 0)), "Punkt auf der Kante sollte innerhalb sein")
	assert_true(barrier.contains_point(Vector2(0, 5)), "Punkt auf der Kante sollte innerhalb sein")


# --- TEST 5: Polygon geschlossen ---
func test_polygon_closed():
	# Arrange: Geschlossenes Polygon (erster = letzter Punkt)
	var closed_polygon := [
		Vector2(0, 0),
		Vector2(10, 0),
		Vector2(10, 10),
		Vector2(0, 10),
		Vector2(0, 0)
	]
	
	# Act
	var barrier := Barrier.new()
	barrier.polygon = closed_polygon
	
	# Assert
	assert_true(barrier.is_polygon_closed(), "Geschlossenes Polygon sollte erkannt werden")


# --- TEST 6: Polygon nicht geschlossen ---
func test_polygon_not_closed():
	# Arrange: Nicht geschlossenes Polygon
	var open_polygon := [
		Vector2(0, 0),
		Vector2(10, 0),
		Vector2(10, 10),
		Vector2(0, 10)
	]
	
	# Act
	var barrier := Barrier.new()
	barrier.polygon = open_polygon
	
	# Assert
	assert_false(barrier.is_polygon_closed(), "Offenes Polygon sollte erkannt werden")


# --- TEST 7: Barriere mit Öffnung ---
func test_barrier_with_opening():
	# Arrange
	var barrier := Barrier.new()
	var opening := Opening.new(Opening.OpeningType.PASS, Vector2(5, 5), 3, false, "Fels")
	
	# Act
	barrier.add_opening(opening)
	
	# Assert
	assert_eq(barrier.openings.size(), 1, "Barriere sollte 1 Öffnung haben")
	assert_eq(barrier.openings[0].type, Opening.OpeningType.PASS, "Öffnungstyp sollte PASS sein")


# --- TEST 8: Barriere mit interaktiver Öffnung ---
func test_barrier_with_interactive_opening():
	# Arrange
	var barrier := Barrier.new()
	var opening := Opening.new(Opening.OpeningType.TUER, Vector2(5, 5), 1, true, "Wald")
	
	# Act
	barrier.add_opening(opening)
	
	# Assert
	assert_true(barrier.has_interactive_openings(), "Barriere sollte interaktive Öffnung haben")


# --- TEST 9: Barriere ohne interaktive Öffnungen ---
func test_barrier_without_interactive_openings():
	# Arrange
	var barrier := Barrier.new()
	var opening := Opening.new(Opening.OpeningType.PASS, Vector2(5, 5), 3, false, "Fels")
	
	# Act
	barrier.add_opening(opening)
	
	# Assert
	assert_false(barrier.has_interactive_openings(), "Barriere sollte keine interaktiven Öffnungen haben")


# --- TEST 10: Punkt in Öffnung ist nicht in Barriere ---
func test_point_in_opening_not_in_barrier():
	# Arrange: Barriere mit Öffnung
	var barrier := Barrier.new()
	barrier.polygon = [
		Vector2(0, 0),
		Vector2(10, 0),
		Vector2(10, 10),
		Vector2(0, 10)
	]
	
	# Öffnung von (4,5) bis (6,5) mit Breite 3
	var opening := Opening.new(Opening.OpeningType.PASS, Vector2(5, 5), 3, false, "Fels")
	barrier.add_opening(opening)
	
	# Act & Assert
	# Punkt in der Öffnung sollte nicht als in der Barriere erkannt werden
	assert_false(barrier.contains_point(Vector2(5, 5)), "Punkt in Öffnung sollte nicht in Barriere sein")
	assert_false(barrier.contains_point(Vector2(4, 5)), "Punkt in Öffnung sollte nicht in Barriere sein")
	assert_false(barrier.contains_point(Vector2(6, 5)), "Punkt in Öffnung sollte nicht in Barriere sein")
	
	# Punkt außerhalb der Öffnung sollte in der Barriere sein
	assert_true(barrier.contains_point(Vector2(2, 5)), "Punkt außerhalb Öffnung sollte in Barriere sein")


# --- TEST 11: Öffnung öffnen und schließen ---
func test_opening_open_close():
	# Arrange
	var opening := Opening.new(Opening.OpeningType.TUER, Vector2(5, 5), 1, true, "Wald")
	
	# Act & Assert
	assert_false(opening.is_open, "Tür sollte zunächst geschlossen sein")
	assert_false(opening.is_passable(), "Geschlossene Tür sollte nicht passierbar sein")
	
	# Tür öffnen
	opening.open()
	assert_true(opening.is_open, "Tür sollte offen sein")
	assert_true(opening.is_passable(), "Offene Tür sollte passierbar sein")
	
	# Tür schließen
	opening.close()
	assert_false(opening.is_open, "Tür sollte wieder geschlossen sein")
	assert_false(opening.is_passable(), "Geschlossene Tür sollte nicht passierbar sein")


# --- TEST 12: Nicht-interaktive Öffnung ist immer passierbar ---
func test_non_interactive_opening_always_passable():
	# Arrange
	var opening := Opening.new(Opening.OpeningType.PASS, Vector2(5, 5), 3, false, "Fels")
	
	# Act & Assert
	assert_true(opening.is_passable(), "Nicht-interaktive Öffnung sollte immer passierbar sein")
	
	# Versuche zu öffnen (sollte keine Wirkung haben)
	opening.open()
	assert_true(opening.is_passable(), "Nicht-interaktive Öffnung bleibt passierbar")
