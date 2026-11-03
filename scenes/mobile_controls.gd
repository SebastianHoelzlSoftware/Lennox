extends CanvasLayer
# Controles tactiles para dispositivos moviles (Android / Pixel 6) y pantalla tactil.
#
# Incluye:
# 1. Joystick virtual semitransparente a la izquierda (caminar suave o correr al empujar al borde exterior).
# 2. Boton de interaccion "E" con icono de corazon a la derecha (se ilumina cuando la arquera esta cerca).
# 3. Botones de zoom arriba a la derecha representados con una lupa pequena (-) y una lupa grande (+)
#    semitransparentes, ademas del gesto de pellizco (pinch-to-zoom) con dos dedos.
# 4. Toque directo sobre un companero NPC en el mundo para abrir/cerrar su burbuja de dialogo.

const HEART_ICON_TEXTURE: Texture2D = preload("res://assets/common/icons/Item9_2.png")

@export var player_path: NodePath
@export var joystick_outer_radius: float = 78.0
@export var joystick_knob_radius: float = 30.0
@export var joystick_deadzone: float = 0.14
@export var auto_run_threshold: float = 0.85

var player: CharacterBody2D = null
var hud_control: Control = null

var move_vector: Vector2 = Vector2.ZERO
var is_interact_highlighted: bool = false

var _joystick_touch_id: int = -1
var _joystick_base_pos: Vector2 = Vector2(148.0, 730.0)
var _joystick_default_pos: Vector2 = Vector2(148.0, 730.0)
var _joystick_knob_offset: Vector2 = Vector2.ZERO

var _interact_touch_id: int = -1
var _interact_flash_timer: float = 0.0
var _pulse_time: float = 0.0

var _interact_btn_center: Vector2 = Vector2(990.0, 735.0)
var _interact_btn_radius: float = 54.0

var _zoom_out_rect: Rect2 = Rect2(Vector2(1015.0, 24.0), Vector2(46.0, 46.0))
var _zoom_in_rect: Rect2 = Rect2(Vector2(1072.0, 24.0), Vector2(46.0, 46.0))

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

	# Lupa pequena (alejar / -) a la izquierda y lupa mas grande (acercar / +) a la derecha
	_zoom_out_rect = Rect2(Vector2(w - 124.0, 22.0), Vector2(44.0, 44.0))
	_zoom_in_rect = Rect2(Vector2(w - 70.0, 20.0), Vector2(48.0, 48.0))


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

		# 1. Botones de lupa (zoom) arriba a la derecha
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

		# 3. Joystick virtual en la mitad izquierda inferior de la pantalla
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

		# 4. Si hay dos dedos libres en pantalla, iniciar gesto de pellizco (pinch-to-zoom)
		var free_touches := _get_non_control_touch_positions()
		if free_touches.size() == 2:
			_pinch_prev_dist = free_touches[0].distance_to(free_touches[1])
			return

		# 5. Toque directo sobre un companero NPC en el mundo para hablar con el
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
		if id == _joystick_touch_id or id == _interact_touch_id:
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
	var should_run := norm_len >= auto_run_threshold

	if player != null and is_instance_valid(player) and "touch_move_vector" in player:
		player.set("touch_move_vector", move_vector)
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
	var c_shadow := Color(0.06, 0.05, 0.10, 0.22)
	var c_outline := Color(0.14, 0.12, 0.18, 0.45)
	var c_panel := Color("#58506B")
	var c_panel_alpha := Color(c_panel.r, c_panel.g, c_panel.b, 0.56)
	var c_slot := Color(0.23, 0.21, 0.29, 0.62)
	var c_orange := Color("#F29B38")
	var c_gold := Color("#FFE875")

	# --- 1. JOYSTICK VIRTUAL SEMITRANSPARENTE (Izquierda) ---
	var joy_active := _joystick_touch_id != -1
	var base_alpha := 0.48 if joy_active else 0.28
	var ring_col := Color(c_panel.r, c_panel.g, c_panel.b, base_alpha)
	var inner_col := Color(0.18, 0.16, 0.24, base_alpha * 0.78)
	var joy_outline := Color(0.14, 0.12, 0.18, base_alpha * 1.1)

	hud_control.draw_circle(_joystick_base_pos + Vector2(2.0, 3.0), joystick_outer_radius + 2.0, Color(0, 0, 0, base_alpha * 0.45))
	hud_control.draw_circle(_joystick_base_pos, joystick_outer_radius + 1.5, joy_outline)
	hud_control.draw_circle(_joystick_base_pos, joystick_outer_radius, ring_col)
	hud_control.draw_circle(_joystick_base_pos, joystick_outer_radius * 0.72, inner_col)

	# Marcas cardinales sutiles en el anillo del joystick
	for dir_vec: Vector2 in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]:
		var mark_pos := _joystick_base_pos + dir_vec * (joystick_outer_radius * 0.84)
		hud_control.draw_circle(mark_pos, 2.5, Color(c_gold.r, c_gold.g, c_gold.b, base_alpha * 0.75))

	var knob_pos := _joystick_base_pos + _joystick_knob_offset
	var norm_len := _joystick_knob_offset.length() / maxf(joystick_outer_radius, 1.0)
	var knob_base_col := c_orange if norm_len >= auto_run_threshold else Color("#7A7094")
	var knob_alpha := 0.65 if joy_active else 0.38
	var knob_col := Color(knob_base_col.r, knob_base_col.g, knob_base_col.b, knob_alpha)
	hud_control.draw_circle(knob_pos + Vector2(1.5, 2.0), joystick_knob_radius + 1.5, Color(0, 0, 0, knob_alpha * 0.4))
	hud_control.draw_circle(knob_pos, joystick_knob_radius + 1.5, joy_outline)
	hud_control.draw_circle(knob_pos, joystick_knob_radius, knob_col)
	hud_control.draw_circle(knob_pos - Vector2(5.0, 5.0), joystick_knob_radius * 0.35, Color(1, 1, 1, knob_alpha * 0.35))

	# --- 2. BOTON DE INTERACCION "E" / CORAZON (Derecha) ---
	var interact_active := _interact_touch_id != -1 or _interact_flash_timer > 0.0
	var pulse := 0.5 + 0.5 * sin(_pulse_time * 5.0)
	if is_interact_highlighted or interact_active:
		var aura_r := _interact_btn_radius + 6.0 + pulse * 4.0
		var aura_col := Color(c_gold.r, c_gold.g, c_gold.b, 0.20 + 0.16 * pulse)
		hud_control.draw_circle(_interact_btn_center, aura_r, aura_col)

	var btn_fill := (
		Color(c_orange.r, c_orange.g, c_orange.b, 0.78)
		if interact_active
		else (Color(c_panel.r, c_panel.g, c_panel.b, 0.68).lightened(0.10) if is_interact_highlighted else c_panel_alpha)
	)
	var rim_col := Color(c_gold.r, c_gold.g, c_gold.b, 0.85) if is_interact_highlighted else c_outline
	hud_control.draw_circle(_interact_btn_center + Vector2(2.0, 3.0), _interact_btn_radius + 2.0, c_shadow)
	hud_control.draw_circle(_interact_btn_center, _interact_btn_radius + 2.0, rim_col)
	hud_control.draw_circle(_interact_btn_center, _interact_btn_radius, btn_fill)
	hud_control.draw_circle(_interact_btn_center, _interact_btn_radius - 7.0, c_slot)

	if HEART_ICON_TEXTURE != null:
		var icon_size := Vector2(36.0, 36.0)
		var icon_rect := Rect2(_interact_btn_center - icon_size * 0.5 - Vector2(0.0, 4.0), icon_size)
		hud_control.draw_texture_rect(HEART_ICON_TEXTURE, icon_rect, false, Color(1, 1, 1, 0.90))

	_draw_centered_label(
		_interact_btn_center + Vector2(0.0, 22.0),
		"E",
		Color(c_gold.r, c_gold.g, c_gold.b, 0.92) if is_interact_highlighted else Color(1, 1, 1, 0.82)
	)

	# --- 3. BOTONES DE ZOOM CON LUPA PEQUENA (-) Y LUPA MAS GRANDE (+) SEMITRANSPARENTES ---
	_draw_magnifier_button(_zoom_out_rect, 8.5, false)
	_draw_magnifier_button(_zoom_in_rect, 12.5, true)


func _draw_magnifier_button(rect: Rect2, lens_radius: float, is_zoom_in: bool) -> void:
	var center := rect.get_center()
	var btn_r := rect.size.x * 0.5
	var bg_col := Color(0.35, 0.31, 0.42, 0.34)
	var rim_col := Color(0.14, 0.12, 0.18, 0.42)
	var glass_fill := Color(0.65, 0.88, 1.0, 0.18)
	var lens_rim := Color(1.0, 0.93, 0.62, 0.62)
	var handle_col := Color(0.95, 0.62, 0.25, 0.68)
	var symbol_col := Color(1.0, 1.0, 1.0, 0.68)

	# Fondo circular muy sutil y semitransparente
	hud_control.draw_circle(center + Vector2(1.0, 2.0), btn_r, Color(0, 0, 0, 0.16))
	hud_control.draw_circle(center, btn_r, bg_col)
	hud_control.draw_arc(center, btn_r, 0.0, TAU, 28, rim_col, 1.5)

	# Lente de la lupa ligeramente desplazada hacia arriba-izquierda para dejar espacio al mango
	var lens_center := center + Vector2(-2.5, -2.5)
	var handle_dir := Vector2(1.0, 1.0).normalized()
	var handle_start := lens_center + handle_dir * (lens_radius + 0.5)
	var handle_end := lens_center + handle_dir * (lens_radius + (8.5 if is_zoom_in else 6.5))

	# Mango de la lupa
	hud_control.draw_line(handle_start, handle_end, Color(0.14, 0.12, 0.18, 0.55), 5.0)
	hud_control.draw_line(handle_start, handle_end, handle_col, 3.0)

	# Cristal y aro de la lupa
	hud_control.draw_circle(lens_center, lens_radius, glass_fill)
	hud_control.draw_arc(lens_center, lens_radius + 1.0, 0.0, TAU, 24, Color(0.14, 0.12, 0.18, 0.50), 2.5)
	hud_control.draw_arc(lens_center, lens_radius, 0.0, TAU, 24, lens_rim, 2.0)

	# Reflejo cristalino y simbolo sutil dentro de la lente (+ / -)
	hud_control.draw_circle(lens_center + Vector2(-lens_radius * 0.35, -lens_radius * 0.35), maxf(1.5, lens_radius * 0.18), Color(1, 1, 1, 0.42))
	var arm := clampf(lens_radius * 0.42, 3.0, 5.5)
	hud_control.draw_line(lens_center + Vector2(-arm, 0.0), lens_center + Vector2(arm, 0.0), symbol_col, 1.6)
	if is_zoom_in:
		hud_control.draw_line(lens_center + Vector2(0.0, -arm), lens_center + Vector2(0.0, arm), symbol_col, 1.6)


func _draw_centered_label(center: Vector2, text: String, col: Color, font_size: int = 15) -> void:
	var font := ThemeDB.fallback_font
	if font == null:
		return
	var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
	var draw_pos := Vector2(center.x - text_size.x * 0.5, center.y)
	hud_control.draw_string_outline(font, draw_pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 3, Color(0.14, 0.12, 0.18, col.a * 0.85))
	hud_control.draw_string(font, draw_pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, col)
