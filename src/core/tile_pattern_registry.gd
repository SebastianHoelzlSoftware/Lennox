class_name TilePatternRegistry

# IMPORTANT!!! 
# As the godot editor does not seem to have the option to name a pattern created from the tile map editor and 
# I can only reference it by an index (which might change), it's crucial to keep a good register of which index
# is which tile pattern

static var dictionary: Dictionary = {

	"Upper Left Corner (High Plateau Rocks)" : {
		"index": 1,
		"atlas_coords": [
			Vector2i(0, 21),
			Vector2i(0, 22),
			Vector2i(1, 21),
			Vector2i(1, 22)
		],
		"pattern": [
			Vector2i(2, 2),
		],
		"is_corner": true,
		"corner_type": CornerType.UL,
		"is_atomic": true,
	},

	"Upper Right Corner (High Plateau Rocks)": {
		"index": 2,
		"atlas_coords": [
			Vector2i(3, 21),
			Vector2i(3, 22),
			Vector2i(4, 21),
			Vector2i(4, 22)
		],
		"pattern": [
			Vector2i(2, 2),			
		],
		"is_corner": true,
		"corner_type": CornerType.UR,
		"is_atomic": true,
	},

	"Lower Left Corner (High Plateau Rocks)": {
		"index": 3,
		"atlas_coords": [
			Vector2i(0, 24),
			Vector2i(0, 25),
			Vector2i(0, 26),
			Vector2i(0, 27),
			Vector2i(1, 24),
			Vector2i(1, 25),
			Vector2i(1, 26),
			Vector2i(1, 27)
		],
		"pattern": [
			Vector2i(2, 4),
		],
		"is_corner": true,
		"corner_type": CornerType.LL,
		"is_atomic": true,
	},

	"Lower Right Corner (High Plateau Rocks)": {
		"index": 4,
		"atlas_coords": [
			Vector2i(3, 24),
			Vector2i(3, 25),
			Vector2i(3, 26),
			Vector2i(3, 27),
			Vector2i(4, 24),
			Vector2i(4, 25),
			Vector2i(4, 26),
			Vector2i(4, 27),
		],
		"pattern": [
			Vector2i(2, 4),	
		],
		"is_corner": true,
		"corner_type": CornerType.LL,
		"is_atomic": true,
	},

	"Top Edge Straight (High Plateau Rocks)": {
		"index": 5,
		"atlas_coords": [
			Vector2i(5, 21),
			Vector2i(5, 22),
			Vector2i(6, 21),
			Vector2i(6, 22)
		],
		"pattern": [
			Vector2i(2, 2),
		],
		"is_corner": false,
		"corner_type": null,
		"is_atomic": true,
	},

	"Bottom Edge Straight (High Plateau Rocks)": {
		"index": 6,
		"atlas_coords": [
			Vector2i(5, 23),
			Vector2i(5, 24),
			Vector2i(5, 25),
			Vector2i(5, 26),
			Vector2i(6, 23),
			Vector2i(6, 24),
			Vector2i(6, 25),
			Vector2i(6, 26)
		],
		"pattern": [
			Vector2i(2, 4),
		],
		"is_corner": false,
		"corner_type": null,
		"is_atomic": true,
	},

	"Left Edge Straight (High Plateau Rocks)": {
		"index": 7,
		"atlas_coords": [
			Vector2i(21, 27),
			Vector2i(21, 28),
			Vector2i(22, 27),
			Vector2i(22, 28)
		],
		"pattern": [
			Vector2i(2, 2),
		],
		"is_corner": false,
		"corner_type": null,
		"is_atomic": true,
	},

	"Right Edge Straight (High Plateau Rocks)": {
		"index": 8,
		"atlas_coords": [
			# Hier hab ich das muster verkehrt herum angelegt, ist aber okay. nur die indizes sind vertauscht hier			
			Vector2i(19, 28),
			Vector2i(19, 27),
			Vector2i(20, 28),
			Vector2i(20, 27)
		],
		"pattern": [
			Vector2i(2, 2),
		],
		"is_corner": false,
		"corner_type": null,
		"is_atomic": true,
	},

	"Ground Plate (High Plateau Rocks) Variant A": {
		"index": 9,
		"atlas_coords": [
			Vector2i(17, 37),
			Vector2i(17, 37),
			Vector2i(17, 37),
			Vector2i(17, 37)
		],
		"pattern": [
			Vector2i(2, 2),
		],
		"is_corner": false,
		"corner_type": null,
		"is_atomic": true,
	},
}
""" 
	"Plateau 1x1 (High Plateau Rocks)": {
		"index": 10,
		"pattern": [
			Vector2i(6, 8)
		],
		"is_corner": false,
		"corner_type": null,
		"is_atomic": false,
	},

	"Bridge Top (High Plateau Rocks)": {
		"index": 11,
		"pattern": [
			Vector2i(4, 4),
		],
		"is_corner": false,
		"corner_type": null,
		"is_atomic": true,
	},

	"Bridge Bottom (High Plateau Rocks)": {
		"index": 12,
		"pattern": [
			Vector2i(4, 2),
		],
		"is_corner": false,
		"corner_type": null,
		"is_atomic": true,
	},

	"Bridge Middle (High Plateau Rocks)": {
		"index": 13, 
		"pattern": [
			Vector2i(4, 2),
		],
		"is_corner": false,
		"corner_type": null,
		"is_atomic": true,
	},

	"Diagonal Down (High Plateau Rocks)": {
		"index": 14,
		"pattern": [
			Vector2i(4, 6),
		],
		"is_corner": false,
		"corner_type": null,
		"is_atomic": true,
	},

	"Diagonal Up (High Plateau Rocks)": {
		"index": 15,
		"pattern": [
			Vector2i(4, 6),
		],
		"is_corner": false,
		"corner_type": null,
		"is_atomic": true,
	},
"""

static func get_pattern_index(pattern_name: String) -> Variant:
	if pattern_name in dictionary.keys():
		return dictionary[pattern_name]["index"]
	else:
		return null

static func get_pattern(pattern_name: String) -> Array:
	if pattern_name in dictionary.keys():
		return dictionary[pattern_name]["pattern"]
	else:
		return []
	

static func is_corner(pattern_name: String) -> Variant:
	if pattern_name in dictionary.keys():
		return dictionary[pattern_name]["is_corner"]
	else:
		return null	

static func is_atomic(pattern_name: String) -> Variant:
	if pattern_name in dictionary.keys():
		return dictionary[pattern_name]["is_atomic"]
	else:
		return null	
