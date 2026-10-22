# main.gd
extends Node2D

@onready var level_tilemap: TileMapLayer = $LevelTileMap


func _ready() -> void:
	# Level generieren
	var level := Level.new(64, 64, 32, 32, 12345)
	level.generate()

	# Level in tilemap laden
	level_tilemap.load_level(level)
