extends GutTest

const ObjectCatalog = preload("res://src/core/object_catalog.gd")

func before_each():
	ObjectCatalog.clear_cache()


func test_biome_names_mapping():
	assert_eq(ObjectCatalog.get_biome_name(BiomeType.CAVE), "cave")
	assert_eq(ObjectCatalog.get_biome_name(BiomeType.DESERT), "desert")
	assert_eq(ObjectCatalog.get_biome_name(BiomeType.FOREST), "forest")
	assert_eq(ObjectCatalog.get_biome_name(BiomeType.GRASSLAND), "grassland")
	assert_eq(ObjectCatalog.get_biome_name(BiomeType.ROCKS), "rocks")
	assert_eq(ObjectCatalog.get_biome_name(BiomeType.ROCKS_AND_WATER), "rocks_and_water")
	assert_eq(ObjectCatalog.get_biome_name(BiomeType.SWAMP), "swamp")
	assert_eq(ObjectCatalog.get_biome_name(BiomeType.SEABED), "seabed")


func test_all_biomes_have_objects_and_tiles():
	var all_biomes = [
		BiomeType.CAVE,
		BiomeType.DESERT,
		BiomeType.FOREST,
		BiomeType.GRASSLAND,
		BiomeType.ROCKS,
		BiomeType.ROCKS_AND_WATER,
		BiomeType.SWAMP,
		BiomeType.SEABED
	]
	for b in all_biomes:
		var objects := ObjectCatalog.get_biome_objects(b)
		var tiles := ObjectCatalog.get_biome_tilesheets(b)
		var b_name := ObjectCatalog.get_biome_name(b)
		assert_gt(objects.size(), 0, "Biome %s should have objects" % b_name)
		assert_gt(tiles.size(), 0, "Biome %s should have tiles" % b_name)


func test_common_categories():
	var categories = ["bushes", "trees", "roads", "ruins", "icons", "characters", "cursed_land"]
	for cat in categories:
		var items := ObjectCatalog.get_common_objects(cat)
		assert_gt(items.size(), 0, "Category %s should have PNG files" % cat)


func test_random_biome_object_deterministic_with_rng():
	var rng1 := RandomNumberGenerator.new()
	rng1.seed = 42
	var obj1 := ObjectCatalog.get_random_biome_object(BiomeType.FOREST, rng1)

	var rng2 := RandomNumberGenerator.new()
	rng2.seed = 42
	var obj2 := ObjectCatalog.get_random_biome_object(BiomeType.FOREST, rng2)

	assert_ne(obj1, "")
	assert_eq(obj1, obj2)
