# Barrieren-System für Lennox

## Übersicht

Barrieren sind **geschlossene Hindernisse** in der Spielwelt, die den Spieler am Durchkommen hindern, es sei denn, er nutzt eine **Öffnung** (z.B. Treppe, Tür, Furt). Barrieren können verschiedene Formen und Typen haben und sind **biom-abhängig**.

---

## Barrieren-Typen

| Typ          | Beschreibung                                                                 | Kachel-Textur       | Kollisionsverhalten       | Innenfläche       |
|--------------|-----------------------------------------------------------------------------|---------------------|---------------------------|-------------------|
| Fels         | Natürliche Felsformationen (z.B. Berge, Klippen).                          | Fels-Texture        | Blockierend               | Fels              |
| Baumgruppe   | Gruppe von Bäumen, die eine Barriere bilden.                              | Baum-Texture        | Blockierend               | Wald              |
| Düne         | Sandhügel in Wüsten- oder Strandregionen.                                  | Sand-Texture        | Blockierend               | Sand              |
| Insel        | Landmasse in Wasser-Biomen (umgekehrte Logik).                             | Gras/Fels-Texture   | Blockierend (Wasser)      | Gras/Fels         |
| Wand         | Künstliche Barriere (z.B. für Gebäude oder Höhlen).                       | Stein-Texture       | Blockierend               | Innenraum         |

---

## Algorithmus: Barrieren-Generierung

### 1. Convex Hull + Perturbation

#### Schritt 1: Zufallspunkte generieren
- Pro Chunk: **5–15 Zufallspunkte** im **inneren Bereich** (nicht am Rand).
- **Abstand:** Mindestens 2 Kacheln zwischen Punkten, um zu kleine Barrieren zu vermeiden.
- **Biom-abhängige Anzahl:**
  - Grasland: 5–8 Punkte
  - Wald: 8–12 Punkte
  - Fels: 10–15 Punkte

```gdscript
func generate_random_points(chunk_x: int, chunk_y: int, biome: String, chunk_size: int = 32) -> Array[Vector2]:
    var points = []
    var num_points = 0
    
    # Biom-abhängige Anzahl von Punkten
    match biome:
        "Grasland": num_points = randi_range(5, 8)
        "Wald": num_points = randi_range(8, 12)
        "Fels": num_points = randi_range(10, 15)
        "Wasser": num_points = randi_range(5, 10)
        "Sand": num_points = randi_range(5, 8)
        _: num_points = 8
    
    # Punkte im inneren Bereich generieren (nicht am Rand)
    var margin = 2  # 2 Kacheln Rand
    for i in range(num_points):
        var x = randi_range(margin, chunk_size - margin - 1)
        var y = randi_range(margin, chunk_size - margin - 1)
        
        # Mindestabstand zu anderen Punkten prüfen
        var valid = true
        for point in points:
            if point.distance_to(Vector2(x, y)) < 2:
                valid = false
                break
        
        if valid:
            points.append(Vector2(x, y))
    
    return points
```

#### Schritt 2: Convex Hull berechnen
- **Ziel:** Kleinstes konvexes Polygon, das alle Punkte umschließt.
- **Algorithmus:** Graham-Scan (einfach zu implementieren).

```gdscript
func compute_convex_hull(points: Array[Vector2]) -> Array[Vector2]:
    if points.size() <= 2:
        return points.duplicate()
    
    # 1. Finde den Punkt mit der niedrigsten y-Koordinate (und links bei Gleichstand)
    var p0 = points[0]
    for point in points:
        if point.y < p0.y or (point.y == p0.y and point.x < p0.x):
            p0 = point
    
    # 2. Sortiere Punkte nach Polarwinkel zu p0
    var sorted_points = []
    for point in points:
        if point != p0:
            sorted_points.append(point)
    
    sorted_points.sort_custom(func(a, b):
        var angle_a = atan2(a.y - p0.y, a.x - p0.x)
        var angle_b = atan2(b.y - p0.y, b.x - p0.x)
        if angle_a < angle_b:
            return true
        elif angle_a > angle_b:
            return false
        else:
            return a.distance_to(p0) < b.distance_to(p0)
    )
    
    # 3. Graham-Scan
    var hull = [p0, sorted_points[0], sorted_points[1]]
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
```

#### Schritt 3: Perturbation für organische Formen
- **Ziel:** Natürlichere, weniger geometrische Barrieren.
- **Methode:** Jeden Punkt der Convex Hull leicht verschieben.

```gdscript
func perturb_hull(hull: Array[Vector2], perturbation: int = 1) -> Array[Vector2]:
    var perturbed_hull = []
    for point in hull:
        var x_offset = randi_range(-perturbation, perturbation)
        var y_offset = randi_range(-perturbation, perturbation)
        perturbed_hull.append(Vector2(point.x + x_offset, point.y + y_offset))
    return perturbed_hull
```

### 2. Barriere als Kacheln umsetzen
- **Alle Kacheln innerhalb des Polygons** werden zu **Barrieren-Kacheln**.
- **Methode:** Point-in-Polygon-Test für jede Kachel im Chunk.

```gdscript
func generate_barrier_tiles(hull: Array[Vector2], chunk_size: int = 32) -> Array:
    var barrier_tiles = []
    for x in range(chunk_size):
        barrier_tiles.append([])
        for y in range(chunk_size):
            # Point-in-Polygon-Test
            if is_point_in_polygon(Vector2(x, y), hull):
                barrier_tiles[x].append(true)  # Barriere-Kachel
            else:
                barrier_tiles[x].append(false) # Keine Barriere
    return barrier_tiles

func is_point_in_polygon(point: Vector2, polygon: Array[Vector2]) -> bool:
    var inside = false
    var n = polygon.size()
    for i in range(n):
        var j = (i + 1) % n
        var xi = polygon[i].x
        var yi = polygon[i].y
        var xj = polygon[j].x
        var yj = polygon[j].y
        
        # Ray-Casting-Algorithmus
        var intersect = ((yi > point.y) != (yj > point.y)) and \
                        (point.x < (xj - xi) * (point.y - yi) / (yj - yi) + xi)
        if intersect:
            inside = not inside
    return inside
```

---

## Öffnungen in Barrieren

### Öffnungs-Typen

| Typ       | Breite (Kacheln) | Beschreibung                          | Passierbar | Interaktiv | Textur          |
|-----------|------------------|---------------------------------------|------------|------------|-----------------|
| Treppe    | 2–3              | Schräge Kacheln für Höhenunterschiede | Ja         | Nein       | Treppen-Texture |
| Tür       | 1                | Einfache Lücke mit Tür-Objekt         | Ja         | **Ja**     | Tür-Texture     |
| Furt      | 2–4              | Wasser-Kacheln in der Barriere        | Ja         | Nein       | Wasser-Texture  |
| Pass      | 3–5              | Schmale Passage mit Fels-Kacheln      | Ja         | Nein       | Fels-Texture    |

### Öffnungen platzieren

#### Schritt 1: Öffnungs-Kandidaten finden
- **Kanten des Polygons** identifizieren.
- **Gültige Kanten:** Kanten, die **nicht an einer Chunk-Grenze** liegen.

```gdscript
func find_valid_edges(hull: Array[Vector2], chunk_size: int = 32) -> Array[Array]:
    var valid_edges = []
    var n = hull.size()
    for i in range(n):
        var j = (i + 1) % n
        var edge = [hull[i], hull[j]]
        
        # Prüfe, ob die Kante an einer Chunk-Grenze liegt
        var is_at_border = false
        for point in edge:
            if point.x == 0 or point.x == chunk_size - 1 or point.y == 0 or point.y == chunk_size - 1:
                is_at_border = true
                break
        
        if not is_at_border:
            valid_edges.append(edge)
    
    return valid_edges
```

#### Schritt 2: Öffnung in Kante platzieren
- **Zufällige Kante** auswählen.
- **Mittelpunkt der Kante** berechnen.
- **Lücke in der Barriere** erstellen (Breite = Öffnungsbreite).

```gdscript
func place_opening(hull: Array[Vector2], opening_type: String, opening_width: int) -> Array[Vector2]:
    var valid_edges = find_valid_edges(hull)
    if valid_edges.size() == 0:
        return hull  # Keine gültigen Kanten
    
    # Zufällige Kante auswählen
    var edge_idx = randi() % valid_edges.size()
    var edge = valid_edges[edge_idx]
    var p1 = edge[0]
    var p2 = edge[1]
    
    # Mittelpunkt der Kante
    var midpoint = Vector2((p1.x + p2.x) / 2, (p1.y + p2.y) / 2)
    
    # Richtung der Kante (senkrecht zur Kante)
    var dx = p2.x - p1.x
    var dy = p2.y - p1.y
    var length = sqrt(dx * dx + dy * dy)
    var nx = -dy / length  # Normale (senkrecht zur Kante)
    var ny = dx / length
    
    # Öffnungs-Punkte generieren (Lücke in der Barriere)
    var opening_points = []
    for i in range(opening_width):
        var offset = i - (opening_width - 1) / 2.0
        var x = midpoint.x + nx * offset
        var y = midpoint.y + ny * offset
        opening_points.append(Vector2(round(x), round(y)))
    
    # Öffnungs-Punkte aus der Hull entfernen (Lücke erstellen)
    var new_hull = []
    for point in hull:
        var is_in_opening = false
        for op in opening_points:
            if point.distance_to(op) < 0.5:
                is_in_opening = true
                break
        if not is_in_opening:
            new_hull.append(point)
    
    return new_hull
```

#### Schritt 3: Öffnungs-Typ zufällig auswählen
- **Biom-abhängige Wahrscheinlichkeiten** (siehe [Biome-Dokumentation](biomes.md)).

```gdscript
func get_random_opening_type(biome: String) -> String:
    var opening_types = []
    match biome:
        "Grasland":
            opening_types = ["Furt", "Furt", "Pass", "Pass", "Treppe"]  # 50% Furt, 30% Pass, 20% Treppe
        "Wald":
            opening_types = ["Pass", "Pass", "Pass", "Furt", "Tür"]  # 60% Pass, 20% Furt, 20% Tür
        "Fels":
            opening_types = ["Pass", "Pass", "Pass", "Treppe", "Treppe"]  # 60% Pass, 40% Treppe
        "Wasser":
            opening_types = ["Furt"]  # Nur Furten
        "Sand":
            opening_types = ["Pass", "Pass", "Pass", "Pass", "Furt"]  # 80% Pass, 20% Furt
        _:
            opening_types = ["Pass"]
    
    return opening_types[randi() % opening_types.size()]
```

---

## Barrieren mit Öffnungen generieren

### Vollständiger Algorithmus pro Chunk

```gdscript
func generate_barriers_for_chunk(chunk_x: int, chunk_y: int, biome: String, seed: int) -> Array[Barrier]:
    var barriers = []
    var num_barriers = get_biome_params(biome)["barrier_count"]
    
    for i in range(num_barriers):
        # 1. Zufallspunkte generieren
        var points = generate_random_points(chunk_x, chunk_y, biome)
        
        # 2. Convex Hull berechnen
        var hull = compute_convex_hull(points)
        
        # 3. Perturbation anwenden
        hull = perturb_hull(hull)
        
        # 4. Öffnungen platzieren (falls gewünscht)
        var num_openings = get_biome_params(biome)["opening_count"]
        var opening_types = get_biome_params(biome)["opening_types"]
        
        for j in range(num_openings):
            var opening_type = opening_types[randi() % opening_types.size()]
            var opening_width = 0
            match opening_type:
                "Treppe": opening_width = randi_range(2, 3)
                "Tür": opening_width = 1
                "Furt": opening_width = randi_range(2, 4)
                "Pass": opening_width = randi_range(3, 5)
            
            hull = place_opening(hull, opening_type, opening_width)
        
        # 5. Barriere-Objekt erstellen
        var barrier = Barrier.new()
        barrier.polygon = hull
        barrier.biome = biome
        barrier.openings = []  # Wird später gefüllt
        barriers.append(barrier)
    
    return barriers
```

---

## Kollisionsabfrage in Godot

### TileMap-Konfiguration
- **Barrieren-Kacheln:**
  - **Kollisionslayer:** `Barrier`
  - **Kollisionsmask:** `Player`
- **Öffnungen:**
  - **Kein Kollisionslayer** (durchgängig).
- **Interaktive Öffnungen (Türen):**
  - **Kollisionslayer:** `Barrier` (standardmäßig gesperrt).
  - **Bei Interaktion:** Kollisionslayer auf `Passable` ändern.

### Beispiel: TileMap in Godot
```gdscript
# In der _ready()-Funktion der TileMap:
func _ready():
    # Kollisionslayer für Barrieren-Kacheln setzen
    set_collision_layer(1)  # Layer 1 = Barrier
    set_collision_mask(1)   # Mask 1 = Player
    
    # Barrieren-Kacheln haben Kollisionsform (z.B. RectangleShape2D)
    # Öffnungen haben keine Kollisionsform
```

### Spieler-Kollisionsabfrage
```gdscript
func _physics_process(delta):
    var collision = move_and_collide(velocity * delta)
    if collision:
        if collision.collider.is_in_group("Barrier"):
            # Spieler kann nicht durch Barrieren
            velocity = Vector2.ZERO
        elif collision.collider.is_in_group("Interactive"):
            # Interaktive Öffnung (z.B. Tür)
            if Input.is_action_just_pressed("interact"):
                collision.collider.open()  # Tür öffnen
```

---

## Beispiele

### Beispiel 1: Fels-Barriere mit Pass
- **Biom:** Fels
- **Barrieren-Polygon:** 12 Punkte (Convex Hull + Perturbation).
- **Öffnung:** 1 Pass (4 Kacheln breit).
- **Kacheln:**
  - Innerhalb des Polygons: Fels-Textur.
  - An der Öffnung: Leere Kacheln (durchgängig).

### Beispiel 2: Wald-Barriere mit Tür
- **Biom:** Wald
- **Barrieren-Polygon:** 10 Punkte (Baumgruppe).
- **Öffnung:** 1 Tür (1 Kachel breit, interaktiv).
- **Kacheln:**
  - Innerhalb des Polygons: Baum-Textur.
  - An der Tür: Tür-Textur (blockierend, bis geöffnet).

### Beispiel 3: Geschlossene Fels-Barriere
- **Biom:** Fels
- **Barrieren-Polygon:** 15 Punkte.
- **Öffnungen:** 0 (geschlossene Barriere).
- **Kacheln:**
  - Innerhalb des Polygons: Fels-Textur.
  - Keine Lücken (nicht passierbar).

---

## Erweiterungen

### 1. Komplexere Barrieren-Formen
- **Nicht-konvexe Polygone:** Algorithmen wie **Alpha Shapes** oder **Concave Hull** für organischere Formen.
- **Löcher in Barrieren:** Mehrere Polygone pro Barriere (z.B. eine Felsformation mit Höhle).

### 2. Dynamische Barrieren
- **Bewegliche Barrieren:** Z.B. rollende Felsbrocken oder schwingende Äste.
- **Zerbrechliche Barrieren:** Barrieren, die durch Spieleraktionen zerstört werden können.

### 3. Biom-spezifische Barrieren-Texturen
- **Fels:** Verschiedene Fels-Texturen (hell, dunkel, schroff).
- **Wald:** Verschiedene Baum-Typen (Eiche, Kiefer, etc.).

---

## Links

- [Convex Hull Algorithmen](https://en.wikipedia.org/wiki/Convex_hull_algorithms)
- [Point-in-Polygon-Algorithmus](https://en.wikipedia.org/wiki/Point_in_polygon)
- [Godot TileMap Tutorial](https://docs.godotengine.org/en/stable/tutorials/2d/procedural_geometry/tilemap.html)
- [Godot Kollisionslayer](https://docs.godotengine.org/en/stable/tutorials/physics/physics_intro.html)
