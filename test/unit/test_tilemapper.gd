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
		Vector2i(2, 2),
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
	pass