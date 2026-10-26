class_name TilePatternRegistry

# IMPORTANT!!! 
# As the godot editor does not seem to have the option to name a pattern created from the tile map editor and 
# I can only reference it by an index (which might change), it's crucial to keep a good register of which index
# is which tile pattern

static var dictionary: Dictionary = {
	"Upper Left Corner (High Plateau)" : {
		"index": 1,
		"pattern": [
			Vector2i(0, 0),
			Vector2i(0, 1),
			Vector2i(1, 0),
			Vector2i(1, 1)
		],
		"is_corner": true,
		"corner_type": CornerType.UL
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
