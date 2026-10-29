class_name CliffAutotiler
extends RefCounted

enum PieceType {
	UPPER_LEFT_CORNER,
	UPPER_RIGHT_CORNER,
	LOWER_LEFT_CORNER,
	LOWER_RIGHT_CORNER,
	TOP_EDGE,
	BOTTOM_EDGE,
	LEFT_EDGE,
	RIGHT_EDGE,
	CENTER_FILL,
	ISOLATED
}

const PATTERN_NAMES := {
	PieceType.UPPER_LEFT_CORNER: "Upper Left Corner (High Plateau Rocks)",
	PieceType.UPPER_RIGHT_CORNER: "Upper Right Corner (High Plateau Rocks)",
	PieceType.LOWER_LEFT_CORNER: "Lower Left Corner (High Plateau Rocks)",
	PieceType.LOWER_RIGHT_CORNER: "Lower Right Corner (High Plateau Rocks)",
	PieceType.TOP_EDGE: "Top Edge Straight (High Plateau Rocks)",
	PieceType.BOTTOM_EDGE: "Bottom Edge Straight (High Plateau Rocks)",
	PieceType.LEFT_EDGE: "Left Edge Straight (High Plateau Rocks)",
	PieceType.RIGHT_EDGE: "Right Edge Straight (High Plateau Rocks)",
	PieceType.CENTER_FILL: "Ground Plate (High Plateau Rocks) Variant A",
	PieceType.ISOLATED: "Upper Left Corner (High Plateau Rocks)"
}

const MACRO_CELL_SIZE := Vector2i(2, 2)


static func get_pattern_name(p_type: PieceType) -> String:
	return PATTERN_NAMES.get(p_type, "Ground Plate (High Plateau Rocks) Variant A")


static func determine_piece_type(
	c: int,
	r: int,
	is_solid: Callable
) -> PieceType:
	var north: bool = is_solid.call(c, r - 1)
	var south: bool = is_solid.call(c, r + 1)
	var west: bool = is_solid.call(c - 1, r)
	var east: bool = is_solid.call(c + 1, r)

	# Isolated block
	if not north and not south and not west and not east:
		return PieceType.ISOLATED

	# Outer corners
	if not north and not west:
		return PieceType.UPPER_LEFT_CORNER
	if not north and not east:
		return PieceType.UPPER_RIGHT_CORNER
	if not south and not west:
		return PieceType.LOWER_LEFT_CORNER
	if not south and not east:
		return PieceType.LOWER_RIGHT_CORNER

	# Straight edges
	if not north:
		return PieceType.TOP_EDGE
	if not south:
		return PieceType.BOTTOM_EDGE
	if not west:
		return PieceType.LEFT_EDGE
	if not east:
		return PieceType.RIGHT_EDGE

	# Interior
	return PieceType.CENTER_FILL


static func draw_plateau_rect(
	tile_mapper: TileMapper,
	origin_tile: Vector2i,
	cols: int,
	rows: int
) -> void:
	if cols <= 0 or rows <= 0:
		return

	var is_in_rect := func(c: int, r: int) -> bool:
		return c >= 0 and c < cols and r >= 0 and r < rows

	for r in range(rows):
		for c in range(cols):
			var piece := determine_piece_type(c, r, is_in_rect)
			var pat_name := get_pattern_name(piece)
			var draw_pos := origin_tile + Vector2i(c * MACRO_CELL_SIZE.x, r * MACRO_CELL_SIZE.y)
			tile_mapper.draw_editor_pattern(pat_name, draw_pos)


static func draw_plateau_mask(
	tile_mapper: TileMapper,
	origin_tile: Vector2i,
	mask: Array
) -> void:
	if mask.is_empty():
		return
	var cols: int = mask.size()
	var rows: int = mask[0].size() if cols > 0 else 0

	var is_solid := func(c: int, r: int) -> bool:
		if c >= 0 and c < cols and r >= 0 and r < rows:
			return bool(mask[c][r])
		return false

	for c in range(cols):
		for r in range(rows):
			if mask[c][r]:
				var piece := determine_piece_type(c, r, is_solid)
				var pat_name := get_pattern_name(piece)
				var draw_pos := origin_tile + Vector2i(c * MACRO_CELL_SIZE.x, r * MACRO_CELL_SIZE.y)
				tile_mapper.draw_editor_pattern(pat_name, draw_pos)


static func draw_plateau_cells(
	tile_mapper: TileMapper,
	origin_tile: Vector2i,
	cells: Array[Vector2i]
) -> void:
	if cells.is_empty():
		return

	var cell_set: Dictionary = {}
	for cell in cells:
		cell_set[cell] = true

	var is_solid := func(c: int, r: int) -> bool:
		return cell_set.has(Vector2i(c, r))

	for cell in cells:
		var c: int = cell.x
		var r: int = cell.y
		var piece := determine_piece_type(c, r, is_solid)
		var pat_name := get_pattern_name(piece)
		var draw_pos := origin_tile + Vector2i(c * MACRO_CELL_SIZE.x, r * MACRO_CELL_SIZE.y)
		tile_mapper.draw_editor_pattern(pat_name, draw_pos)


