extends TileMapLayer

const TILE_SOURCE_NAMES := {
	TileType.GRASS: [&"gras_01", &"gras_02"],
	TileType.ROCK: [&"rock_01", &"rock_02"],
	TileType.TREE: [&"tree_01"],
	TileType.SAND: [&"sand_01"],
	TileType.WATER: [&"water_01"],
}

var level: Level
var _tile_source_ids: Dictionary = {}


func load_level(p_level: Level) -> void:
	if tile_set == null:
		push_error("Cannot load level: LevelTileMap has no TileSet.")
		return
	if not _cache_tile_source_ids():
		return

	level = p_level
	clear()

	for x in range(level.width):
		for y in range(level.height):
			var chunk := level.get_chunk(x, y)
			if chunk != null:
				_draw_chunk(chunk, x, y)


func _cache_tile_source_ids() -> bool:
	var source_ids_by_name: Dictionary = {}
	for source_index in range(tile_set.get_source_count()):
		var source_id := tile_set.get_source_id(source_index)
		var source: TileSetSource = tile_set.get_source(source_id)
		var source_name := StringName(source.resource_name)
		if source_name != &"":
			source_ids_by_name[source_name] = source_id

	_tile_source_ids.clear()
	for tile_type: int in TILE_SOURCE_NAMES:
		var source_ids: Array[int] = []
		for source_name: StringName in TILE_SOURCE_NAMES[tile_type]:
			if not source_ids_by_name.has(source_name):
				push_error("TileSet is missing an atlas source named '%s'." % source_name)
				return false
			source_ids.append(source_ids_by_name[source_name])
		_tile_source_ids[tile_type] = source_ids

	return true


func _draw_chunk(p_chunk: Chunk, p_chunk_x: int, p_chunk_y: int) -> void:
	for tile_x in range(p_chunk.tiles.size()):
		for tile_y in range(p_chunk.tiles[tile_x].size()):
			var global_x := p_chunk_x * level.chunk_size + tile_x
			var global_y := p_chunk_y * level.chunk_size + tile_y
			var tile_type: TileType.Type = p_chunk.get_tile(tile_x, tile_y)
			var source_id := _get_tile_id(tile_type)
			if source_id != -1:
				set_cell(Vector2i(global_x, global_y), source_id, Vector2i.ZERO)


func _get_tile_id(p_tile_type: TileType.Type) -> int:
	var source_ids: Array = _tile_source_ids.get(p_tile_type, [])
	if source_ids.is_empty():
		push_error("No atlas source is configured for tile type '%s'." % p_tile_type)
		return -1
	return source_ids[randi_range(0, source_ids.size() - 1)]
