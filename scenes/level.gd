extends TileMapLayer
# Renderizado del mundo generado.
#
# El terreno se dibuja con TerrainPainter en capas hijas propias (suelo, manchas, decals,
# caras y cimas de acantilado, derrames). Este TileMapLayer se queda vacio y conserva su
# TileSet de patrones para herramientas/tests (TileMapper / CliffAutotiler).

const TerrainPainter = preload("res://src/core/terrain_painter.gd")
const TerrainStyles = preload("res://src/core/terrain_styles.gd")
const ObjectCatalog = preload("res://src/core/object_catalog.gd")

# Las capas de terreno quedan por debajo de jugador y objetos (z 0)
const TERRAIN_Z_BASE := -20

var level: Level
var tile_mapper: TileMapper
var painter: TerrainPainter
var _objects_node: Node2D = null


func load_level(p_level: Level, p_tile_mapper: TileMapper) -> void:
	tile_mapper = p_tile_mapper
	level = p_level
	clear()
	_setup_objects_container()
	_paint_terrain()
	_spawn_objects()


func _setup_objects_container() -> void:
	if _objects_node != null and is_instance_valid(_objects_node):
		for child in _objects_node.get_children():
			child.queue_free()
	else:
		_objects_node = get_parent().get_node_or_null("WorldObjects") as Node2D
		if _objects_node == null:
			_objects_node = Node2D.new()
			_objects_node.name = "WorldObjects"
			_objects_node.y_sort_enabled = true
			get_parent().add_child(_objects_node)


func _paint_terrain() -> void:
	painter = TerrainPainter.new()
	painter.create_layers(self)
	for layer_name: String in painter.layers:
		var layer: TileMapLayer = painter.layers[layer_name]
		layer.z_index = TERRAIN_Z_BASE + TerrainPainter.LAYER_NAMES.find(layer_name)

	var w := level.width * level.chunk_size
	var h := level.height * level.chunk_size
	@warning_ignore("INTEGER_DIVISION")
	var mw := w / 2
	@warning_ignore("INTEGER_DIVISION")
	var mh := h / 2

	# Datos por macro-celda (2x2 baldosas)
	var macro_biome := PackedInt32Array()
	macro_biome.resize(mw * mh)
	var macro_overlay := PackedByteArray()
	macro_overlay.resize(mw * mh)
	var macro_cliff := PackedInt32Array()
	macro_cliff.resize(mw * mh)
	var style_keys: Array = TerrainStyles.CLIFFS.keys()
	for my in range(mh):
		for mx in range(mw):
			var i := my * mw + mx
			macro_biome[i] = level.get_biome_at_macro(mx, my)
			macro_overlay[i] = 1 if level.is_floor_overlay_macro(mx, my) else 0
			if level.is_macro_cell_solid(mx, my):
				macro_cliff[i] = style_keys.find(level.get_plateau_style(mx, my)) + 1

	# Expandir a baldosas
	var cliff := PackedInt32Array()
	cliff.resize(w * h)
	var overlay := PackedByteArray()
	overlay.resize(w * h)
	for y in range(h):
		for x in range(w):
			@warning_ignore("INTEGER_DIVISION")
			var mi := (y / 2) * mw + (x / 2)
			cliff[y * w + x] = macro_cliff[mi]
			overlay[y * w + x] = macro_overlay[mi]

	var face_mask := painter.paint_cliffs(w, h, cliff, style_keys, level.world_seed)

	var blocked := PackedByteArray()
	blocked.resize(w * h)
	for i in range(w * h):
		blocked[i] = 1 if cliff[i] > 0 or face_mask[i] == 1 else 0

	var biome_at := func(x: int, y: int) -> int:
		@warning_ignore("INTEGER_DIVISION")
		return macro_biome[(y / 2) * mw + (x / 2)]
	painter.paint_floor(w, h, biome_at, overlay, blocked, level.world_seed)


func _spawn_objects() -> void:
	if _objects_node == null:
		return
	for x in range(level.width):
		for y in range(level.height):
			var chunk := level.get_chunk(x, y)
			if chunk == null:
				continue
			for obj in chunk.placed_objects:
				var path: String = obj.get("path", "")
				var local_pos: Vector2i = obj.get("pos", Vector2i.ZERO)
				var global_tile := Vector2i(x * level.chunk_size + local_pos.x, y * level.chunk_size + local_pos.y)
				var tex := ObjectCatalog.load_texture(path)
				if tex == null:
					continue
				var sprite := Sprite2D.new()
				sprite.texture = tex
				sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
				# El pie del sprite descansa sobre el borde inferior de su baldosa
				sprite.position = map_to_local(global_tile) + Vector2(0, 7)
				sprite.offset = Vector2(0, -tex.get_height() / 2.0)
				# Ligera variedad: algunos objetos se reflejan
				if (global_tile.x * 31 + global_tile.y * 17) % 3 == 0:
					sprite.flip_h = true
				_objects_node.add_child(sprite)
