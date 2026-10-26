class_name TilePatternRegistry

# IMPORTANT!!! 
# As the godot editor does not seem to have the option to name a pattern created from the tile map editor and 
# I can only reference it by an index (which might change), it's crucial to keep a good register of which index
# is which tile pattern

static var dictionary: Dictionary = {

	"Upper Left Corner (High Plateau Rocks)" : {
		"index": 1,
		"pattern": [
			Vector2i(0, 0),
			Vector2i(0, 1),
			Vector2i(1, 0),
			Vector2i(1, 1),
		],
		"is_corner": true,
		"corner_type": CornerType.UL,
		"is_atomic": true,
	},

	"Upper Right Corner (High Plateau Rocks)": {
		"index": 2,
		"pattern": [
			Vector2i(0, 0),
			Vector2i(0, 1),
			Vector2i(1, 0),
			Vector2i(1, 1),			
		],
		"is_corner": true,
		"corner_type": CornerType.UR,
		"is_atomic": true,
	},

	"Lower Left Corner (High Plateau Rocks)": {
		"index": 3,
		"pattern": [
			Vector2i(0, 0),
			Vector2i(0, 1),
			Vector2i(1, 0),
			Vector2i(1, 1),			
			Vector2i(2, 0),
			Vector2i(2, 1),
			Vector2i(3, 0),
			Vector2i(3, 1),			
		],
		"is_corner": true,
		"corner_type": CornerType.LL,
		"is_atomic": true,
	},

	"Lower Right Corner (High Plateau Rocks)": {
		"index": 4,
		"pattern": [
			Vector2i(0, 0),
			Vector2i(0, 1),
			Vector2i(1, 0),
			Vector2i(1, 1),			
			Vector2i(2, 0),
			Vector2i(2, 1),
			Vector2i(3, 0),
			Vector2i(3, 1),		
		],
		"is_corner": true,
		"corner_type": CornerType.LL,
		"is_atomic": true,
	},

	"Top Edge Straight (High Plateau Rocks)": {
		"index": 5,
		"pattern": [
			Vector2i(0, 0),
			Vector2i(0, 1),
			Vector2i(1, 0),
			Vector2i(1, 1),
		],
		"is_corner": false,
		"corner_type": null,
		"is_atomic": true,
	},

	"Bottom Edge Straight (High Plateau Rocks)": {
		"index": 6,
		"pattern": [
			Vector2i(0, 0),
			Vector2i(0, 1),
			Vector2i(1, 0),
			Vector2i(1, 1),
			Vector2i(2, 0),
			Vector2i(2, 1),
			Vector2i(3, 0),
			Vector2i(3, 1),		
		],
		"is_corner": false,
		"corner_type": null,
		"is_atomic": true,
	},

	"Left Edge Straight (High Plateau Rocks)": {
		"index": 7,
		"pattern": [
			Vector2i(0, 0),
			Vector2i(0, 1),
			Vector2i(1, 0),
			Vector2i(1, 1),
			Vector2i(2, 0),
			Vector2i(2, 1),
			Vector2i(3, 0),
			Vector2i(3, 1),		
		],
		"is_corner": false,
		"corner_type": null,
		"is_atomic": true,
	},

	"Right Edge Straight (High Plateau Rocks)": {
		"index": 8,
		"pattern": [
			Vector2i(0, 0),
			Vector2i(0, 1),
			Vector2i(1, 0),
			Vector2i(1, 1),
			Vector2i(2, 0),
			Vector2i(2, 1),
			Vector2i(3, 0),
			Vector2i(3, 1),		
		],
		"is_corner": false,
		"corner_type": null,
		"is_atomic": true,
	},

	"Ground Plate (High Plateau Rocks)": {
		"index": 9,
		"pattern": [
			Vector2i(0, 0),
			Vector2i(0, 1),
			Vector2i(1, 0),
			Vector2i(1, 1),
		],
		"is_corner": false,
		"corner_type": null,
		"is_atomic": true,
	},

	"Plateau 1x1 (High Plateau Rocks)": {
		"index": 10,
		"pattern": [
			Vector2i(6, 8)
		],
		"is_corner": false,
		"corner_type": null,
		"is_atomic": false,
	},

	
}

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
