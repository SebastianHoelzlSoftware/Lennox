extends Node2D

@onready var level_tilemap: TileMapLayer = $LevelTileMap
@onready var player: CharacterBody2D = $CharacterBody2D
@onready var camera: Camera2D = $Camera2D

const CliffAutotiler = preload("res://src/core/cliff_autotiler.gd")
const ObjectCatalog = preload("res://src/core/object_catalog.gd")


func _ready() -> void:
	var tile_mapper := TileMapper.new(level_tilemap)

	# 1. Fill ground area with grass tiles
	var grass_coords := Vector2i(2, 1)
	for x in range(-5, 45):
		for y in range(-5, 35):
			level_tilemap.set_cell(Vector2i(x, y), 1, grass_coords)

	# 2. Draw Plateau 1: Clean 4x3 rectangular cliff plateau (8x6 tiles)
	CliffAutotiler.draw_plateau_rect(tile_mapper, Vector2i(4, 4), 4, 3)

	# 3. Draw Plateau 2: Small 2x2 cliff plateau (4x4 tiles)
	CliffAutotiler.draw_plateau_rect(tile_mapper, Vector2i(16, 4), 2, 2)

	# 4. Draw Plateau 3: Irregular L-shaped cliff barrier mask
	var l_mask: Array = [
		[true, true, true, true],
		[true, true, true, true],
		[true, true, false, false],
		[true, true, false, false],
		[true, true, false, false],
	]
	CliffAutotiler.draw_plateau_mask(tile_mapper, Vector2i(4, 14), l_mask)

	# 5. Place decorative objects
	_decorate_level()

	# 6. Position player in a clear walkable area
	if player != null:
		player.position = level_tilemap.map_to_local(Vector2i(18, 16))

	# 7. Position camera centered on the formations
	if camera != null:
		camera.position = level_tilemap.map_to_local(Vector2i(14, 12))

	if OS.get_cmdline_user_args().has("--screenshot") or OS.get_cmdline_args().has("--screenshot"):
		_capture_and_quit()


func _capture_and_quit() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	await save_screenshot("doc/images/visual_test_autotiling.png")
	get_tree().quit()


func _decorate_level() -> void:
	var decor_positions: Array[Vector2i] = [
		Vector2i(14, 10),
		Vector2i(22, 5),
		Vector2i(2, 2),
		Vector2i(16, 18),
		Vector2i(22, 16),
	]
	var rng := RandomNumberGenerator.new()
	rng.seed = 999
	for cell_pos in decor_positions:
		var obj_path := ObjectCatalog.get_random_biome_object(BiomeType.GRASSLAND, rng)
		if obj_path != "":
			var tex := ObjectCatalog.load_texture(obj_path)
			if tex != null:
				var sprite := Sprite2D.new()
				sprite.texture = tex
				sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
				sprite.position = level_tilemap.map_to_local(cell_pos)
				add_child(sprite)


func save_screenshot(path: String = "doc/images/visual_test_autotiling.png") -> bool:
	await get_tree().process_frame
	await get_tree().process_frame
	var viewport := get_viewport()
	if viewport != null:
		var tex := viewport.get_texture()
		if tex != null:
			var img := tex.get_image()
			if img != null:
				var err := img.save_png(path)
				return err == OK
	return false

