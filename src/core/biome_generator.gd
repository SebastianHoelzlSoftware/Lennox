# biome_generator.gd
class_name BiomeGenerator

const BIOME_REGION_SIZE_CHUNKS := 4

static func generate_biome_map(p_seed: int, p_width: int, p_height: int) -> Array:
	"""
	Genera un mapa de biomas para un nivel.
	Usa regiones de Voronoi y deforma sus coordenadas con ruido Simplex para que
	las fronteras no formen una cuadrícula regular.
	"""
	var biome_map := []

	# Esta semilla hace que tanto la asignación de biomas como el ruido sean reproducibles.
	var rng := RandomNumberGenerator.new()
	rng.seed = p_seed

	# Un espaciado menor entre centros crea regiones de bioma más pequeñas.
	var voronoi_points := []
	var step := BIOME_REGION_SIZE_CHUNKS
	for x in range(0, p_width, step):
		for y in range(0, p_height, step):
			voronoi_points.append(Vector2(x, y))

	# Define los biomas posibles y asigna uno aleatorio a cada centro de Voronoi.
	var biome_types: Array[BiomeType.Type] = [
		BiomeType.CAVE,
		BiomeType.DESERT,
		BiomeType.FOREST,
		BiomeType.GRASSLAND,
		BiomeType.ROCKS,
		BiomeType.ROCKS_AND_WATER,
		BiomeType.SWAMP,
		BiomeType.SEABED
	]
	var biome_assignments: Array[BiomeType.Type] = []
	for point in voronoi_points:
		var biome_idx := rng.randi_range(0, biome_types.size() - 1)
		biome_assignments.append(biome_types[biome_idx])

	# El ruido Simplex fractal aporta variaciones suaves a las coordenadas consultadas.
	var noise := FastNoiseLite.new()
	noise.seed = p_seed
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	noise.fractal_octaves = 4
	noise.frequency = 1.0 / 20.0
	noise.fractal_gain = 0.5

	# Para cada chunk, busca el centro de Voronoi más cercano a la posición deformada.
	for x in range(p_width):
		biome_map.append([])
		for y in range(p_height):
			# La deformación desplaza la posición de consulta y da forma irregular a las fronteras.
			var sample_position := _warp_position(noise, Vector2(x, y))

			# Conserva el índice del centro más cercano para recuperar el bioma asignado.
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
	# Dos muestras con coordenadas desplazadas aportan el desplazamiento de cada eje.
	var noise_x := p_noise.get_noise_2d(p_position.x, p_position.y)
	var noise_y := p_noise.get_noise_2d(p_position.x + 1000.0, p_position.y + 1000.0)
	return p_position + Vector2(noise_x, noise_y) * 2.5

static func get_biome_params(
	p_biome: BiomeType.Type,
	p_rng: RandomNumberGenerator = null
) -> Dictionary:
	# Reutiliza el generador recibido para que quien llama pueda controlar la semilla.
	# Si no se proporciona uno, crea una secuencia aleatoria independiente.
	var rng := p_rng
	if rng == null:
		rng = RandomNumberGenerator.new()
		rng.randomize()

	# Los rangos y tipos permitidos se centralizan para facilitar el balanceo.
	var profile := BiomeConfig.get_biome_profile(p_biome)
	var barrier_count_range: Vector2i = profile["barrier_count"]
	var barrier_size_range: Vector2i = profile["barrier_size"]
	var opening_count_range: Vector2i = profile["opening_count"]

	return {
		"barrier_count": rng.randi_range(barrier_count_range.x, barrier_count_range.y),
		"barrier_size": rng.randi_range(barrier_size_range.x, barrier_size_range.y),
		"opening_count": rng.randi_range(opening_count_range.x, opening_count_range.y),
		"opening_types": profile["opening_types"]
	}
