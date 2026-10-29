extends GutTest

const TerrainPainter = preload("res://src/core/terrain_painter.gd")
const TerrainStyles = preload("res://src/core/terrain_styles.gd")


func _mask_fn(p_rows: Array) -> Callable:
	return func(x: int, y: int) -> bool:
		if y < 0 or y >= p_rows.size():
			return false
		var line: String = p_rows[y]
		if x < 0 or x >= line.length():
			return false
		return line[x] == "#"


func test_classify_nine_slice_pieces():
	var same := _mask_fn(["###", "###", "###"])
	assert_eq(TerrainPainter.classify(same, 0, 0), {"col": 0, "row": 0, "inner": ""}, "NO")
	assert_eq(TerrainPainter.classify(same, 1, 0), {"col": 1, "row": 0, "inner": ""}, "N")
	assert_eq(TerrainPainter.classify(same, 2, 0), {"col": 2, "row": 0, "inner": ""}, "NE")
	assert_eq(TerrainPainter.classify(same, 0, 1), {"col": 0, "row": 1, "inner": ""}, "O")
	assert_eq(TerrainPainter.classify(same, 1, 1), {"col": 1, "row": 1, "inner": ""}, "Centro")
	assert_eq(TerrainPainter.classify(same, 2, 2), {"col": 2, "row": 2, "inner": ""}, "SE")


func test_classify_concave_corners():
	# Meseta con muesca en la esquina superior izquierda
	var same := _mask_fn([
		"..####",
		"..####",
		"######",
		"######",
	])
	var cls := TerrainPainter.classify(same, 2, 2)
	assert_eq(cls["inner"], "nw", "La baldosa junto a la muesca es una esquina concava NO")
	var edge := TerrainPainter.classify(same, 1, 2)
	assert_eq(edge["row"], 0, "La baldosa bajo la muesca es borde norte")


func test_blob_coords_falls_back_to_center_without_inner_piece():
	var style := TerrainStyles.get_cliff_style("rock")
	var coords := TerrainPainter.blob_coords(style, {"col": 1, "row": 1, "inner": "se"})
	assert_eq(coords, Vector2i(style["cols"][1], style["rows"][1]), "Sin pieza concava se usa el relleno")


func test_paint_cliffs_draws_face_below_south_edge_and_underlay():
	var root := Node2D.new()
	add_child_autofree(root)
	var painter := TerrainPainter.new()
	painter.create_layers(root)

	# Meseta en L: la cara del tramo derecho toca el flanco del tramo izquierdo
	var rows := [
		"..........",
		".######...",
		".######...",
		".##.......",
		".##.......",
		"..........",
		"..........",
	]
	var w := 10
	var h := rows.size()
	var cliff := PackedInt32Array()
	cliff.resize(w * h)
	for y in range(h):
		for x in range(w):
			if (rows[y] as String)[x] == "#":
				cliff[y * w + x] = 1
	var face_mask := painter.paint_cliffs(w, h, cliff, ["grass"], 1)

	var face_layer: TileMapLayer = painter.layers["CliffFace"]
	var top_layer: TileMapLayer = painter.layers["CliffTop"]
	# Cara de 2 filas bajo el borde sur del tramo derecho (x=3..6, y=3..4)
	for x in range(3, 7):
		assert_eq(face_mask[3 * w + x], 1, "Cara en la fila 1 bajo el borde sur")
		assert_eq(face_mask[4 * w + x], 1, "Cara en la fila 2 bajo el borde sur")
		assert_ne(face_layer.get_cell_source_id(Vector2i(x, 3)), -1, "Baldosa de cara dibujada")
	assert_eq(face_mask[5 * w + 4], 0, "La cara no baja mas de 2 filas")
	# Cara por debajo del flanco este del tramo izquierdo (esquina concava sur)
	assert_ne(face_layer.get_cell_source_id(Vector2i(2, 3)), -1, "La roca continua bajo el flanco")
	assert_ne(top_layer.get_cell_source_id(Vector2i(2, 3)), -1, "El flanco se dibuja encima")
	# La cara del tramo izquierdo arranca en su borde sur
	assert_eq(face_mask[5 * w + 1], 1, "Cara bajo el tramo izquierdo")
	# Ningun hueco: todas las baldosas solidas tienen cima
	for y in range(h):
		for x in range(w):
			if cliff[y * w + x] > 0:
				assert_ne(top_layer.get_cell_source_id(Vector2i(x, y)), -1, "Cima en %d,%d" % [x, y])


func test_paint_cliffs_rock_style_emits_spill():
	var root := Node2D.new()
	add_child_autofree(root)
	var painter := TerrainPainter.new()
	painter.create_layers(root)
	var w := 8
	var h := 8
	var cliff := PackedInt32Array()
	cliff.resize(w * h)
	for y in range(2, 4):
		for x in range(2, 4):
			cliff[y * w + x] = 1
	painter.paint_cliffs(w, h, cliff, ["rock"], 1)
	var spill_v: TileMapLayer = painter.layers["CliffSpillV"]
	var spill_h: TileMapLayer = painter.layers["CliffSpillH"]
	assert_ne(spill_v.get_cell_source_id(Vector2i(2, 1)), -1, "Agujas sobre el borde norte")
	assert_ne(spill_h.get_cell_source_id(Vector2i(1, 2)), -1, "Agujas en el flanco oeste")
	assert_ne(spill_v.get_cell_source_id(Vector2i(2, 6)), -1, "Agujas bajo la cara")


func test_every_biome_has_valid_floor_and_cliff_style():
	for biome: int in BiomeType.Type.values():
		var style := TerrainStyles.get_biome_style(biome)
		assert_true(style.has("base"), "Suelo base para el bioma %d" % biome)
		assert_true(TerrainStyles.CLIFFS.has(style["cliff"]), "Estilo de acantilado valido para %d" % biome)
		assert_true(ResourceLoader.exists(style["base"]["sheet"]), "Hoja de suelo existente")
	for key: String in TerrainStyles.CLIFFS:
		var cliff: Dictionary = TerrainStyles.CLIFFS[key]
		assert_true(ResourceLoader.exists(cliff["sheet"]), "Hoja de acantilado %s existente" % key)
		assert_eq((cliff["cols"] as Array).size(), 3, "3 columnas en %s" % key)
		assert_eq((cliff["rows"] as Array).size(), 3, "3 filas en %s" % key)
		assert_gt((cliff["face"] as Array).size(), 0, "Cara definida en %s" % key)

