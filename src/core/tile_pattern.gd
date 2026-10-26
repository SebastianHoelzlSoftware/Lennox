class_name TilePattern

var name: String
var index: int	 	# Index of the pattern attached to godot in the tile map editor
var is_corner: bool
var is_atomic: bool
var pattern: Array # Array of Vector2i


func _init(p_name: String, p_index: int, p_is_corner: bool, p_is_atomic: bool, p_pattern: Array):
	name = p_name
	index = p_index
	is_corner = p_is_corner
	p_is_atomic = p_is_atomic
	pattern = p_pattern
