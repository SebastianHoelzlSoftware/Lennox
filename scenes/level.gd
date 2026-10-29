extends TileMapLayer

const CliffAutotiler = preload("res://src/core/cliff_autotiler.gd")
const ObjectCatalog = preload("res://src/core/object_catalog.gd")

const TILE_SOURCE_NAME := &"Ground_rocks"
const TILE_ATLAS_COORDS := {
	TileType.GRASS: [Vector2i(2, 1), Vector2i(2, 2), Vector2i(3, 2)],
	TileType.SAND: [Vector2i(2, 1), Vector2i(2, 2), Vector2i(3, 2)],
	TileType.WATER: [Vector2i(2, 1), Vector2i(2, 2), Vector2i(3, 2)],
	TileType.ROCK: [Vector2i(2, 1), Vector2i(2, 2), Vector2i(3, 2)],
	TileType.TREE: [Vector2i(2, 1), Vector2i(2, 2), Vector2i(3, 2)],
}

var level: Level
var tile_mapper: TileMapper
var _tile_source_id: int = -1
var _objects_node: Node2D = null


func load_level(p_level: Level, p_tile_mapper: TileMapper) -> void:
	tile_mapper = p_tile_mapper
	if tile_set == null:
		push_error("Cannot load level: LevelTileMap has no TileSet.")
		return
	if not _cache_tile_source_id():
		return

	level = p_level
	clear()
	_setup_objects_container()

	for x in range(level.width):
		for y in range(level.height):
			var chunk := level.get_chunk(x, y)
			if chunk != null:
				_draw_chunk(chunk, x, y)


func _setup_objects_container() -> void:
	if _objects_node != null and is_instance_valid(_objects_node):
		for child in _objects_node.get_children():
			child.queue_free()
	else:
		_objects_node = get_parent().get_node_or_null("WorldObjects") as Node2D
		if _objects_node == null:
			_objects_node = Node2D.new()
			_objects_node.name = "WorldObjects"
			_objects_node.y_sort_enabled = true
			get_parent().add_child(_objects_node)


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
	# 1. Dibujar baldosas base del terreno (valle / suelo inferior)
	for tile_x in range(p_chunk.tiles.size()):
		for tile_y in range(p_chunk.tiles[tile_x].size()):
			var global_x := p_chunk_x * level.chunk_size + tile_x
			var global_y := p_chunk_y * level.chunk_size + tile_y
			var draw_pos := Vector2i(global_x, global_y)
			var tile_type: TileType.Type = p_chunk.get_tile(tile_x, tile_y)
			var coords_list: Array = TILE_ATLAS_COORDS.get(tile_type, [Vector2i(2, 1)])
			var atlas_coord: Vector2i = coords_list[(global_x * 7 + global_y * 13) % coords_list.size()]
			set_cell(draw_pos, _tile_source_id, atlas_coord)

	# 2. Dibujar las plataformas elevadas con acantilados, cornisas y caras de roca (autotiling)
	var chunk_origin := Vector2i(p_chunk_x * level.chunk_size, p_chunk_y * level.chunk_size)
	if tile_mapper != null:
		for barrier_item in p_chunk.barriers:
			var barrier: Barrier = barrier_item
			if not barrier.cells.is_empty():
				CliffAutotiler.draw_plateau_cells(tile_mapper, chunk_origin, barrier.cells, p_chunk.biome)

	# 3. Instanciar objetos poblados del chunk (ruinas en mesetas, arboles/rocas en valles)
	if _objects_node != null:
		for obj in p_chunk.placed_objects:
			var path: String = obj.get("path", "")
			var local_pos: Vector2i = obj.get("pos", Vector2i.ZERO)
			var global_tile := Vector2i(
				p_chunk_x * level.chunk_size + local_pos.x,
				p_chunk_y * level.chunk_size + local_pos.y
			)
			var tex := ObjectCatalog.load_texture(path)
			if tex != null:
				var sprite := Sprite2D.new()
				sprite.texture = tex
				sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
				sprite.position = map_to_local(global_tile)
				_objects_node.add_child(sprite)
