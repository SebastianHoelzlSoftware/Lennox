class_name TileObjectLibrary
extends Resource

@export var patterns: Array[TileObjectPattern] = []
@export var atlas_groups: Dictionary = {}


func get_pattern(p_name: StringName) -> TileObjectPattern:
	var found: TileObjectPattern
	for pattern: TileObjectPattern in patterns:
		if pattern.pattern_name != p_name:
			continue
		if found != null:
			push_error("Tile object library contains duplicate pattern name '%s'." % p_name)
			return null
		found = pattern
	if found != null:
		return found

	for source_name: StringName in atlas_groups:
		var source_patterns: Dictionary = atlas_groups[source_name]
		if not source_patterns.has(p_name):
			continue
		var atlas_coords: Array[Vector2i] = source_patterns[p_name]
		if atlas_coords.is_empty():
			push_error("Tile object atlas group '%s' has no tiles." % p_name)
			return null

		var pattern_from_atlas := TileObjectPattern.new()
		pattern_from_atlas.pattern_name = p_name
		pattern_from_atlas.atlas_source_name = source_name
		pattern_from_atlas.footprint.clear()
		var min_x := atlas_coords[0].x
		var min_y := atlas_coords[0].y
		for atlas_coord: Vector2i in atlas_coords:
			min_x = mini(min_x, atlas_coord.x)
			min_y = mini(min_y, atlas_coord.y)
		for atlas_coord: Vector2i in atlas_coords:
			var local_position := atlas_coord - Vector2i(min_x, min_y)
			pattern_from_atlas.atlas_coords.append(atlas_coord)
			pattern_from_atlas.local_positions.append(local_position)
			pattern_from_atlas.footprint.append(local_position)
		return pattern_from_atlas

	return null


func get_pattern_names() -> Array[StringName]:
	var names: Array[StringName] = []
	for pattern: TileObjectPattern in patterns:
		names.append(pattern.pattern_name)
	for source_name: StringName in atlas_groups:
		var source_patterns: Dictionary = atlas_groups[source_name]
		for pattern_name: StringName in source_patterns:
			names.append(pattern_name)
	return names
