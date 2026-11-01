extends Node2D
# Ventana de dialogo flotante inspirada en el arte de la Vision de Lennox:
# marco morado pizarra (#564E68) con borde oscuro redondeado, estrella decorativa
# en la esquina superior izquierda, casilla de icono (con signo de interrogacion
# pixel-art o cualquier Texture2D) y barra naranja inferior estilo boton.

const APPLE_ICON_TEXTURE: Texture2D = preload("res://assets/common/icons/Alchemy4_2.png")

const QUESTION_MARK_ASCII := [
	"................",
	".....######.....",
	"...##########...",
	"..###......###..",
	"..###......###..",
	"..........####..",
	"........#####...",
	".......####.....",
	"......####......",
	"......####......",
	"................",
	"......####......",
	".....######.....",
	"......####......",
	"................",
	"................",
]

var icon_texture: Texture2D = null:
	set(value):
		icon_texture = value
		queue_redraw()

var _pulse_time: float = 0.0
var _default_question_texture: Texture2D = null


func _ready() -> void:
	z_index = 40
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_default_question_texture = _build_question_mark_texture()
	if icon_texture == null:
		icon_texture = APPLE_ICON_TEXTURE


func show_apple() -> void:
	show_icon(APPLE_ICON_TEXTURE)


func show_question_mark() -> void:
	if _default_question_texture == null:
		_default_question_texture = _build_question_mark_texture()
	show_icon(_default_question_texture)


func show_icon(p_texture: Texture2D) -> void:
	icon_texture = p_texture if p_texture != null else APPLE_ICON_TEXTURE
	visible = true
	_pulse_time = 0.0
	scale = Vector2(0.75, 0.75)
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2.ONE, 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	queue_redraw()


func hide_bubble() -> void:
	visible = false


func _process(delta: float) -> void:
	if not visible:
		return
	_pulse_time += delta
	queue_redraw()


func _draw() -> void:
	var float_y := sin(_pulse_time * 3.8) * 1.4
	var box_w := 44.0
	var box_h := 46.0
	var box_rect := Rect2(Vector2(-box_w * 0.5, -box_h - 6.0 + float_y), Vector2(box_w, box_h))

	# Colores tomados del widget en doc/images/lennox_project_vision.jpg
	var c_shadow := Color(0.08, 0.07, 0.12, 0.42)
	var c_outline := Color("#231F2E")
	var c_panel := Color("#58506B")
	var c_panel_hi := Color("#6E6585")
	var c_slot := Color("#3B354A")
	var c_slot_border := Color("#2A2536")
	var c_bar_fill := Color("#F29B38")
	var c_bar_hi := Color("#FFBE66")
	var c_star := Color("#FFD24C")

	# Sombra proyectada
	_draw_pixel_rounded_rect(Rect2(box_rect.position + Vector2(1.5, 2.0), box_rect.size), c_shadow, Color.TRANSPARENT)

	# Panel principal morado pizarra con borde oscuro
	_draw_pixel_rounded_rect(box_rect, c_panel, c_outline)

	# Brillo superior interno del panel
	draw_line(
		box_rect.position + Vector2(3.0, 2.0),
		box_rect.position + Vector2(box_rect.size.x - 3.0, 2.0),
		c_panel_hi,
		1.0
	)

	# Cola / piquito inferior apuntando hacia el NPC
	var tip_y := box_rect.end.y
	var tail_pts := PackedVector2Array([
		Vector2(-5.0, tip_y - 1.0),
		Vector2(5.0, tip_y - 1.0),
		Vector2(0.0, tip_y + 5.0),
	])
	draw_colored_polygon(tail_pts, c_panel)
	draw_line(Vector2(-5.0, tip_y), Vector2(0.0, tip_y + 5.0), c_outline, 1.5)
	draw_line(Vector2(5.0, tip_y), Vector2(0.0, tip_y + 5.0), c_outline, 1.5)

	# Estrellita dorada en la esquina superior izquierda (como en el arte de la vision)
	var star_c := box_rect.position + Vector2(5.5, 5.5)
	draw_rect(Rect2(star_c - Vector2(1.5, 0.5), Vector2(3.0, 1.0)), c_star, true)
	draw_rect(Rect2(star_c - Vector2(0.5, 1.5), Vector2(1.0, 3.0)), c_star, true)

	# Casilla oscura central para el icono (estilo slot de la Vision de Lennox)
	var slot_size := Vector2(28.0, 26.0)
	var slot_pos := box_rect.position + Vector2((box_w - slot_size.x) * 0.5, 5.5)
	var slot_rect := Rect2(slot_pos, slot_size)
	_draw_pixel_rounded_rect(slot_rect, c_slot, c_slot_border)

	# Icono dentro de la casilla (por defecto la manzana de los assets comunes)
	# Si la textura tiene margen transparente (como los iconos 32x32 de CraftPix),
	# recortamos su region util para que el icono llene bien la casilla.
	var tex := icon_texture if icon_texture != null else APPLE_ICON_TEXTURE
	if tex != null:
		var src_rect := _get_visible_icon_region(tex)
		var target_max := slot_size - Vector2(4.0, 4.0)
		var scale_factor := minf(target_max.x / maxf(src_rect.size.x, 1.0), target_max.y / maxf(src_rect.size.y, 1.0))
		var draw_size := src_rect.size * scale_factor
		var draw_pos := slot_rect.position + (slot_rect.size - draw_size) * 0.5
		draw_texture_rect_region(tex, Rect2(draw_pos, draw_size), src_rect)

	# Barra naranja inferior (como el boton/barra inferior del GUI en la Vision de Lennox)
	var bar_size := Vector2(30.0, 7.0)
	var bar_pos := box_rect.position + Vector2((box_w - bar_size.x) * 0.5, box_h - 12.0)
	var bar_rect := Rect2(bar_pos, bar_size)
	_draw_pixel_rounded_rect(bar_rect, c_bar_fill, c_outline)
	draw_line(
		bar_rect.position + Vector2(2.0, 1.5),
		bar_rect.position + Vector2(bar_rect.size.x - 2.0, 1.5),
		c_bar_hi,
		1.0
	)


func _draw_pixel_rounded_rect(rect: Rect2, fill_color: Color, border_color: Color) -> void:
	# Relleno con esquinas biseladas de 1px para aspecto pixel-art limpio
	draw_rect(Rect2(rect.position + Vector2(1, 0), rect.size - Vector2(2, 0)), fill_color, true)
	draw_rect(Rect2(rect.position + Vector2(0, 1), rect.size - Vector2(0, 2)), fill_color, true)
	if border_color.a > 0.0:
		var x0 := rect.position.x
		var y0 := rect.position.y
		var x1 := rect.end.x
		var y1 := rect.end.y
		draw_line(Vector2(x0 + 1, y0), Vector2(x1 - 1, y0), border_color, 1.0)
		draw_line(Vector2(x0 + 1, y1), Vector2(x1 - 1, y1), border_color, 1.0)
		draw_line(Vector2(x0, y0 + 1), Vector2(x0, y1 - 1), border_color, 1.0)
		draw_line(Vector2(x1, y0 + 1), Vector2(x1, y1 - 1), border_color, 1.0)


static func _get_visible_icon_region(tex: Texture2D) -> Rect2:
	var img := tex.get_image()
	if img != null:
		var used := img.get_used_rect()
		if used.size.x > 0 and used.size.y > 0:
			return Rect2(used.position, used.size)
	return Rect2(Vector2.ZERO, tex.get_size())


static func _build_question_mark_texture() -> ImageTexture:
	var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	var c_outline := Color("#231F2E")
	var c_main := Color("#FFD84D")
	var c_hi := Color("#FFF3A1")
	var c_shade := Color("#E09F24")

	for y in range(16):
		var row_str: String = QUESTION_MARK_ASCII[y]
		var prev_row: String = QUESTION_MARK_ASCII[y - 1] if y > 0 else ""
		var next_row: String = QUESTION_MARK_ASCII[y + 1] if y < 15 else ""
		for x in range(16):
			if row_str[x] == "#":
				var above_empty: bool = y == 0 or prev_row[x] != "#"
				var below_empty: bool = y == 15 or next_row[x] != "#"
				if above_empty:
					img.set_pixel(x, y, c_hi)
				elif below_empty:
					img.set_pixel(x, y, c_shade)
				else:
					img.set_pixel(x, y, c_main)

	# Contorno oscuro de 1px alrededor del '?'
	var mask := img.duplicate() as Image
	for y in range(16):
		for x in range(16):
			if mask.get_pixel(x, y).a > 0.0:
				continue
			var touches := false
			for offset: Vector2i in [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]:
				var nx := x + offset.x
				var ny := y + offset.y
				if nx >= 0 and nx < 16 and ny >= 0 and ny < 16 and mask.get_pixel(nx, ny).a > 0.0:
					touches = true
					break
			if touches:
				img.set_pixel(x, y, c_outline)

	return ImageTexture.create_from_image(img)
