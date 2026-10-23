extends TileMapLayer

const TILE_SOURCE_NAME := &"Ground_rocks"
const TILE_ATLAS_COORDS := {
	TileType.GRASS: [Vector2i(2, 1), Vector2i(2, 2), Vector2i(3, 2)],
	TileType.ROCK: [
		Vector2i(8, 3),
		Vector2i(9, 3),
		Vector2i(10, 3),
		Vector2i(11, 3),
		Vector2i(12, 3),
		Vector2i(13, 3),
	],
	TileType.TREE: [
		Vector2i(8, 3),
		Vector2i(9, 3),
		Vector2i(10, 3),
		Vector2i(11, 3),
		Vector2i(12, 3),
		Vector2i(13, 3),
	],
	TileType.SAND: [Vector2i(2, 1), Vector2i(2, 2), Vector2i(3, 2)],
	TileType.WATER: [Vector2i(2, 1), Vector2i(2, 2), Vector2i(3, 2)],
}

var level: Level
var _tile_source_id: int = -1


func load_level(p_level: Level) -> void:
	if tile_set == null:
		push_error("Cannot load level: LevelTileMap has no TileSet.")
		return
	if not _cache_tile_source_id():
		return

	level = p_level
	clear()

	for x in range(level.width):
		for y in range(level.height):
			var chunk := level.get_chunk(x, y)
			if chunk != null:
				_draw_chunk(chunk, x, y)


func _cache_tile_source_id() -> bool:
	_tile_source_id = -1
	for source_index in range(tile_set.get_source_count()):
		var source_id := tile_set.get_source_id(source_index)
		var source: TileSetSource = tile_set.get_source(source_id)
		if StringName(source.resource_name) == TILE_SOURCE_NAME:
			if not source is TileSetAtlasSource:
				push_error("TileSet source '%s' is not an atlas." % TILE_SOURCE_NAME)
				return false
			_tile_source_id = source_id
			break

	if _tile_source_id == -1:
		push_error("TileSet is missing an atlas source named '%s'." % TILE_SOURCE_NAME)
		return false

	var atlas_source := tile_set.get_source(_tile_source_id) as TileSetAtlasSource
	for tile_type: int in TILE_ATLAS_COORDS:
		for atlas_coords: Vector2i in TILE_ATLAS_COORDS[tile_type]:
			if not atlas_source.has_tile(atlas_coords):
				push_error(
					"TileSet atlas '%s' has no tile at %s for tile type '%s'."
					% [TILE_SOURCE_NAME, atlas_coords, tile_type]
				)
				return false

	return true


func _draw_chunk(p_chunk: Chunk, p_chunk_x: int, p_chunk_y: int) -> void:
	for tile_x in range(p_chunk.tiles.size()):
		for tile_y in range(p_chunk.tiles[tile_x].size()):
			var global_x := p_chunk_x * level.chunk_size + tile_x
			var global_y := p_chunk_y * level.chunk_size + tile_y
			var tile_type: TileType.Type = p_chunk.get_tile(tile_x, tile_y)
			var atlas_coords := _get_tile_atlas_coords(tile_type)
			if atlas_coords != Vector2i(-1, -1):
				set_cell(Vector2i(global_x, global_y), _tile_source_id, atlas_coords)


func _get_tile_atlas_coords(p_tile_type: TileType.Type) -> Vector2i:
	var atlas_coords: Array = TILE_ATLAS_COORDS.get(p_tile_type, [])
	if atlas_coords.is_empty():
		push_error("No atlas tile is configured for tile type '%s'." % p_tile_type)
		return Vector2i(-1, -1)
	return atlas_coords[randi_range(0, atlas_coords.size() - 1)]
