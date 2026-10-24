extends GutTest


func test_main_scene_places_bone_fragments_on_object_layer():
	var scene := load("res://scenes/main.tscn") as PackedScene
	var main := scene.instantiate() as Node2D
	add_child(main)
	autofree(main)
	await get_tree().process_frame

	var object_tilemap := main.get_node("ObjectTileMap") as TileMapLayer
	var object_source_ids: Array[int] = []
	for source_index in range(object_tilemap.tile_set.get_source_count()):
		var source_id := object_tilemap.tile_set.get_source_id(source_index)
		if StringName(object_tilemap.tile_set.get_source(source_id).resource_name) == &"Objects":
			object_source_ids.append(source_id)

	assert_eq(object_source_ids.size(), 1)
	assert_eq(object_tilemap.get_used_cells().size(), 130)
	for cell: Vector2i in object_tilemap.get_used_cells():
		assert_eq(object_tilemap.get_cell_source_id(cell), object_source_ids[0])

	var ground_tilemap := main.get_node("LevelTileMap") as TileMapLayer
	assert_eq(ground_tilemap.get_used_cells().size(), 12 * 32 * 12 * 32)
