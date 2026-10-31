extends GutTest

const NpcFriendScript = preload("res://scenes/npc_friend.gd")


func test_archer_sprite_frames_have_all_directions():
	var npc := NpcFriendScript.new()
	add_child_autofree(npc)
	var frames: SpriteFrames = npc.animated_sprite.sprite_frames
	assert_not_null(frames, "SpriteFrames creado")

	for prefix in [&"idle", &"walk", &"run", &"attack", &"hurt", &"death"]:
		for dir in [&"down", &"left", &"right", &"up"]:
			var anim := StringName("%s_%s" % [prefix, dir])
			assert_true(frames.has_animation(anim), "Animacion existente: %s" % anim)
			assert_gt(frames.get_frame_count(anim), 0, "Frames > 0 en %s" % anim)
	assert_eq(frames.get_frame_count(&"idle_up"), 4, "idle_up de la arquera tiene 4 frames")
	assert_eq(frames.get_frame_count(&"idle_down"), 12, "idle_down de la arquera tiene 12 frames")


func test_npc_stays_idle_when_within_comfort_distance():
	var root := Node2D.new()
	add_child_autofree(root)

	var player := CharacterBody2D.new()
	player.name = "CharacterBody2D"
	root.add_child(player)
	player.global_position = Vector2(100, 100)

	var npc := NpcFriendScript.new()
	root.add_child(npc)
	npc.set_follow_target(player, true)

	npc._physics_process(0.1)
	assert_eq(npc.velocity, Vector2.ZERO, "Dentro de la distancia comoda no se mueve")
	assert_true(String(npc.animated_sprite.animation).begins_with("idle_"), "Reproduce idle")


func test_npc_walks_and_runs_to_follow_moving_player():
	var root := Node2D.new()
	add_child_autofree(root)

	var player := CharacterBody2D.new()
	player.name = "CharacterBody2D"
	root.add_child(player)
	player.global_position = Vector2(100, 100)

	var npc := NpcFriendScript.new()
	root.add_child(npc)
	npc.set_follow_target(player, true)

	# El jugador se aleja moderadamente hacia la derecha -> la arquera camina
	player.global_position = Vector2(148, 100)
	for _i in range(6):
		npc._physics_process(0.05)
	assert_gt(npc.velocity.x, 0.0, "Camina hacia la derecha tras el jugador")
	assert_eq(npc.animated_sprite.animation, &"walk_right", "Animacion walk_right")

	# El jugador se aleja mucho -> la arquera corre para alcanzarlo
	player.global_position = Vector2(260, 100)
	for _i in range(4):
		npc._physics_process(0.05)
		npc.global_position += npc.velocity * 0.05
	assert_gt(npc.velocity.x, NpcFriendScript.RUN_SPEED_THRESHOLD, "Corre cuando el jugador se aleja")
	assert_eq(npc.animated_sprite.animation, &"run_right", "Animacion run_right")


func test_npc_teleports_if_player_is_extremely_far():
	var root := Node2D.new()
	add_child_autofree(root)

	var player := CharacterBody2D.new()
	root.add_child(player)
	player.global_position = Vector2(0, 0)

	var npc := NpcFriendScript.new()
	root.add_child(npc)
	npc.set_follow_target(player, true)

	player.global_position = Vector2(1000, 0)
	npc._physics_process(0.05)
	assert_lt(npc.global_position.distance_to(player.global_position), 100.0, "Se acerca si queda demasiado lejos")
