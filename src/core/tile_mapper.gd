class_name TileMapper

var tile_set: TileSet  # Level extends TileMapLayer so it has tile_set 
var tile_map_layer: TileMapLayer

func _init(p_level_tile_map_layer: TileMapLayer):
	tile_set = p_level_tile_map_layer.tile_set
	tile_map_layer = p_level_tile_map_layer

	
func create_tile_pattern(pattern_name: String) -> TilePattern:
	var tile_index = TilePatternRegistry.get_pattern_index(pattern_name)
	var hull_pattern = TilePatternRegistry.get_hull_pattern(pattern_name)
	var is_corner = TilePatternRegistry.is_corner(pattern_name)
	var is_atomic = TilePatternRegistry.is_atomic(pattern_name)
	
	# Todo: Add more complex logic here
	# for example not every pattern is intended to have a hull_pattern. so this could
	# be null in future.
	if tile_index != null && hull_pattern != null && is_corner != null:
		return TilePattern.new(pattern_name, tile_index, is_corner, is_atomic, hull_pattern)
	else:
		return null
	
func get_editor_pattern(pattern_name: String) -> TileMapPattern:
	var tile_pattern: TilePattern = create_tile_pattern(pattern_name)
	var editor_pattern: TileMapPattern = tile_set.get_pattern(tile_pattern.index)
	return editor_pattern

func draw_editor_pattern(pattern_name: String, position: Vector2i) -> void:
	var editor_pattern = get_editor_pattern(pattern_name)
	tile_map_layer.set_pattern(position, editor_pattern)
