# main.gd
extends Node2D

@onready var level_tilemap: TileMapLayer = $LevelTileMap
@onready var object_tilemap: TileMapLayer = $ObjectTileMap
@onready var player: CharacterBody2D = $CharacterBody2D

const TILE_OBJECT_LIBRARY: TileObjectLibrary = preload(
	"res://assets/tiles/rocks/tile_object_library.tres"
)
const GRASSLAND_OBJECT_SEARCH_RADIUS := 6
const GRASSLAND_DECORATIONS := [
	{"pattern": &"objects_r04_c08", "offset": Vector2i(-24, -24)},
	{"pattern": &"objects_r04_c14", "offset": Vector2i(0, -28)},
	{"pattern": &"objects_r05_c19", "offset": Vector2i(22, -22)},
	{"pattern": &"objects_r06_c23", "offset": Vector2i(29, -9)},
	{"pattern": &"objects_r09_c16", "offset": Vector2i(27, 10)},
	{"pattern": &"objects_r15_c16", "offset": Vector2i(16, 25)},
	{"pattern": &"objects_r18_c02", "offset": Vector2i(-4, 28)},
	{"pattern": &"objects_r18_c09", "offset": Vector2i(-23, 22)},
	{"pattern": &"objects_r18_c12", "offset": Vector2i(-29, 5)},
	{"pattern": &"objects_r18_c23", "offset": Vector2i(-28, -11)},
	{"pattern": &"bone_fragment", "offset": Vector2i(-9, -18)},
	{"pattern": &"objects_r29_c14", "offset": Vector2i(11, -15)},
	{"pattern": &"objects_r34_c14", "offset": Vector2i(22, 17)},
	{"pattern": &"objects_r35_c10", "offset": Vector2i(9, 24)},
	{"pattern": &"objects_r39_c10", "offset": Vector2i(-16, 17)},
	{"pattern": &"objects_r41_c22", "offset": Vector2i(-18, -2)},
	{"pattern": &"objects_r44_c02", "offset": Vector2i(-15, -25)},
	{"pattern": &"objects_r44_c18", "offset": Vector2i(2, -20)},
]

var start_cell := Vector2i.ZERO
var start_biome_chunks: Array[Vector2i] = []
var start_biome_type: BiomeType.Type = BiomeType.GRASSLAND


func _ready() -> void:
	var level := Level.new(12, 12, 32, 16, 12345)
	level.generate()
	start_biome_chunks = _find_nearest_biome_region(level.biome_map, BiomeType.GRASSLAND)
	if start_biome_chunks.is_empty():
		push_warning("No grass biome was generated; starting in the center of the world.")
		start_cell = Vector2i(
			level.width * level.chunk_size / 2,
			level.height * level.chunk_size / 2
		)
	else:
		var start_chunk := _get_region_center(start_biome_chunks)
		var chunk := level.get_chunk(start_chunk.x, start_chunk.y)
		start_cell = _get_nearest_walkable_cell(chunk, start_chunk, level.chunk_size)

	level_tilemap.load_level(level)
	if not start_biome_chunks.is_empty():
		_place_grassland_decorations(level, start_cell)
	player.position = to_local(level_tilemap.to_global(level_tilemap.map_to_local(start_cell)))


func _find_nearest_biome_region(
	p_biome_map: Array,
	p_biome_type: BiomeType.Type
) -> Array[Vector2i]:
	if p_biome_map.is_empty() or p_biome_map[0].is_empty():
		return []

	var visited: Dictionary = {}
	var map_center := Vector2(p_biome_map.size() - 1, p_biome_map[0].size() - 1) / 2.0
	var nearest_region: Array[Vector2i] = []
	var nearest_distance := INF
	for x in range(p_biome_map.size()):
		for y in range(p_biome_map[x].size()):
			var origin := Vector2i(x, y)
			if visited.has(origin) or p_biome_map[x][y] != p_biome_type:
				continue

			var region: Array[Vector2i] = []
			var frontier: Array[Vector2i] = [origin]
			visited[origin] = true
			while not frontier.is_empty():
				var chunk_position: Vector2i = frontier.pop_back()
				region.append(chunk_position)
				for direction: Vector2i in [
					Vector2i.LEFT,
					Vector2i.RIGHT,
					Vector2i.UP,
					Vector2i.DOWN,
				]:
					var neighbor := chunk_position + direction
					if (
						neighbor.x < 0
						or neighbor.y < 0
						or neighbor.x >= p_biome_map.size()
						or neighbor.y >= p_biome_map[neighbor.x].size()
						or visited.has(neighbor)
						or p_biome_map[neighbor.x][neighbor.y] != p_biome_type
					):
						continue
					visited[neighbor] = true
					frontier.append(neighbor)

			var region_center := Vector2.ZERO
			for chunk_position: Vector2i in region:
				region_center += Vector2(chunk_position)
			region_center /= region.size()
			var distance := map_center.distance_squared_to(region_center)
			if distance < nearest_distance or (
				is_equal_approx(distance, nearest_distance)
				and region.size() > nearest_region.size()
			):
				nearest_distance = distance
				nearest_region = region

	return nearest_region


func _get_region_center(p_region: Array[Vector2i]) -> Vector2i:
	var center := Vector2.ZERO
	for chunk_position: Vector2i in p_region:
		center += Vector2(chunk_position)
	center /= p_region.size()

	var center_chunk := p_region[0]
	var closest_distance := INF
	for chunk_position: Vector2i in p_region:
		var distance := center.distance_squared_to(Vector2(chunk_position))
		if distance < closest_distance:
			closest_distance = distance
			center_chunk = chunk_position
	return center_chunk


func _get_nearest_walkable_cell(
	p_chunk: Chunk,
	p_chunk_position: Vector2i,
	p_chunk_size: int
) -> Vector2i:
	if p_chunk == null:
		push_error("Cannot find a spawn cell: selected grass-biome chunk is missing.")
		return p_chunk_position * p_chunk_size + Vector2i.ONE * (p_chunk_size / 2)

	var local_center := Vector2(p_chunk_size / 2, p_chunk_size / 2)
	var nearest_cell := Vector2i(-1, -1)
	var nearest_distance := INF
	for local_x in range(p_chunk_size):
		for local_y in range(p_chunk_size):
			if p_chunk.get_tile(local_x, local_y) != TileType.GRASS:
				continue
			var distance := local_center.distance_squared_to(Vector2(local_x, local_y))
			if distance < nearest_distance:
				nearest_distance = distance
				nearest_cell = Vector2i(local_x, local_y)

	if nearest_cell == Vector2i(-1, -1):
		push_error("Cannot find a walkable grass tile in the selected grass-biome chunk.")
		return p_chunk_position * p_chunk_size + Vector2i.ONE * (p_chunk_size / 2)
	return p_chunk_position * p_chunk_size + nearest_cell


func _place_grassland_decorations(p_level: Level, p_center_cell: Vector2i) -> void:
	if object_tilemap.tile_set == null:
		push_error("Cannot decorate grass biome: ObjectTileMap has no TileSet.")
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
	for courtyard_object: Dictionary in GRASSLAND_DECORATIONS:
		if not _place_pattern_near(
			StringName(courtyard_object["pattern"]),
			p_center_cell + courtyard_object["offset"],
			map_size,
			occupied_cells,
			terrain_by_cell
		):
			push_warning(
				"Could not place '%s' in the grass-biome starting area."
				% courtyard_object["pattern"]
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

	for radius in range(GRASSLAND_OBJECT_SEARCH_RADIUS + 1):
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
