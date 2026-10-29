# biome_type.gd
class_name BiomeType

enum Type {
	CAVE,
	DESERT,
	FOREST,
	GRASSLAND,
	ROCKS,
	ROCKS_AND_WATER,
	SWAMP,
	SEABED
}

const CAVE: Type = Type.CAVE
const DESERT: Type = Type.DESERT
const FOREST: Type = Type.FOREST
const GRASSLAND: Type = Type.GRASSLAND
const ROCKS: Type = Type.ROCKS
const ROCKS_AND_WATER: Type = Type.ROCKS_AND_WATER
const SWAMP: Type = Type.SWAMP
const SEABED: Type = Type.SEABED

# Backwards compatibility aliases
const WOOD: Type = Type.FOREST
const SAND: Type = Type.DESERT
const WATER: Type = Type.ROCKS_AND_WATER

