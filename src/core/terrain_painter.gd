# terrain_painter.gd
# Motor de autotiling a nivel de baldosa para suelos y acantilados.
#
# Reglas:
#  * Cada baldosa solida se clasifica con sus 8 vecinos en una de 9 piezas (3x3) o en una
#    de las 4 esquinas concavas ("inner"). Las mascaras se construyen con macro-celdas de 2x2,
#    por lo que todas las formas tienen al menos 2 baldosas de grosor y la clasificacion es
#    siempre inequivoca.
#  * La cara de roca de un acantilado se dibuja DEBAJO de cada borde sur (vista 3/4).
#  * Donde una cara de roca toca el flanco de una meseta (esquina concava sur) se dibuja la
#    cara tambien por debajo del flanco, asi el borde transparente de la hierba "cuelga"
#    sobre la roca sin dejar huecos.
#  * Los estilos con "spill" (agujas de roca) emiten baldosas de derrame hacia las celdas
#    vacias vecinas en capas propias.
class_name TerrainPainter
extends RefCounted

const TerrainStyles = preload("res://src/core/terrain_styles.gd")

const TILE_SIZE := 16
const LAYER_NAMES := [
	"Ground", "GroundOverlay", "GroundDecor", "CliffFace", "CliffTop", "TopDecor", "CliffSpillV", "CliffSpillH",
]

var tile_set: TileSet
var layers: Dictionary = {}

var _source_ids: Dictionary = {}


func _init() -> void:
	tile_set = TileSet.new()
	tile_set.tile_size = Vector2i(TILE_SIZE, TILE_SIZE)


func create_layers(p_parent: Node) -> void:
	"""Crea (o reutiliza) las capas TileMapLayer de terreno como hijas de p_parent."""
	for i in range(LAYER_NAMES.size()):
		var layer_name: String = LAYER_NAMES[i]
		var layer := p_parent.get_node_or_null(layer_name) as TileMapLayer
		if layer == null:
			layer = TileMapLayer.new()
			layer.name = layer_name
			p_parent.add_child(layer)
		layer.tile_set = tile_set
		layer.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		layer.z_index = i
		layer.clear()
		layers[layer_name] = layer


func source_for(p_sheet: String) -> int:
	if _source_ids.has(p_sheet):
		return _source_ids[p_sheet]
	var src := TileSetAtlasSource.new()
	src.texture = load(p_sheet)
	src.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)
	var id := tile_set.add_source(src)
	_source_ids[p_sheet] = id
	return id


func put(p_layer_name: String, p_cell: Vector2i, p_sheet: String, p_coords: Vector2i) -> void:
	var layer: TileMapLayer = layers.get(p_layer_name)
	if layer == null:
		return
	var id := source_for(p_sheet)
	var src := tile_set.get_source(id) as TileSetAtlasSource
	if not src.has_tile(p_coords):
		var grid := src.get_atlas_grid_size()
		if p_coords.x < 0 or p_coords.y < 0 or p_coords.x >= grid.x or p_coords.y >= grid.y:
			return
		src.create_tile(p_coords)
	layer.set_cell(p_cell, id, p_coords)


static func _hash2(x: int, y: int, salt: int) -> int:
	var h := (x * 73856093) ^ (y * 19349663) ^ (salt * 83492791)
	h = (h ^ (h >> 13)) * 1274126177
	return absi(h ^ (h >> 16))


static func classify(p_same: Callable, x: int, y: int) -> Dictionary:
	"""Clasifica una baldosa: col (0=O,1=C,2=E), row (0=N,1=C,2=S) e inner ("", nw, ne, sw, se)."""
	var n: bool = p_same.call(x, y - 1)
	var s: bool = p_same.call(x, y + 1)
	var w: bool = p_same.call(x - 1, y)
	var e: bool = p_same.call(x + 1, y)
	var col := 1
	var row := 1
	if not w:
		col = 0
	elif not e:
		col = 2
	if not n:
		row = 0
	elif not s:
		row = 2
	var inner := ""
	if col == 1 and row == 1:
		if not p_same.call(x - 1, y - 1):
			inner = "nw"
		elif not p_same.call(x + 1, y - 1):
			inner = "ne"
		elif not p_same.call(x - 1, y + 1):
			inner = "sw"
		elif not p_same.call(x + 1, y + 1):
			inner = "se"
	return {"col": col, "row": row, "inner": inner}


static func blob_coords(p_style: Dictionary, p_class: Dictionary) -> Vector2i:
	var inner: String = p_class["inner"]
	var inner_map: Dictionary = p_style.get("inner", {})
	if inner != "" and inner_map.has(inner):
		return inner_map[inner]
	var cols: Array = p_style["cols"]
	var rows: Array = p_style["rows"]
	return Vector2i(cols[p_class["col"]], rows[p_class["row"]])


# ---------------------------------------------------------------------------
# Suelo
# ---------------------------------------------------------------------------
func paint_floor(p_w: int, p_h: int, p_biome_at: Callable, p_overlay: PackedByteArray, p_blocked: PackedByteArray, p_seed: int) -> void:
	"""Dibuja suelo base, manchas autotile y decals.

	p_biome_at(x, y) -> int  bioma por baldosa
	p_overlay[y*w+x] -> 1 si la baldosa lleva mancha de overlay
	p_blocked[y*w+x] -> 1 si la baldosa esta cubierta por meseta o cara (sin decals)
	"""
	var biomes := PackedInt32Array()
	biomes.resize(p_w * p_h)
	for y in range(p_h):
		for x in range(p_w):
			biomes[y * p_w + x] = p_biome_at.call(x, y)

	var same_overlay := func(x: int, y: int) -> bool:
		if x < 0 or y < 0 or x >= p_w or y >= p_h:
			return true
		return p_overlay[y * p_w + x] == 1

	for y in range(p_h):
		for x in range(p_w):
			var idx := y * p_w + x
			var biome := biomes[idx]
			var style := TerrainStyles.get_biome_style(biome)
			var cell := Vector2i(x, y)

			# 1. Suelo base con ligeras variantes
			var base: Dictionary = style["base"]
			var tiles: Array = base["tiles"]
			var pick: Vector2i = tiles[0]
			if tiles.size() > 1 and _hash2(x, y, p_seed) % 100 < 30:
				pick = tiles[1 + _hash2(x, y, p_seed + 7) % (tiles.size() - 1)]
			put("Ground", cell, base["sheet"], pick)

			# 2. Manchas de overlay (hierba, musgo...) con autotiling 3x3 + esquinas interiores
			if p_overlay[idx] == 1 and style.has("overlay"):
				var ov: Dictionary = style["overlay"]
				var cls := classify(same_overlay, x, y)
				put("GroundOverlay", cell, ov["sheet"], blob_coords(ov, cls))

			# 3. Decals sueltos
			if style.has("decals") and p_blocked[idx] == 0:
				var decals: Dictionary = style["decals"]
				var density: float = decals.get("density", 0.04)
				if float(_hash2(x, y, p_seed + 31) % 1000) / 1000.0 < density:
					var dt: Array = decals["tiles"]
					put("GroundDecor", cell, decals["sheet"], dt[_hash2(x, y, p_seed + 57) % dt.size()])


# ---------------------------------------------------------------------------
# Acantilados
# ---------------------------------------------------------------------------
func paint_cliffs(p_w: int, p_h: int, p_cliff: PackedInt32Array, p_style_keys: Array, p_seed: int) -> PackedByteArray:
	"""Dibuja mesetas y caras de acantilado.

	p_cliff[y*w+x] = 0 vacio, k > 0 -> estilo p_style_keys[k-1]
	Devuelve una mascara con 1 en las baldosas ocupadas por cara de roca.
	"""
	var solid := func(x: int, y: int) -> bool:
		if x < 0 or y < 0 or x >= p_w or y >= p_h:
			return false
		return p_cliff[y * p_w + x] > 0

	# 1. Mapa de caras: fila de cara (-1 = ninguna) y estilo
	var face_row := PackedInt32Array()
	face_row.resize(p_w * p_h)
	face_row.fill(-1)
	var face_style := PackedInt32Array()
	face_style.resize(p_w * p_h)
	for y in range(p_h):
		for x in range(p_w):
			var k := p_cliff[y * p_w + x]
			if k == 0 or solid.call(x, y + 1):
				continue
			var style := TerrainStyles.get_cliff_style(p_style_keys[k - 1])
			var face: Array = style["face"]
			for i in range(face.size()):
				var fy := y + 1 + i
				if fy >= p_h or solid.call(x, fy):
					break
				var fidx := fy * p_w + x
				if face_row[fidx] == -1:
					face_row[fidx] = i
					face_style[fidx] = k

	var is_face := func(x: int, y: int) -> bool:
		if x < 0 or y < 0 or x >= p_w or y >= p_h:
			return false
		return face_row[y * p_w + x] >= 0

	var face_mask := PackedByteArray()
	face_mask.resize(p_w * p_h)

	# 2. Caras de roca
	for y in range(p_h):
		for x in range(p_w):
			var fidx := y * p_w + x
			var row := face_row[fidx]
			if row < 0:
				continue
			face_mask[fidx] = 1
			var style := TerrainStyles.get_cliff_style(p_style_keys[face_style[fidx] - 1])
			var cols: Array = style["cols"]
			var face: Array = style["face"]
			var left_cont: bool = solid.call(x - 1, y) or is_face.call(x - 1, y)
			var right_cont: bool = solid.call(x + 1, y) or is_face.call(x + 1, y)
			var col := 1
			if not left_cont:
				col = 0
			elif not right_cont:
				col = 2
			put("CliffFace", Vector2i(x, y), style["sheet"], Vector2i(cols[col], face[row]))

			# Derrame lateral e inferior de la cara (agujas)
			if style.has("spill"):
				var sp: Dictionary = style["spill"]
				if col == 0 and sp.has("l") and not solid.call(x - 1, y) and not is_face.call(x - 1, y):
					put("CliffSpillH", Vector2i(x - 1, y), style["sheet"], Vector2i(sp["l"], face[row]))
				if col == 2 and sp.has("r") and not solid.call(x + 1, y) and not is_face.call(x + 1, y):
					put("CliffSpillH", Vector2i(x + 1, y), style["sheet"], Vector2i(sp["r"], face[row]))
				if row == face.size() - 1 and sp.has("b") and not solid.call(x, y + 1) and not is_face.call(x, y + 1):
					put("CliffSpillV", Vector2i(x, y + 1), style["sheet"], Vector2i(cols[col], sp["b"]))
					if col == 0 and sp.has("l") and not solid.call(x - 1, y + 1) and not is_face.call(x - 1, y + 1):
						put("CliffSpillH", Vector2i(x - 1, y + 1), style["sheet"], Vector2i(sp["l"], sp["b"]))
					if col == 2 and sp.has("r") and not solid.call(x + 1, y + 1) and not is_face.call(x + 1, y + 1):
						put("CliffSpillH", Vector2i(x + 1, y + 1), style["sheet"], Vector2i(sp["r"], sp["b"]))

	# 3. Superficies superiores
	for y in range(p_h):
		for x in range(p_w):
			var k := p_cliff[y * p_w + x]
			if k == 0:
				continue
			var style := TerrainStyles.get_cliff_style(p_style_keys[k - 1])
			var cls := classify(solid, x, y)
			var coords := blob_coords(style, cls)
			var col: int = cls["col"]
			var row: int = cls["row"]
			if col == 1 and row == 0 and style.has("n_alt") and _hash2(x, y, p_seed) % 3 == 0:
				var alts: Array = style["n_alt"]
				coords = alts[_hash2(x, y, p_seed + 3) % alts.size()]
			elif col == 1 and row == 1 and cls["inner"] == "" and style.has("c_alt") and _hash2(x, y, p_seed + 5) % 7 == 0:
				var calts: Array = style["c_alt"]
				coords = calts[_hash2(x, y, p_seed + 9) % calts.size()]
			put("CliffTop", Vector2i(x, y), style["sheet"], coords)

			# Detalles sobre la cima (matas, flores...) solo en el interior
			if col == 1 and row == 1 and cls["inner"] == "" and style.has("top_decals"):
				var td: Dictionary = style["top_decals"]
				if float(_hash2(x, y, p_seed + 77) % 1000) / 1000.0 < float(td.get("density", 0.05)):
					var td_tiles: Array = td["tiles"]
					put("TopDecor", Vector2i(x, y), td["sheet"], td_tiles[_hash2(x, y, p_seed + 79) % td_tiles.size()])

			var cols: Array = style["cols"]
			var rows: Array = style["rows"]
			var face: Array = style["face"]

			# Cara por debajo del flanco donde la roca de al lado continua (esquina concava sur)
			if col == 0 and is_face.call(x - 1, y):
				put("CliffFace", Vector2i(x, y), style["sheet"], Vector2i(cols[1], face[mini(face_row[y * p_w + x - 1], face.size() - 1)]))
			elif col == 2 and is_face.call(x + 1, y):
				put("CliffFace", Vector2i(x, y), style["sheet"], Vector2i(cols[1], face[mini(face_row[y * p_w + x + 1], face.size() - 1)]))

			# Derrame (agujas que sobresalen de la huella)
			if style.has("spill"):
				var sp: Dictionary = style["spill"]
				if row == 0 and sp.has("t") and not solid.call(x, y - 1) and not is_face.call(x, y - 1):
					put("CliffSpillV", Vector2i(x, y - 1), style["sheet"], Vector2i(cols[col], sp["t"]))
					if col == 0 and sp.has("l") and not solid.call(x - 1, y - 1):
						put("CliffSpillH", Vector2i(x - 1, y - 1), style["sheet"], Vector2i(sp["l"], sp["t"]))
					elif col == 2 and sp.has("r") and not solid.call(x + 1, y - 1):
						put("CliffSpillH", Vector2i(x + 1, y - 1), style["sheet"], Vector2i(sp["r"], sp["t"]))
				if col == 0 and sp.has("l") and not solid.call(x - 1, y) and not is_face.call(x - 1, y):
					put("CliffSpillH", Vector2i(x - 1, y), style["sheet"], Vector2i(sp["l"], rows[row]))
				elif col == 2 and sp.has("r") and not solid.call(x + 1, y) and not is_face.call(x + 1, y):
					put("CliffSpillH", Vector2i(x + 1, y), style["sheet"], Vector2i(sp["r"], rows[row]))

	return face_mask
