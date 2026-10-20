# biome_generator.gd
class_name BiomeGenerator

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

	# Crea una celda de Voronoi por cada bloque de 5 × 5 chunks.
	var voronoi_points := []
	var step := 5
	for x in range(0, p_width, step):
		for y in range(0, p_height, step):
			voronoi_points.append(Vector2(x, y))

	# Define los biomas posibles y asigna uno aleatorio a cada centro de Voronoi.
	var biome_types: Array[BiomeType.Type] = [
		BiomeType.GRASSLAND,
		BiomeType.WOOD,
		BiomeType.ROCKS,
		BiomeType.WATER,
		BiomeType.SAND
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

	# Cada bioma define sus límites de barreras y los tipos de apertura permitidos.
	match p_biome:
		BiomeType.GRASSLAND:
			return {
				"barrier_count": rng.randi_range(1, 2),
				"barrier_size": rng.randi_range(5, 10),
				"opening_count": rng.randi_range(1, 3),
				"opening_types": [
					Opening.OpeningType.FORD,
					Opening.OpeningType.PASS,
					Opening.OpeningType.STEPS
				]
			}
		BiomeType.WOOD:
			return {
				"barrier_count": rng.randi_range(3, 5),
				"barrier_size": rng.randi_range(8, 15),
				"opening_count": rng.randi_range(1, 2),
				"opening_types": [
					Opening.OpeningType.PASS,
					Opening.OpeningType.FORD,
					Opening.OpeningType.DOOR
				]
			}
		BiomeType.ROCKS:
			return {
				"barrier_count": rng.randi_range(5, 8),
				"barrier_size": rng.randi_range(10, 20),
				"opening_count": rng.randi_range(0, 1),
				"opening_types": [
					Opening.OpeningType.PASS,
					Opening.OpeningType.STEPS
				]
			}
		BiomeType.WATER:
			return {
				"barrier_count": rng.randi_range(0, 1),
				"barrier_size": rng.randi_range(15, 30),
				"opening_count": rng.randi_range(1, 2),
				"opening_types": [Opening.OpeningType.FORD]
			}
		BiomeType.SAND:
			return {
				"barrier_count": rng.randi_range(1, 2),
				"barrier_size": rng.randi_range(6, 12),
				"opening_count": rng.randi_range(1, 3),
				"opening_types": [
					Opening.OpeningType.PASS,
					Opening.OpeningType.FORD
				]
			}
		_:
			return {
				"barrier_count": 1,
				"barrier_size": 8,
				"opening_count": 1,
				"opening_types": [Opening.OpeningType.PASS]
			}
