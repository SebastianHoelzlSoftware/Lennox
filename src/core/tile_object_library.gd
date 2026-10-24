class_name TileObjectLibrary
extends Resource

@export var patterns: Array[TileObjectPattern] = []


func get_pattern(p_name: StringName) -> TileObjectPattern:
	var found: TileObjectPattern
	for pattern: TileObjectPattern in patterns:
		if pattern.pattern_name != p_name:
			continue
		if found != null:
			push_error("Tile object library contains duplicate pattern name '%s'." % p_name)
			return null
		found = pattern
	return found


func get_pattern_names() -> Array[StringName]:
	var names: Array[StringName] = []
	for pattern: TileObjectPattern in patterns:
		names.append(pattern.pattern_name)
	return names
