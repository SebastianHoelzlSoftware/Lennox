# test_chunk.gd
extends GutTest

func test_chunk_initialization():
	# Arrange
	var x := 5
	var y := 10

	# Act
	var chunk := Chunk.new(x, y)

	# Assert
	assert_eq(chunk.x, x, "X-Koordinate sollte 5 sein")
	assert_eq(chunk.y, y, "Y-Koordinate sollte 10 sein")
	assert_eq(chunk.tiles.size(), 32, "Chunk sollte 32x32 Kacheln haben")
	assert_eq(chunk.tiles[0].size(), 32, "Jede Zeile sollte 32 Kacheln haben")

# --- TEST 2: Chunk hat Standard-Biom ---
func test_chunk_has_default_biome():
	# Arrange & Act
	var chunk := Chunk.new(0, 0)

	# Assert
	assert_eq(chunk.biome, "Grasland", "Standard-Biom sollte Grasland sein")

# --- TEST 3: Barrieren-Liste ist leer ---
func test_chunk_barriers_list_is_empty():
	# Arrange & Act
	var chunk := Chunk.new(0, 0)

	# Assert
	assert_eq(chunk.barriers.size(), 0, "Barrieren-Liste sollte leer sein")

# --- TEST 4: Kacheln sind initial leer ---
func test_chunk_tiles_are_empty():
	# Arrange & Act
	var chunk := Chunk.new(0, 0)

	# Assert: Alle Kacheln sollten Standardwert haben
	for x in range(32):
		for y in range(32):
			assert_eq(chunk.tiles[x][y], "Gras", "Standard-Kachel sollte Gras sein")

# --- TEST 5: Barriere hinzufügen ---
func test_chunk_add_barrier():
	# Arrange
	var chunk := Chunk.new(0, 0)
	var polygon: Array[Vector2] = [
		Vector2(0, 0),
		Vector2(10, 0),
		Vector2(10, 10),
		Vector2(0, 10)
	]

	# Act
	chunk.add_barrier(polygon)

	# Assert
	assert_eq(chunk.barriers.size(), 1, "Barrieren-Liste sollte 1 Barriere enthalten")
	assert_eq(chunk.barriers[0].polygon, polygon, "Polygon der Barriere sollte übereinstimmen")
	assert_true(chunk.is_barrier(5, 5), "Punkt (5, 5) sollte als Barriere erkannt werden")
	assert_false(chunk.is_barrier(20, 20), "Punkt (20, 20) sollte nicht als Barriere erkannt werden")
