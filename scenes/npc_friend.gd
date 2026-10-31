extends CharacterBody2D
# Compañera NPC arquera que sigue al jugador de forma natural.
#
# Utiliza las hojas de animacion de la arquera (Archer_lvl1) con 4 direcciones (down, left,
# right, up), una cola de migas de pan (breadcrumb trail) para seguir el camino recorrido
# por el jugador con suavidad, aceleracion/frenado progresivo y pequenas miradas curiosas
# cuando ambos estan detenidos.

@export var target_path: NodePath
@export var follow_distance: float = 28.0
@export var run_catchup_distance: float = 58.0
@export var teleport_distance: float = 360.0
@export var breadcrumb_spacing: float = 12.0

@onready var animated_sprite: AnimatedSprite2D = get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D

const WALK_SPEED := 105.0
const RUN_SPEED := 210.0
const ACCELERATION := 650.0
const FRICTION := 800.0
const STOP_SPEED_THRESHOLD := 8.0
const RUN_SPEED_THRESHOLD := 145.0
const FRAME_SIZE := Vector2i(64, 64)
const DIRECTION_ROWS := {
	&"down": 0,
	&"left": 1,
	&"right": 2,
	&"up": 3,
}

const IDLE_SHEET: Texture2D = preload(
	"res://assets/common/characters/Archer_lvl1_Idle_without_shadow.png"
)
const WALK_SHEET: Texture2D = preload(
	"res://assets/common/characters/Archer_lvl1_Walk_without_shadow.png"
)
const RUN_SHEET: Texture2D = preload(
	"res://assets/common/characters/Archer_lvl1_Run_without_shadow.png"
)
const ATTACK_SHEET: Texture2D = preload(
	"res://assets/common/characters/Archer_lvl1_Attack_without_shadow.png"
)
const HURT_SHEET: Texture2D = preload(
	"res://assets/common/characters/Archer_lvl1_Hurt_without_shadow.png"
)
const DEATH_SHEET: Texture2D = preload(
	"res://assets/common/characters/Archer_lvl1_Death_without_shadow.png"
)

var target: Node2D = null
var _facing_direction: StringName = &"down"
var _breadcrumbs: Array[Vector2] = []
var _is_catching_up: bool = false
var _idle_glance_timer: float = 2.5


func _ready() -> void:
	# Evitar empujar al jugador al caminar a su lado
	collision_layer = 0
	collision_mask = 0

	if animated_sprite == null:
		animated_sprite = AnimatedSprite2D.new()
		animated_sprite.name = "AnimatedSprite2D"
		animated_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		add_child(animated_sprite)

	animated_sprite.sprite_frames = _create_sprite_frames()
	animated_sprite.play(&"idle_down")

	if not target_path.is_empty():
		target = get_node_or_null(target_path) as Node2D
	if target == null and get_parent() != null:
		target = get_parent().get_node_or_null("CharacterBody2D") as Node2D


func set_follow_target(p_target: Node2D, p_snap: bool = false) -> void:
	target = p_target
	_breadcrumbs.clear()
	if target != null and p_snap:
		global_position = target.global_position + Vector2(-follow_distance, 6.0)


func _physics_process(delta: float) -> void:
	if target == null or not is_instance_valid(target):
		velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)
		_update_animation(velocity)
		move_and_slide()
		return

	_record_breadcrumbs()
	var desired_velocity := _compute_follow_velocity(delta)
	var accel := ACCELERATION if not desired_velocity.is_zero_approx() else FRICTION
	velocity = velocity.move_toward(desired_velocity, accel * delta)

	if velocity.length() < STOP_SPEED_THRESHOLD and desired_velocity.is_zero_approx():
		velocity = Vector2.ZERO
		_update_idle_glance(delta)

	_update_animation(velocity)
	move_and_slide()


func _record_breadcrumbs() -> void:
	var target_pos := target.global_position
	if _breadcrumbs.is_empty():
		if global_position.distance_to(target_pos) > follow_distance:
			_breadcrumbs.append(target_pos)
		return

	var last_point: Vector2 = _breadcrumbs[_breadcrumbs.size() - 1]
	if last_point.distance_to(target_pos) >= breadcrumb_spacing:
		_breadcrumbs.append(target_pos)
		if _breadcrumbs.size() > 32:
			_breadcrumbs.pop_front()


func _compute_follow_velocity(_delta: float) -> Vector2:
	var to_target := target.global_position - global_position
	var dist_to_target := to_target.length()

	# Si se queda demasiado lejos, se acerca rapidamente al jugador
	if dist_to_target > teleport_distance:
		global_position = target.global_position - to_target.normalized() * (follow_distance * 1.2)
		_breadcrumbs.clear()
		return Vector2.ZERO

	# Histeresis para empezar/parar de caminar con naturalidad (sin vibrar en el borde)
	var start_dist := follow_distance + 8.0
	var stop_dist := follow_distance - 3.0
	if dist_to_target <= stop_dist:
		_is_catching_up = false
		_breadcrumbs.clear()
		return Vector2.ZERO
	if not _is_catching_up and dist_to_target < start_dist:
		return Vector2.ZERO

	_is_catching_up = true

	# Consumir puntos intermedios del rastro que ya hemos alcanzado
	while _breadcrumbs.size() > 1 and global_position.distance_to(_breadcrumbs[0]) <= breadcrumb_spacing:
		_breadcrumbs.pop_front()

	var steer_point := target.global_position
	if not _breadcrumbs.is_empty():
		steer_point = _breadcrumbs[0]

	var dir := (steer_point - global_position).normalized()
	if dir.is_zero_approx():
		dir = to_target.normalized()

	# Ajustar velocidad: corre si esta lejos o si el jugador va corriendo; frena suave al llegar
	var target_vel := Vector2.ZERO
	if target is CharacterBody2D:
		target_vel = (target as CharacterBody2D).velocity

	var max_speed := WALK_SPEED
	if dist_to_target > run_catchup_distance or target_vel.length() > WALK_SPEED + 20.0:
		max_speed = RUN_SPEED

	var slow_radius := follow_distance + 22.0
	var arrival_factor := clampf((dist_to_target - stop_dist) / maxf(slow_radius - stop_dist, 1.0), 0.35, 1.0)
	return dir * (max_speed * arrival_factor)


func _update_idle_glance(delta: float) -> void:
	_idle_glance_timer -= delta
	if _idle_glance_timer > 0.0:
		return
	_idle_glance_timer = randf_range(2.4, 4.8)
	# De vez en cuando mira hacia el jugador cuando estan parados juntos
	var to_player := target.global_position - global_position
	if to_player.length() > 4.0:
		_facing_direction = direction_name_from_vector(to_player)


static func direction_name_from_vector(vec: Vector2) -> StringName:
	if absf(vec.x) > absf(vec.y):
		return &"right" if vec.x > 0.0 else &"left"
	return &"down" if vec.y > 0.0 else &"up"


func _update_animation(move_vec: Vector2) -> void:
	if animated_sprite == null or animated_sprite.sprite_frames == null:
		return
	var speed := move_vec.length()
	if speed >= STOP_SPEED_THRESHOLD:
		_facing_direction = direction_name_from_vector(move_vec)

	var movement_animation: StringName = &"idle"
	if speed >= RUN_SPEED_THRESHOLD:
		movement_animation = &"run"
	elif speed >= STOP_SPEED_THRESHOLD:
		movement_animation = &"walk"

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
