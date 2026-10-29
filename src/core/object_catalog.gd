class_name ObjectCatalog
extends RefCounted

const BIOME_DIR := "res://assets/biomes"
const COMMON_DIR := "res://assets/common"

const BIOME_NAMES := {
	BiomeType.CAVE: "cave",
	BiomeType.DESERT: "desert",
	BiomeType.FOREST: "forest",
	BiomeType.GRASSLAND: "grassland",
	BiomeType.ROCKS: "rocks",
	BiomeType.ROCKS_AND_WATER: "rocks_and_water",
	BiomeType.SWAMP: "swamp",
	BiomeType.SEABED: "seabed",
}

static var _cached_biome_objects: Dictionary = {}
static var _cached_biome_tiles: Dictionary = {}
static var _cached_common: Dictionary = {}
static var _texture_cache: Dictionary = {}


static func get_biome_name(p_biome: BiomeType.Type) -> String:
	return BIOME_NAMES.get(p_biome, "grassland")


static func get_biome_objects(p_biome: BiomeType.Type) -> Array[String]:
	if _cached_biome_objects.has(p_biome):
		var cached: Array[String] = []
		cached.assign(_cached_biome_objects[p_biome])
		return cached

	var b_name := get_biome_name(p_biome)
	var dir_path := "%s/%s/objects" % [BIOME_DIR, b_name]
	var paths := _list_png_files(dir_path)
	_cached_biome_objects[p_biome] = paths
	var result: Array[String] = []
	result.assign(paths)
	return result


static func get_biome_tilesheets(p_biome: BiomeType.Type) -> Array[String]:
	if _cached_biome_tiles.has(p_biome):
		var cached: Array[String] = []
		cached.assign(_cached_biome_tiles[p_biome])
		return cached

	var b_name := get_biome_name(p_biome)
	var dir_path := "%s/%s/tiles" % [BIOME_DIR, b_name]
	var paths := _list_png_files(dir_path)
	_cached_biome_tiles[p_biome] = paths
	var result: Array[String] = []
	result.assign(paths)
	return result


static func get_common_objects(category: String) -> Array[String]:
	if _cached_common.has(category):
		var cached: Array[String] = []
		cached.assign(_cached_common[category])
		return cached

	var dir_path := "%s/%s" % [COMMON_DIR, category]
	var paths := _list_png_files(dir_path)
	_cached_common[category] = paths
	var result: Array[String] = []
	result.assign(paths)
	return result


static func get_random_biome_object(p_biome: BiomeType.Type, rng: RandomNumberGenerator = null) -> String:
	var objects := get_biome_objects(p_biome)
	if objects.is_empty():
		return ""
	if rng != null:
		var index := rng.randi_range(0, objects.size() - 1)
		return objects[index]
	return objects[randi() % objects.size()]


static func get_random_common_object(category: String, rng: RandomNumberGenerator = null) -> String:
	var objects := get_common_objects(category)
	if objects.is_empty():
		return ""
	if rng != null:
		var index := rng.randi_range(0, objects.size() - 1)
		return objects[index]
	return objects[randi() % objects.size()]


static func load_texture(res_path: String) -> Texture2D:
	if res_path.is_empty():
		return null
	if _texture_cache.has(res_path):
		return _texture_cache[res_path]
	if ResourceLoader.exists(res_path):
		var tex := load(res_path) as Texture2D
		if tex != null:
			_texture_cache[res_path] = tex
			return tex
	return null


static func clear_cache() -> void:
	_cached_biome_objects.clear()
	_cached_biome_tiles.clear()
	_cached_common.clear()
	_texture_cache.clear()


static func _list_png_files(dir_path: String) -> Array[String]:
	var results: Array[String] = []
	if not DirAccess.dir_exists_absolute(dir_path):
		return results

	var dir := DirAccess.open(dir_path)
	if dir == null:
		return results

	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".png"):
			# Avoid matching Godot .import auxiliary files
			if not file_name.ends_with(".png.import"):
				results.append("%s/%s" % [dir_path, file_name])
		file_name = dir.get_next()
	dir.list_dir_end()
	results.sort()
	return results

