# barrier.gd
class_name Barrier

# Polygon (Liste von Punkten)
var polygon: Array[Vector2] = []


# --- Hilfsfunktionen ---
func contains_point(p_point: Vector2) -> bool:
    """Prüft, ob ein Punkt innerhalb des Polygons liegt (Ray-Casting)."""
    var inside := false
    var n := polygon.size()

    for i in range(n):
        var j := (i + 1) % n
        var xi := polygon[i].x
        var yi := polygon[i].y
        var xj := polygon[j].x
        var yj := polygon[j].y

        # Prüfe, ob der Ray (von Punkt nach rechts) die Kante schneidet
        var intersect := ((yi > p_point.y) != (yj > p_point.y)) and \
                        (p_point.x < (xj - xi) * (p_point.y - yi) / (yj - yi) + xi)
        if intersect:
            inside = not inside

    return inside

func is_polygon_closed() -> bool:
    """Prüft, ob das Polygon geschlossen ist (erster = letzter Punkt)."""
    if polygon.size() < 3:
        return false
    return polygon[0].distance_to(polygon[-1]) < 0.001