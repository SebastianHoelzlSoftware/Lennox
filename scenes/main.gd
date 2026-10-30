# main.gd
extends Node2D

@export var regenerate_on_start: bool = false
@export var world_seed: int = 691

@onready var level_tilemap: TileMapLayer = $LevelTileMap
@onready var object_tilemap: TileMapLayer = $ObjectTileMap
@onready var player: CharacterBody2D = $CharacterBody2D

var start_cell := Vector2i.ZERO
var level: Level


func _ready() -> void:
	# Jugador y objetos del mundo se ordenan por Y (el jugador pasa por detras de los arboles)
	y_sort_enabled = true

	var tile_mapper := TileMapper.new(level_tilemap)
	# 10x10 chunks de 32x32 baldosas = 320x320 baldosas de mundo continuo.
	# La semilla 691 contiene los 8 biomas, con un bosque encantado en el centro.
	level = Level.new(10, 10, 32, 16, world_seed)
	level.generate()

	@warning_ignore("INTEGER_DIVISION")
	var center := Vector2i(level.width * level.chunk_size / 2, level.height * level.chunk_size / 2)
	start_cell = level.find_open_tile_near(center)

	# Si el mapa ya esta horneado en la escena (para edicion manual en el editor de Godot),
	# conservamos las capas pintadas y solo regeneramos cuando regenerate_on_start es true
	# o cuando aun no existen las capas en la escena.
	var has_baked_map := level_tilemap.get_node_or_null("Ground") != null
	if regenerate_on_start or not has_baked_map:
		level_tilemap.load_level(level, tile_mapper)

	player.position = to_local(level_tilemap.to_global(level_tilemap.map_to_local(start_cell)))

	var args := OS.get_cmdline_user_args() + OS.get_cmdline_args()
	for arg: String in args:
		if arg.begins_with("--tour="):
			_capture_tour(arg.substr(7))
			return
	if args.has("--screenshot"):
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
	var camera := player.get_node_or_null("Camera2D") as Camera2D
	if camera != null:
		camera.zoom = Vector2(1.0, 1.0)
		camera.position_smoothing_enabled = false
	await _save_view("doc/images/screenshot_of_the_day.png")
	get_tree().quit()


func _capture_tour(p_dir: String) -> void:
	"""Guarda una captura centrada en un chunk de cada bioma (para revisar el arte)."""
	var camera := player.get_node_or_null("Camera2D") as Camera2D
	if camera == null:
		get_tree().quit()
		return
	camera.position_smoothing_enabled = false
	camera.zoom = Vector2(1.5, 1.5)
	var seen: Dictionary = {}
	for cx in range(level.width):
		for cy in range(level.height):
			var biome: int = level.get_chunk(cx, cy).biome
			if seen.has(biome):
				continue
			seen[biome] = true
			var tile := Vector2i(cx * level.chunk_size + 16, cy * level.chunk_size + 16)
			player.position = level_tilemap.map_to_local(tile)
			await _save_view("%s/tour_%s.png" % [p_dir, BiomeType.Type.keys()[biome].to_lower()])
	camera.zoom = Vector2(0.6, 0.6)
	player.position = level_tilemap.map_to_local(start_cell)
	await _save_view("%s/tour_overview.png" % p_dir)
	get_tree().quit()


func _save_view(p_path: String) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	if img != null:
		img.save_png(p_path)
