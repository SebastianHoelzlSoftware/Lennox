# main.gd
extends Node2D

@onready var level_tilemap: TileMapLayer = $LevelTileMap
@onready var object_tilemap: TileMapLayer = $ObjectTileMap

const TILE_OBJECT_LIBRARY: TileObjectLibrary = preload(
	"res://assets/tiles/rocks/tile_object_library.tres"
)
const BONE_FRAGMENT_COUNT := 8


func _ready() -> void:
	var level := Level.new(12, 12, 32, 16, 12345)
	level.generate()
	level_tilemap.load_level(level)
	_place_bone_fragments(level)


func _place_bone_fragments(p_level: Level) -> void:
	if object_tilemap.tile_set == null:
		push_error("Cannot place demo objects: ObjectTileMap has no TileSet.")
		return

	object_tilemap.clear()
	var pattern := TILE_OBJECT_LIBRARY.get_pattern(&"bone_fragment")
	if pattern == null:
		push_error("Tile object library is missing pattern 'bone_fragment'.")
		return

	var terrain_by_cell: Dictionary = {}
	for chunk_x in range(p_level.width):
		for chunk_y in range(p_level.height):
			var chunk := p_level.get_chunk(chunk_x, chunk_y)
			if chunk == null:
				continue
			for tile_x in range(chunk.tiles.size()):
				for tile_y in range(chunk.tiles[tile_x].size()):
					var map_cell := Vector2i(
						chunk_x * p_level.chunk_size + tile_x,
						chunk_y * p_level.chunk_size + tile_y
					)
					terrain_by_cell[map_cell] = chunk.get_tile(tile_x, tile_y)

	var map_size := Vector2i(
		p_level.width * p_level.chunk_size,
		p_level.height * p_level.chunk_size
	)
	var occupied_cells: Dictionary = {}
	var placed_count := 0
	for y in range(4, map_size.y - 2, 9):
		for x in range(4, map_size.x - 1, 11):
			if pattern.try_place(
				object_tilemap,
				Vector2i(x, y),
				map_size,
				occupied_cells,
				terrain_by_cell
			):
				placed_count += 1
				if placed_count == BONE_FRAGMENT_COUNT:
					return

	if placed_count < BONE_FRAGMENT_COUNT:
		push_warning(
			"Placed %d of %d demo bone fragments on available grass."
			% [placed_count, BONE_FRAGMENT_COUNT]
		)
