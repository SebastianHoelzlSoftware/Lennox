class_name BiomeConfig
extends RefCounted

const DEFAULT_PROFILE := {
	"barrier_count": Vector2i(1, 1),
	"barrier_size": Vector2i(6, 6),
	"opening_count": Vector2i(1, 1),
	"point_count": Vector2i(5, 10),
	"opening_types": [Opening.OpeningType.PASS]
}

# Valores iniciales de balance para chunks de 32 x 32 tiles.
# barrier_size limita la dispersion de los puntos que forman cada barrera.
const BIOME_PROFILES := {
	BiomeType.CAVE: {
		"barrier_count": Vector2i(8, 12),
		"barrier_size": Vector2i(12, 18),
		"opening_count": Vector2i(1, 2),
		"point_count": Vector2i(10, 15),
		"opening_types": [
			Opening.OpeningType.PASS,
			Opening.OpeningType.STEPS
		]
	},
	BiomeType.DESERT: {
		"barrier_count": Vector2i(4, 6),
		"barrier_size": Vector2i(8, 14),
		"opening_count": Vector2i(1, 2),
		"point_count": Vector2i(5, 8),
		"opening_types": [
			Opening.OpeningType.PASS,
			Opening.OpeningType.FORD
		]
	},
	BiomeType.FOREST: {
		"barrier_count": Vector2i(7, 10),
		"barrier_size": Vector2i(10, 16),
		"opening_count": Vector2i(1, 2),
		"point_count": Vector2i(8, 12),
		"opening_types": [
			Opening.OpeningType.PASS,
			Opening.OpeningType.FORD,
			Opening.OpeningType.DOOR
		]
	},
	BiomeType.GRASSLAND: {
		"barrier_count": Vector2i(4, 6),
		"barrier_size": Vector2i(8, 14),
		"opening_count": Vector2i(1, 2),
		"point_count": Vector2i(5, 8),
		"opening_types": [
			Opening.OpeningType.FORD,
			Opening.OpeningType.PASS,
			Opening.OpeningType.STEPS
		]
	},
	BiomeType.ROCKS: {
		"barrier_count": Vector2i(8, 12),
		"barrier_size": Vector2i(12, 18),
		"opening_count": Vector2i(0, 1),
		"point_count": Vector2i(10, 15),
		"opening_types": [
			Opening.OpeningType.PASS,
			Opening.OpeningType.STEPS
		]
	},
	BiomeType.ROCKS_AND_WATER: {
		"barrier_count": Vector2i(4, 8),
		"barrier_size": Vector2i(8, 14),
		"opening_count": Vector2i(1, 2),
		"point_count": Vector2i(6, 10),
		"opening_types": [
			Opening.OpeningType.FORD,
			Opening.OpeningType.PASS
		]
	},
	BiomeType.SWAMP: {
		"barrier_count": Vector2i(5, 8),
		"barrier_size": Vector2i(9, 15),
		"opening_count": Vector2i(1, 2),
		"point_count": Vector2i(7, 11),
		"opening_types": [
			Opening.OpeningType.FORD,
			Opening.OpeningType.PASS
		]
	},
	BiomeType.SEABED: {
		"barrier_count": Vector2i(4, 7),
		"barrier_size": Vector2i(8, 14),
		"opening_count": Vector2i(1, 2),
		"point_count": Vector2i(6, 10),
		"opening_types": [
			Opening.OpeningType.FORD,
			Opening.OpeningType.PASS
		]
	}
}

const OPENING_WIDTH_RANGES := {
	Opening.OpeningType.STEPS: Vector2i(2, 3),
	Opening.OpeningType.DOOR: Vector2i(1, 1),
	Opening.OpeningType.FORD: Vector2i(2, 4),
	Opening.OpeningType.PASS: Vector2i(3, 5)
}


static func get_biome_profile(p_biome: BiomeType.Type) -> Dictionary:
	var profile: Dictionary = BIOME_PROFILES.get(p_biome, DEFAULT_PROFILE)
	return profile.duplicate(true)


static func get_opening_width_range(p_opening_type: int) -> Vector2i:
	return OPENING_WIDTH_RANGES.get(p_opening_type, Vector2i(1, 1))
