# main.gd
extends Node2D

@onready var level_tilemap: TileMapLayer = $LevelTileMap
@onready var object_tilemap: TileMapLayer = $ObjectTileMap
@onready var player: CharacterBody2D = $CharacterBody2D

var start_cell := Vector2i.ZERO


func _ready() -> void:
	var tile_mapper := TileMapper.new(level_tilemap)
	var level := Level.new(12, 12, 32, 16, 12345)
	level.generate()

	"""
	@warning_ignore("INTEGER_DIVISION")
	start_cell = Vector2i(
		level.width * level.chunk_size / 2,
		level.height * level.chunk_size / 2
	)
	"""

	level_tilemap.load_level(level, tile_mapper)
	player.position = to_local(level_tilemap.to_global(level_tilemap.map_to_local(start_cell)))

	tile_mapper.draw_editor_pattern("Upper Left Corner (High Plateau Rocks)", start_cell + Vector2i(10, 0))
