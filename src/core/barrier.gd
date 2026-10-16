# barrier.gd
class_name Barrier

# Polygon (Liste von Punkten)
var polygon: Array[Vector2] = []

# Biom der Barriere (für Textur-Auswahl)
var biome: String = ""

# Öffnungen in dieser Barriere
var openings: Array = []


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

# --- Öffnungsverwaltung ---
func add_opening(p_opening: Opening) -> void:
    """Fügt eine Öffnung zur Barriere hinzu."""
    openings.append(p_opening)

func has_interactive_openings() -> bool:
    """Prüft, ob die Barriere interaktive Öffnungen hat."""
    for opening in openings:
        if opening.is_interactive:
            return true
    return false

func get_passable_points(chunk_size: int = 32) -> Array[Vector2]:
    """Gibt alle passierbaren Punkte der Barriere zurück (Öffnungen)."""
    var passable_points := []
    
    for opening in openings:
        if opening.is_passable():
            var start_x := int(opening.position.x - opening.width / 2)
            var end_x := int(opening.position.x + opening.width / 2)
            var y := int(opening.position.y)
            
            for x in range(start_x, end_x + 1):
                if x >= 0 and x < chunk_size and y >= 0 and y < chunk_size:
                    passable_points.append(Vector2(x, y))
    
    return passable_points

func contains_point(p_point: Vector2) -> bool:
    """Prüft, ob ein Punkt innerhalb des Polygons liegt (Ray-Casting).
    
    Berücksichtigt auch Öffnungen - Punkte in Öffnungen gelten als NICHT in der Barriere.
    """
    # Prüfe zuerst, ob der Punkt in einer Öffnung liegt
    for opening in openings:
        if opening.is_passable():
            var start_x := int(opening.position.x - opening.width / 2)
            var end_x := int(opening.position.x + opening.width / 2)
            var y := int(opening.position.y)
            
            if p_point.x >= start_x and p_point.x <= end_x and p_point.y >= y - 0.5 and p_point.y <= y + 0.5:
                return false
    
    # Standard Ray-Casting-Algorithmus
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