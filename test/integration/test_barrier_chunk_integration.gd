extends GutTest

# test_barrier_chunk_integration.gd
# Tests de integracion para el sistema de barreras con chunks y niveles (LEN-5 / LEN-17)

func test_level_generation_creates_barriers_across_chunks():
	var level := Level.new(2, 2, 32, 32, 12345)
	level.generate()
	
	var total_barriers := 0
	for cx in range(level.width):
		for cy in range(level.height):
			var chunk := level.get_chunk(cx, cy)
			assert_not_null(chunk, "El chunk debe existir en la posicion dada")
			total_barriers += chunk.barriers.size()
			
			# Comprobar que las baldosas reflejan las barreras
			for barrier_item in chunk.barriers:
				var barrier: Barrier = barrier_item
				var expected_tile := level.get_barrier_tile_type_from_biome(barrier.biome)
				assert_gt(barrier.polygon.size(), 2, "El poligono de la barrera debe ser valido")
				
				# Comprobar algunos puntos dentro de la barrera
				for x in range(32):
					for y in range(32):
						if barrier.contains_point(Vector2(x, y)):
							assert_eq(chunk.get_tile(x, y), expected_tile, "La baldosa dentro de la barrera debe coincidir con el tipo esperado")
							assert_true(chunk.is_barrier(x, y), "El chunk debe reconocer la baldosa como barrera")
	
	assert_gt(total_barriers, 0, "El nivel debe haber generado barreras entre los chunks")


func test_barrier_openings_create_passable_gaps_in_tiles():
	var chunk := Chunk.new(0, 0)
	chunk.biome = BiomeType.GRASSLAND
	
	# Crear barrera de (2, 2) a (12, 12)
	var barrier := Barrier.new()
	barrier.polygon = [
		Vector2(2, 2),
		Vector2(12, 2),
		Vector2(12, 12),
		Vector2(2, 12)
	]
	barrier.biome = BiomeType.ROCKS
	
	# Apertura fija tipo PASS en (7, 5) con ancho 3 (cubre x de 6 a 8 en y=5)
	var opening := Opening.new(Opening.OpeningType.PASS, Vector2(7, 5), 3, false, BiomeType.ROCKS)
	barrier.add_opening(opening)
	chunk.barriers.append(barrier)
	
	# Aplicar a baldosas
	chunk.apply_barriers_to_tiles()
	
	# El centro de la apertura no debe ser barrera
	assert_false(chunk.is_barrier(7, 5), "El punto central de la apertura no debe ser barrera")
	assert_false(chunk.is_barrier(6, 5), "Los puntos dentro del ancho de la apertura no deben ser barrera")
	assert_false(chunk.is_barrier(8, 5), "Los puntos dentro del ancho de la apertura no deben ser barrera")
	assert_eq(chunk.get_tile(7, 5), TileType.GRASS, "La baldosa en la apertura debe permanecer transitable (GRASS)")
	
	# Puntos fuera de la apertura pero dentro del poligono deben ser barrera
	assert_true(chunk.is_barrier(4, 5), "Puntos fuera de la apertura deben ser barrera")
	assert_eq(chunk.get_tile(4, 5), TileType.ROCK, "Puntos fuera de la apertura deben ser de tipo ROCK")
	assert_true(chunk.is_barrier(10, 5), "Puntos a la derecha de la apertura deben ser barrera")
	assert_eq(chunk.get_tile(10, 5), TileType.ROCK, "Puntos a la derecha deben ser de tipo ROCK")


func test_interactive_door_state_changes_passability():
	var chunk := Chunk.new(0, 0)
	chunk.biome = BiomeType.WOOD
	
	var barrier := Barrier.new()
	barrier.polygon = [
		Vector2(5, 5),
		Vector2(15, 5),
		Vector2(15, 15),
		Vector2(5, 15)
	]
	barrier.biome = BiomeType.WOOD
	
	# Puerta interactiva en (10, 10)
	var door := Opening.new(Opening.OpeningType.DOOR, Vector2(10, 10), 2, true, BiomeType.WOOD)
	barrier.add_opening(door)
	chunk.barriers.append(barrier)
	
	# 1. Puerta cerrada inicialmente
	assert_false(door.is_passable(), "La puerta debe estar cerrada inicialmente")
	assert_true(chunk.is_barrier(10, 10), "Con la puerta cerrada, el punto debe ser barrera")
	
	chunk.apply_barriers_to_tiles()
	assert_eq(chunk.get_tile(10, 10), TileType.TREE, "Con la puerta cerrada, la baldosa debe ser TREE")
	
	# 2. Abrir la puerta
	door.open()
	assert_true(door.is_passable(), "La puerta abierta debe ser transitable")
	assert_false(chunk.is_barrier(10, 10), "Con la puerta abierta, el punto no debe ser barrera")
	
	# Re-aplicar a baldosas para simular actualizacion dinamica
	chunk.tiles[10][10] = TileType.GRASS
	chunk.apply_barriers_to_tiles()
	assert_eq(chunk.get_tile(10, 10), TileType.GRASS, "Con la puerta abierta, la baldosa se mantiene transitable")
	
	# 3. Cerrar la puerta de nuevo
	door.close()
	assert_false(door.is_passable(), "La puerta cerrada de nuevo no debe ser transitable")
	assert_true(chunk.is_barrier(10, 10), "Despues de cerrar, debe volver a ser barrera")
	chunk.apply_barriers_to_tiles()
	assert_eq(chunk.get_tile(10, 10), TileType.TREE, "Despues de cerrar, la baldosa debe volver a ser TREE")


func test_barrier_bounds_respect_chunk_boundaries():
	var level := Level.new(3, 3, 32, 32, 98765)
	level.generate()
	
	for cx in range(3):
		for cy in range(3):
			var chunk := level.get_chunk(cx, cy)
			assert_not_null(chunk, "El chunk debe ser valido")
			assert_eq(chunk.x, cx, "Coordenada x del chunk debe ser correcta")
			assert_eq(chunk.y, cy, "Coordenada y del chunk debe ser correcta")
			
			for barrier_item in chunk.barriers:
				var barrier: Barrier = barrier_item
				for vertex in barrier.polygon:
					assert_true(vertex.x >= 0 and vertex.x < 32, "El vertice X del poligono debe estar dentro del chunk [0, 31]")
					assert_true(vertex.y >= 0 and vertex.y < 32, "El vertice Y del poligono debe estar dentro del chunk [0, 31]")
				
				var pass_points: Array[Vector2] = barrier.get_passable_points(32)
				for pt in pass_points:
					assert_true(pt.x >= 0 and pt.x < 32, "Punto transitable X debe estar dentro del chunk [0, 31]")
					assert_true(pt.y >= 0 and pt.y < 32, "Punto transitable Y debe estar dentro del chunk [0, 31]")


func test_multi_chunk_coexistence_and_determinism():
	var level1 := Level.new(2, 2, 32, 32, 54321)
	var level2 := Level.new(2, 2, 32, 32, 54321)
	var level3 := Level.new(2, 2, 32, 32, 99999)
	
	level1.generate()
	level2.generate()
	level3.generate()
	
	# level1 y level2 deben coincidir al 100%
	for cx in range(2):
		for cy in range(2):
			var c1 := level1.get_chunk(cx, cy)
			var c2 := level2.get_chunk(cx, cy)
			assert_eq(c1.barriers.size(), c2.barriers.size(), "La cantidad de barreras debe ser identica con la misma semilla")
			for x in range(32):
				for y in range(32):
					assert_eq(c1.tiles[x][y], c2.tiles[x][y], "Las baldosas deben coincidir al 100% entre ejecuciones deterministicas")
	
	# level3 con semilla diferente debe ser valido
	var c3 := level3.get_chunk(0, 0)
	assert_not_null(c3, "El chunk de level3 debe ser valido")
	assert_eq(c3.tiles.size(), 32, "El chunk debe tener dimensiones de 32x32")
