# main.gd
extends Node2D

@onready var level_tilemap: TileMapLayer = $LevelTileMap
@onready var object_tilemap: TileMapLayer = $ObjectTileMap

const TILE_OBJECT_LIBRARY: TileObjectLibrary = preload(
	"res://assets/tiles/rocks/tile_object_library.tres"
)
const BONE_FRAGMENT_COUNT := 8
const SHOWCASE_OBJECTS := [
	{"pattern": &"objects_r04_c08", "anchor": Vector2i(15, 7)},
	{"pattern": &"objects_r44_c18", "anchor": Vector2i(8, 13)},
	{"pattern": &"objects_r09_c16", "anchor": Vector2i(23, 8)},
	{"pattern": &"objects_r18_c02", "anchor": Vector2i(16, 16)},
	{"pattern": &"objects_r35_c10", "anchor": Vector2i(27, 16)},
	{"pattern": &"bone_fragment", "anchor": Vector2i(8, 10)},
	{"pattern": &"bone_fragment", "anchor": Vector2i(22, 20)},
]


func _ready() -> void:
	var level := Level.new(12, 12, 32, 16, 12345)
	level.generate()
	level_tilemap.load_level(level)
	_place_showcase(level)


func _place_showcase(p_level: Level) -> void:
	if object_tilemap.tile_set == null:
		push_error("Cannot place showcase objects: ObjectTileMap has no TileSet.")
		return

	object_tilemap.clear()
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
	var placed_bones := 0
	for showcase_object: Dictionary in SHOWCASE_OBJECTS:
		if _place_pattern_near(
			StringName(showcase_object["pattern"]),
			showcase_object["anchor"],
			map_size,
			occupied_cells,
			terrain_by_cell
		) and showcase_object["pattern"] == &"bone_fragment":
			placed_bones += 1

	while placed_bones < BONE_FRAGMENT_COUNT:
		var bone_index := placed_bones
		var anchor := Vector2i(7 + bone_index * 4, 25 + (bone_index % 2) * 4)
		if not _place_pattern_near(
			&"bone_fragment",
			anchor,
			map_size,
			occupied_cells,
			terrain_by_cell
		):
			break
		placed_bones += 1

	if placed_bones < BONE_FRAGMENT_COUNT:
		push_warning(
			"Placed %d of %d showcase bone fragments on available grass."
			% [placed_bones, BONE_FRAGMENT_COUNT]
		)


func _place_pattern_near(
	p_pattern_name: StringName,
	p_anchor: Vector2i,
	p_map_size: Vector2i,
	p_occupied_cells: Dictionary,
	p_terrain_by_cell: Dictionary
) -> bool:
	var pattern := TILE_OBJECT_LIBRARY.get_pattern(p_pattern_name)
	if pattern == null:
		push_error("Tile object library is missing pattern '%s'." % p_pattern_name)
		return false
	pattern = pattern.duplicate() as TileObjectPattern
	pattern.allowed_terrain_types = [TileType.GRASS]

	var max_radius := 8
	for radius in range(max_radius + 1):
		for offset_y in range(-radius, radius + 1):
			var offset_x_abs := radius - absi(offset_y)
			var offsets := [Vector2i(-offset_x_abs, offset_y)]
			if offset_x_abs > 0:
				offsets.append(Vector2i(offset_x_abs, offset_y))
			for offset: Vector2i in offsets:
				if pattern.try_place(
					object_tilemap,
					p_anchor + offset,
					p_map_size,
					p_occupied_cells,
					p_terrain_by_cell
				):
					return true

	return false
