# biome_generator.gd
class_name BiomeGenerator

static func generate_biome_map(p_seed: int, p_width: int, p_height: int) -> Array:
	""" Generar mapa de biomas """
	var biome_map := []
	for x in range(p_width):
		biome_map.append([])
		for y in range(p_height):
			# Dummy: Siempre Grassland
			biome_map[x].append(BiomeType.GRASSLAND)
	return biome_map

static func get_biome_params(p_biome: BiomeType.Type) -> Dictionary:
	match p_biome:
		BiomeType.GRASSLAND: return {
			"barrier_count": 1,
			"barrier_size": 8,
			"opening_count": 1,
			"opening_types": [Opening.OpeningType.DOOR, Opening.OpeningType.STEPS]
		}
		_: return {
			"barrier_count": 2,
			"barrier_size": 8,
			"opening_count": 1,
			"opening_types": [Opening.OpeningType.PASS, Opening.OpeningType.STEPS]
		}
