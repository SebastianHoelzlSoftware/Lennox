extends CanvasLayer
# Controles tactiles para dispositivos moviles (Android / Pixel 6) y pantalla tactil.
#
# Incluye:
# 1. Joystick virtual a la izquierda (caminar suave o correr al empujar al borde exterior).
# 2. Boton de interaccion "E" con icono de corazon a la derecha (se ilumina cuando la arquera esta cerca).
# 3. Boton de correr ("RUN") a la derecha (mantener pulsado para correr).
# 4. Botones de zoom "+" / "-" arriba a la derecha + gesto de pellizco (pinch-to-zoom) con dos dedos.
# 5. Toque directo sobre un compañero NPC en el mundo para abrir/cerrar su burbuja de dialogo.

const HEART_ICON_TEXTURE: Texture2D = preload("res://assets/common/icons/Item9_2.png")

@export var player_path: NodePath
@export var joystick_outer_radius: float = 78.0
@export var joystick_knob_radius: float = 30.0
@export var joystick_deadzone: float = 0.14
@export var auto_run_threshold: float = 0.88

var player: CharacterBody2D = null
var hud_control: Control = null

var move_vector: Vector2 = Vector2.ZERO
var is_running_pressed: bool = false
var is_interact_highlighted: bool = false

var _joystick_touch_id: int = -1
var _joystick_base_pos: Vector2 = Vector2(148.0, 730.0)
var _joystick_default_pos: Vector2 = Vector2(148.0, 730.0)
var _joystick_knob_offset: Vector2 = Vector2.ZERO

var _run_touch_id: int = -1
var _interact_touch_id: int = -1
var _interact_flash_timer: float = 0.0
var _pulse_time: float = 0.0

var _interact_btn_center: Vector2 = Vector2(990.0, 735.0)
var _interact_btn_radius: float = 54.0
var _run_btn_center: Vector2 = Vector2(855.0, 765.0)
var _run_btn_radius: float = 42.0

var _zoom_in_rect: Rect2 = Rect2(Vector2(1015.0, 28.0), Vector2(46.0, 46.0))
var _zoom_out_rect: Rect2 = Rect2(Vector2(1072.0, 28.0), Vector2(46.0, 46.0))

# Seguimiento de puntos de toque activos para pellizco de zoom (pinch-to-zoom)
var _active_touches: Dictionary = {}
var _pinch_prev_dist: float = 0.0


func _ready() -> void:
	layer = 30
	hud_control = Control.new()
	hud_control.name = "TouchHUD"
	hud_control.set_anchors_preset(Control.PRESET_FULL_RECT)
	hud_control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_control.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	hud_control.draw.connect(_on_hud_draw)
	add_child(hud_control)

	if not player_path.is_empty():
		player = get_node_or_null(player_path) as CharacterBody2D
	if player == null and get_parent() != null:
		player = get_parent().get_node_or_null("CharacterBody2D") as CharacterBody2D

	_update_layout_positions()


func _process(delta: float) -> void:
	_pulse_time += delta
	if _interact_flash_timer > 0.0:
		_interact_flash_timer = maxf(0.0, _interact_flash_timer - delta)
	_update_layout_positions()
	_update_npc_proximity_highlight()
	if hud_control != null:
		hud_control.queue_redraw()


func _update_layout_positions() -> void:
	var vp := get_viewport()
	if vp == null:
		return
	var rect := vp.get_visible_rect()
	var w := rect.size.x
	var h := rect.size.y
	if w <= 0.0 or h <= 0.0:
		return

	var margin_x := clampf(w * 0.11, 115.0, 175.0)
	var margin_y := clampf(h * 0.18, 125.0, 165.0)

	_joystick_default_pos = Vector2(margin_x, h - margin_y)
	if _joystick_touch_id == -1:
		_joystick_base_pos = _joystick_default_pos

	_interact_btn_center = Vector2(w - margin_x + 10.0, h - margin_y - 6.0)
	_run_btn_center = Vector2(w - margin_x - 122.0, h - margin_y + 22.0)

	_zoom_out_rect = Rect2(Vector2(w - 68.0, 24.0), Vector2(44.0, 44.0))
	_zoom_in_rect = Rect2(Vector2(w - 122.0, 24.0), Vector2(44.0, 44.0))


func _update_npc_proximity_highlight() -> void:
	is_interact_highlighted = false
	if player == null or not is_instance_valid(player) or not is_inside_tree():
		return
	var companions := get_tree().get_nodes_in_group(&"npc_companions")
	for node in companions:
		if node is Node2D and is_instance_valid(node):
			var npc := node as Node2D
			var max_dist := 72.0
			if "interaction_radius" in npc:
				max_dist = float(npc.get("interaction_radius"))
			if player.global_position.distance_to(npc.global_position) <= max_dist:
				is_interact_highlighted = true
				break


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		_handle_screen_touch(touch.index, touch.position, touch.pressed)
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		_handle_screen_drag(drag.index, drag.position)


func _handle_screen_touch(index: int, pos: Vector2, pressed: bool) -> void:
	if pressed:
		_active_touches[index] = pos

		# 1. Botones de zoom arriba a la derecha
		if _zoom_in_rect.has_point(pos):
			_zoom_camera(1.18)
			_consume_input()
			return
		if _zoom_out_rect.has_point(pos):
			_zoom_camera(0.84)
			_consume_input()
			return

		# 2. Boton de interaccion (E / Corazon)
		if pos.distance_to(_interact_btn_center) <= _interact_btn_radius * 1.15:
			_interact_touch_id = index
			_interact_flash_timer = 0.22
			trigger_interact()
			_consume_input()
			return

		# 3. Boton de correr (RUN)
		if pos.distance_to(_run_btn_center) <= _run_btn_radius * 1.18:
			_run_touch_id = index
			_set_run_state(true)
			_consume_input()
			return

		# 4. Joystick virtual en la mitad izquierda inferior de la pantalla
		var vp_size := _get_viewport_size()
		var in_joystick_zone := (
			pos.distance_to(_joystick_default_pos) <= joystick_outer_radius * 1.75
			or (pos.x <= vp_size.x * 0.45 and pos.y >= vp_size.y * 0.35)
		)
		if _joystick_touch_id == -1 and in_joystick_zone:
			_joystick_touch_id = index
			if pos.distance_to(_joystick_default_pos) <= joystick_outer_radius * 1.35:
				_joystick_base_pos = _joystick_default_pos
			else:
				_joystick_base_pos = pos
			_update_joystick_from_pos(pos)
			_consume_input()
			return

		# 5. Si hay dos dedos libres en pantalla, iniciar gesto de pellizco (pinch-to-zoom)
		var free_touches := _get_non_control_touch_positions()
		if free_touches.size() == 2:
			_pinch_prev_dist = free_touches[0].distance_to(free_touches[1])
			return

		# 6. Toque directo sobre un compañero NPC en el mundo para hablar con el
		if _try_tap_world_npc(pos):
			_consume_input()
			return
	else:
		_active_touches.erase(index)
		if index == _joystick_touch_id:
			_joystick_touch_id = -1
			_joystick_base_pos = _joystick_default_pos
			_joystick_knob_offset = Vector2.ZERO
			_apply_move_vector(Vector2.ZERO)
		if index == _run_touch_id:
			_run_touch_id = -1
			_set_run_state(false)
		if index == _interact_touch_id:
			_interact_touch_id = -1
		if _get_non_control_touch_positions().size() < 2:
			_pinch_prev_dist = 0.0


func _handle_screen_drag(index: int, pos: Vector2) -> void:
	_active_touches[index] = pos
	if index == _joystick_touch_id:
		_update_joystick_from_pos(pos)
		_consume_input()
		return

	var free_touches := _get_non_control_touch_positions()
	if free_touches.size() == 2:
		var new_dist := free_touches[0].distance_to(free_touches[1])
		if _pinch_prev_dist > 12.0 and new_dist > 12.0:
			var ratio := clampf(new_dist / _pinch_prev_dist, 0.85, 1.15)
			_zoom_camera(ratio)
		_pinch_prev_dist = new_dist


func _get_non_control_touch_positions() -> Array[Vector2]:
	var list: Array[Vector2] = []
	for id: int in _active_touches.keys():
		if id == _joystick_touch_id or id == _run_touch_id or id == _interact_touch_id:
			continue
		list.append(_active_touches[id])
	return list


func _update_joystick_from_pos(pos: Vector2) -> void:
	var delta := pos - _joystick_base_pos
	var dist := delta.length()
	var max_r := maxf(joystick_outer_radius, 1.0)
	if dist > max_r:
		_joystick_knob_offset = delta.normalized() * max_r
	else:
		_joystick_knob_offset = delta

	var norm := dist / max_r
	if norm < joystick_deadzone:
		_apply_move_vector(Vector2.ZERO)
	else:
		var strength := clampf((norm - joystick_deadzone) / maxf(1.0 - joystick_deadzone, 0.01), 0.0, 1.0)
		_apply_move_vector(delta.normalized() * strength)


func _apply_move_vector(vec: Vector2) -> void:
	move_vector = vec
	var norm_len := _joystick_knob_offset.length() / maxf(joystick_outer_radius, 1.0)
	var auto_run := norm_len >= auto_run_threshold
	var should_run := is_running_pressed or auto_run

	if player != null and is_instance_valid(player) and "touch_move_vector" in player:
		player.set("touch_move_vector", move_vector)
		player.set("touch_run_active", should_run)


func _set_run_state(active: bool) -> void:
	is_running_pressed = active
	var norm_len := _joystick_knob_offset.length() / maxf(joystick_outer_radius, 1.0)
	var should_run := is_running_pressed or (norm_len >= auto_run_threshold)
	if player != null and is_instance_valid(player) and "touch_run_active" in player:
		player.set("touch_run_active", should_run)


func trigger_interact() -> Node2D:
	if player != null and is_instance_valid(player) and player.has_method("interact_with_nearest_npc"):
		return player.call("interact_with_nearest_npc") as Node2D
	return null


func _try_tap_world_npc(screen_pos: Vector2) -> bool:
	if not is_inside_tree() or player == null or not is_instance_valid(player):
		return false
	var world_pos := _screen_to_world(screen_pos)
	var companions := get_tree().get_nodes_in_group(&"npc_companions")
	for node in companions:
		if not (node is Node2D) or not is_instance_valid(node) or not node.has_method("interact"):
			continue
		var npc := node as Node2D
		# Radio generoso en coordenadas del mundo para que sea facil tocar a la arquera en el movil
		if npc.global_position.distance_to(world_pos) <= 44.0:
			npc.call("interact", player)
			_interact_flash_timer = 0.22
			return true
	return false


func _screen_to_world(screen_pos: Vector2) -> Vector2:
	var vp := get_viewport()
	if vp == null:
		return screen_pos
	return vp.get_canvas_transform().affine_inverse() * screen_pos


func _zoom_camera(factor: float) -> void:
	if player == null or not is_instance_valid(player):
		return
	var camera := player.get_node_or_null("Camera2D") as Camera2D
	if camera == null:
		return
	camera.zoom = (camera.zoom * factor).clamp(Vector2(0.3, 0.3), Vector2(3.5, 3.5))


func _get_viewport_size() -> Vector2:
	var vp := get_viewport()
	if vp != null:
		return vp.get_visible_rect().size
	return Vector2(1150.0, 900.0)


func _consume_input() -> void:
	var vp := get_viewport()
	if vp != null:
		vp.set_input_as_handled()


func _on_hud_draw() -> void:
	var c_shadow := Color(0.06, 0.05, 0.10, 0.38)
	var c_outline := Color("#231F2E")
	var c_panel := Color("#58506B")
	var c_panel_alpha := Color(c_panel.r, c_panel.g, c_panel.b, 0.72)
	var c_slot := Color(0.23, 0.21, 0.29, 0.80)
	var c_orange := Color("#F29B38")
	var c_gold := Color("#FFE875")
	var c_cyan := Color("#68F2FF")

	# --- 1. JOYSTICK VIRTUAL (Izquierda) ---
	var joy_active := _joystick_touch_id != -1
	var base_alpha := 0.86 if joy_active else 0.58
	var ring_col := Color(c_panel.r, c_panel.g, c_panel.b, base_alpha)
	var inner_col := Color(0.18, 0.16, 0.24, base_alpha * 0.85)

	hud_control.draw_circle(_joystick_base_pos + Vector2(2.0, 3.0), joystick_outer_radius + 2.0, c_shadow)
	hud_control.draw_circle(_joystick_base_pos, joystick_outer_radius + 2.0, c_outline)
	hud_control.draw_circle(_joystick_base_pos, joystick_outer_radius, ring_col)
	hud_control.draw_circle(_joystick_base_pos, joystick_outer_radius * 0.72, inner_col)

	# Marcas cardinales sutiles en el anillo del joystick
	for dir_vec: Vector2 in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]:
		var mark_pos := _joystick_base_pos + dir_vec * (joystick_outer_radius * 0.84)
		hud_control.draw_circle(mark_pos, 3.0, Color(c_gold.r, c_gold.g, c_gold.b, 0.45))

	var knob_pos := _joystick_base_pos + _joystick_knob_offset
	var norm_len := _joystick_knob_offset.length() / maxf(joystick_outer_radius, 1.0)
	var knob_col := c_orange if norm_len >= auto_run_threshold else Color("#7A7094")
	if joy_active:
		knob_col = knob_col.lightened(0.12)
	hud_control.draw_circle(knob_pos + Vector2(1.5, 2.5), joystick_knob_radius + 2.0, c_shadow)
	hud_control.draw_circle(knob_pos, joystick_knob_radius + 2.0, c_outline)
	hud_control.draw_circle(knob_pos, joystick_knob_radius, knob_col)
	hud_control.draw_circle(knob_pos - Vector2(5.0, 5.0), joystick_knob_radius * 0.35, Color(1, 1, 1, 0.28))

	# --- 2. BOTON DE INTERACCION "E" / CORAZON (Derecha) ---
	var interact_active := _interact_touch_id != -1 or _interact_flash_timer > 0.0
	var pulse := 0.5 + 0.5 * sin(_pulse_time * 5.0)
	if is_interact_highlighted or interact_active:
		var aura_r := _interact_btn_radius + 6.0 + pulse * 4.0
		var aura_col := Color(c_gold.r, c_gold.g, c_gold.b, 0.22 + 0.18 * pulse)
		hud_control.draw_circle(_interact_btn_center, aura_r, aura_col)

	var btn_fill := c_orange if interact_active else (c_panel.lightened(0.10) if is_interact_highlighted else c_panel_alpha)
	var rim_col := c_gold if is_interact_highlighted else c_outline
	hud_control.draw_circle(_interact_btn_center + Vector2(2.0, 3.0), _interact_btn_radius + 2.0, c_shadow)
	hud_control.draw_circle(_interact_btn_center, _interact_btn_radius + 2.5, rim_col)
	hud_control.draw_circle(_interact_btn_center, _interact_btn_radius, btn_fill)
	hud_control.draw_circle(_interact_btn_center, _interact_btn_radius - 7.0, c_slot)

	if HEART_ICON_TEXTURE != null:
		var icon_size := Vector2(36.0, 36.0)
		var icon_rect := Rect2(_interact_btn_center - icon_size * 0.5 - Vector2(0.0, 4.0), icon_size)
		hud_control.draw_texture_rect(HEART_ICON_TEXTURE, icon_rect, false)

	# Etiqueta "E" debajo del icono dentro del boton
	_draw_centered_label(_interact_btn_center + Vector2(0.0, 22.0), "E", c_gold if is_interact_highlighted else Color.WHITE)

	# --- 3. BOTON DE CORRER "RUN" (Abajo a la derecha) ---
	var norm_joy := _joystick_knob_offset.length() / maxf(joystick_outer_radius, 1.0)
	var run_active := is_running_pressed or (norm_joy >= auto_run_threshold)
	var run_fill := c_orange if run_active else c_panel_alpha
	var run_rim := c_cyan if run_active else c_outline

	hud_control.draw_circle(_run_btn_center + Vector2(2.0, 3.0), _run_btn_radius + 2.0, c_shadow)
	hud_control.draw_circle(_run_btn_center, _run_btn_radius + 2.0, run_rim)
	hud_control.draw_circle(_run_btn_center, _run_btn_radius, run_fill)
	hud_control.draw_circle(_run_btn_center, _run_btn_radius - 6.0, c_slot)
	_draw_centered_label(_run_btn_center + Vector2(0.0, 4.0), "RUN", c_cyan if run_active else Color.WHITE)

	# --- 4. BOTONES DE ZOOM "+" y "-" (Arriba a la derecha) ---
	_draw_square_button(_zoom_in_rect, "+", c_panel_alpha, c_outline, c_gold)
	_draw_square_button(_zoom_out_rect, "-", c_panel_alpha, c_outline, c_gold)


func _draw_square_button(rect: Rect2, label: String, fill: Color, border: Color, text_col: Color) -> void:
	hud_control.draw_rect(Rect2(rect.position + Vector2(2.0, 2.0), rect.size), Color(0, 0, 0, 0.32), true)
	hud_control.draw_rect(rect, fill, true)
	hud_control.draw_rect(rect, border, false, 2.0)
	_draw_centered_label(rect.get_center() + Vector2(0.0, 5.0), label, text_col, 20)


func _draw_centered_label(center: Vector2, text: String, col: Color, font_size: int = 15) -> void:
	var font := ThemeDB.fallback_font
	if font == null:
		return
	var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
	var draw_pos := Vector2(center.x - text_size.x * 0.5, center.y)
	hud_control.draw_string_outline(font, draw_pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 3, Color("#231F2E"))
	hud_control.draw_string(font, draw_pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, col)

