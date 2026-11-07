# test_mage_tower.gd
# Pruebas unitarias de la integracion de la Torre de Magos (exterior, interior y TileSet).
extends GutTest

const MAGE_TOWER_TILESET_PATH := "res://assets/tiles/mage_tower.tres"
const MAGE_TOWER_EXTERIOR_PATH := "res://scenes/mage_tower_exterior.tscn"
const MAGE_TOWER_INTERIOR_PATH := "res://scenes/mage_tower_interior.tscn"


func test_mage_tower_tileset_loads_with_all_five_sources() -> void:
	var tset := load(MAGE_TOWER_TILESET_PATH) as TileSet
	assert_not_null(tset, "El TileSet mage_tower.tres debe cargarse correctamente")
	assert_eq(tset.tile_size, Vector2i(16, 16), "El tamano de celda debe ser 16x16")
	assert_eq(tset.get_source_count(), 5, "El TileSet debe incluir las 5 hojas de atlas del paquete")


func test_mage_tower_exterior_scene_instantiates_and_animates_dragon() -> void:
	var packed := load(MAGE_TOWER_EXTERIOR_PATH) as PackedScene
	assert_not_null(packed, "mage_tower_exterior.tscn debe cargarse")
	var ext := packed.instantiate() as Node2D
	add_child_autofree(ext)
	await get_tree().process_frame

	var tower_base := ext.get_node_or_null("TowerBase") as Sprite2D
	assert_not_null(tower_base, "Debe existir el sprite principal TowerBase")
	for part_name: String in ["DragonBack", "DragonBody", "DragonWing", "DragonTail", "DoorSprite"]:
		var anim := ext.get_node_or_null(part_name) as AnimatedSprite2D
		assert_not_null(anim, "Debe existir el nodo animado %s" % part_name)
		assert_not_null(anim.sprite_frames, "%s debe tener SpriteFrames generados" % part_name)


func test_mage_tower_interior_scene_instantiates_with_tilemaps_and_inhabitants() -> void:
	var packed := load(MAGE_TOWER_INTERIOR_PATH) as PackedScene
	assert_not_null(packed, "mage_tower_interior.tscn debe cargarse")
	var interior := packed.instantiate() as Node2D
	add_child_autofree(interior)
	await get_tree().process_frame

	var floor_map := interior.get_node_or_null("FloorTileMap") as TileMapLayer
	var wall_map := interior.get_node_or_null("WallsTileMap") as TileMapLayer
	assert_not_null(floor_map, "FloorTileMap debe existir para edicion 2D")
	assert_not_null(wall_map, "WallsTileMap debe existir para edicion 2D")
	assert_gt(floor_map.get_used_cells().size(), 100, "FloorTileMap debe tener el suelo pintado por defecto")
	assert_gt(wall_map.get_used_cells().size(), 50, "WallsTileMap debe tener los muros pintados por defecto")

	var demon := interior.get_node_or_null("Inhabitants/SummonedDemon") as AnimatedSprite2D
	assert_not_null(demon, "Debe existir el demonio invocado en el pentagrama")
	assert_not_null(demon.sprite_frames, "SummonedDemon debe tener SpriteFrames cargados")
	assert_eq(demon.sprite_frames.get_frame_count(&"idle"), 18, "El demonio debe tener sus 18 fotogramas")


func test_main_scene_contains_mage_tower_exterior() -> void:
	var main_packed := load("res://scenes/main.tscn") as PackedScene
	assert_not_null(main_packed, "main.tscn debe cargarse sin errores")
	var main_instance := main_packed.instantiate() as Node2D
	add_child_autofree(main_instance)
	await get_tree().process_frame

	var tower_ext := main_instance.get_node_or_null("MageTowerExterior") as Node2D
	assert_not_null(tower_ext, "main.tscn debe incluir la instancia de MageTowerExterior")
	var courtyard := tower_ext.get_node_or_null("CourtyardTileMap") as TileMapLayer
	assert_not_null(courtyard, "MageTowerExterior debe tener su CourtyardTileMap para edicion 2D")
	assert_gt(courtyard.get_used_cells().size(), 0, "CourtyardTileMap debe tener el camino de entrada pintado")
