class_name TileMapper

var tile_set: TileSet  # Level extends TileMapLayer so it has tile_set 

func _init(p_level_tile_set: TileSet):
	tile_set = p_level_tile_set
	
func create_tile_pattern(pattern_name: String) -> TilePattern:
	var tile_index = TilePatternRegistry.get_pattern_index(pattern_name)
	var pattern = TilePatternRegistry.get_pattern(pattern_name)
	var is_corner = TilePatternRegistry.is_corner(pattern_name)
	
	if tile_index != null && pattern != null && is_corner != null:
		return TilePattern.new(pattern_name, tile_index, is_corner, pattern)
	else:
		return null
	
