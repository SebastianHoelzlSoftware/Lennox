extends Node2D

@onready var level_tilemap: TileMapLayer = $LevelTileMap
@onready var objects_container: Node2D = $ObjectsContainer
@onready var player: CharacterBody2D = $CharacterBody2D
@onready var camera: Camera2D = $CharacterBody2D/Camera2D

const CliffAutotiler = preload("res://src/core/cliff_autotiler.gd")
const ObjectCatalog = preload("res://src/core/object_catalog.gd")

const MAP_START := Vector2i(-10, -10)
const MAP_END := Vector2i(160, 120)
const GRASS_COORDS := Vector2i(2, 1)

var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.seed = 20261029
	var tile_mapper := TileMapper.new(level_tilemap)

	# 1. Fill ground with lush grass tiles
	_fill_ground()

	# 2. Build diverse autotiled cliff formations
	_build_cliff_formations(tile_mapper)

	# 3. Populate with hundreds of biome and common objects
	_populate_objects()

	# 4. Position player and camera
	if player != null:
		player.position = level_tilemap.map_to_local(Vector2i(42, 36))

	# 5. Handle automated screenshot capture if triggered via CLI
	if OS.get_cmdline_user_args().has("--screenshot") or OS.get_cmdline_args().has("--screenshot"):
		_capture_and_quit()


func _unhandled_input(event: InputEvent) -> void:
	if camera == null:
		return
	# Smooth zoom in / zoom out with mouse wheel
	if event is InputEventMouseButton and event.is_pressed():
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			camera.zoom = (camera.zoom * 1.15).clamp(Vector2(0.3, 0.3), Vector2(3.5, 3.5))
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			camera.zoom = (camera.zoom * 0.85).clamp(Vector2(0.3, 0.3), Vector2(3.5, 3.5))


func _fill_ground() -> void:
	for x in range(MAP_START.x, MAP_END.x):
		for y in range(MAP_START.y, MAP_END.y):
			level_tilemap.set_cell(Vector2i(x, y), 1, GRASS_COORDS)


func _build_cliff_formations(tile_mapper: TileMapper) -> void:
	# ==========================================
	# ZONE 1: Northern Fortress & Mesas (Top)
	# ==========================================
	# Large 7x4 fortress plateau
	CliffAutotiler.draw_plateau_rect(tile_mapper, Vector2i(6, 4), 7, 4)

	# Twin stepped mesas (4x3 and 3x3)
	CliffAutotiler.draw_plateau_rect(tile_mapper, Vector2i(28, 4), 4, 3)
	CliffAutotiler.draw_plateau_rect(tile_mapper, Vector2i(38, 6), 3, 3)

	# High solitary watchtowers / pillars (2x2)
	CliffAutotiler.draw_plateau_rect(tile_mapper, Vector2i(52, 6), 2, 2)
	CliffAutotiler.draw_plateau_rect(tile_mapper, Vector2i(62, 10), 2, 2)
	CliffAutotiler.draw_plateau_rect(tile_mapper, Vector2i(72, 4), 3, 2)

	# ==========================================
	# ZONE 2: Western Horseshoe Canyon & Craters
	# ==========================================
	# U-shaped horseshoe canyon opening to the south
	var horseshoe_mask: Array = [
		[true, true, true, true, true],
		[true, true, true, true, true],
		[true, true, false, false, false],
		[true, true, false, false, false],
		[true, true, false, false, false],
		[true, true, true, true, true],
		[true, true, true, true, true],
	]
	CliffAutotiler.draw_plateau_mask(tile_mapper, Vector2i(6, 26), horseshoe_mask)

	# Deep Crater / Hollow Ring with an enclosed valley
	var crater_cells: Array[Vector2i] = []
	for cx in range(6):
		for cy in range(6):
			# Hollow inside (2..3, 2..3)
			if (cx >= 2 and cx <= 3) and (cy >= 2 and cy <= 3):
				continue
			crater_cells.append(Vector2i(cx, cy))
	CliffAutotiler.draw_plateau_cells(tile_mapper, Vector2i(6, 52), crater_cells)

	# ==========================================
	# ZONE 3: Central Citadel (L & T Shapes)
	# ==========================================
	# Massive L-shaped ridge
	var large_l_mask: Array = [
		[true, true, true, true, true, true],
		[true, true, true, true, true, true],
		[true, true, false, false, false, false],
		[true, true, false, false, false, false],
		[true, true, false, false, false, false],
		[true, true, false, false, false, false],
	]
	CliffAutotiler.draw_plateau_mask(tile_mapper, Vector2i(32, 26), large_l_mask)

	# T-shaped defensive plateau
	var t_mask: Array = [
		[false, false, true, true, false, false],
		[false, false, true, true, false, false],
		[true, true, true, true, true, true],
		[true, true, true, true, true, true],
		[false, false, true, true, false, false],
		[false, false, true, true, false, false],
	]
	CliffAutotiler.draw_plateau_mask(tile_mapper, Vector2i(52, 30), t_mask)

	# ==========================================
	# ZONE 4: Eastern Serpentine Mountain Chain
	# ==========================================
	# A winding, organic mountain range stretching from top-right down
	var ridge_cells: Array[Vector2i] = []
	var cur_pos := Vector2i(0, 0)
	var steps: Array[Vector2i] = [
		Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(2, 1),
		Vector2i(3, 1), Vector2i(3, 2), Vector2i(4, 2), Vector2i(5, 2),
		Vector2i(5, 3), Vector2i(6, 3), Vector2i(6, 4), Vector2i(7, 4),
		Vector2i(7, 5), Vector2i(8, 5), Vector2i(9, 5), Vector2i(9, 6),
		Vector2i(10, 6), Vector2i(11, 6), Vector2i(11, 7), Vector2i(12, 7),
		Vector2i(12, 8), Vector2i(13, 8), Vector2i(13, 9), Vector2i(14, 9),
	]
	for s in steps:
		# Give the ridge a thickness of 2 macro-cells
		ridge_cells.append(s)
		ridge_cells.append(s + Vector2i(0, 1))
		ridge_cells.append(s + Vector2i(1, 0))
	CliffAutotiler.draw_plateau_cells(tile_mapper, Vector2i(85, 12), ridge_cells)

	# ==========================================
	# ZONE 5: Southern Organic Blob Formations & Archipelagos
	# ==========================================
	_draw_organic_blob(tile_mapper, Vector2i(10, 75), 4)
	_draw_organic_blob(tile_mapper, Vector2i(40, 72), 5)
	_draw_organic_blob(tile_mapper, Vector2i(75, 74), 4)
	_draw_organic_blob(tile_mapper, Vector2i(110, 70), 5)

	# Stepping stone islands
	CliffAutotiler.draw_plateau_rect(tile_mapper, Vector2i(25, 96), 3, 2)
	CliffAutotiler.draw_plateau_rect(tile_mapper, Vector2i(58, 96), 2, 3)
	CliffAutotiler.draw_plateau_rect(tile_mapper, Vector2i(92, 94), 4, 2)
	CliffAutotiler.draw_plateau_rect(tile_mapper, Vector2i(124, 96), 3, 3)


func _draw_organic_blob(tile_mapper: TileMapper, origin_tile: Vector2i, radius: int) -> void:
	var cells: Array[Vector2i] = []
	var r_sq := float(radius * radius)
	for x in range(-radius, radius + 1):
		for y in range(-radius, radius + 1):
			var dist_sq := float(x * x + y * y)
			# Add subtle noise/jitter to round circle for organic cliff look
			var noise_val := _rng.randf_range(-0.8, 0.8)
			if dist_sq + noise_val <= r_sq:
				cells.append(Vector2i(x + radius, y + radius))
	CliffAutotiler.draw_plateau_cells(tile_mapper, origin_tile, cells)


func _populate_objects() -> void:
	# 1. Place grand ancient ruins atop plateaus and in mysterious spots
	var ruin_locations: Array[Vector2i] = [
		Vector2i(10, 8),    # Inside Northern Fortress
		Vector2i(32, 7),    # Atop Mesa 1
		Vector2i(12, 30),   # Inside Horseshoe Canyon
		Vector2i(11, 57),   # Center of Crater
		Vector2i(36, 30),   # Center of L-Ridge
		Vector2i(57, 34),   # Center of T-Plateau
		Vector2i(44, 76),   # Center of Southern Organic Blob
		Vector2i(114, 74),  # Atop Eastern Plateau
		Vector2i(96, 96),   # Stepping Stone Shrine
	]
	for cell_pos in ruin_locations:
		var ruin_path := ObjectCatalog.get_random_common_object("ruins", _rng)
		_spawn_sprite(ruin_path, cell_pos, Vector2(1.0, 1.0))

	# 2. Place rich forest groves & clusters of trees
	var tree_clusters: Array[Vector2i] = [
		Vector2i(22, 18), Vector2i(25, 20), Vector2i(21, 23),
		Vector2i(48, 16), Vector2i(52, 20), Vector2i(46, 22),
		Vector2i(70, 24), Vector2i(74, 28), Vector2i(68, 30),
		Vector2i(24, 48), Vector2i(28, 52), Vector2i(22, 56),
		Vector2i(78, 56), Vector2i(84, 58), Vector2i(80, 64),
		Vector2i(100, 36), Vector2i(104, 40), Vector2i(108, 44),
		Vector2i(28, 86), Vector2i(32, 90), Vector2i(66, 86),
		Vector2i(102, 86), Vector2i(106, 90), Vector2i(135, 88),
	]
	for base_pos in tree_clusters:
		for i in range(4):
			var offset := Vector2i(_rng.randi_range(-2, 2), _rng.randi_range(-2, 2))
			var tree_path := ObjectCatalog.get_random_common_object("trees", _rng)
			_spawn_sprite(tree_path, base_pos + offset, Vector2(1.0, 1.0))

	# 3. Scatter bushes across open meadows and cliff edges
	for i in range(80):
		var rx := _rng.randi_range(MAP_START.x + 5, MAP_END.x - 5)
		var ry := _rng.randi_range(MAP_START.y + 5, MAP_END.y - 5)
		var bush_path := ObjectCatalog.get_random_common_object("bushes", _rng)
		_spawn_sprite(bush_path, Vector2i(rx, ry), Vector2(1.0, 1.0))

	# 4. Scatter rocks, boulders, and grassland flora from Biome Catalogs
	for i in range(120):
		var rx := _rng.randi_range(MAP_START.x + 5, MAP_END.x - 5)
		var ry := _rng.randi_range(MAP_START.y + 5, MAP_END.y - 5)
		var biome_type := BiomeType.ROCKS if _rng.randf() > 0.4 else BiomeType.GRASSLAND
		var obj_path := ObjectCatalog.get_random_biome_object(biome_type, _rng)
		_spawn_sprite(obj_path, Vector2i(rx, ry), Vector2(1.0, 1.0))


func _spawn_sprite(path: String, cell_pos: Vector2i, scale_factor: Vector2 = Vector2.ONE) -> void:
	if path.is_empty():
		return
	var tex := ObjectCatalog.load_texture(path)
	if tex == null:
		return
	var sprite := Sprite2D.new()
	sprite.texture = tex
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.scale = scale_factor
	sprite.position = level_tilemap.map_to_local(cell_pos)
	objects_container.add_child(sprite)


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


func _capture_and_quit() -> void:
	# Zoom out camera slightly for screenshot so a wider panoramic view is captured
	if camera != null:
		camera.zoom = Vector2(0.85, 0.85)
		camera.position = level_tilemap.map_to_local(Vector2i(55, 45))
	await get_tree().process_frame
	await get_tree().process_frame
	await save_screenshot("doc/images/visual_test_autotiling.png")
	get_tree().quit()
