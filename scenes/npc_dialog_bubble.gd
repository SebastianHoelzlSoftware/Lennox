extends Node2D
# Ventana de dialogo flotante inspirada en el arte de la Vision de Lennox:
# marco morado pizarra (#58506B) con borde oscuro redondeado, estrella decorativa
# en la esquina superior izquierda, casilla central para el icono, fila de letras
# en cuadritos de colores estilo bloques educativos ("LOVE", "APPLE", etc.) y
# barra naranja inferior estilo boton.

const HEART_ICON_TEXTURE: Texture2D = preload("res://assets/common/icons/Item9_2.png")
const APPLE_ICON_TEXTURE: Texture2D = preload("res://assets/common/icons/Alchemy4_2.png")

# Colores ciclicos para los cuadritos de letras (inspirados en la puerta magica y el cielo de title_art_03.jpg)
const TILE_BG_COLORS := [
	Color("#2C263D"),
	Color("#233238"),
	Color("#2D253E"),
	Color("#1F333B"),
]
const LETTER_CORE_COLORS := [
	Color("#FFE875"), # Dorado solar brillante ('A')
	Color("#A8FF60"), # Verde esmeralda luminoso ('M')
	Color("#FFAE52"), # Ambar / fuego magico ('O')
	Color("#68F2FF"), # Cian magico ('R')
]
const LETTER_HALO_COLORS := [
	Color("#FF9424"),
	Color("#32D848"),
	Color("#FF5828"),
	Color("#1CB8FF"),
]

# Fuente pixel-art 5x7 para letras A-Z, 0-9 y signos basicos
const PIXEL_FONT_5X7 := {
	"A": ["01110", "10001", "10001", "11111", "10001", "10001", "10001"],
	"B": ["11110", "10001", "10001", "11110", "10001", "10001", "11110"],
	"C": ["01110", "10001", "10000", "10000", "10000", "10001", "01110"],
	"D": ["11110", "10001", "10001", "10001", "10001", "10001", "11110"],
	"E": ["11111", "10000", "10000", "11110", "10000", "10000", "11111"],
	"F": ["11111", "10000", "10000", "11110", "10000", "10000", "10000"],
	"G": ["01110", "10001", "10000", "10111", "10001", "10001", "01110"],
	"H": ["10001", "10001", "10001", "11111", "10001", "10001", "10001"],
	"I": ["01110", "00100", "00100", "00100", "00100", "00100", "01110"],
	"J": ["00111", "00010", "00010", "00010", "10010", "10010", "01100"],
	"K": ["10001", "10010", "10100", "11000", "10100", "10010", "10001"],
	"L": ["10000", "10000", "10000", "10000", "10000", "10000", "11111"],
	"M": ["10001", "11011", "10101", "10101", "10001", "10001", "10001"],
	"N": ["10001", "11001", "10101", "10011", "10001", "10001", "10001"],
	"O": ["01110", "10001", "10001", "10001", "10001", "10001", "01110"],
	"P": ["11110", "10001", "10001", "11110", "10000", "10000", "10000"],
	"Q": ["01110", "10001", "10001", "10001", "10101", "10010", "01101"],
	"R": ["11110", "10001", "10001", "11110", "10100", "10010", "10001"],
	"S": ["01111", "10000", "10000", "01110", "00001", "00001", "11110"],
	"T": ["11111", "00100", "00100", "00100", "00100", "00100", "00100"],
	"U": ["10001", "10001", "10001", "10001", "10001", "10001", "01110"],
	"V": ["10001", "10001", "10001", "10001", "10001", "01010", "00100"],
	"W": ["10001", "10001", "10001", "10101", "10101", "11011", "10001"],
	"X": ["10001", "10001", "01010", "00100", "01010", "10001", "10001"],
	"Y": ["10001", "10001", "01010", "00100", "00100", "00100", "00100"],
	"Z": ["11111", "00001", "00010", "00100", "01000", "10000", "11111"],
	"0": ["01110", "10001", "10011", "10101", "11001", "10001", "01110"],
	"1": ["00100", "01100", "00100", "00100", "00100", "00100", "01110"],
	"2": ["01110", "10001", "00001", "00110", "01000", "10000", "11111"],
	"3": ["11110", "00001", "00001", "01110", "00001", "00001", "11110"],
	"4": ["10010", "10010", "10010", "11111", "00010", "00010", "00010"],
	"5": ["11111", "10000", "10000", "11110", "00001", "00001", "11110"],
	"6": ["01110", "10000", "10000", "11110", "10001", "10001", "01110"],
	"7": ["11111", "00001", "00010", "00100", "01000", "01000", "01000"],
	"8": ["01110", "10001", "10001", "01110", "10001", "10001", "01110"],
	"9": ["01110", "10001", "10001", "01111", "00001", "00001", "01110"],
	"?": ["01110", "10001", "00010", "00100", "00100", "00000", "00100"],
	"!": ["00100", "00100", "00100", "00100", "00100", "00000", "00100"],
}

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

var word_text: String = "LOVE":
	set(value):
		word_text = value.strip_edges().to_upper()
		queue_redraw()

var _pulse_time: float = 0.0
var _default_question_texture: Texture2D = null


func _ready() -> void:
	z_index = 40
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_default_question_texture = _build_question_mark_texture()
	if icon_texture == null:
		icon_texture = HEART_ICON_TEXTURE


func show_symbol_and_word(p_texture: Texture2D, p_word: String = "LOVE") -> void:
	icon_texture = p_texture if p_texture != null else HEART_ICON_TEXTURE
	word_text = p_word
	_animate_open()


func show_heart(p_word: String = "LOVE") -> void:
	show_symbol_and_word(HEART_ICON_TEXTURE, p_word)


func show_apple(p_word: String = "APPLE") -> void:
	show_symbol_and_word(APPLE_ICON_TEXTURE, p_word)


func show_question_mark(p_word: String = "?") -> void:
	if _default_question_texture == null:
		_default_question_texture = _build_question_mark_texture()
	show_symbol_and_word(_default_question_texture, p_word)


func show_icon(p_texture: Texture2D, p_word: String = "") -> void:
	icon_texture = p_texture if p_texture != null else HEART_ICON_TEXTURE
	if not p_word.is_empty():
		word_text = p_word
	_animate_open()


func _animate_open() -> void:
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
	var clean_word := word_text.strip_edges().to_upper()
	var char_count := clean_word.length()

	var tile_w := 11.0
	var tile_h := 11.0
	var tile_gap := 2.0
	var tiles_row_w := 0.0
	if char_count > 0:
		tiles_row_w = char_count * tile_w + (char_count - 1) * tile_gap

	var box_w := maxf(46.0, tiles_row_w + 12.0)
	var box_h := 60.0 if char_count > 0 else 46.0
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
	var slot_size := Vector2(28.0, 25.0)
	var slot_pos := box_rect.position + Vector2((box_w - slot_size.x) * 0.5, 5.0)
	var slot_rect := Rect2(slot_pos, slot_size)
	_draw_pixel_rounded_rect(slot_rect, c_slot, c_slot_border)

	# Icono dentro de la casilla (por defecto el corazon de los assets comunes)
	var tex := icon_texture if icon_texture != null else HEART_ICON_TEXTURE
	if tex != null:
		var src_rect := _get_visible_icon_region(tex)
		var target_max := slot_size - Vector2(4.0, 4.0)
		var scale_factor := minf(target_max.x / maxf(src_rect.size.x, 1.0), target_max.y / maxf(src_rect.size.y, 1.0))
		var draw_size := src_rect.size * scale_factor
		var draw_pos := slot_rect.position + (slot_rect.size - draw_size) * 0.5
		draw_texture_rect_region(tex, Rect2(draw_pos, draw_size), src_rect)

	# Fila de cuadritos con letras magicas luminosas (como en el arco de piedra y el cielo de title_art_03.jpg)
	if char_count > 0:
		var tiles_start_x := box_rect.position.x + (box_w - tiles_row_w) * 0.5
		var tiles_y := slot_rect.end.y + 3.5
		for i in range(char_count):
			var ch := clean_word.substr(i, 1)
			if ch == " ":
				continue
			# Onda suave desfasada por letra para que parezcan flotar con energia magica
			var wave := sin(_pulse_time * 4.5 - float(i) * 0.85)
			var glow_pulse := 0.5 + 0.5 * wave
			var letter_bob := roundf(wave * 0.65)
			var tile_pos := Vector2(tiles_start_x + i * (tile_w + tile_gap), tiles_y + letter_bob)
			var tile_rect := Rect2(tile_pos, Vector2(tile_w, tile_h))

			var bg_col: Color = TILE_BG_COLORS[i % TILE_BG_COLORS.size()]
			var core_col: Color = LETTER_CORE_COLORS[i % LETTER_CORE_COLORS.size()]
			var halo_col: Color = LETTER_HALO_COLORS[i % LETTER_HALO_COLORS.size()]

			# 1. Aura exterior difusa alrededor del bloque de piedra/magia
			var outer_aura := Color(halo_col.r, halo_col.g, halo_col.b, 0.16 + 0.18 * glow_pulse)
			_draw_pixel_rounded_rect(
				Rect2(tile_rect.position - Vector2(1.0, 1.0), tile_rect.size + Vector2(2.0, 2.0)),
				outer_aura,
				Color.TRANSPARENT
			)

			# 2. Bloque oscuro con borde iluminado por el color magico de la letra
			var rim_col := c_outline.lerp(halo_col, 0.35 + 0.35 * glow_pulse)
			_draw_pixel_rounded_rect(tile_rect, bg_col, rim_col)

			# 3. Resplandor interior suave dentro del bloque
			var inner_glow := Color(halo_col.r, halo_col.g, halo_col.b, 0.18 + 0.16 * glow_pulse)
			draw_rect(Rect2(tile_rect.position + Vector2(2.0, 2.0), tile_rect.size - Vector2(4.0, 4.0)), inner_glow, true)

			# 4. Letra con halo magico + nucleo incandescente
			var bright_core := core_col.lerp(Color.WHITE, 0.25 + 0.35 * glow_pulse)
			var halo_alpha_col := Color(halo_col.r, halo_col.g, halo_col.b, 0.48 + 0.32 * glow_pulse)
			_draw_glowing_pixel_glyph(ch, tile_pos + Vector2(3.0, 2.0), bright_core, halo_alpha_col)

		# 5. Estrellitas / chispas magicas (sparkles) parpadeando alrededor de las letras
		_draw_magic_sparkles(
			Rect2(Vector2(tiles_start_x - 3.0, tiles_y - 2.0), Vector2(tiles_row_w + 6.0, tile_h + 4.0)),
			char_count
		)

	# Barra naranja inferior (como el boton/barra inferior del GUI en la Vision de Lennox)
	var bar_w := clampf(box_w - 14.0, 30.0, box_w - 10.0)
	var bar_size := Vector2(bar_w, 6.0)
	var bar_pos := box_rect.position + Vector2((box_w - bar_size.x) * 0.5, box_h - 9.5)
	var bar_rect := Rect2(bar_pos, bar_size)
	_draw_pixel_rounded_rect(bar_rect, c_bar_fill, c_outline)
	draw_line(
		bar_rect.position + Vector2(2.0, 1.5),
		bar_rect.position + Vector2(bar_rect.size.x - 2.0, 1.5),
		c_bar_hi,
		1.0
	)


func _draw_glowing_pixel_glyph(ch: String, top_left: Vector2, core_color: Color, halo_color: Color) -> void:
	var rows: Array = PIXEL_FONT_5X7.get(ch, PIXEL_FONT_5X7["?"])
	# Primero dibujamos el halo luminoso 1px alrededor de cada pixel activo de la letra
	var offsets := [Vector2(-1.0, 0.0), Vector2(1.0, 0.0), Vector2(0.0, -1.0), Vector2(0.0, 1.0)]
	for ry in range(rows.size()):
		var row_str: String = rows[ry]
		for rx in range(row_str.length()):
			if row_str[rx] == "1":
				var p := top_left + Vector2(rx, ry)
				for off: Vector2 in offsets:
					draw_rect(Rect2(p + off, Vector2(1.0, 1.0)), halo_color, true)

	# Encima dibujamos el nucleo brillante de la letra
	for ry in range(rows.size()):
		var row_str: String = rows[ry]
		for rx in range(row_str.length()):
			if row_str[rx] == "1":
				var p := top_left + Vector2(rx, ry)
				draw_rect(Rect2(p, Vector2(1.0, 1.0)), core_color, true)


func _draw_magic_sparkles(region: Rect2, count: int) -> void:
	var sparkle_count := maxi(3, count)
	for s in range(sparkle_count):
		var phase := _pulse_time * 3.2 + float(s) * 1.75
		var twinkle := sin(phase)
		if twinkle < 0.15:
			continue
		var norm := (twinkle - 0.15) / 0.85
		var t_x := fmod(float(s) * 0.37 + 0.12, 1.0)
		var t_y := 0.15 if (s % 2 == 0) else 0.88
		var pos := Vector2(
			region.position.x + region.size.x * t_x,
			region.position.y + region.size.y * t_y + cos(phase * 0.7) * 1.2
		)
		var col: Color = LETTER_CORE_COLORS[s % LETTER_CORE_COLORS.size()].lerp(Color.WHITE, 0.6)
		col.a = clampf(norm * 0.95, 0.0, 1.0)
		draw_rect(Rect2(pos, Vector2(1.0, 1.0)), col, true)
		if norm > 0.65:
			var ray_col := Color(col.r, col.g, col.b, col.a * 0.45)
			draw_rect(Rect2(pos + Vector2(-1.0, 0.0), Vector2(3.0, 1.0)), ray_col, true)
			draw_rect(Rect2(pos + Vector2(0.0, -1.0), Vector2(1.0, 3.0)), ray_col, true)


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
