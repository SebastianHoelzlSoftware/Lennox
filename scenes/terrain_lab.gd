# terrain_lab.gd
# Laboratorio visual del motor de terreno: dibuja una forma de prueba (con esquinas
# concavas en todos los lados, escalones, muescas y piezas finas) para cada bioma.
# Uso: abrir scenes/terrain_lab.tscn y pulsar F6. Flechas izquierda/derecha cambian de bioma.
# Con el argumento --lab-shot=<carpeta> guarda una captura por bioma y sale.
extends Node2D

const TerrainPainter = preload("res://src/core/terrain_painter.gd")
const TerrainStyles = preload("res://src/core/terrain_styles.gd")

const PANEL_W := 36
const PANEL_H := 30
const SHAPE := [
	"..................",
	"..................",
	"...######....##...",
	"...########..##...",
	"...########.......",
	"...#####.##...###.",
	".....###.##...###.",
	".....###......###.",
	"..................",
	"..................",
	"..##......#######.",
	"..##......##...##.",
	"..........##...##.",
	"..........#######.",
	"..................",
]

var _biomes: Array = [
	BiomeType.Type.GRASSLAND, BiomeType.Type.FOREST, BiomeType.Type.DESERT, BiomeType.Type.ROCKS,
	BiomeType.Type.CAVE, BiomeType.Type.SWAMP, BiomeType.Type.SEABED, BiomeType.Type.ROCKS_AND_WATER,
]
var _camera: Camera2D
var _panel := 0


func _ready() -> void:
	var painter := TerrainPainter.new()
	painter.create_layers(self)

	var w := PANEL_W * _biomes.size()
	var h := PANEL_H
	var cliff := PackedInt32Array()
	cliff.resize(w * h)
	var overlay := PackedByteArray()
	overlay.resize(w * h)
	var noise := FastNoiseLite.new()
	noise.seed = 7
	noise.frequency = 0.09

	var style_keys: Array = []
	for p in range(_biomes.size()):
		var key := TerrainStyles.get_cliff_key_for_biome(_biomes[p])
		if not style_keys.has(key):
			style_keys.append(key)
		var k := style_keys.find(key) + 1
		for my in range(SHAPE.size()):
			var line: String = SHAPE[my]
			for mx in range(line.length()):
				var solid := line[mx] == "#"
				for dy in range(2):
					for dx in range(2):
						var x := p * PANEL_W + mx * 2 + dx
						var y := my * 2 + dy
						if solid:
							cliff[y * w + x] = k
		for my in range(PANEL_H / 2):
			for mx in range(PANEL_W / 2):
				var on := noise.get_noise_2d(float(p * 100 + mx), float(my)) > -0.1
				for dy in range(2):
					for dx in range(2):
						overlay[(my * 2 + dy) * w + p * PANEL_W + mx * 2 + dx] = 1 if on else 0

	var biome_at := func(x: int, _y: int) -> int:
		return _biomes[clampi(x / PANEL_W, 0, _biomes.size() - 1)]
	var blocked := PackedByteArray()
	blocked.resize(w * h)
	painter.paint_floor(w, h, biome_at, overlay, blocked, 11)
	painter.paint_cliffs(w, h, cliff, style_keys, 13)

	_camera = Camera2D.new()
	_camera.zoom = Vector2(2, 2)
	add_child(_camera)
	_camera.make_current()
	_focus(0)

	for arg in OS.get_cmdline_user_args() + OS.get_cmdline_args():
		if String(arg).begins_with("--lab-shot="):
			_capture_all(String(arg).substr(11))
			return


func _focus(p: int) -> void:
	_panel = clampi(p, 0, _biomes.size() - 1)
	_camera.position = Vector2((_panel * PANEL_W + PANEL_W / 2.0) * 16.0, PANEL_H / 2.0 * 16.0)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_RIGHT:
			_focus(_panel + 1)
		elif event.keycode == KEY_LEFT:
			_focus(_panel - 1)


func _capture_all(p_dir: String) -> void:
	for p in range(_biomes.size()):
		_focus(p)
		await get_tree().process_frame
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var img := get_viewport().get_texture().get_image()
		img.save_png("%s/lab_%d.png" % [p_dir, p])
	get_tree().quit()
