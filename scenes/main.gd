# main.gd
extends Node2D

@onready var level_tilemap: TileMapLayer = $LevelTileMap
@onready var object_tilemap: TileMapLayer = $ObjectTileMap
@onready var player: CharacterBody2D = $CharacterBody2D

var start_cell := Vector2i.ZERO


func _ready() -> void:
	var tile_mapper := TileMapper.new(level_tilemap)
	# 6x6 chunks de 32x32 baldosas cada uno = 192x192 baldosas de mundo continuo
	var level := Level.new(6, 6, 32, 16, 12345)
	level.generate()

	@warning_ignore("INTEGER_DIVISION")
	start_cell = Vector2i(
		level.width * level.chunk_size / 2,
		level.height * level.chunk_size / 2
	)

	level_tilemap.load_level(level, tile_mapper)
	player.position = to_local(level_tilemap.to_global(level_tilemap.map_to_local(start_cell)))

	if OS.get_cmdline_user_args().has("--screenshot") or OS.get_cmdline_args().has("--screenshot"):
		var camera := player.get_node_or_null("Camera2D") as Camera2D
		if camera != null:
			camera.zoom = Vector2(0.85, 0.85)
		_capture_and_quit()


func _unhandled_input(event: InputEvent) -> void:
	var camera := player.get_node_or_null("Camera2D") as Camera2D
	if camera == null:
		return
	if event is InputEventMouseButton and event.is_pressed():
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			camera.zoom = (camera.zoom * 1.15).clamp(Vector2(0.3, 0.3), Vector2(3.5, 3.5))
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			camera.zoom = (camera.zoom * 0.85).clamp(Vector2(0.3, 0.3), Vector2(3.5, 3.5))


func _capture_and_quit() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	var viewport := get_viewport()
	if viewport != null:
		var tex := viewport.get_texture()
		if tex != null:
			var img := tex.get_image()
			if img != null:
				img.save_png("doc/images/screenshot_of_the_day.png")
	get_tree().quit()
