extends Node2D

@onready var level_tilemap: TileMapLayer = $LevelTileMap
@onready var objects_container: Node2D = $ObjectsContainer
@onready var player: CharacterBody2D = $CharacterBody2D
@onready var camera: Camera2D = $CharacterBody2D/Camera2D

const CliffAutotiler = preload("res://src/core/cliff_autotiler.gd")
const ObjectCatalog = preload("res://src/core/object_catalog.gd")

# Massive world boundary (200 x 160 tiles = 3200 x 2560 pixels)
const WORLD_START := Vector2i(-15, -15)
const WORLD_END := Vector2i(210, 165)
const GRASS_COORDS := Vector2i(2, 1)

var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.seed = 20261029
	var tile_mapper := TileMapper.new(level_tilemap)

	# 1. Base terrain canvas
	_generate_base_terrain()

	# 2. Majestic, grand natural plateaus (generous scale with ample walkable tops)
	_build_grand_plateaus(tile_mapper)

	# 3. Dense ecological fairytale population across all 8 biomes (400+ objects)
	_populate_fairytale_biomes()

	# 4. Spawn player at an enchanted crossroad
	if player != null:
		player.position = level_tilemap.map_to_local(Vector2i(90, 75))

	# 5. CLI automated screenshot capture
	if OS.get_cmdline_user_args().has("--screenshot") or OS.get_cmdline_args().has("--screenshot"):
		_capture_and_quit()


func _unhandled_input(event: InputEvent) -> void:
	if camera == null:
		return
	if event is InputEventMouseButton and event.is_pressed():
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			camera.zoom = (camera.zoom * 1.15).clamp(Vector2(0.2, 0.2), Vector2(3.5, 3.5))
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			camera.zoom = (camera.zoom * 0.85).clamp(Vector2(0.2, 0.2), Vector2(3.5, 3.5))


func _generate_base_terrain() -> void:
	for x in range(WORLD_START.x, WORLD_END.x):
		for y in range(WORLD_START.y, WORLD_END.y):
			level_tilemap.set_cell(Vector2i(x, y), 1, GRASS_COORDS)


func _build_grand_plateaus(tile_mapper: TileMapper) -> void:
	# =========================================================================
	# REGEL 1 FÜR NATÜRLICHE PLATEAUS:
	# Große Dimensionen (mindestens 6x5 Makrozellen = 12x10 Kacheln)
	# Dadurch haben Plateaus eine riesige begehbare Hochfläche ("Center-Fill")
	# und die Klippenfronten an der Südseite haben ausreichend Platz.
	# =========================================================================

	# 1. Großes Drachen-Hochplateau im Nordwesten (ROCKS)
	CliffAutotiler.draw_plateau_rect(tile_mapper, Vector2i(10, 10), 12, 7, BiomeType.ROCKS)

	# 2. Heilige Bergfeste im Nordosten (FOREST)
	CliffAutotiler.draw_plateau_rect(tile_mapper, Vector2i(120, 10), 10, 6, BiomeType.FOREST)

	# 3. Zwillings-Mesa im Zentrum (DESERT)
	CliffAutotiler.draw_plateau_rect(tile_mapper, Vector2i(65, 35), 8, 5, BiomeType.DESERT)

	# 4. Südliches Sonnenplateau (GRASSLAND)
	CliffAutotiler.draw_plateau_rect(tile_mapper, Vector2i(20, 100), 14, 7, BiomeType.GRASSLAND)

	# 5. Südöstliche Klippenbastion (SWAMP)
	CliffAutotiler.draw_plateau_rect(tile_mapper, Vector2i(115, 105), 11, 6, BiomeType.SWAMP)

	# 6. Freistehende Monolith-Inseln (CAVE & ROCKS_AND_WATER)
	CliffAutotiler.draw_plateau_rect(tile_mapper, Vector2i(10, 65), 5, 4, BiomeType.CAVE)
	CliffAutotiler.draw_plateau_rect(tile_mapper, Vector2i(155, 65), 5, 4, BiomeType.ROCKS_AND_WATER)


func _populate_fairytale_biomes() -> void:
	# =========================================================================
	# REGEL 2 & 3: BIOLOGISCHE CLUSTER & THEMATISCHE BIOM-IDENTITÄT
	# Alle 8 Biome erhalten ihre eigenen Zonen mit dichten Hainen,
	# Ruinen-Heiligtümern und reicher Flora.
	# =========================================================================

	# --- BIOM 1: GRASSLAND (Blumenauen & Märchenwiesen) [Zentrum: (80..110, 60..90)] ---
	_populate_landmark(Vector2i(90, 70), "ruins")
	_populate_grove(Vector2i(82, 65), "trees", 4)
	_populate_grove(Vector2i(102, 78), "trees", 5)
	_populate_scatter(Vector2i(75, 55), Vector2i(115, 90), "bushes", 25)
	_populate_biome_scatter(Vector2i(75, 55), Vector2i(115, 90), BiomeType.GRASSLAND, 40)

	# --- BIOM 2: FOREST (Zauberwald) [Nord-Zentrum: (35..65, 5..35)] ---
	_populate_landmark(Vector2i(50, 18), "ruins")
	for i in range(5):
		var gx := _rng.randi_range(38, 60)
		var gy := _rng.randi_range(8, 30)
		_populate_grove(Vector2i(gx, gy), "trees", 6)
	_populate_scatter(Vector2i(35, 5), Vector2i(65, 35), "bushes", 30)
	_populate_biome_scatter(Vector2i(35, 5), Vector2i(65, 35), BiomeType.FOREST, 45)

	# --- BIOM 3: ROCKS (Drachenfelsen auf Hochplateau 1) [Nordwest: (10..34, 10..24)] ---
	_populate_landmark(Vector2i(22, 16), "ruins")
	_populate_biome_scatter(Vector2i(12, 12), Vector2i(32, 22), BiomeType.ROCKS, 35)
	_populate_scatter(Vector2i(12, 12), Vector2i(32, 22), "bushes", 15)

	# --- BIOM 4: DESERT (Goldwüste & Oase) [West: (5..35, 35..65)] ---
	_populate_landmark(Vector2i(20, 50), "ruins")
	_populate_grove(Vector2i(25, 46), "trees", 3)
	_populate_biome_scatter(Vector2i(5, 35), Vector2i(35, 65), BiomeType.DESERT, 40)
	_populate_scatter(Vector2i(5, 35), Vector2i(35, 65), "bushes", 12)

	# --- BIOM 5: SWAMP (Verwunschenes Moor) [Ost: (120..155, 35..65)] ---
	_populate_landmark(Vector2i(138, 50), "ruins")
	_populate_grove(Vector2i(130, 42), "trees", 5)
	_populate_grove(Vector2i(145, 55), "trees", 4)
	_populate_biome_scatter(Vector2i(120, 35), Vector2i(155, 65), BiomeType.SWAMP, 40)
	_populate_scatter(Vector2i(120, 35), Vector2i(155, 65), "bushes", 20)

	# --- BIOM 6: ROCKS_AND_WATER (Klippenküste) [Nordost: (120..144, 10..24)] ---
	_populate_landmark(Vector2i(130, 16), "ruins")
	_populate_biome_scatter(Vector2i(122, 12), Vector2i(142, 22), BiomeType.ROCKS_AND_WATER, 35)
	_populate_scatter(Vector2i(122, 12), Vector2i(142, 22), "bushes", 15)

	# --- BIOM 7: SEABED / LAGOON (Korallenbucht) [Südost: (115..150, 95..135)] ---
	_populate_landmark(Vector2i(132, 118), "ruins")
	_populate_biome_scatter(Vector2i(115, 95), Vector2i(150, 135), BiomeType.SEABED, 45)
	_populate_scatter(Vector2i(115, 95), Vector2i(150, 135), "bushes", 10)

	# --- BIOM 8: CAVE (Glimmergrotte / Unterwelt) [Südwest: (20..50, 95..135)] ---
	_populate_landmark(Vector2i(34, 115), "ruins")
	_populate_biome_scatter(Vector2i(20, 95), Vector2i(50, 135), BiomeType.CAVE, 45)
	_populate_scatter(Vector2i(20, 95), Vector2i(50, 135), "bushes", 10)


func _populate_landmark(cell_pos: Vector2i, category: String) -> void:
	var path := ObjectCatalog.get_random_common_object(category, _rng)
	_spawn_sprite(path, cell_pos)


func _populate_grove(base_pos: Vector2i, category: String, count: int) -> void:
	for i in range(count):
		var offset := Vector2i(_rng.randi_range(-2, 2), _rng.randi_range(-2, 2))
		var path := ObjectCatalog.get_random_common_object(category, _rng)
		_spawn_sprite(path, base_pos + offset)


func _populate_scatter(start_pos: Vector2i, end_pos: Vector2i, category: String, count: int) -> void:
	for i in range(count):
		var rx := _rng.randi_range(start_pos.x, end_pos.x)
		var ry := _rng.randi_range(start_pos.y, end_pos.y)
		var path := ObjectCatalog.get_random_common_object(category, _rng)
		_spawn_sprite(path, Vector2i(rx, ry))


func _populate_biome_scatter(start_pos: Vector2i, end_pos: Vector2i, biome: BiomeType.Type, count: int) -> void:
	for i in range(count):
		var rx := _rng.randi_range(start_pos.x, end_pos.x)
		var ry := _rng.randi_range(start_pos.y, end_pos.y)
		var path := ObjectCatalog.get_random_biome_object(biome, _rng)
		_spawn_sprite(path, Vector2i(rx, ry))


func _spawn_sprite(path: String, cell_pos: Vector2i) -> void:
	if path.is_empty():
		return
	var tex := ObjectCatalog.load_texture(path)
	if tex == null:
		return
	var sprite := Sprite2D.new()
	sprite.texture = tex
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
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
	if camera != null:
		camera.zoom = Vector2(0.65, 0.65)
		camera.position = level_tilemap.map_to_local(Vector2i(90, 75))
	await get_tree().process_frame
	await get_tree().process_frame
	await save_screenshot("doc/images/visual_test_autotiling.png")
	get_tree().quit()
