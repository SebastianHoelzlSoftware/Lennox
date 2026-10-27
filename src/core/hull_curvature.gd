class_name HullCurvature

enum Curvature {
	STRAIGHT_HORIZONTAL,
	STRAIGHT_VERTCAL,
	LEFT,
	RIGHT,
	NO_HULL
}

const STRAIGHT_HORIZONTAL: Curvature = Curvature.STRAIGHT_HORIZONTAL
const STRAIGHT_VERTCAL: Curvature = Curvature.STRAIGHT_VERTCAL
const LEFT: Curvature = Curvature.LEFT
const RIGHT: Curvature = Curvature.RIGHT
const NO_HULL: Curvature = Curvature.NO_HULL  # For inside tiles. maybe i remove this in future