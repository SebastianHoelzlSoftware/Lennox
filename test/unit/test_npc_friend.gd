extends GutTest

const NpcFriendScript = preload("res://scenes/npc_friend.gd")
const PlayerScript = preload("res://scenes/player.gd")
const MobileControlsScript = preload("res://scenes/mobile_controls.gd")


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


func test_dino_sprite_frames_have_all_directions():
	var dino := NpcFriendScript.new()
	dino.character_style = "dino"
	add_child_autofree(dino)
	var frames: SpriteFrames = dino.animated_sprite.sprite_frames
	assert_not_null(frames, "SpriteFrames del dino creado")

	for prefix in [&"idle", &"walk", &"run"]:
		for dir in [&"down", &"left", &"right", &"up"]:
			var anim := StringName("%s_%s" % [prefix, dir])
			assert_true(frames.has_animation(anim), "Animacion de dino existente: %s" % anim)
			assert_gt(frames.get_frame_count(anim), 0, "Frames > 0 en %s" % anim)
	assert_eq(frames.get_frame_count(&"idle_up"), 4, "idle_up del dino tiene 4 frames")
	assert_eq(frames.get_frame_count(&"idle_down"), 12, "idle_down del dino tiene 12 frames")


func test_polar_bear_sprite_frames_have_all_directions():
	var bear := NpcFriendScript.new()
	bear.character_style = "polar_bear"
	add_child_autofree(bear)
	var frames: SpriteFrames = bear.animated_sprite.sprite_frames
	assert_not_null(frames, "SpriteFrames del oso polar creado")

	for prefix in [&"idle", &"walk", &"run"]:
		for dir in [&"down", &"left", &"right", &"up"]:
			var anim := StringName("%s_%s" % [prefix, dir])
			assert_true(frames.has_animation(anim), "Animacion de oso polar existente: %s" % anim)
			assert_gt(frames.get_frame_count(anim), 0, "Frames > 0 en %s" % anim)
	assert_eq(frames.get_frame_count(&"idle_up"), 4, "idle_up del oso polar tiene 4 frames")
	assert_eq(frames.get_frame_count(&"idle_down"), 12, "idle_down del oso polar tiene 12 frames")


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


func test_npc_interaction_toggles_question_mark_dialog():
	var root := Node2D.new()
	add_child_autofree(root)

	var player := PlayerScript.new()
	player.name = "CharacterBody2D"
	var player_sprite := AnimatedSprite2D.new()
	player_sprite.name = "AnimatedSprite2D"
	player.add_child(player_sprite)
	root.add_child(player)
	player.global_position = Vector2(100, 100)

	var npc := NpcFriendScript.new()
	root.add_child(npc)
	npc.global_position = Vector2(75, 100)

	assert_false(npc.is_dialog_visible(), "El dialogo empieza oculto")
	var icon_tex: Texture2D = npc.dialog_bubble.get("icon_texture") as Texture2D
	assert_not_null(icon_tex, "Tiene el icono de corazon listo")
	assert_eq(icon_tex.resource_path, "res://assets/common/icons/Item9_2.png", "Muestra el icono de corazon de los assets")
	assert_eq(npc.dialog_bubble.get("word_text"), "LOVE", "La palabra por defecto debajo del icono es LOVE")

	# Al interactuar con E (o llamando interact_with_nearest_npc), se abre la ventana con corazon + LOVE
	var interacted := player.interact_with_nearest_npc()
	assert_eq(interacted, npc, "Interactua con el companero mas cercano")
	assert_true(npc.is_dialog_visible(), "La ventana de dialogo se muestra al interactuar")
	assert_eq(npc.animated_sprite.animation, &"idle_right", "El NPC mira hacia el jugador al hablar")

	# Se puede cambiar dinamicamente el simbolo y la palabra mostrada
	npc.interact(player, null, "APPLE")
	assert_eq(npc.dialog_bubble.get("word_text"), "APPLE", "Permite actualizar la palabra mostrada en los bloques")

	# Al volver a pulsar E mientras esta abierta, se cierra
	player.interact_with_nearest_npc()
	assert_false(npc.is_dialog_visible(), "La ventana se oculta al interactuar de nuevo")


func test_mobile_touch_controls_move_player_and_trigger_npc_dialog():
	var root := Node2D.new()
	add_child_autofree(root)

	var player := PlayerScript.new()
	player.name = "CharacterBody2D"
	var player_sprite := AnimatedSprite2D.new()
	player_sprite.name = "AnimatedSprite2D"
	player.add_child(player_sprite)
	var camera := Camera2D.new()
	camera.name = "Camera2D"
	camera.zoom = Vector2(2.0, 2.0)
	player.add_child(camera)
	root.add_child(player)
	player.global_position = Vector2(100, 100)

	var npc := NpcFriendScript.new()
	root.add_child(npc)
	npc.global_position = Vector2(80, 100)

	var controls := MobileControlsScript.new()
	controls.player = player
	root.add_child(controls)
	controls._process(0.05)
	assert_true(controls.is_interact_highlighted, "El boton E se ilumina cuando la arquera esta cerca")

	# 1. Simular toque y arrastre en el joystick virtual hacia la derecha (caminar -> correr en el borde)
	var joy_base: Vector2 = controls._joystick_default_pos
	controls._handle_screen_touch(0, joy_base, true)
	controls._handle_screen_drag(0, joy_base + Vector2(controls.joystick_outer_radius * 0.5, 0.0))
	player._physics_process(0.05)
	assert_gt(player.velocity.x, 0.0, "El joystick virtual mueve al jugador hacia la derecha")
	assert_lt(player.velocity.x, PlayerScript.RUN_SPEED, "A mitad de recorrido camina")

	controls._handle_screen_drag(0, joy_base + Vector2(controls.joystick_outer_radius, 0.0))
	player._physics_process(0.05)
	assert_almost_eq(player.velocity.x, PlayerScript.RUN_SPEED, 1.0, "En el borde exterior del joystick corre automaticamente")

	controls._handle_screen_touch(0, joy_base, false)
	player._physics_process(0.05)
	assert_eq(player.velocity, Vector2.ZERO, "Al soltar el joystick el jugador se detiene")

	# 2. Simular toque en el boton de interaccion E / Corazon
	assert_false(npc.is_dialog_visible(), "La burbuja empieza cerrada")
	controls._handle_screen_touch(1, controls._interact_btn_center, true)
	controls._handle_screen_touch(1, controls._interact_btn_center, false)
	assert_true(npc.is_dialog_visible(), "Tocar el boton E abre la burbuja de dialogo del NPC")

	# 3. Simular botones de zoom + y -
	var initial_zoom := camera.zoom.x
	controls._handle_screen_touch(2, controls._zoom_in_rect.get_center(), true)
	controls._handle_screen_touch(2, controls._zoom_in_rect.get_center(), false)
	assert_gt(camera.zoom.x, initial_zoom, "El boton + acerca la camara")
