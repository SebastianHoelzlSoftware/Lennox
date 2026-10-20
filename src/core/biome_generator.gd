# biome_generator.gd
class_name BiomeGenerator

static func generate_biome_map(p_seed: int, p_width: int, p_height: int) -> Array:
	"""
	Genera un mapa de biomas para un nivel.
	Utiliza Voronoi con domain warping basado en ruido simplex para variar las fronteras.
	"""
	var biome_map := []

	# Seed für Determinismus setzen
	randomize()
	seed(p_seed)

	# Voronoi-Punkte generieren (1 Punkt pro 5x5 Chunks)
	var voronoi_points := []
	var step := 5
	for x in range(0, p_width, step):
		for y in range(0, p_height, step):
			voronoi_points.append(Vector2(x, y))

	# Biom-Typen für Voronoi-Punkte zuweisen
	var biome_types: Array[BiomeType.Type] = [
		BiomeType.GRASSLAND,
		BiomeType.WOOD,
		BiomeType.ROCKS,
		BiomeType.WATER,
		BiomeType.SAND
	]
	var biome_assignments: Array[BiomeType.Type] = []
	for point in voronoi_points:
		var biome_idx := randi() % biome_types.size()
		biome_assignments.append(biome_types[biome_idx])

	# Perlin Noise für Glättung
	var noise := FastNoiseLite.new()
	noise.seed = p_seed
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	noise.fractal_octaves = 4
	noise.frequency = 1.0 / 20.0
	noise.fractal_gain = 0.5

	# Biom-Karte erstellen
	for x in range(p_width):
		biome_map.append([])
		for y in range(p_height):
			# Domain warping verschiebt die Abfragekoordinate kontinuierlich und formt die Grenzen.
			var sample_position := _warp_position(noise, Vector2(x, y))

			# Nächsten Voronoi-Punkt finden
			var min_dist := INF
			var closest_idx := -1
			for i in range(voronoi_points.size()):
				var voronoi_point: Vector2 = voronoi_points[i]
				var dist: float = voronoi_point.distance_to(sample_position)
				if dist < min_dist:
					min_dist = dist
					closest_idx = i

			var biome: BiomeType.Type = biome_assignments[closest_idx]
			biome_map[x].append(biome)

	return biome_map

static func _warp_position(p_noise: FastNoiseLite, p_position: Vector2) -> Vector2:
	var noise_x := p_noise.get_noise_2d(p_position.x, p_position.y)
	var noise_y := p_noise.get_noise_2d(p_position.x + 1000.0, p_position.y + 1000.0)
	return p_position + Vector2(noise_x, noise_y) * 2.5

static func get_biome_params(p_biome: BiomeType.Type) -> Dictionary:
	match p_biome:
		BiomeType.GRASSLAND:
			return {
				"barrier_count": randi_range(1, 2),
				"barrier_size": randi_range(5, 10),
				"opening_count": randi_range(1, 3),
				"opening_types": [Opening.OpeningType.FORD, Opening.OpeningType.PASS, Opening.OpeningType.STEPS]
			}
		BiomeType.WOOD:
			return {
				"barrier_count": randi_range(3, 5),
				"barrier_size": randi_range(8, 15),
				"opening_count": randi_range(1, 2),
				"opening_types": [Opening.OpeningType.PASS, Opening.OpeningType.FORD, Opening.OpeningType.DOOR]
			}
		BiomeType.ROCKS:
			return {
				"barrier_count": randi_range(5, 8),
				"barrier_size": randi_range(10, 20),
				"opening_count": randi_range(0, 1),
				"opening_types": [Opening.OpeningType.PASS, Opening.OpeningType.STEPS]
			}
		BiomeType.WATER:
			return {
				"barrier_count": randi_range(0, 1),
				"barrier_size": randi_range(15, 30),
				"opening_count": randi_range(1, 2),
				"opening_types": [Opening.OpeningType.FORD]
			}
		BiomeType.SAND:
			return {
				"barrier_count": randi_range(1, 2),
				"barrier_size": randi_range(6, 12),
				"opening_count": randi_range(1, 3),
				"opening_types": [Opening.OpeningType.PASS, Opening.OpeningType.FORD]
			}
		_:
			return {
				"barrier_count": 1,
				"barrier_size": 8,
				"opening_count": 1,
				"opening_types": [Opening.OpeningType.PASS]
			}
