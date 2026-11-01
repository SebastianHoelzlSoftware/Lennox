extends CharacterBody2D

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

const WALK_SPEED := 100.0
const RUN_SPEED := 200.0
const FRAME_SIZE := Vector2i(64, 64)
const DIRECTION_ROWS := {
	&"down": 0,
	&"left": 1,
	&"right": 2,
	&"up": 3,
}
const IDLE_SHEET: Texture2D = preload(
	"res://assets/player_sprites/Swordsman_lvl1/Without_shadow/Swordsman_lvl1_Idle_without_shadow.png"
)
const WALK_SHEET: Texture2D = preload(
	"res://assets/player_sprites/Swordsman_lvl1/Without_shadow/Swordsman_lvl1_Walk_without_shadow.png"
)
const RUN_SHEET: Texture2D = preload(
	"res://assets/player_sprites/Swordsman_lvl1/Without_shadow/Swordsman_lvl1_Run_without_shadow.png"
)
const ATTACK_SHEET: Texture2D = preload(
	"res://assets/player_sprites/Swordsman_lvl1/Without_shadow/Swordsman_lvl1_attack_without_shadow.png"
)
const WALK_ATTACK_SHEET: Texture2D = preload(
	"res://assets/player_sprites/Swordsman_lvl1/Without_shadow/Swordsman_lvl1_Walk_Attack_without_shadow.png"
)
const RUN_ATTACK_SHEET: Texture2D = preload(
	"res://assets/player_sprites/Swordsman_lvl1/Without_shadow/Swordsman_lvl1_Run_Attack_without_shadow.png"
)
const HURT_SHEET: Texture2D = preload(
	"res://assets/player_sprites/Swordsman_lvl1/Without_shadow/Swordsman_lvl1_Hurt_without_shadow.png"
)
const DEATH_SHEET: Texture2D = preload(
	"res://assets/player_sprites/Swordsman_lvl1/Without_shadow/Swordsman_lvl1_Death_without_shadow.png"
)

var _facing_direction: StringName = &"down"


func _ready() -> void:
	animated_sprite.sprite_frames = _create_sprite_frames()
	animated_sprite.play(&"idle_down")


func _unhandled_input(event: InputEvent) -> void:
	if _is_interact_event(event):
		if interact_with_nearest_npc() != null:
			var vp := get_viewport()
			if vp != null:
				vp.set_input_as_handled()


static func _is_interact_event(event: InputEvent) -> bool:
	if event.is_action_pressed(&"interact"):
		return true
	if event is InputEventKey:
		var key_event := event as InputEventKey
		if key_event.pressed and not key_event.echo:
			return key_event.keycode == KEY_E or key_event.physical_keycode == KEY_E
	return false


func interact_with_nearest_npc() -> Node2D:
	var candidates: Array[Node] = []
	if is_inside_tree():
		candidates.assign(get_tree().get_nodes_in_group(&"npc_companions"))
	if candidates.is_empty() and get_parent() != null:
		for child in get_parent().get_children():
			if child != self and child is Node2D and child.has_method("interact"):
				candidates.append(child)

	var nearest: Node2D = null
	var nearest_dist := INF
	for node in candidates:
		if not (node is Node2D) or not is_instance_valid(node) or not node.has_method("interact"):
			continue
		var npc := node as Node2D
		var max_dist := 72.0
		if "interaction_radius" in npc:
			max_dist = float(npc.get("interaction_radius"))
		var dist := global_position.distance_to(npc.global_position)
		if dist <= max_dist and dist < nearest_dist:
			nearest = npc
			nearest_dist = dist

	if nearest != null:
		# Si otro companero tenia una ventana abierta, la cerramos para centrar la atencion
		for node in candidates:
			if node != nearest and is_instance_valid(node) and "dialog_bubble" in node:
				var other_bubble: Object = node.get("dialog_bubble")
				if other_bubble != null and other_bubble.has_method("hide_bubble"):
					other_bubble.call("hide_bubble")
		nearest.call("interact", self)
	return nearest


func _physics_process(_delta: float) -> void:
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var is_running := Input.is_action_pressed("run")
	velocity = direction * (RUN_SPEED if is_running else WALK_SPEED)
	_update_animation(direction)
	move_and_slide()


func _update_animation(direction: Vector2) -> void:
	if not direction.is_zero_approx():
		if absf(direction.x) > absf(direction.y):
			_facing_direction = &"right" if direction.x > 0.0 else &"left"
		else:
			_facing_direction = &"down" if direction.y > 0.0 else &"up"

	var movement_animation: StringName = &"idle"
	if not direction.is_zero_approx():
		movement_animation = &"run" if Input.is_action_pressed("run") else &"walk"
	var animation_name := StringName("%s_%s" % [movement_animation, _facing_direction])
	if animated_sprite.animation != animation_name or not animated_sprite.is_playing():
		animated_sprite.play(animation_name)


func _create_sprite_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	_add_sheet(frames, &"idle", IDLE_SHEET, 12, 6.0, true, {&"up": 4})
	_add_sheet(frames, &"walk", WALK_SHEET, 6, 9.0, true)
	_add_sheet(frames, &"run", RUN_SHEET, 8, 12.0, true)
	_add_sheet(frames, &"attack", ATTACK_SHEET, 8, 12.0, false)
	_add_sheet(frames, &"walk_attack", WALK_ATTACK_SHEET, 6, 12.0, false)
	_add_sheet(frames, &"run_attack", RUN_ATTACK_SHEET, 8, 12.0, false)
	_add_sheet(frames, &"hurt", HURT_SHEET, 5, 10.0, false)
	_add_sheet(frames, &"death", DEATH_SHEET, 7, 8.0, false)
	return frames


func _add_sheet(
	frames: SpriteFrames,
	animation_prefix: StringName,
	texture: Texture2D,
	frame_count: int,
	fps: float,
	loop_animation: bool,
	direction_frame_overrides: Dictionary = {}
) -> void:
	for direction: StringName in DIRECTION_ROWS:
		var animation_name := StringName("%s_%s" % [animation_prefix, direction])
		frames.add_animation(animation_name)
		frames.set_animation_speed(animation_name, fps)
		frames.set_animation_loop(animation_name, loop_animation)
		var row: int = DIRECTION_ROWS[direction]
		var count: int = direction_frame_overrides.get(direction, frame_count)
		for frame_index in range(count):
			var atlas_frame := AtlasTexture.new()
			atlas_frame.atlas = texture
			atlas_frame.region = Rect2(
				Vector2(frame_index * FRAME_SIZE.x, row * FRAME_SIZE.y),
				Vector2(FRAME_SIZE)
			)
			frames.add_frame(animation_name, atlas_frame)
