# terrain_styles.gd
# Definiciones de estilos de terreno por bioma: suelo base, manchas de suelo (overlay
# autotile 3x3 + esquinas interiores), decals y acantilados (plantilla 3x3 + cara + derrame).
#
# Convenciones de una plantilla "blob":
#   cols = [columna_oeste, columna_centro, columna_este]
#   rows = [fila_norte, fila_centro, fila_sur]
#   inner = { "nw", "ne", "sw", "se" } -> pieza para la esquina concava cuyo vecino
#           diagonal en esa direccion esta vacio (los cuatro ortogonales son solidos).
# Un acantilado anade:
#   face  = filas de la cara de roca dibujadas DEBAJO del borde sur (1 o 2 filas).
#   spill = (opcional) columnas/filas de derrame que sobresalen fuera de la huella:
#           { "l": col_izq, "r": col_der, "t": fila_sup, "b": fila_inf }.
#   n_alt = variantes opcionales para el borde norte recto.
class_name TerrainStyles
extends RefCounted

const GRASSLAND_SHEET := "res://assets/biomes/grassland/tiles/ground_grasss.png"
const FOREST_SHEET := "res://assets/biomes/forest/tiles/Ground_grass.png"
const DESERT_SHEET := "res://assets/biomes/desert/tiles/Ground_grass.png"
const DESERT_TUFTS_SHEET := "res://assets/biomes/desert/tiles/sand.png"
const ROCKS_SHEET := "res://assets/tiles/rocks/Ground_rocks.png"
const MOSS_SHEET := "res://assets/biomes/rocks/tiles/Ground_moss.png"
const CAVE_SHEET := "res://assets/biomes/cave/tiles/ground_source.png"
const DUNGEON_SHEET := "res://assets/biomes/cave/tiles/dungeon_walls_floor.png"
const SWAMP_SHEET := "res://assets/biomes/swamp/tiles/ground_grass.png"
const SEABED_SHEET := "res://assets/biomes/seabed/tiles/Ground_sand.png"
const FLYING_SHEET := "res://assets/biomes/rocks_and_water/tiles/Ground_grass_flying.png"
const GRASSLAND_DETAILS_SHEET := "res://assets/biomes/grassland/tiles/Details.png"

# Detalles sueltos de pradera: matas de hierba, flores, piedrecitas y motas de tierra
const MEADOW_DECALS := {
	"sheet": GRASSLAND_DETAILS_SHEET,
	"tiles": [
		Vector2i(0, 13), Vector2i(1, 13), Vector2i(2, 13), Vector2i(3, 13), Vector2i(4, 13), Vector2i(5, 13),
		Vector2i(0, 13), Vector2i(1, 13), Vector2i(2, 13), Vector2i(3, 13), Vector2i(4, 13), Vector2i(5, 13),
		Vector2i(7, 10), Vector2i(8, 10), Vector2i(9, 10), Vector2i(10, 10), Vector2i(11, 10), Vector2i(0, 10),
		Vector2i(10, 8), Vector2i(11, 8), Vector2i(3, 1), Vector2i(3, 0), Vector2i(6, 12), Vector2i(8, 12),
	],
	"density": 0.08,
}
const DESERT_DECALS := {
	"sheet": "res://assets/biomes/desert/tiles/sand.png",
	"tiles": [
		Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0),
		Vector2i(4, 0), Vector2i(5, 0), Vector2i(6, 0), Vector2i(7, 0),
	],
	"density": 0.06,
}


# ---------------------------------------------------------------------------
# Acantilados
# ---------------------------------------------------------------------------
const CLIFFS := {
	# Meseta de hierba con cara de adoquin marron (pradera / bosque / pantano)
	# (las esquinas concavas sur usan el relleno central: encaja mejor con la cara)
	"grass": {
		"sheet": GRASSLAND_SHEET,
		"cols": [0, 1, 2],
		"rows": [0, 1, 2],
		"face": [3, 4],
		"inner": {
			"nw": Vector2i(3, 3), "ne": Vector2i(4, 3),
		},
		"n_alt": [Vector2i(3, 0), Vector2i(4, 0)],
		"top_decals": MEADOW_DECALS,
	},
	# Mesa de tierra anaranjada con cara de adoquin (desierto)
	# (las esquinas concavas sur usan el relleno central: encaja mejor con la cara)
	"dirt": {
		"sheet": GRASSLAND_SHEET,
		"cols": [7, 8, 9],
		"rows": [0, 1, 2],
		"face": [3, 4],
		"inner": {
			"nw": Vector2i(10, 3), "ne": Vector2i(11, 3),
		},
		"n_alt": [Vector2i(10, 0), Vector2i(11, 0)],
		"top_decals": DESERT_DECALS,
	},
	# Macizo rocoso gris con agujas oscuras que sobresalen (rocas)
	"rock": {
		"sheet": ROCKS_SHEET,
		"cols": [1, 2, 3],
		"rows": [1, 2, 3],
		"face": [4, 5],
		"inner": {},
		"spill": {"l": 0, "r": 4, "t": 0, "b": 6},
		"c_alt": [Vector2i(8, 1), Vector2i(9, 1)],
	},
	# Paredes de cueva: techo negro y muro de rocas pardas (cueva)
	"cave": {
		"sheet": CAVE_SHEET,
		"cols": [0, 2, 4],
		"rows": [0, 2, 3],
		"face": [4, 5, 6],
		"inner": {},
		"c_alt": [Vector2i(3, 2), Vector2i(2, 1), Vector2i(3, 1)],
	},
	# Islas flotantes con raiz de roca (rocas y agua)
	"flying": {
		"sheet": FLYING_SHEET,
		"cols": [0, 1, 2],
		"rows": [0, 1, 2],
		"face": [3, 4],
		"inner": {
			"se": Vector2i(4, 0), "sw": Vector2i(6, 0),
			"ne": Vector2i(4, 2), "nw": Vector2i(6, 2),
		},
	},
	# Montículos de arena azulada del lecho marino (cara de 1 fila)
	"seabed": {
		"sheet": SEABED_SHEET,
		"cols": [0, 1, 2],
		"rows": [5, 6, 7],
		"face": [8],
		"inner": {},
	},
}


# ---------------------------------------------------------------------------
# Suelos por bioma
# ---------------------------------------------------------------------------
# base:     { sheet, tiles: [Vector2i...] }  (la primera es la dominante)
# overlay:  blob opcional dibujado donde el ruido de suelo lo indica
# cover:    umbral de ruido para el overlay (mas bajo = mas cobertura)
# paths:    anchura de los senderos serpenteantes que cortan el overlay (0 = ninguno)
# decals:   { sheet, tiles } piezas transparentes sueltas
# cliff:    clave en CLIFFS
const BIOMES := {
	BiomeType.Type.GRASSLAND: {
		"base": {"sheet": GRASSLAND_SHEET, "tiles": [Vector2i(8, 1)]},
		"overlay": {
			"sheet": GRASSLAND_SHEET,
			"cols": [5, 6, 7], "rows": [5, 6, 7],
			"inner": {
				"se": Vector2i(8, 5), "sw": Vector2i(9, 5),
				"ne": Vector2i(8, 6), "nw": Vector2i(9, 6),
			},
		},
		"cover": -0.55,
		"paths": 0.07,
		"decals": MEADOW_DECALS,
		"cliff": "grass",
	},
	BiomeType.Type.FOREST: {
		"base": {"sheet": FOREST_SHEET, "tiles": [Vector2i(1, 4)]},
		"overlay": {
			"sheet": FOREST_SHEET,
			"cols": [0, 1, 2], "rows": [6, 7, 8],
			"inner": {
				"se": Vector2i(3, 7), "sw": Vector2i(4, 7),
				"ne": Vector2i(3, 8), "nw": Vector2i(4, 8),
			},
		},
		"cover": -0.6,
		"paths": 0.05,
		"decals": MEADOW_DECALS,
		"cliff": "grass",
	},
	BiomeType.Type.DESERT: {
		"base": {"sheet": DESERT_SHEET, "tiles": [Vector2i(1, 1)]},
		"overlay": {
			"sheet": DESERT_SHEET,
			"cols": [5, 6, 7], "rows": [0, 1, 2],
			"inner": {
				"se": Vector2i(8, 0), "sw": Vector2i(9, 0),
				"ne": Vector2i(8, 1), "nw": Vector2i(9, 1),
			},
		},
		"cover": 0.32,
		"paths": 0.0,
		"decals": DESERT_DECALS,
		"cliff": "dirt",
	},
	BiomeType.Type.ROCKS: {
		"base": {"sheet": MOSS_SHEET, "tiles": [Vector2i(1, 4)]},
		"cover": 2.0,
		"paths": 0.0,
		"cliff": "rock",
	},
	BiomeType.Type.CAVE: {
		"base": {"sheet": DUNGEON_SHEET, "tiles": [Vector2i(1, 10)]},
		"cover": 2.0,
		"paths": 0.0,
		"cliff": "rock",
	},
	BiomeType.Type.SWAMP: {
		"base": {"sheet": SWAMP_SHEET, "tiles": [Vector2i(1, 1)]},
		"overlay": {
			"sheet": SWAMP_SHEET,
			"cols": [0, 1, 2], "rows": [6, 7, 8],
			"inner": {
				"se": Vector2i(5, 6), "sw": Vector2i(6, 6),
				"ne": Vector2i(5, 7), "nw": Vector2i(6, 7),
			},
		},
		"cover": -0.15,
		"paths": 0.0,
		"decals": {
			"sheet": SWAMP_SHEET,
			"tiles": [
				Vector2i(0, 28), Vector2i(1, 28), Vector2i(2, 28), Vector2i(3, 28),
				Vector2i(0, 29), Vector2i(1, 29), Vector2i(2, 29), Vector2i(3, 29),
				Vector2i(4, 29), Vector2i(5, 29), Vector2i(6, 29),
			],
			"density": 0.06,
		},
		"cliff": "grass",
	},
	BiomeType.Type.SEABED: {
		"base": {"sheet": SEABED_SHEET, "tiles": [Vector2i(25, 1)]},
		"cover": 2.0,
		"paths": 0.0,
		"cliff": "seabed",
	},
	BiomeType.Type.ROCKS_AND_WATER: {
		"base": {"sheet": FLYING_SHEET, "tiles": [Vector2i(1, 6)]},
		"cover": 2.0,
		"paths": 0.0,
		"cliff": "flying",
	},
}


static func get_biome_style(p_biome: int) -> Dictionary:
	return BIOMES.get(p_biome, BIOMES[BiomeType.Type.GRASSLAND])


static func get_cliff_style(p_key: String) -> Dictionary:
	return CLIFFS.get(p_key, CLIFFS["grass"])


static func get_cliff_key_for_biome(p_biome: int) -> String:
	return get_biome_style(p_biome).get("cliff", "grass")
