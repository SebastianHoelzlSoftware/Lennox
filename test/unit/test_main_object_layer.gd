extends GutTest


func test_main_scene_starts_in_decorated_grass_biome():
	var scene := load("res://scenes/main.tscn") as PackedScene
	var main := scene.instantiate() as Node2D
	add_child(main)
	autofree(main)
	await get_tree().process_frame

	var object_tilemap := main.get_node("ObjectTileMap") as TileMapLayer
	var player := main.get_node("CharacterBody2D") as CharacterBody2D
	var collision_shape := player.get_node("CollisionShape2D") as CollisionShape2D
	var player_sprite := player.get_node("AnimatedSprite2D") as AnimatedSprite2D
	var camera := player.get_node("Camera2D") as Camera2D
	var level_tilemap := main.get_node("LevelTileMap") as TileMapLayer
	assert_eq(collision_shape.shape.radius, 9.0)
	assert_eq(collision_shape.shape.height, 26.0)
	assert_eq(player_sprite.scale, Vector2.ONE)
	assert_eq(camera.zoom, Vector2(2.5, 2.5))
	assert_eq(player_sprite.animation, &"idle_down")
	assert_true(InputMap.has_action("run"))
	var frame_counts := {
		&"idle": 12,
		&"walk": 6,
		&"run": 8,
		&"attack": 8,
		&"walk_attack": 6,
		&"run_attack": 8,
		&"hurt": 5,
		&"death": 7,
	}
	var direction_rows := {
		&"down": 0,
		&"left": 1,
		&"right": 2,
		&"up": 3,
	}
	var sprite_sheet_paths := {
		&"idle": "res://assets/player_sprites/Swordsman_lvl1/Without_shadow/Swordsman_lvl1_Idle_without_shadow.png",
		&"walk": "res://assets/player_sprites/Swordsman_lvl1/Without_shadow/Swordsman_lvl1_Walk_without_shadow.png",
		&"run": "res://assets/player_sprites/Swordsman_lvl1/Without_shadow/Swordsman_lvl1_Run_without_shadow.png",
		&"attack": "res://assets/player_sprites/Swordsman_lvl1/Without_shadow/Swordsman_lvl1_attack_without_shadow.png",
		&"walk_attack": "res://assets/player_sprites/Swordsman_lvl1/Without_shadow/Swordsman_lvl1_Walk_Attack_without_shadow.png",
		&"run_attack": "res://assets/player_sprites/Swordsman_lvl1/Without_shadow/Swordsman_lvl1_Run_Attack_without_shadow.png",
		&"hurt": "res://assets/player_sprites/Swordsman_lvl1/Without_shadow/Swordsman_lvl1_Hurt_without_shadow.png",
		&"death": "res://assets/player_sprites/Swordsman_lvl1/Without_shadow/Swordsman_lvl1_Death_without_shadow.png",
	}
	for animation_prefix: StringName in frame_counts:
		for direction: StringName in direction_rows:
			var animation_name := StringName("%s_%s" % [animation_prefix, direction])
			var expected_frame_count: int = (
				4
				if animation_prefix == &"idle" and direction == &"up"
				else frame_counts[animation_prefix]
			)
			assert_true(player_sprite.sprite_frames.has_animation(animation_name))
			assert_eq(
				player_sprite.sprite_frames.get_frame_count(animation_name),
				expected_frame_count
			)
			var frame := player_sprite.sprite_frames.get_frame_texture(animation_name, 0) as AtlasTexture
			assert_not_null(frame)
			assert_eq(frame.atlas.resource_path, sprite_sheet_paths[animation_prefix])
			assert_eq(frame.region.position.y, direction_rows[direction] * 64.0)
	var start_chunk: Vector2i = main.start_cell / 32
	var object_cells := object_tilemap.get_used_cells()
	assert_false(main.start_biome_chunks.is_empty())
	assert_eq(main.start_biome_type, BiomeType.GRASSLAND)
	assert_true(main.start_biome_chunks.has(start_chunk))
	assert_gt(object_cells.size(), 200)
	assert_eq(level_tilemap.local_to_map(player.position), main.start_cell)
	var ground_source := level_tilemap.tile_set.get_source(
		level_tilemap.get_cell_source_id(main.start_cell)
	) as TileSetAtlasSource
	var start_tile_data := ground_source.get_tile_data(
		level_tilemap.get_cell_atlas_coords(main.start_cell),
		0
	)
	assert_eq(start_tile_data.get_collision_polygons_count(0), 0)
	var generated_level := Level.new(12, 12, 32, 16, 12345)
	generated_level.generate()
	var grassland_chunks: Dictionary = {}
	var decorated_chunks: Dictionary = {}
	var placed_atlas_coords: Dictionary = {}
	for chunk_x in range(generated_level.width):
		for chunk_y in range(generated_level.height):
			if generated_level.biome_map[chunk_x][chunk_y] == BiomeType.GRASSLAND:
				grassland_chunks[Vector2i(chunk_x, chunk_y)] = true

	for cell: Vector2i in object_cells:
		var chunk_position: Vector2i = cell / generated_level.chunk_size
		var local_cell := cell % generated_level.chunk_size
		var chunk := generated_level.get_chunk(chunk_position.x, chunk_position.y)
		assert_eq(chunk.biome, BiomeType.GRASSLAND)
		#assert_eq(chunk.get_tile(local_cell.x, local_cell.y), TileType.GRASS)
		decorated_chunks[chunk_position] = true
		var source := object_tilemap.tile_set.get_source(
			object_tilemap.get_cell_source_id(cell)
		)
		assert_eq(StringName(source.resource_name), &"Objects")
		placed_atlas_coords[object_tilemap.get_cell_atlas_coords(cell)] = true
		assert_false(
			absi(cell.x - main.start_cell.x) <= 2 and absi(cell.y - main.start_cell.y) <= 2,
			"Keep a small clear space around the player spawn."
		)
	assert_eq(decorated_chunks.size(), grassland_chunks.size())
	assert_gt(placed_atlas_coords.size(), 20)
