# level.gd
class_name Level

# Level-Parameter
var width: int
var height: int
var chunk_size: int
var tile_size: int
var world_seed: int

# Chunks (2D-Array)
var chunks: Array = []

# --- Initialisierung ---
func _init(p_width: int, p_height: int, p_chunk_size: int, p_tile_size: int, p_world_seed: int):
	width = p_width
	height = p_height
	chunk_size = p_chunk_size
	tile_size = p_tile_size
	world_seed = p_world_seed

# --- Level generieren ---
func generate() -> void:
	"""Generiert alle Chunks für das Level."""
	# Seed für Determinismus setzen
	seed_random(world_seed)

	for x in range(width):
		chunks.append([])
		for y in range(height):
			chunks[x].append(generate_chunk(x, y))

func generate_chunk(p_x: int, p_y: int) -> Chunk:
	"""Generiert einen einzelnen Chunk."""
	var chunk := Chunk.new(p_x, p_y)

	# Biom für den Chunk generieren (vereinfacht für Prototyp)
	chunk.biome = _get_biome_for_chunk(p_x, p_y)

	# Barrieren für den Chunk generieren (LEN-5)
	var barriers := generate_barriers_for_chunk(p_x, p_y, chunk.biome)
	for barrier in barriers:
		chunk.barriers.append(barrier)
	
	# Barrieren in Kacheln umsetzen
	chunk.apply_barriers_to_tiles()

	return chunk

func _get_biome_for_chunk(p_x: int, p_y: int) -> String:
	"""Gibt ein Biom für den Chunk zurück (vereinfacht für Prototyp)."""
	# Deterministisch basierend auf Seed + Koordinaten
	var hash_val := hash([p_x, p_y, world_seed])
	var biome_index : int = abs(hash_val) % 5  # 5 Biome
	var biomes := ["Grasland", "Wald", "Fels", "Wasser", "Sand"]
	return biomes[biome_index]

# --- Chunk-Zugriff ---
func get_chunk(p_x: int, p_y: int) -> Chunk:
	"""Gibt den Chunk an der Position (x, y) zurück."""
	if p_x >= 0 and p_x < width and p_y >= 0 and p_y < height:
		return chunks[p_x][p_y]
	return null

# --- Hilfsfunktionen ---
func hash(arr: Array) -> int:
	"""Einfache Hash-Funktion für Determinismus."""
	var result := 0
	for item in arr:
		result = (result * 31 + item) % 2147483647
	return result

func seed_random(p_world_seed: int) -> void:
	randomize()
	seed(p_world_seed)


# --- Barrieren-Generierung (LEN-5) ---

func generate_barriers_for_chunk(p_x: int, p_y: int, p_biome: String) -> Array:
	"""Generiert Barrieren für einen Chunk basierend auf Biom und Seed."""
	var barriers := []
	
	# Seed für diesen Chunk setzen (deterministisch)
	var chunk_seed := hash([p_x, p_y, world_seed, "barriers"])
	seed_random(chunk_seed)
	
	# Anzahl der Barrieren pro Biom
	var num_barriers := _get_barrier_count_for_biome(p_biome)
	
	for i in range(num_barriers):
		# 1. Zufallspunkte generieren
		var points := _generate_random_points(p_biome, self.chunk_size)
		
		if points.size() < 3:
			continue  # Nicht genug Punkte für ein Polygon
		
		# 2. Convex Hull berechnen
		var hull := _compute_convex_hull(points)
		
		if hull.size() < 3:
			continue  # Kein gültiges Polygon
		
		# 3. Perturbation für organische Formen
		hull = _perturb_hull(hull)
		
		# 4. Öffnungen platzieren
		var num_openings := _get_opening_count_for_biome(p_biome)
		
		for j in range(num_openings):
			var opening_type := _get_random_opening_type(p_biome)
			var opening_width := _get_opening_width(opening_type)
			var _is_interactive := opening_type == Opening.OpeningType.TUER
			
			var opening_pos := _find_opening_position(hull)
			if opening_pos != null:
				hull = _place_opening_in_hull(hull, opening_pos, opening_width)
		
		# 5. Barriere erstellen
		var barrier := Barrier.new()
		barrier.polygon = hull
		barrier.biome = p_biome
		barriers.append(barrier)
	
	return barriers


func _get_barrier_count_for_biome(p_biome: String) -> int:
	"""Gibt die Anzahl der Barrieren für ein Biom zurück."""
	match p_biome:
		"Grasland": return randi_range(1, 2)
		"Wald": return randi_range(3, 5)
		"Fels": return randi_range(5, 8)
		"Wasser": return randi_range(0, 1)
		"Sand": return randi_range(1, 2)
		_: return randi_range(1, 3)


func _get_opening_count_for_biome(p_biome: String) -> int:
	"""Gibt die Anzahl der Öffnungen pro Barriere für ein Biom zurück."""
	match p_biome:
		"Grasland": return randi_range(1, 3)
		"Wald": return randi_range(1, 2)
		"Fels": return randi_range(0, 1)
		"Wasser": return 1
		"Sand": return randi_range(1, 3)
		_: return randi_range(1, 2)


func _get_random_opening_type(p_biome: String) -> int:
	"""Gibt einen zufälligen Öffnungstyp für ein Biom zurück."""
	var opening_types := []
	
	match p_biome:
		"Grasland":
			opening_types = [Opening.OpeningType.FURT, Opening.OpeningType.FURT, 
						   Opening.OpeningType.PASS, Opening.OpeningType.PASS, 
						   Opening.OpeningType.TREPPE]
		"Wald":
			opening_types = [Opening.OpeningType.PASS, Opening.OpeningType.PASS, 
						   Opening.OpeningType.PASS, Opening.OpeningType.FURT, 
						   Opening.OpeningType.TUER]
		"Fels":
			opening_types = [Opening.OpeningType.PASS, Opening.OpeningType.PASS, 
						   Opening.OpeningType.PASS, Opening.OpeningType.TREPPE, 
						   Opening.OpeningType.TREPPE]
		"Wasser":
			opening_types = [Opening.OpeningType.FURT]
		"Sand":
			opening_types = [Opening.OpeningType.PASS, Opening.OpeningType.PASS, 
						   Opening.OpeningType.PASS, Opening.OpeningType.PASS, 
						   Opening.OpeningType.FURT]
		_:
			opening_types = [Opening.OpeningType.PASS]
	
	return opening_types[randi() % opening_types.size()]


func _get_opening_width(p_opening_type: int) -> int:
	"""Gibt die Breite einer Öffnung basierend auf dem Typ zurück."""
	match p_opening_type:
		Opening.OpeningType.TREPPE: return randi_range(2, 3)
		Opening.OpeningType.TUER: return 1
		Opening.OpeningType.FURT: return randi_range(2, 4)
		Opening.OpeningType.PASS: return randi_range(3, 5)
		_: return 1


func _generate_random_points(p_biome: String, p_chunk_size: int = 32) -> Array:
	"""Generiert Zufallspunkte für die Barrieren-Generierung."""
	var points := []
	var num_points := 0
	
	# Biom-abhängige Anzahl von Punkten
	match p_biome:
		"Grasland": num_points = randi_range(5, 8)
		"Wald": num_points = randi_range(8, 12)
		"Fels": num_points = randi_range(10, 15)
		"Wasser": num_points = randi_range(5, 10)
		"Sand": num_points = randi_range(5, 8)
		_: num_points = randi_range(5, 10)
	
	# Punkte im inneren Bereich generieren (nicht am Rand)
	var margin := 2
	
	for i in range(num_points):
		var x := randi_range(margin, p_chunk_size - margin - 1)
		var y := randi_range(margin, p_chunk_size - margin - 1)
		
		# Mindestabstand zu anderen Punkten prüfen
		var valid := true
		for point in points:
			if point.distance_to(Vector2(x, y)) < 2:
				valid = false
				break
		
		if valid:
			points.append(Vector2(x, y))
	
	return points


func _compute_convex_hull(p_points: Array) -> Array:
	"""Berechnet die Convex Hull aus einer Menge von Punkten (Graham-Scan)."""
	if p_points.size() <= 2:
		return p_points.duplicate()
	
	# 1. Finde den Punkt mit der niedrigsten y-Koordinate (und links bei Gleichstand)
	var p0 = p_points[0]
	for point in p_points:
		if point.y < p0.y or (point.y == p0.y and point.x < p0.x):
			p0 = point
	
	# 2. Sortiere Punkte nach Polarwinkel zu p0
	var sorted_points := []
	for point in p_points:
		if point != p0:
			sorted_points.append(point)
	
	sorted_points.sort_custom(func(a, b):
		var angle_a := atan2(a.y - p0.y, a.x - p0.x)
		var angle_b := atan2(b.y - p0.y, b.x - p0.x)
		if angle_a < angle_b:
			return true
		elif angle_a > angle_b:
			return false
		else:
			return a.distance_to(p0) < b.distance_to(p0)
	)
	
	# 3. Graham-Scan
	var hull := [p0, sorted_points[0], sorted_points[1]]
	
	for i in range(2, sorted_points.size()):
		var p = sorted_points[i]
		while hull.size() >= 2:
			var top = hull[-1]
			var next_to_top = hull[-2]
			
			# Berechne den Winkel zwischen next_to_top -> top -> p
			var cross = (top.x - next_to_top.x) * (p.y - top.y) - (top.y - next_to_top.y) * (p.x - top.x)
			if cross > 0:  # Linkskurve (konvex)
				break
			else:
				hull.pop_back()
		hull.append(p)
	
	return hull


func _perturb_hull(p_hull: Array, p_perturbation: int = 1) -> Array:
	"""Verschiebt Punkte der Convex Hull leicht für organischere Formen."""
	var perturbed_hull := []
	
	for point in p_hull:
		var x_offset := randi_range(-p_perturbation, p_perturbation)
		var y_offset := randi_range(-p_perturbation, p_perturbation)
		perturbed_hull.append(Vector2(point.x + x_offset, point.y + y_offset))
	
	return perturbed_hull


func _find_opening_position(p_hull: Array) -> Vector2:
	"""Findet eine gültige Position für eine Öffnung in der Barriere."""
	var valid_edges := _find_valid_edges(p_hull)
	
	if valid_edges.size() == 0:
		return Vector2.ZERO
	
	# Zufällige Kante auswählen
	var edge_idx := randi() % valid_edges.size()
	var edge = valid_edges[edge_idx]
	var p1 = edge[0]
	var p2 = edge[1]
	
	# Mittelpunkt der Kante
	return Vector2((p1.x + p2.x) / 2.0, (p1.y + p2.y) / 2.0)


func _find_valid_edges(p_hull: Array, p_chunk_size: int = 32) -> Array:
	"""Findet gültige Kanten für Öffnungen (nicht an Chunk-Grenzen)."""
	var valid_edges := []
	var n := p_hull.size()
	
	for i in range(n):
		var j := (i + 1) % n
		var edge := [p_hull[i], p_hull[j]]
		
		# Prüfe, ob die Kante an einer Chunk-Grenze liegt
		var is_at_border := false
		for point in edge:
			if point.x <= 0 or point.x >= p_chunk_size - 1 or point.y <= 0 or point.y >= p_chunk_size - 1:
				is_at_border = true
				break
		
		if not is_at_border:
			valid_edges.append(edge)
	
	return valid_edges


func _place_opening_in_hull(p_hull: Array, p_midpoint: Vector2, p_width: int) -> Array:
	"""Platziert eine Öffnung in der Hull durch Entfernen von Punkten."""
	var new_hull := []
	
	for point in p_hull:
		# Prüfe, ob der Punkt in der Nähe des Mittelpunkts liegt
		var distance = point.distance_to(p_midpoint)
		if distance < p_width * 0.5 + 0.5:
			continue  # Punkt entfernen (Öffnung)
		new_hull.append(point)
	
	# Falls die Hull zu klein wird, füge die ursprünglichen Punkte wieder hinzu
	if new_hull.size() < 3:
		return p_hull
	
	return new_hull
