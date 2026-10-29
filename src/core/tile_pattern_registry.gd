class_name TilePatternRegistry

# IMPORTANT!!! 
# As the godot editor does not seem to have the option to name a pattern created from the tile map editor and 
# I can only reference it by an index (which might change), it's crucial to keep a good register of which index
# is which tile pattern

# TODO: Create more dictionaries equivalating the pattern lists (different ones please!) in godot editor
static var dictionary: Dictionary = {

	"Upper Left Corner (High Plateau Rocks)" : {
		"index": 1,
		"atlas_coords": [
			Vector2i(0, 21),
			Vector2i(0, 22),
			Vector2i(1, 21),
			Vector2i(1, 22)
		],
		"hull_pattern": [
			Vector2i(1, 22),
			Vector2i(1, 22)
		],
		"hull_curvature": HullCurvature.LEFT,
		"is_corner": true,
		"corner_type": CornerType.UL,
		"is_atomic": true,
	},

	"Upper Right Corner (High Plateau Rocks)": {
		"index": 2,
		"atlas_coords": [
			Vector2i(3, 21),
			Vector2i(3, 22),
			Vector2i(4, 21),
			Vector2i(4, 22)
		],
		"hull_pattern": [
			Vector2i(4, 21),
			Vector2i(4, 21)			
		],
		"hull_curvature": HullCurvature.RIGHT,
		"is_corner": true,
		"corner_type": CornerType.UR,
		"is_atomic": true,
	},

	"Lower Left Corner (High Plateau Rocks)": {
		"index": 3,
		"atlas_coords": [
			Vector2i(0, 24),
			Vector2i(0, 25),
			Vector2i(0, 26),
			Vector2i(0, 27),
			Vector2i(1, 24),
			Vector2i(1, 25),
			Vector2i(1, 26),
			Vector2i(1, 27)
		],
		"hull_pattern": [
			Vector2i(1, 24),
			Vector2i(1, 24)
		],
		"hull_curvature": HullCurvature.LEFT,
		"is_corner": true,
		"corner_type": CornerType.LL,
		"is_atomic": true,
	},

	"Lower Right Corner (High Plateau Rocks)": {
		"index": 4,
		"atlas_coords": [
			Vector2i(3, 24),
			Vector2i(3, 25),
			Vector2i(3, 26),
			Vector2i(3, 27),
			Vector2i(4, 24),
			Vector2i(4, 25),
			Vector2i(4, 26),
			Vector2i(4, 27),
		],
		"hull_pattern": [
			Vector2i(3, 24),
			Vector2i(3, 24)
		],
		"hull_curvature": HullCurvature.RIGHT,
		"is_corner": true,
		"corner_type": CornerType.LL,
		"is_atomic": true,
	},

	"Top Edge Straight (High Plateau Rocks)": {
		"index": 5,
		"atlas_coords": [
			Vector2i(5, 21),
			Vector2i(5, 22),
			Vector2i(6, 21),
			Vector2i(6, 22)
		],
		"hull_pattern": [
			Vector2i(6, 21),
			Vector2i(6, 22)
		],
		"hull_curvature": HullCurvature.STRAIGHT_HORIZONTAL,
		"is_corner": false,
		"corner_type": null,
		"is_atomic": true,
	},

	"Bottom Edge Straight (High Plateau Rocks)": {
		"index": 6,
		"atlas_coords": [
			Vector2i(5, 23),
			Vector2i(5, 24),
			Vector2i(5, 25),
			Vector2i(5, 26),
			Vector2i(6, 23),
			Vector2i(6, 24),
			Vector2i(6, 25),
			Vector2i(6, 26)
		],
		"hull_pattern": [
			Vector2i(5, 23),
			Vector2i(6, 23)
		],
		"hull_curvature": HullCurvature.STRAIGHT_HORIZONTAL,
		"is_corner": false,
		"corner_type": null,
		"is_atomic": true,
	},

	"Left Edge Straight (High Plateau Rocks)": {
		"index": 7,
		"atlas_coords": [
			Vector2i(21, 27),
			Vector2i(21, 28),
			Vector2i(22, 27),
			Vector2i(22, 28)
		],
		"hull_pattern": [
			Vector2i(22, 28),
			Vector2i(22, 27)
		],
		"hull_curvature": HullCurvature.STRAIGHT_VERTCAL,
		"is_corner": false,
		"corner_type": null,
		"is_atomic": true,
	},

	"Right Edge Straight (High Plateau Rocks)": {
		"index": 8,
		"atlas_coords": [
			# Hier hab ich das muster verkehrt herum angelegt, ist aber okay. nur die indizes sind vertauscht hier			
			Vector2i(19, 28),
			Vector2i(19, 27),
			Vector2i(20, 28),
			Vector2i(20, 27)
		],
		"hull_pattern": [
			Vector2i(19, 28), 
			Vector2i(19, 27)
		],
		"hull_curvature": HullCurvature.STRAIGHT_VERTCAL,
		"is_corner": false,
		"corner_type": CornerType.NO_CORNER,
		"is_atomic": true,
	},

	"Ground Plate (High Plateau Rocks) Variant A": {
		"index": 9,
		"atlas_coords": [
			Vector2i(17, 37),
			Vector2i(17, 37),
			Vector2i(17, 37),
			Vector2i(17, 37)
		],
		"hull_pattern": [],
		"hull_curvature": HullCurvature.NO_HULL,
		"is_corner": false,
		"corner_type": CornerType.NO_CORNER,
		"is_atomic": true,
	},

	"Ground Plate (High Plateau Rocks) Variant B": {
		"index": 16,
		"atlas_coords": [
			Vector2i(17, 37),
			Vector2i(17, 37),
			Vector2i(17, 37),
			Vector2i(17, 37)
		],
		"hull_pattern": [],
		"hull_curvature": HullCurvature.NO_HULL,
		"is_corner": false,
		"corner_type": CornerType.NO_CORNER,
		"is_atomic": true,
	},

	"Ground Plate (High Plateau Rocks) Variant C": {
		"index": 17,
		"atlas_coords": [
			Vector2i(17, 37),
			Vector2i(17, 37),
			Vector2i(17, 37),
			Vector2i(17, 37)
		],
		"hull_pattern": [],
		"hull_curvature": HullCurvature.NO_HULL,
		"is_corner": false,
		"corner_type": CornerType.NO_CORNER,
		"is_atomic": true,
	},

	"Upper Left Corner (Grassland)": {
		"index": 18,
		"atlas_coords": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)],
		"hull_pattern": [Vector2i(0, 1), Vector2i(1, 1)],
		"hull_curvature": HullCurvature.LEFT,
		"is_corner": true,
		"corner_type": CornerType.UL,
		"is_atomic": true,
	},

	"Upper Right Corner (Grassland)": {
		"index": 19,
		"atlas_coords": [Vector2i(1, 0), Vector2i(2, 0), Vector2i(1, 1), Vector2i(2, 1)],
		"hull_pattern": [Vector2i(1, 1), Vector2i(2, 1)],
		"hull_curvature": HullCurvature.RIGHT,
		"is_corner": true,
		"corner_type": CornerType.UR,
		"is_atomic": true,
	},

	"Lower Left Corner (Grassland)": {
		"index": 20,
		"atlas_coords": [Vector2i(0, 1), Vector2i(1, 1), Vector2i(0, 2), Vector2i(1, 2), Vector2i(0, 3), Vector2i(1, 3), Vector2i(0, 4), Vector2i(1, 4)],
		"hull_pattern": [Vector2i(0, 2), Vector2i(1, 2)],
		"hull_curvature": HullCurvature.LEFT,
		"is_corner": true,
		"corner_type": CornerType.LL,
		"is_atomic": true,
	},

	"Lower Right Corner (Grassland)": {
		"index": 21,
		"atlas_coords": [Vector2i(1, 1), Vector2i(2, 1), Vector2i(1, 2), Vector2i(2, 2), Vector2i(1, 3), Vector2i(2, 3), Vector2i(1, 4), Vector2i(2, 4)],
		"hull_pattern": [Vector2i(1, 2), Vector2i(2, 2)],
		"hull_curvature": HullCurvature.RIGHT,
		"is_corner": true,
		"corner_type": CornerType.LR,
		"is_atomic": true,
	},

	"Top Edge Straight (Grassland)": {
		"index": 22,
		"atlas_coords": [Vector2i(1, 0), Vector2i(1, 0), Vector2i(1, 1), Vector2i(1, 1)],
		"hull_pattern": [Vector2i(1, 0), Vector2i(1, 0)],
		"hull_curvature": HullCurvature.STRAIGHT_HORIZONTAL,
		"is_corner": false,
		"corner_type": null,
		"is_atomic": true,
	},

	"Bottom Edge Straight (Grassland)": {
		"index": 23,
		"atlas_coords": [Vector2i(1, 1), Vector2i(1, 1), Vector2i(1, 2), Vector2i(1, 2), Vector2i(1, 3), Vector2i(1, 3), Vector2i(1, 4), Vector2i(1, 4)],
		"hull_pattern": [Vector2i(1, 2), Vector2i(1, 2)],
		"hull_curvature": HullCurvature.STRAIGHT_HORIZONTAL,
		"is_corner": false,
		"corner_type": null,
		"is_atomic": true,
	},

	"Left Edge Straight (Grassland)": {
		"index": 24,
		"atlas_coords": [Vector2i(0, 1), Vector2i(1, 1), Vector2i(0, 1), Vector2i(1, 1)],
		"hull_pattern": [Vector2i(0, 1), Vector2i(0, 1)],
		"hull_curvature": HullCurvature.STRAIGHT_VERTCAL,
		"is_corner": false,
		"corner_type": null,
		"is_atomic": true,
	},

	"Right Edge Straight (Grassland)": {
		"index": 25,
		"atlas_coords": [Vector2i(1, 1), Vector2i(2, 1), Vector2i(1, 1), Vector2i(2, 1)],
		"hull_pattern": [Vector2i(2, 1), Vector2i(2, 1)],
		"hull_curvature": HullCurvature.STRAIGHT_VERTCAL,
		"is_corner": false,
		"corner_type": null,
		"is_atomic": true,
	},

	"Ground Plate (Grassland)": {
		"index": 26,
		"atlas_coords": [Vector2i(1, 1), Vector2i(1, 1), Vector2i(1, 1), Vector2i(1, 1)],
		"hull_pattern": [],
		"hull_curvature": HullCurvature.NO_HULL,
		"is_corner": false,
		"corner_type": CornerType.NO_CORNER,
		"is_atomic": true,
	},

	"Upper Left Corner (Forest)": {
		"index": 27,
		"atlas_coords": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)],
		"hull_pattern": [Vector2i(0, 1), Vector2i(1, 1)],
		"hull_curvature": HullCurvature.LEFT,
		"is_corner": true,
		"corner_type": CornerType.UL,
		"is_atomic": true,
	},

	"Upper Right Corner (Forest)": {
		"index": 28,
		"atlas_coords": [Vector2i(1, 0), Vector2i(2, 0), Vector2i(1, 1), Vector2i(2, 1)],
		"hull_pattern": [Vector2i(1, 1), Vector2i(2, 1)],
		"hull_curvature": HullCurvature.RIGHT,
		"is_corner": true,
		"corner_type": CornerType.UR,
		"is_atomic": true,
	},

	"Lower Left Corner (Forest)": {
		"index": 29,
		"atlas_coords": [Vector2i(0, 1), Vector2i(1, 1), Vector2i(0, 2), Vector2i(1, 2), Vector2i(0, 3), Vector2i(1, 3), Vector2i(0, 4), Vector2i(1, 4)],
		"hull_pattern": [Vector2i(0, 2), Vector2i(1, 2)],
		"hull_curvature": HullCurvature.LEFT,
		"is_corner": true,
		"corner_type": CornerType.LL,
		"is_atomic": true,
	},

	"Lower Right Corner (Forest)": {
		"index": 30,
		"atlas_coords": [Vector2i(1, 1), Vector2i(2, 1), Vector2i(1, 2), Vector2i(2, 2), Vector2i(1, 3), Vector2i(2, 3), Vector2i(1, 4), Vector2i(2, 4)],
		"hull_pattern": [Vector2i(1, 2), Vector2i(2, 2)],
		"hull_curvature": HullCurvature.RIGHT,
		"is_corner": true,
		"corner_type": CornerType.LR,
		"is_atomic": true,
	},

	"Top Edge Straight (Forest)": {
		"index": 31,
		"atlas_coords": [Vector2i(1, 0), Vector2i(1, 0), Vector2i(1, 1), Vector2i(1, 1)],
		"hull_pattern": [Vector2i(1, 0), Vector2i(1, 0)],
		"hull_curvature": HullCurvature.STRAIGHT_HORIZONTAL,
		"is_corner": false,
		"corner_type": null,
		"is_atomic": true,
	},

	"Bottom Edge Straight (Forest)": {
		"index": 32,
		"atlas_coords": [Vector2i(1, 1), Vector2i(1, 1), Vector2i(1, 2), Vector2i(1, 2), Vector2i(1, 3), Vector2i(1, 3), Vector2i(1, 4), Vector2i(1, 4)],
		"hull_pattern": [Vector2i(1, 2), Vector2i(1, 2)],
		"hull_curvature": HullCurvature.STRAIGHT_HORIZONTAL,
		"is_corner": false,
		"corner_type": null,
		"is_atomic": true,
	},

	"Left Edge Straight (Forest)": {
		"index": 33,
		"atlas_coords": [Vector2i(0, 1), Vector2i(1, 1), Vector2i(0, 1), Vector2i(1, 1)],
		"hull_pattern": [Vector2i(0, 1), Vector2i(0, 1)],
		"hull_curvature": HullCurvature.STRAIGHT_VERTCAL,
		"is_corner": false,
		"corner_type": null,
		"is_atomic": true,
	},

	"Right Edge Straight (Forest)": {
		"index": 34,
		"atlas_coords": [Vector2i(1, 1), Vector2i(2, 1), Vector2i(1, 1), Vector2i(2, 1)],
		"hull_pattern": [Vector2i(2, 1), Vector2i(2, 1)],
		"hull_curvature": HullCurvature.STRAIGHT_VERTCAL,
		"is_corner": false,
		"corner_type": null,
		"is_atomic": true,
	},

	"Ground Plate (Forest)": {
		"index": 35,
		"atlas_coords": [Vector2i(1, 1), Vector2i(1, 1), Vector2i(1, 1), Vector2i(1, 1)],
		"hull_pattern": [],
		"hull_curvature": HullCurvature.NO_HULL,
		"is_corner": false,
		"corner_type": CornerType.NO_CORNER,
		"is_atomic": true,
	},

	"Upper Left Corner (Desert)": {
		"index": 36,
		"atlas_coords": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)],
		"hull_pattern": [Vector2i(0, 1), Vector2i(1, 1)],
		"hull_curvature": HullCurvature.LEFT,
		"is_corner": true,
		"corner_type": CornerType.UL,
		"is_atomic": true,
	},

	"Upper Right Corner (Desert)": {
		"index": 37,
		"atlas_coords": [Vector2i(1, 0), Vector2i(2, 0), Vector2i(1, 1), Vector2i(2, 1)],
		"hull_pattern": [Vector2i(1, 1), Vector2i(2, 1)],
		"hull_curvature": HullCurvature.RIGHT,
		"is_corner": true,
		"corner_type": CornerType.UR,
		"is_atomic": true,
	},

	"Lower Left Corner (Desert)": {
		"index": 38,
		"atlas_coords": [Vector2i(0, 1), Vector2i(1, 1), Vector2i(0, 2), Vector2i(1, 2), Vector2i(0, 3), Vector2i(1, 3), Vector2i(0, 4), Vector2i(1, 4)],
		"hull_pattern": [Vector2i(0, 2), Vector2i(1, 2)],
		"hull_curvature": HullCurvature.LEFT,
		"is_corner": true,
		"corner_type": CornerType.LL,
		"is_atomic": true,
	},

	"Lower Right Corner (Desert)": {
		"index": 39,
		"atlas_coords": [Vector2i(1, 1), Vector2i(2, 1), Vector2i(1, 2), Vector2i(2, 2), Vector2i(1, 3), Vector2i(2, 3), Vector2i(1, 4), Vector2i(2, 4)],
		"hull_pattern": [Vector2i(1, 2), Vector2i(2, 2)],
		"hull_curvature": HullCurvature.RIGHT,
		"is_corner": true,
		"corner_type": CornerType.LR,
		"is_atomic": true,
	},

	"Top Edge Straight (Desert)": {
		"index": 40,
		"atlas_coords": [Vector2i(1, 0), Vector2i(1, 0), Vector2i(1, 1), Vector2i(1, 1)],
		"hull_pattern": [Vector2i(1, 0), Vector2i(1, 0)],
		"hull_curvature": HullCurvature.STRAIGHT_HORIZONTAL,
		"is_corner": false,
		"corner_type": null,
		"is_atomic": true,
	},

	"Bottom Edge Straight (Desert)": {
		"index": 41,
		"atlas_coords": [Vector2i(1, 1), Vector2i(1, 1), Vector2i(1, 2), Vector2i(1, 2), Vector2i(1, 3), Vector2i(1, 3), Vector2i(1, 4), Vector2i(1, 4)],
		"hull_pattern": [Vector2i(1, 2), Vector2i(1, 2)],
		"hull_curvature": HullCurvature.STRAIGHT_HORIZONTAL,
		"is_corner": false,
		"corner_type": null,
		"is_atomic": true,
	},

	"Left Edge Straight (Desert)": {
		"index": 42,
		"atlas_coords": [Vector2i(0, 1), Vector2i(1, 1), Vector2i(0, 1), Vector2i(1, 1)],
		"hull_pattern": [Vector2i(0, 1), Vector2i(0, 1)],
		"hull_curvature": HullCurvature.STRAIGHT_VERTCAL,
		"is_corner": false,
		"corner_type": null,
		"is_atomic": true,
	},

	"Right Edge Straight (Desert)": {
		"index": 43,
		"atlas_coords": [Vector2i(1, 1), Vector2i(2, 1), Vector2i(1, 1), Vector2i(2, 1)],
		"hull_pattern": [Vector2i(2, 1), Vector2i(2, 1)],
		"hull_curvature": HullCurvature.STRAIGHT_VERTCAL,
		"is_corner": false,
		"corner_type": null,
		"is_atomic": true,
	},

	"Ground Plate (Desert)": {
		"index": 44,
		"atlas_coords": [Vector2i(1, 1), Vector2i(1, 1), Vector2i(1, 1), Vector2i(1, 1)],
		"hull_pattern": [],
		"hull_curvature": HullCurvature.NO_HULL,
		"is_corner": false,
		"corner_type": CornerType.NO_CORNER,
		"is_atomic": true,
	},

	"Upper Left Corner (Cave)": {
		"index": 45,
		"atlas_coords": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)],
		"hull_pattern": [Vector2i(0, 1), Vector2i(1, 1)],
		"hull_curvature": HullCurvature.LEFT,
		"is_corner": true,
		"corner_type": CornerType.UL,
		"is_atomic": true,
	},

	"Upper Right Corner (Cave)": {
		"index": 46,
		"atlas_coords": [Vector2i(1, 0), Vector2i(2, 0), Vector2i(1, 1), Vector2i(2, 1)],
		"hull_pattern": [Vector2i(1, 1), Vector2i(2, 1)],
		"hull_curvature": HullCurvature.RIGHT,
		"is_corner": true,
		"corner_type": CornerType.UR,
		"is_atomic": true,
	},

	"Lower Left Corner (Cave)": {
		"index": 47,
		"atlas_coords": [Vector2i(0, 1), Vector2i(1, 1), Vector2i(0, 2), Vector2i(1, 2), Vector2i(0, 3), Vector2i(1, 3), Vector2i(0, 4), Vector2i(1, 4)],
		"hull_pattern": [Vector2i(0, 2), Vector2i(1, 2)],
		"hull_curvature": HullCurvature.LEFT,
		"is_corner": true,
		"corner_type": CornerType.LL,
		"is_atomic": true,
	},

	"Lower Right Corner (Cave)": {
		"index": 48,
		"atlas_coords": [Vector2i(1, 1), Vector2i(2, 1), Vector2i(1, 2), Vector2i(2, 2), Vector2i(1, 3), Vector2i(2, 3), Vector2i(1, 4), Vector2i(2, 4)],
		"hull_pattern": [Vector2i(1, 2), Vector2i(2, 2)],
		"hull_curvature": HullCurvature.RIGHT,
		"is_corner": true,
		"corner_type": CornerType.LR,
		"is_atomic": true,
	},

	"Top Edge Straight (Cave)": {
		"index": 49,
		"atlas_coords": [Vector2i(1, 0), Vector2i(1, 0), Vector2i(1, 1), Vector2i(1, 1)],
		"hull_pattern": [Vector2i(1, 0), Vector2i(1, 0)],
		"hull_curvature": HullCurvature.STRAIGHT_HORIZONTAL,
		"is_corner": false,
		"corner_type": null,
		"is_atomic": true,
	},

	"Bottom Edge Straight (Cave)": {
		"index": 50,
		"atlas_coords": [Vector2i(1, 1), Vector2i(1, 1), Vector2i(1, 2), Vector2i(1, 2), Vector2i(1, 3), Vector2i(1, 3), Vector2i(1, 4), Vector2i(1, 4)],
		"hull_pattern": [Vector2i(1, 2), Vector2i(1, 2)],
		"hull_curvature": HullCurvature.STRAIGHT_HORIZONTAL,
		"is_corner": false,
		"corner_type": null,
		"is_atomic": true,
	},

	"Left Edge Straight (Cave)": {
		"index": 51,
		"atlas_coords": [Vector2i(0, 1), Vector2i(1, 1), Vector2i(0, 1), Vector2i(1, 1)],
		"hull_pattern": [Vector2i(0, 1), Vector2i(0, 1)],
		"hull_curvature": HullCurvature.STRAIGHT_VERTCAL,
		"is_corner": false,
		"corner_type": null,
		"is_atomic": true,
	},

	"Right Edge Straight (Cave)": {
		"index": 52,
		"atlas_coords": [Vector2i(1, 1), Vector2i(2, 1), Vector2i(1, 1), Vector2i(2, 1)],
		"hull_pattern": [Vector2i(2, 1), Vector2i(2, 1)],
		"hull_curvature": HullCurvature.STRAIGHT_VERTCAL,
		"is_corner": false,
		"corner_type": null,
		"is_atomic": true,
	},

	"Ground Plate (Cave)": {
		"index": 53,
		"atlas_coords": [Vector2i(1, 1), Vector2i(1, 1), Vector2i(1, 1), Vector2i(1, 1)],
		"hull_pattern": [],
		"hull_curvature": HullCurvature.NO_HULL,
		"is_corner": false,
		"corner_type": CornerType.NO_CORNER,
		"is_atomic": true,
	},

	"Upper Left Corner (Swamp)": {
		"index": 54,
		"atlas_coords": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)],
		"hull_pattern": [Vector2i(0, 1), Vector2i(1, 1)],
		"hull_curvature": HullCurvature.LEFT,
		"is_corner": true,
		"corner_type": CornerType.UL,
		"is_atomic": true,
	},

	"Upper Right Corner (Swamp)": {
		"index": 55,
		"atlas_coords": [Vector2i(1, 0), Vector2i(2, 0), Vector2i(1, 1), Vector2i(2, 1)],
		"hull_pattern": [Vector2i(1, 1), Vector2i(2, 1)],
		"hull_curvature": HullCurvature.RIGHT,
		"is_corner": true,
		"corner_type": CornerType.UR,
		"is_atomic": true,
	},

	"Lower Left Corner (Swamp)": {
		"index": 56,
		"atlas_coords": [Vector2i(0, 1), Vector2i(1, 1), Vector2i(0, 2), Vector2i(1, 2), Vector2i(0, 3), Vector2i(1, 3), Vector2i(0, 4), Vector2i(1, 4)],
		"hull_pattern": [Vector2i(0, 2), Vector2i(1, 2)],
		"hull_curvature": HullCurvature.LEFT,
		"is_corner": true,
		"corner_type": CornerType.LL,
		"is_atomic": true,
	},

	"Lower Right Corner (Swamp)": {
		"index": 57,
		"atlas_coords": [Vector2i(1, 1), Vector2i(2, 1), Vector2i(1, 2), Vector2i(2, 2), Vector2i(1, 3), Vector2i(2, 3), Vector2i(1, 4), Vector2i(2, 4)],
		"hull_pattern": [Vector2i(1, 2), Vector2i(2, 2)],
		"hull_curvature": HullCurvature.RIGHT,
		"is_corner": true,
		"corner_type": CornerType.LR,
		"is_atomic": true,
	},

	"Top Edge Straight (Swamp)": {
		"index": 58,
		"atlas_coords": [Vector2i(1, 0), Vector2i(1, 0), Vector2i(1, 1), Vector2i(1, 1)],
		"hull_pattern": [Vector2i(1, 0), Vector2i(1, 0)],
		"hull_curvature": HullCurvature.STRAIGHT_HORIZONTAL,
		"is_corner": false,
		"corner_type": null,
		"is_atomic": true,
	},

	"Bottom Edge Straight (Swamp)": {
		"index": 59,
		"atlas_coords": [Vector2i(1, 1), Vector2i(1, 1), Vector2i(1, 2), Vector2i(1, 2), Vector2i(1, 3), Vector2i(1, 3), Vector2i(1, 4), Vector2i(1, 4)],
		"hull_pattern": [Vector2i(1, 2), Vector2i(1, 2)],
		"hull_curvature": HullCurvature.STRAIGHT_HORIZONTAL,
		"is_corner": false,
		"corner_type": null,
		"is_atomic": true,
	},

	"Left Edge Straight (Swamp)": {
		"index": 60,
		"atlas_coords": [Vector2i(0, 1), Vector2i(1, 1), Vector2i(0, 1), Vector2i(1, 1)],
		"hull_pattern": [Vector2i(0, 1), Vector2i(0, 1)],
		"hull_curvature": HullCurvature.STRAIGHT_VERTCAL,
		"is_corner": false,
		"corner_type": null,
		"is_atomic": true,
	},

	"Right Edge Straight (Swamp)": {
		"index": 61,
		"atlas_coords": [Vector2i(1, 1), Vector2i(2, 1), Vector2i(1, 1), Vector2i(2, 1)],
		"hull_pattern": [Vector2i(2, 1), Vector2i(2, 1)],
		"hull_curvature": HullCurvature.STRAIGHT_VERTCAL,
		"is_corner": false,
		"corner_type": null,
		"is_atomic": true,
	},

	"Ground Plate (Swamp)": {
		"index": 62,
		"atlas_coords": [Vector2i(1, 1), Vector2i(1, 1), Vector2i(1, 1), Vector2i(1, 1)],
		"hull_pattern": [],
		"hull_curvature": HullCurvature.NO_HULL,
		"is_corner": false,
		"corner_type": CornerType.NO_CORNER,
		"is_atomic": true,
	},

	"Upper Left Corner (Seabed)": {
		"index": 63,
		"atlas_coords": [Vector2i(0, 5), Vector2i(1, 5), Vector2i(0, 6), Vector2i(1, 6)],
		"hull_pattern": [Vector2i(0, 6), Vector2i(1, 6)],
		"hull_curvature": HullCurvature.LEFT,
		"is_corner": true,
		"corner_type": CornerType.UL,
		"is_atomic": true,
	},

	"Upper Right Corner (Seabed)": {
		"index": 64,
		"atlas_coords": [Vector2i(1, 5), Vector2i(2, 5), Vector2i(1, 6), Vector2i(2, 6)],
		"hull_pattern": [Vector2i(1, 6), Vector2i(2, 6)],
		"hull_curvature": HullCurvature.RIGHT,
		"is_corner": true,
		"corner_type": CornerType.UR,
		"is_atomic": true,
	},

	"Lower Left Corner (Seabed)": {
		"index": 65,
		"atlas_coords": [Vector2i(0, 6), Vector2i(1, 6), Vector2i(0, 7), Vector2i(1, 7), Vector2i(0, 8), Vector2i(1, 8), Vector2i(0, 9), Vector2i(1, 9)],
		"hull_pattern": [Vector2i(0, 7), Vector2i(1, 7)],
		"hull_curvature": HullCurvature.LEFT,
		"is_corner": true,
		"corner_type": CornerType.LL,
		"is_atomic": true,
	},

	"Lower Right Corner (Seabed)": {
		"index": 66,
		"atlas_coords": [Vector2i(1, 6), Vector2i(2, 6), Vector2i(1, 7), Vector2i(2, 7), Vector2i(1, 8), Vector2i(2, 8), Vector2i(1, 9), Vector2i(2, 9)],
		"hull_pattern": [Vector2i(1, 7), Vector2i(2, 7)],
		"hull_curvature": HullCurvature.RIGHT,
		"is_corner": true,
		"corner_type": CornerType.LR,
		"is_atomic": true,
	},

	"Top Edge Straight (Seabed)": {
		"index": 67,
		"atlas_coords": [Vector2i(1, 5), Vector2i(1, 5), Vector2i(1, 6), Vector2i(1, 6)],
		"hull_pattern": [Vector2i(1, 5), Vector2i(1, 5)],
		"hull_curvature": HullCurvature.STRAIGHT_HORIZONTAL,
		"is_corner": false,
		"corner_type": null,
		"is_atomic": true,
	},

	"Bottom Edge Straight (Seabed)": {
		"index": 68,
		"atlas_coords": [Vector2i(1, 6), Vector2i(1, 6), Vector2i(1, 7), Vector2i(1, 7), Vector2i(1, 8), Vector2i(1, 8), Vector2i(1, 9), Vector2i(1, 9)],
		"hull_pattern": [Vector2i(1, 7), Vector2i(1, 7)],
		"hull_curvature": HullCurvature.STRAIGHT_HORIZONTAL,
		"is_corner": false,
		"corner_type": null,
		"is_atomic": true,
	},

	"Left Edge Straight (Seabed)": {
		"index": 69,
		"atlas_coords": [Vector2i(0, 6), Vector2i(1, 6), Vector2i(0, 6), Vector2i(1, 6)],
		"hull_pattern": [Vector2i(0, 6), Vector2i(0, 6)],
		"hull_curvature": HullCurvature.STRAIGHT_VERTCAL,
		"is_corner": false,
		"corner_type": null,
		"is_atomic": true,
	},

	"Right Edge Straight (Seabed)": {
		"index": 70,
		"atlas_coords": [Vector2i(1, 6), Vector2i(2, 6), Vector2i(1, 6), Vector2i(2, 6)],
		"hull_pattern": [Vector2i(2, 6), Vector2i(2, 6)],
		"hull_curvature": HullCurvature.STRAIGHT_VERTCAL,
		"is_corner": false,
		"corner_type": null,
		"is_atomic": true,
	},

	"Ground Plate (Seabed)": {
		"index": 71,
		"atlas_coords": [Vector2i(1, 6), Vector2i(1, 6), Vector2i(1, 6), Vector2i(1, 6)],
		"hull_pattern": [],
		"hull_curvature": HullCurvature.NO_HULL,
		"is_corner": false,
		"corner_type": CornerType.NO_CORNER,
		"is_atomic": true,
	},

	"Upper Left Corner (Rocks and Water)": {
		"index": 72,
		"atlas_coords": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)],
		"hull_pattern": [Vector2i(0, 1), Vector2i(1, 1)],
		"hull_curvature": HullCurvature.LEFT,
		"is_corner": true,
		"corner_type": CornerType.UL,
		"is_atomic": true,
	},

	"Upper Right Corner (Rocks and Water)": {
		"index": 73,
		"atlas_coords": [Vector2i(1, 0), Vector2i(2, 0), Vector2i(1, 1), Vector2i(2, 1)],
		"hull_pattern": [Vector2i(1, 1), Vector2i(2, 1)],
		"hull_curvature": HullCurvature.RIGHT,
		"is_corner": true,
		"corner_type": CornerType.UR,
		"is_atomic": true,
	},

	"Lower Left Corner (Rocks and Water)": {
		"index": 74,
		"atlas_coords": [Vector2i(0, 1), Vector2i(1, 1), Vector2i(0, 2), Vector2i(1, 2), Vector2i(0, 3), Vector2i(1, 3), Vector2i(0, 4), Vector2i(1, 4)],
		"hull_pattern": [Vector2i(0, 2), Vector2i(1, 2)],
		"hull_curvature": HullCurvature.LEFT,
		"is_corner": true,
		"corner_type": CornerType.LL,
		"is_atomic": true,
	},

	"Lower Right Corner (Rocks and Water)": {
		"index": 75,
		"atlas_coords": [Vector2i(1, 1), Vector2i(2, 1), Vector2i(1, 2), Vector2i(2, 2), Vector2i(1, 3), Vector2i(2, 3), Vector2i(1, 4), Vector2i(2, 4)],
		"hull_pattern": [Vector2i(1, 2), Vector2i(2, 2)],
		"hull_curvature": HullCurvature.RIGHT,
		"is_corner": true,
		"corner_type": CornerType.LR,
		"is_atomic": true,
	},

	"Top Edge Straight (Rocks and Water)": {
		"index": 76,
		"atlas_coords": [Vector2i(1, 0), Vector2i(1, 0), Vector2i(1, 1), Vector2i(1, 1)],
		"hull_pattern": [Vector2i(1, 0), Vector2i(1, 0)],
		"hull_curvature": HullCurvature.STRAIGHT_HORIZONTAL,
		"is_corner": false,
		"corner_type": null,
		"is_atomic": true,
	},

	"Bottom Edge Straight (Rocks and Water)": {
		"index": 77,
		"atlas_coords": [Vector2i(1, 1), Vector2i(1, 1), Vector2i(1, 2), Vector2i(1, 2), Vector2i(1, 3), Vector2i(1, 3), Vector2i(1, 4), Vector2i(1, 4)],
		"hull_pattern": [Vector2i(1, 2), Vector2i(1, 2)],
		"hull_curvature": HullCurvature.STRAIGHT_HORIZONTAL,
		"is_corner": false,
		"corner_type": null,
		"is_atomic": true,
	},

	"Left Edge Straight (Rocks and Water)": {
		"index": 78,
		"atlas_coords": [Vector2i(0, 1), Vector2i(1, 1), Vector2i(0, 1), Vector2i(1, 1)],
		"hull_pattern": [Vector2i(0, 1), Vector2i(0, 1)],
		"hull_curvature": HullCurvature.STRAIGHT_VERTCAL,
		"is_corner": false,
		"corner_type": null,
		"is_atomic": true,
	},

	"Right Edge Straight (Rocks and Water)": {
		"index": 79,
		"atlas_coords": [Vector2i(1, 1), Vector2i(2, 1), Vector2i(1, 1), Vector2i(2, 1)],
		"hull_pattern": [Vector2i(2, 1), Vector2i(2, 1)],
		"hull_curvature": HullCurvature.STRAIGHT_VERTCAL,
		"is_corner": false,
		"corner_type": null,
		"is_atomic": true,
	},

	"Ground Plate (Rocks and Water)": {
		"index": 80,
		"atlas_coords": [Vector2i(1, 1), Vector2i(1, 1), Vector2i(1, 1), Vector2i(1, 1)],
		"hull_pattern": [],
		"hull_curvature": HullCurvature.NO_HULL,
		"is_corner": false,
		"corner_type": CornerType.NO_CORNER,
		"is_atomic": true,
	},


}
""" 
	"Plateau 1x1 (High Plateau Rocks)": {
		"index": 10,
		"pattern": [
			Vector2i(6, 8)
		],
		"is_corner": false,
		"corner_type": null,
		"is_atomic": false,
	},

	"Bridge Top (High Plateau Rocks)": {
		"index": 11,
		"pattern": [
			Vector2i(4, 4),
		],
		"is_corner": false,
		"corner_type": null,
		"is_atomic": true,
	},

	"Bridge Bottom (High Plateau Rocks)": {
		"index": 12,
		"pattern": [
			Vector2i(4, 2),
		],
		"is_corner": false,
		"corner_type": null,
		"is_atomic": true,
	},

	"Bridge Middle (High Plateau Rocks)": {
		"index": 13, 
		"pattern": [
			Vector2i(4, 2),
		],
		"is_corner": false,
		"corner_type": null,
		"is_atomic": true,
	},

	"Diagonal Down (High Plateau Rocks)": {
		"index": 14,
		"pattern": [
			Vector2i(4, 6),
		],
		"is_corner": false,
		"corner_type": null,
		"is_atomic": true,
	},

	"Diagonal Up (High Plateau Rocks)": {
		"index": 15,
		"pattern": [
			Vector2i(4, 6),
		],
		"is_corner": false,
		"corner_type": null,
		"is_atomic": true,
	},
"""

static func get_pattern_index(pattern_name: String) -> Variant:
	if pattern_name in dictionary.keys():
		return dictionary[pattern_name]["index"]
	else:
		return null

static func get_hull_pattern(pattern_name: String) -> Array:
	if pattern_name in dictionary.keys():
		return dictionary[pattern_name]["hull_pattern"]
	else:
		return []
	

static func is_corner(pattern_name: String) -> Variant:
	if pattern_name in dictionary.keys():
		return dictionary[pattern_name]["is_corner"]
	else:
		return null	

static func is_atomic(pattern_name: String) -> Variant:
	if pattern_name in dictionary.keys():
		return dictionary[pattern_name]["is_atomic"]
	else:
		return null	

static func get_atlas_coords(pattern_name: String) -> Array:
	if pattern_name in dictionary.keys():
		return dictionary[pattern_name]["atlas_coords"]
	else:
		return []
