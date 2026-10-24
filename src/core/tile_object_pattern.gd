class_name TileObjectPattern
extends Resource

@export var pattern_name: StringName
@export var cells: Array[TileObjectCell] = []
@export var variants: Array[TileObjectCell] = []
@export var atlas_source_name: StringName
@export var atlas_coords: Array[Vector2i] = []
@export var local_positions: Array[Vector2i] = []
@export var footprint: Array[Vector2i] = [Vector2i.ZERO]
@export var allowed_terrain_types: Array[int] = []


func get_random_variant() -> TileObjectCell:
	if variants.is_empty():
		push_error("Tile object pattern '%s' has no variants." % pattern_name)
		return null
	return variants[randi_range(0, variants.size() - 1)]


func try_place(
	p_tile_map: TileMapLayer,
	p_anchor: Vector2i,
	p_map_size: Vector2i,
	p_occupied_cells: Dictionary,
	p_terrain_by_cell: Dictionary = {}
) -> bool:
	var selected_cells := _get_visual_cells()
	if not variants.is_empty():
		if not cells.is_empty() or not atlas_coords.is_empty():
			push_error("Tile object pattern '%s' cannot define cells and variants together." % pattern_name)
			return false
		var variant := get_random_variant()
		if variant == null:
			return false
		selected_cells = [variant]
	if selected_cells.is_empty():
		push_error("Tile object pattern '%s' has no visual cells." % pattern_name)
		return false

	if not _can_place(p_anchor, p_map_size, p_occupied_cells, p_terrain_by_cell):
		return false
	for object_cell: TileObjectCell in selected_cells:
		var map_cell := p_anchor + object_cell.local_position
		if map_cell.x < 0 or map_cell.y < 0 or map_cell.x >= p_map_size.x or map_cell.y >= p_map_size.y:
			return false
	if not _can_render(p_tile_map, selected_cells):
		return false

	for object_cell: TileObjectCell in selected_cells:
		var source_id := _get_source_id(p_tile_map.tile_set, object_cell.atlas_source_name)
		p_tile_map.set_cell(
			p_anchor + object_cell.local_position,
			source_id,
			object_cell.atlas_coords,
			object_cell.alternative_tile
		)

	for footprint_cell: Vector2i in footprint:
		p_occupied_cells[p_anchor + footprint_cell] = true

	return true


func _get_visual_cells() -> Array[TileObjectCell]:
	if not cells.is_empty():
		if not atlas_coords.is_empty():
			push_error("Tile object pattern '%s' cannot define cells and atlas_coords together." % pattern_name)
			return []
		return cells
	if atlas_coords.is_empty():
		return []
	if atlas_coords.size() != local_positions.size() or atlas_source_name == &"":
		push_error("Tile object pattern '%s' has incomplete atlas-cell data." % pattern_name)
		return []

	var visual_cells: Array[TileObjectCell] = []
	for index in range(atlas_coords.size()):
		var object_cell := TileObjectCell.new()
		object_cell.atlas_source_name = atlas_source_name
		object_cell.atlas_coords = atlas_coords[index]
		object_cell.local_position = local_positions[index]
		visual_cells.append(object_cell)
	return visual_cells


func _can_place(
	p_anchor: Vector2i,
	p_map_size: Vector2i,
	p_occupied_cells: Dictionary,
	p_terrain_by_cell: Dictionary
) -> bool:
	if footprint.is_empty():
		push_error("Tile object pattern '%s' has no footprint." % pattern_name)
		return false

	var checked_cells: Dictionary = {}
	for footprint_cell: Vector2i in footprint:
		var map_cell := p_anchor + footprint_cell
		if checked_cells.has(map_cell):
			push_error("Tile object pattern '%s' has duplicate footprint cells." % pattern_name)
			return false
		checked_cells[map_cell] = true
		if map_cell.x < 0 or map_cell.y < 0 or map_cell.x >= p_map_size.x or map_cell.y >= p_map_size.y:
			return false
		if p_occupied_cells.has(map_cell):
			return false
		if not allowed_terrain_types.is_empty():
			if not p_terrain_by_cell.has(map_cell):
				return false
			if not allowed_terrain_types.has(int(p_terrain_by_cell[map_cell])):
				return false

	return true


func _can_render(p_tile_map: TileMapLayer, p_cells: Array[TileObjectCell]) -> bool:
	if p_tile_map == null or p_tile_map.tile_set == null:
		push_error("Cannot place tile object pattern '%s': TileMapLayer has no TileSet." % pattern_name)
		return false
	if p_cells.is_empty():
		push_error("Tile object pattern '%s' has no visual cells." % pattern_name)
		return false

	for object_cell: TileObjectCell in p_cells:
		var source_id := _get_source_id(p_tile_map.tile_set, object_cell.atlas_source_name)
		if source_id == -1:
			push_error(
				"TileSet is missing atlas source '%s' for pattern '%s'."
				% [object_cell.atlas_source_name, pattern_name]
			)
			return false
		var source := p_tile_map.tile_set.get_source(source_id)
		if not source is TileSetAtlasSource:
			push_error("Tile object pattern '%s' references a non-atlas source." % pattern_name)
			return false
		var atlas_source := source as TileSetAtlasSource
		if not atlas_source.has_tile(object_cell.atlas_coords):
			push_error(
				"Atlas '%s' has no tile at %s for pattern '%s'."
				% [object_cell.atlas_source_name, object_cell.atlas_coords, pattern_name]
			)
			return false
		if atlas_source.get_tile_data(object_cell.atlas_coords, object_cell.alternative_tile) == null:
			push_error(
				"Atlas '%s' tile %s has no alternative %s for pattern '%s'."
				% [
					object_cell.atlas_source_name,
					object_cell.atlas_coords,
					object_cell.alternative_tile,
					pattern_name
				]
			)
			return false

	return true


func _get_source_id(p_tile_set: TileSet, p_source_name: StringName) -> int:
	for source_index in range(p_tile_set.get_source_count()):
		var source_id := p_tile_set.get_source_id(source_index)
		if StringName(p_tile_set.get_source(source_id).resource_name) == p_source_name:
			return source_id
	return -1
