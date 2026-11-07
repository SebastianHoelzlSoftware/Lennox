@tool
# mage_tower_exterior.gd
# Fachada exterior de la Torre de Magos con dragon guardian animado y puerta interactiva.
extends Node2D

@export_file("*.tscn") var interior_scene_path: String = "res://scenes/mage_tower_interior.tscn"
@export var dragon_animated: bool = true

const EXTERIOR_TEX: Texture2D = preload("res://assets/common/mage_tower/Exterior.png")
const DOORS_TEX: Texture2D = preload("res://assets/common/mage_tower/Doors.png")
const DRAGON_BACK_TEX: Texture2D = preload("res://assets/common/mage_tower/Dragon/Dragon_back.png")
const DRAGON_BODY_TEX: Texture2D = preload("res://assets/common/mage_tower/Dragon/Dragon_body.png")
const DRAGON_WING_TEX: Texture2D = preload("res://assets/common/mage_tower/Dragon/Dragon_wing.png")
const DRAGON_TAIL_TEX: Texture2D = preload("res://assets/common/mage_tower/Dragon/Dragon_tail.png")

var _door_sprite: AnimatedSprite2D
var _portal_area: Area2D
var _transitioning: bool = false


func _ready() -> void:
	_ensure_default_courtyard()
	_setup_visuals()
	if Engine.is_editor_hint():
		return
	_portal_area = get_node_or_null("EntrancePortal") as Area2D
	if _portal_area != null and not _portal_area.body_entered.is_connected(_on_portal_body_entered):
		_portal_area.body_entered.connect(_on_portal_body_entered)


func _ensure_default_courtyard() -> void:
	var courtyard := get_node_or_null("CourtyardTileMap") as TileMapLayer
	if courtyard == null or not courtyard.get_used_cells().is_empty():
		return
	# Camino de adoquines frente a la puerta (usando Walls_street.png, source_id = 2)
	for y in range(1, 5):
		for x in range(-1, 1):
			courtyard.set_cell(Vector2i(x, y), 2, Vector2i(14 + posmod(x, 2), 14 + posmod(y, 2)))


func _notification(what: int) -> void:
	if what == NOTIFICATION_EDITOR_PRE_SAVE:
		_clear_sprite_frames()
	elif what == NOTIFICATION_EDITOR_POST_SAVE:
		_setup_visuals()


func _clear_sprite_frames() -> void:
	for node_path: String in ["DragonBack", "DragonBody", "DragonWing", "DragonTail", "DoorSprite"]:
		var anim := get_node_or_null(node_path) as AnimatedSprite2D
		if anim != null:
			anim.sprite_frames = null
			anim.animation = &""


func _setup_visuals() -> void:
	_setup_anim_node("DragonBack", DRAGON_BACK_TEX, 48, 48, 6, 8.0)
	_setup_anim_node("DragonBody", DRAGON_BODY_TEX, 80, 112, 24, 8.0)
	_setup_anim_node("DragonWing", DRAGON_WING_TEX, 80, 128, 6, 8.0)
	_setup_anim_node("DragonTail", DRAGON_TAIL_TEX, 64, 80, 15, 8.0)
	_door_sprite = get_node_or_null("DoorSprite") as AnimatedSprite2D
	if _door_sprite != null:
		var frames := SpriteFrames.new()
		frames.add_animation(&"open")
		frames.set_animation_loop(&"open", false)
		frames.set_animation_speed(&"open", 12.0)
		for row in range(6):
			var atlas := AtlasTexture.new()
			atlas.atlas = DOORS_TEX
			atlas.region = Rect2(0, row * 48, 48, 48)
			frames.add_frame(&"open", atlas)
		if frames.has_animation(&"default"):
			frames.remove_animation(&"default")
		_door_sprite.sprite_frames = frames
		_door_sprite.animation = &"open"
		_door_sprite.frame = 0


func _setup_anim_node(node_name: String, tex: Texture2D, fw: int, fh: int, count: int, fps: float) -> void:
	var anim := get_node_or_null(node_name) as AnimatedSprite2D
	if anim == null or tex == null:
		return
	var frames := SpriteFrames.new()
	frames.add_animation(&"idle")
	frames.set_animation_loop(&"idle", true)
	frames.set_animation_speed(&"idle", fps)
	@warning_ignore("INTEGER_DIVISION")
	var cols: int = maxi(1, tex.get_width() / fw)
	for i in range(count):
		@warning_ignore("INTEGER_DIVISION")
		var r: int = i / cols
		var c: int = i % cols
		var atlas := AtlasTexture.new()
		atlas.atlas = tex
		atlas.region = Rect2(c * fw, r * fh, fw, fh)
		frames.add_frame(&"idle", atlas)
	if frames.has_animation(&"default"):
		frames.remove_animation(&"default")
	anim.sprite_frames = frames
	anim.animation = &"idle"
	if dragon_animated:
		anim.play(&"idle")


func _on_portal_body_entered(body: Node2D) -> void:
	if Engine.is_editor_hint() or _transitioning:
		return
	if body == null or not (body is CharacterBody2D):
		return
	# Solo el jugador principal dispara el cambio de escena (no el NPC acompanante)
	if body.name != "CharacterBody2D" and not body.is_in_group("player"):
		return
	_transitioning = true
	if _door_sprite != null and _door_sprite.sprite_frames != null:
		_door_sprite.play(&"open")
		await _door_sprite.animation_finished
	if interior_scene_path != "" and ResourceLoader.exists(interior_scene_path):
		get_tree().change_scene_to_file(interior_scene_path)
	else:
		_transitioning = false
