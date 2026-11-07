@tool
# mage_tower_interior.gd
# Escena interior de la Torre de Magos: biblioteca arcana, sala de invocacion y laboratorio.
# Todos los azulejos y objetos estan expuestos en nodos TileMapLayer y Sprite2D/AnimatedSprite2D
# para poder editarlos comodamente en el editor 2D de Godot.
extends Node2D

@export_file("*.tscn") var exterior_scene_path: String = "res://scenes/main.tscn"
@export var build_default_room_if_empty: bool = true

const MAGE1_TEX: Texture2D = preload("res://assets/common/mage_tower/Mages/Mage1.png")
const MAGE2_TEX: Texture2D = preload("res://assets/common/mage_tower/Mages/Mage2.png")
const DEMON_TEX: Texture2D = preload("res://assets/common/mage_tower/Demon/Demon.png")
const LIGHTNING_TEX: Texture2D = preload("res://assets/common/mage_tower/Lightning.png")
const DRAGON_CHILD_TEX: Texture2D = preload("res://assets/common/mage_tower/Dragon_child/Dragon_child.png")
const PUPILS_FLOOR1_TEX: Texture2D = preload("res://assets/common/mage_tower/Pupils/Pupils_together_floor1.png")
const PUPILS_FLOOR2_TEX: Texture2D = preload("res://assets/common/mage_tower/Pupils/Pupils_together_floor2.png")
const READER1_TEX: Texture2D = preload("res://assets/common/mage_tower/Readers/Reader1.png")
const READER2_TEX: Texture2D = preload("res://assets/common/mage_tower/Readers/Reader2.png")
const READER3_TEX: Texture2D = preload("res://assets/common/mage_tower/Readers/Reader3.png")
const DOORS_TEX: Texture2D = preload("res://assets/common/mage_tower/Doors.png")
const MobileControlsScript = preload("res://scenes/mobile_controls.gd")

const ANIMATED_NODES_CONFIG := {
	"Inhabitants/Archmage": {"tex": MAGE1_TEX, "fw": 32, "fh": 48, "count": 24, "fps": 8.0},
	"Inhabitants/SummonerMage": {"tex": MAGE2_TEX, "fw": 32, "fh": 48, "count": 24, "fps": 8.0},
	"Inhabitants/SummonedDemon": {"tex": DEMON_TEX, "fw": 80, "fh": 80, "count": 18, "fps": 7.0},
	"Inhabitants/ArcaneLightning": {"tex": LIGHTNING_TEX, "fw": 80, "fh": 128, "count": 12, "fps": 10.0},
	"Inhabitants/SleepingDragonChild": {"tex": DRAGON_CHILD_TEX, "fw": 64, "fh": 48, "count": 12, "fps": 5.0},
	"Inhabitants/PupilsCircleLarge": {"tex": PUPILS_FLOOR1_TEX, "fw": 256, "fh": 112, "count": 12, "fps": 6.0},
	"Inhabitants/PupilsCircleSmall": {"tex": PUPILS_FLOOR2_TEX, "fw": 224, "fh": 96, "count": 12, "fps": 6.0},
	"Inhabitants/Reader1": {"tex": READER1_TEX, "fw": 32, "fh": 48, "count": 18, "fps": 6.0},
	"Inhabitants/Reader2": {"tex": READER2_TEX, "fw": 32, "fh": 48, "count": 2, "fps": 2.0},
	"Inhabitants/Reader3": {"tex": READER3_TEX, "fw": 32, "fh": 48, "count": 2, "fps": 2.0},
}

var _transitioning: bool = false


func _ready() -> void:
	y_sort_enabled = true
	if build_default_room_if_empty:
		_ensure_default_tilemap_layout()
	_setup_animated_inhabitants()
	if Engine.is_editor_hint():
		return

	var player := get_node_or_null("CharacterBody2D") as CharacterBody2D
	var npc_friend := get_node_or_null("NpcFriend") as CharacterBody2D
	if npc_friend != null and player != null and npc_friend.has_method("set_follow_target"):
		npc_friend.call("set_follow_target", player, false)

	var mobile_controls := get_node_or_null("MobileControls") as CanvasLayer
	if mobile_controls == null and player != null:
		mobile_controls = MobileControlsScript.new()
		mobile_controls.name = "MobileControls"
		mobile_controls.set("player", player)
		add_child(mobile_controls)

	var exit_portal := get_node_or_null("ExitPortal") as Area2D
	if exit_portal != null and not exit_portal.body_entered.is_connected(_on_exit_portal_body_entered):
		exit_portal.body_entered.connect(_on_exit_portal_body_entered)


func _notification(what: int) -> void:
	if what == NOTIFICATION_EDITOR_PRE_SAVE:
		_clear_sprite_frames()
	elif what == NOTIFICATION_EDITOR_POST_SAVE:
		_setup_animated_inhabitants()


func _clear_sprite_frames() -> void:
	for path: String in ANIMATED_NODES_CONFIG.keys():
		var anim := get_node_or_null(path) as AnimatedSprite2D
		if anim != null:
			anim.sprite_frames = null
			anim.animation = &""
	var exit_door := get_node_or_null("ExitDoorSprite") as AnimatedSprite2D
	if exit_door != null:
		exit_door.sprite_frames = null
		exit_door.animation = &""


func _setup_animated_inhabitants() -> void:
	for path: String in ANIMATED_NODES_CONFIG.keys():
		var anim := get_node_or_null(path) as AnimatedSprite2D
		if anim == null:
			continue
		var cfg: Dictionary = ANIMATED_NODES_CONFIG[path]
		var tex: Texture2D = cfg["tex"]
		var fw: int = cfg["fw"]
		var fh: int = cfg["fh"]
		var count: int = cfg["count"]
		var fps: float = cfg["fps"]
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
		anim.play(&"idle")

	var exit_door := get_node_or_null("ExitDoorSprite") as AnimatedSprite2D
	if exit_door != null:
		var dframes := SpriteFrames.new()
		dframes.add_animation(&"open")
		dframes.set_animation_loop(&"open", false)
		dframes.set_animation_speed(&"open", 12.0)
		for row in range(6):
			var atlas := AtlasTexture.new()
			atlas.atlas = DOORS_TEX
			atlas.region = Rect2(96, row * 48, 32, 48)
			dframes.add_frame(&"open", atlas)
		if dframes.has_animation(&"default"):
			dframes.remove_animation(&"default")
		exit_door.sprite_frames = dframes
		exit_door.animation = &"open"
		exit_door.frame = 0


func _ensure_default_tilemap_layout() -> void:
	var floor_map := get_node_or_null("FloorTileMap") as TileMapLayer
	var wall_map := get_node_or_null("WallsTileMap") as TileMapLayer
	if floor_map == null or wall_map == null:
		return
	if not floor_map.get_used_cells().is_empty():
		return

	# Pintamos un gran salon arcano de 28x18 celdas (x: -14..13, y: -9..8) usando Interior_walls.png (source_id = 0)
	var floor_blocks := [Vector2i(0, 23), Vector2i(3, 23), Vector2i(6, 23), Vector2i(9, 23)]
	for y in range(-6, 9):
		for x in range(-14, 14):
			var block_idx: int = posmod((x >> 1) + (y >> 1), floor_blocks.size())
			var base_atlas: Vector2i = floor_blocks[block_idx]
			var dx: int = posmod(x, 2)
			var dy: int = posmod(y, 2)
			floor_map.set_cell(Vector2i(x, y), 0, base_atlas + Vector2i(dx, dy))

	# Muro norte estrellado con zocalo de madera (filas 19, 20, 21 de Interior_walls.png)
	# y ventanas arqueadas intercaladas (columnas 5..6 y 7..8)
	for x in range(-14, 14):
		var col_in_wall: int = posmod(x, 3)
		# Ventanas arqueadas en x = -10..-9, -4..-3, 3..4, 9..10
		if x in [-10, -4, 3, 9]:
			wall_map.set_cell(Vector2i(x, -9), 0, Vector2i(5, 19))
			wall_map.set_cell(Vector2i(x, -8), 0, Vector2i(5, 20))
			wall_map.set_cell(Vector2i(x, -7), 0, Vector2i(5, 21))
		elif x in [-9, -3, 4, 10]:
			wall_map.set_cell(Vector2i(x, -9), 0, Vector2i(6, 19))
			wall_map.set_cell(Vector2i(x, -8), 0, Vector2i(6, 20))
			wall_map.set_cell(Vector2i(x, -7), 0, Vector2i(6, 21))
		else:
			wall_map.set_cell(Vector2i(x, -9), 0, Vector2i(col_in_wall, 19))
			wall_map.set_cell(Vector2i(x, -8), 0, Vector2i(col_in_wall, 20))
			wall_map.set_cell(Vector2i(x, -7), 0, Vector2i(col_in_wall, 21))

	# Bordes laterales (columnas de piedra en x = -15 y x = 14) y muro inferior con salida en x = -1..0
	for y in range(-9, 9):
		wall_map.set_cell(Vector2i(-15, y), 0, Vector2i(12, 14 + posmod(y, 2)))
		wall_map.set_cell(Vector2i(14, y), 0, Vector2i(14, 14 + posmod(y, 2)))
	for x in range(-15, 15):
		if x == -1 or x == 0:
			continue
		wall_map.set_cell(Vector2i(x, 9), 0, Vector2i(13, 12))


func _unhandled_input(event: InputEvent) -> void:
	if Engine.is_editor_hint():
		return
	var player := get_node_or_null("CharacterBody2D") as CharacterBody2D
	if player == null:
		return
	var camera := player.get_node_or_null("Camera2D") as Camera2D
	if camera == null:
		return
	if event is InputEventMouseButton and event.is_pressed():
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			camera.zoom = (camera.zoom * 1.15).clamp(Vector2(0.5, 0.5), Vector2(4.0, 4.0))
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			camera.zoom = (camera.zoom * 0.85).clamp(Vector2(0.5, 0.5), Vector2(4.0, 4.0))


func _on_exit_portal_body_entered(body: Node2D) -> void:
	if Engine.is_editor_hint() or _transitioning:
		return
	if body == null or not (body is CharacterBody2D):
		return
	if body.name != "CharacterBody2D" and not body.is_in_group("player"):
		return
	_transitioning = true
	var exit_door := get_node_or_null("ExitDoorSprite") as AnimatedSprite2D
	if exit_door != null and exit_door.sprite_frames != null:
		exit_door.play(&"open")
		await exit_door.animation_finished
	if exterior_scene_path != "" and ResourceLoader.exists(exterior_scene_path):
		get_tree().change_scene_to_file(exterior_scene_path)
	else:
		_transitioning = false
