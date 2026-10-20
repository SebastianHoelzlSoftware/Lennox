# test_biome.gd
extends GutTest

func test_biome_map_generation():
	var biome_map := BiomeGenerator.generate_biome_map(12345, 4, 4)
	assert_eq(biome_map.size(), 4, "El mapa de biomas debería ser de 4x4")
	for x in range(4):
		assert_eq(biome_map[x].size(), 4, "Cada fila debería tener 4 biomas")

func test_biome_types_are_valid():
	var biome_map := BiomeGenerator.generate_biome_map(54321, 2, 2)
	for x in range(2):
		for y in range(2):
			assert_true(BiomeType.Type.values().has(biome_map[x][y]), "Tipo de bioma debe ser válido")

func test_biome_generation_is_deterministic():
	var biome_map1 := BiomeGenerator.generate_biome_map(9999, 12, 12)
	var biome_map2 := BiomeGenerator.generate_biome_map(9999, 12, 12)
	for x in range(12):
		for y in range(12):
			assert_eq(biome_map1[x][y], biome_map2[x][y], "El mapa de biomas debería ser determinista")


func test_biome_generation_does_not_change_global_random_state():
	seed(314159)
	var expected_next_value := randi()

	seed(314159)
	BiomeGenerator.generate_biome_map(9999, 12, 12)
	var actual_next_value := randi()

	assert_eq(actual_next_value, expected_next_value, "La generación del bioma no debe cambiar el RNG global")


func test_noise_warp_changes_voronoi_sample_position_within_strength():
	var noise := FastNoiseLite.new()
	noise.seed = 12345
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	noise.fractal_octaves = 4
	noise.frequency = 1.0 / 20.0
	noise.fractal_gain = 0.5

	var original_position := Vector2(12, 17)
	var warped_position := BiomeGenerator._warp_position(noise, original_position)

	assert_ne(warped_position, original_position, "Der Noise-Warp muss die Sample-Position verschieben")
	assert_lte(warped_position.distance_to(original_position), 2.5, "Der Warp muss innerhalb seiner festgelegten Stärke bleiben")


func test_get_biome_params_returns_valid_values():
	var params := BiomeGenerator.get_biome_params(BiomeType.GRASSLAND)
	assert_true(params.has("barrier_count"), "Debe contener barrier_count")
	assert_true(params.has("barrier_size"), "Debe contener barrier_size")
	assert_true(params.has("opening_count"), "Debe contener opening_count")
	assert_true(params.has("opening_types"), "Debe contener opening_types")            


func test_biome_params_are_deterministic_with_local_rng():
	var rng1 := RandomNumberGenerator.new()
	rng1.seed = 12345
	var rng2 := RandomNumberGenerator.new()
	rng2.seed = 12345

	assert_eq(
		BiomeGenerator.get_biome_params(BiomeType.ROCKS, rng1),
		BiomeGenerator.get_biome_params(BiomeType.ROCKS, rng2),
		"Biome params mit gleicher lokaler Seed müssen übereinstimmen"
	)


func test_biome_params_stay_within_biome_ranges():
	var cases := [
		{"biome": BiomeType.GRASSLAND, "barriers": Vector2i(1, 2), "size": Vector2i(5, 10), "openings": Vector2i(1, 3)},
		{"biome": BiomeType.WOOD, "barriers": Vector2i(3, 5), "size": Vector2i(8, 15), "openings": Vector2i(1, 2)},
		{"biome": BiomeType.ROCKS, "barriers": Vector2i(5, 8), "size": Vector2i(10, 20), "openings": Vector2i(0, 1)},
		{"biome": BiomeType.WATER, "barriers": Vector2i(0, 1), "size": Vector2i(15, 30), "openings": Vector2i(1, 2)},
		{"biome": BiomeType.SAND, "barriers": Vector2i(1, 2), "size": Vector2i(6, 12), "openings": Vector2i(1, 3)}
	]

	for index in range(cases.size()):
		var rng := RandomNumberGenerator.new()
		rng.seed = index + 1
		var params: Dictionary = BiomeGenerator.get_biome_params(cases[index]["biome"], rng)
		assert_gte(params["barrier_count"], cases[index]["barriers"].x)
		assert_lte(params["barrier_count"], cases[index]["barriers"].y)
		assert_gte(params["barrier_size"], cases[index]["size"].x)
		assert_lte(params["barrier_size"], cases[index]["size"].y)
		assert_gte(params["opening_count"], cases[index]["openings"].x)
		assert_lte(params["opening_count"], cases[index]["openings"].y)
		assert_gt(params["opening_types"].size(), 0, "Jedes Biom muss mindestens einen Öffnungstyp konfigurieren")


func test_biome_barrier_density():
	var grassland_params := BiomeGenerator.get_biome_params(BiomeType.GRASSLAND)
	var rock_params := BiomeGenerator.get_biome_params(BiomeType.ROCKS)
	# GRASSLAND debe tener menos barreras que ROCKS
	assert_lt(grassland_params["barrier_count"], rock_params["barrier_count"],
			"Grassland debe tener menos barreras que rocks")
