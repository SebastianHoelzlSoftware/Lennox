extends GutTest

func test_tilemapper_creates_tile():
	# 1. Test-Szene sicher im Test laden (falls noch nicht geschehen)
	var scene = load("res://scenes/main.tscn").instantiate() # Ersetze den Pfad mit deiner Szene
	add_child_autofree(scene) # Lädt die Szene in den Tree, damit @onready funktioniert
	
	# 2. Den TileMapLayer über den geladenen Pfad holen
	var level_tilemap: TileMapLayer = scene.get_node("LevelTileMap")
	
	# Absicherung, falls der Pfad nicht stimmt
	assert_not_null(level_tilemap, "LevelTileMap wurde nicht gefunden!")
	assert_not_null(level_tilemap.tile_set, "TileSet ist null im TileMapLayer!")

	# 3. Jetzt den TileMapper sicher mit dem TileSet initialisieren
	var tile_mapper := TileMapper.new(level_tilemap.tile_set)
	var ul_corner_pattern = tile_mapper.create_tile_pattern("Upper Left Corner (High Plateau)")
	
	var upper_left_pattern = [
		Vector2i(0, 0),
		Vector2i(0, 1),
		Vector2i(1, 0),
		Vector2i(1, 1)
	]
	var p1 = TilePattern.new(
		"Upper Left Corner (High Plateau)",
		1,
		true,
		true,
		upper_left_pattern
	)

	# Wichtig: Da TilePattern eine reine Datenklasse ist, schlägt assert_eq evtl. fehl, 
	# wenn sie kein _eq() implementiert hat. Vergleiche ggf. die Properties einzeln:
	assert_not_null(ul_corner_pattern)
	if ul_corner_pattern != null:
		assert_eq(ul_corner_pattern.name, p1.name)
		assert_eq(ul_corner_pattern.index, p1.index)
		assert_eq(ul_corner_pattern.is_corner, p1.is_corner)
		assert_eq(ul_corner_pattern.is_atomic, p1.is_atomic)
		assert_eq(ul_corner_pattern.pattern, p1.pattern)
