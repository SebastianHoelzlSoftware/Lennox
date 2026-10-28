extends GutTest

func test_tilemapper_creates_tile():
	# Arrange
	# 1. Test-Szene sicher im Test laden (falls noch nicht geschehen)
	var scene = load("res://scenes/main.tscn").instantiate() # Ersetze den Pfad mit deiner Szene
	add_child_autofree(scene) # Lädt die Szene in den Tree, damit @onready funktioniert
	
	# 2. Den TileMapLayer über den geladenen Pfad holen
	var level_tilemap: TileMapLayer = scene.get_node("LevelTileMap")
	
	# Absicherung, falls der Pfad nicht stimmt
	assert_not_null(level_tilemap, "LevelTileMap wurde nicht gefunden!")
	assert_not_null(level_tilemap.tile_set, "TileSet ist null im TileMapLayer!")

	# 3. Jetzt den TileMapper sicher mit dem TileSet initialisieren
	var tile_mapper := TileMapper.new(level_tilemap)
	
	var upper_left_pattern = [
		Vector2i(1, 22),
		Vector2i(1, 22)
	]
	var p1 = TilePattern.new(
		"Upper Left Corner (High Plateau Rocks)",
		1,
		true,
		true,
		upper_left_pattern
	)
	
	# Act	
	var ul_corner_pattern = tile_mapper.create_tile_pattern("Upper Left Corner (High Plateau Rocks)")

	# Assert
	# Wichtig: Da TilePattern eine reine Datenklasse ist, schlägt assert_eq evtl. fehl, 
	# wenn sie kein _eq() implementiert hat. Vergleiche ggf. die Properties einzeln:
	assert_not_null(ul_corner_pattern)
	if ul_corner_pattern != null:
		assert_eq(ul_corner_pattern.name, p1.name)
		assert_eq(ul_corner_pattern.index, p1.index)
		assert_eq(ul_corner_pattern.is_corner, p1.is_corner)
		assert_eq(ul_corner_pattern.is_atomic, p1.is_atomic)
		assert_eq(ul_corner_pattern.pattern, p1.pattern)


func test_tilemapper_draws_a_tile_correctly():
	var scene := load("res://scenes/main.tscn") as PackedScene
	var main := scene.instantiate() as Node2D
	add_child(main)
	autofree(main)
	await get_tree().process_frame
	var level_tilemap := main.get_node("LevelTileMap") as TileMapLayer
	var tile_mapper := TileMapper.new(level_tilemap)
	
	var draw_positions = [
		Vector2i(10, 10), 
		Vector2i(10, 11), 
		Vector2i(11, 10), 
		Vector2i(11, 11)
		]
	var expected_atlas_coords = [
		Vector2i(3, 21),
		Vector2i(3, 22),
		Vector2i(4, 21),
		Vector2i(4, 22)
	]
	tile_mapper.draw_editor_pattern("Upper Right Corner (High Plateau Rocks)", draw_positions[0])

	var returned_coords = []
	for draw_pos in draw_positions:
		returned_coords.append(level_tilemap.get_cell_atlas_coords(draw_pos))

	assert_eq(returned_coords, expected_atlas_coords)

func test_tilemapper_draws_all_tiles_correctly():
	var scene := load("res://scenes/main.tscn") as PackedScene
	var main := scene.instantiate() as Node2D
	add_child(main)
	autofree(main)
	await get_tree().process_frame
	var level_tilemap := main.get_node("LevelTileMap") as TileMapLayer
	var tile_mapper := TileMapper.new(level_tilemap)

	var start_draw_pos = Vector2i(10, 10)
	var draw_pos = start_draw_pos
	var tile_dict = TilePatternRegistry.dictionary

	for tilename in tile_dict.keys():
		# Skip Ground tile checking for now
		if not "Ground Plate" in tilename:
			# Get atlas coords for tile from registry
			var atlas_coords = tile_dict[tilename]["atlas_coords"]
			# Draw the pattern
			tile_mapper.draw_editor_pattern(tilename, draw_pos)

			var returned_atlas_coords = level_tilemap.get_cell_atlas_coords(draw_pos)
			var ret_x = returned_atlas_coords[0]
			var ret_y = returned_atlas_coords[1]
			var ret_as_vec = Vector2i(ret_x, ret_y)
			print("ATLAS COORDS:")
			print(atlas_coords)
			print("RETURNED COORDS:")
			print(ret_as_vec)
			assert_eq(ret_as_vec, atlas_coords[0], "Retrieved atlas coordinates should be equal with registry ones")

			# Move draw position to the right
			draw_pos = Vector2i(draw_pos[0] + 10, draw_pos[1])
		
	# --- DYNAMIC CAMERA FRAMING FOR SCREENSHOT ---
	# 1. Create a temporary Camera2D for the test
	var camera := Camera2D.new()
	main.add_child(camera)
	autofree(camera)

	# 2. Convert cell coordinates to pixel positions
	var start_pixel_pos = level_tilemap.map_to_local(start_draw_pos)
	var end_pixel_pos = level_tilemap.map_to_local(draw_pos) # final draw_pos after loop

	# 3. Position the camera at the exact center of all drawn tiles
	camera.position = (start_pixel_pos + end_pixel_pos) / 2.0
	
	# 4. Adjust zoom if necessary (e.g., Vector2(2, 2) to zoom in, Vector2(1, 1) for default)
	camera.zoom = Vector2(2.0, 2.0)
	
	# 5. Make this camera active so the viewport renders from its perspective
	camera.make_current()

	# Wait a couple of frames for the tilemap and camera to settle
	await get_tree().process_frame
	await get_tree().process_frame

	# Grab and save the viewport image
	var viewport = get_viewport()
	var image := viewport.get_texture().get_image()
	var file_path = "user://test_tilemapper_output.png"
	
	if image.save_png(file_path) == OK:
		print("Screenshot saved to: ", ProjectSettings.globalize_path(file_path))
	else:
		printerr("Failed to save screenshot.")
