# Level- und Chunk-Struktur für Lennox

## Übersicht

Dieses Dokument beschreibt die **Datenstrukturen und den Aufbau** von Levels und Chunks in Lennox. Die Map wird **prozedural generiert** und besteht aus **Chunks**, die jeweils **Biome, Barrieren und Öffnungen** enthalten.

---

## Level-Struktur

### Grundlegende Parameter

| Parameter          | Wert                     | Beschreibung                          |
|--------------------|--------------------------|--------------------------------------|
| **Level-Größe**    | 64x64 Chunks             | Gesamtgröße eines Levels              |
| **Chunk-Größe**    | 32x32 Kacheln            | Anzahl Kacheln pro Chunk              |
| **Kachelgröße**    | 32x32 Pixel              | Größe einer Kachel in Pixeln         |
| **Gesamtgröße**    | 2048x2048 Pixel          | 64 × 32 × 32 = 2048 Pixel pro Achse   |

### Level-Klasse (GDScript)

```gdscript
class_name Level

# Basisparameter
var width: int          # Anzahl Chunks in x-Richtung (64)
var height: int         # Anzahl Chunks in y-Richtung (64)
var chunk_size: int     # Kacheln pro Chunk (32)
var tile_size: int      # Pixel pro Kachel (32)
var seed: int           # Basis-Seed für Determinismus

# Chunks
var chunks: Array = []  # 2D-Array von Chunks (chunks[x][y])

# Hilfsfunktionen
func _init(p_width: int = 64, p_height: int = 64, p_chunk_size: int = 32, p_tile_size: int = 32, p_seed: int = 0):
    width = p_width
    height = p_height
    chunk_size = p_chunk_size
    tile_size = p_tile_size
    seed = p_seed
    chunks = []
    for x in range(width):
        chunks.append([])
        for y in range(height):
            chunks[x].append(null)

# Chunk abrufen oder generieren
func get_chunk(x: int, y: int) -> Chunk:
    if chunks[x][y] == null:
        chunks[x][y] = generate_chunk(x, y)
    return chunks[x][y]

# Level generieren
func generate() -> void:
    for x in range(width):
        for y in range(height):
            chunks[x][y] = generate_chunk(x, y)

# Chunk generieren (wird in Unterklassen implementiert)
func generate_chunk(x: int, y: int) -> Chunk:
    pass
```

---

## Chunk-Struktur

### Grundlegende Parameter

| Parameter      | Wert                     | Beschreibung                          |
|----------------|--------------------------|--------------------------------------|
| **x, y**       | int                      | Chunk-Koordinaten im Level           |
| **biome**      | String                   | Biom-Typ (z.B. "Grasland")            |
| **tiles**      | Array[Array]             | 2D-Array von Kachel-Typen (32x32)     |
| **barriers**   | Array[Barrier]           | Liste von Barrieren im Chunk          |

### Chunk-Klasse (GDScript)

```gdscript
class_name Chunk

# Position
var x: int
var y: int

# Biom
var biome: String

# Kacheln (2D-Array: tiles[x][y] = Kachel-Typ)
var tiles: Array = []

# Barrieren
var barriers: Array[Barrier] = []

# Hilfsfunktionen
func _init(p_x: int, p_y: int):
    x = p_x
    y = p_y
    tiles = []
    for i in range(32):  # chunk_size = 32
        tiles.append([])
        for j in range(32):
            tiles[i].append("Gras")  # Standard-Kachel

# Kachel-Typ abrufen
func get_tile(x: int, y: int) -> String:
    if x >= 0 and x < 32 and y >= 0 and y < 32:
        return tiles[x][y]
    return null

# Barriere an Position prüfen
func is_barrier(x: int, y: int) -> bool:
    for barrier in barriers:
        if barrier.contains_point(Vector2(x, y)):
            return true
    return false

# Öffnung an Position prüfen
func is_opening(x: int, y: int) -> bool:
    for barrier in barriers:
        if barrier.is_opening_at(Vector2(x, y)):
            return true
    return false
```

---

## Kachel-Typen

### Basis-Kacheln

| Kachel-Typ       | Beschreibung                          | Kollisionsverhalten | Textur          |
|------------------|---------------------------------------|----------------------|-----------------|
| Gras             | Standard-Kachel für Grasland.         | Keine Kollision      | gras.png        |
| Sand             | Standard-Kachel für Sand-Biome.       | Keine Kollision      | sand.png        |
| Wasser           | Standard-Kachel für Wasser-Biome.    | Kollision (Wasser)   | water.png       |
| Fels             | Standard-Kachel für Fels-Biome.       | Kollision            | rock.png        |
| Baum             | Kachel mit Baum (für Wald-Biome).    | Kollision            | tree.png        |

### Barrieren-Kacheln

| Kachel-Typ       | Beschreibung                          | Kollisionsverhalten | Textur          |
|------------------|---------------------------------------|----------------------|-----------------|
| Fels-Barriere    | Kachel innerhalb einer Fels-Barriere. | Kollision            | rock_barrier.png |
| Baum-Barriere    | Kachel innerhalb einer Baumgruppe.    | Kollision            | tree_barrier.png |
| Sand-Barriere    | Kachel innerhalb einer Düne.          | Kollision            | sand_barrier.png |

### Öffnungs-Kacheln

| Kachel-Typ       | Beschreibung                          | Kollisionsverhalten | Textur          |
|------------------|---------------------------------------|----------------------|-----------------|
| Treppe           | Kachel für Treppen-Öffnungen.          | Keine Kollision      | stairs.png      |
| Tür              | Kachel für Tür-Öffnungen.              | Kollision (interaktiv) | door.png       |
| Furt             | Kachel für Furt-Öffnungen.             | Keine Kollision      | water_shallow.png |
| Pass             | Kachel für Pass-Öffnungen.            | Keine Kollision      | pass.png        |

---

## Barrieren-Struktur

### Barrieren-Klasse (GDScript)

```gdscript
class_name Barrier

# Polygon (Liste von Punkten in Kachel-Koordinaten)
var polygon: Array[Vector2] = []

# Biom-Typ der Innenfläche
var biome: String

# Öffnungen in dieser Barriere
var openings: Array[Opening] = []

# Hilfsfunktionen
func contains_point(point: Vector2) -> bool:
    return is_point_in_polygon(point, polygon)

func is_opening_at(point: Vector2) -> bool:
    for opening in openings:
        if opening.contains_point(point):
            return true
    return false

func is_point_in_polygon(point: Vector2, polygon: Array[Vector2]) -> bool:
    # Ray-Casting-Algorithmus
    var inside = false
    var n = polygon.size()
    for i in range(n):
        var j = (i + 1) % n
        var xi = polygon[i].x
        var yi = polygon[i].y
        var xj = polygon[j].x
        var yj = polygon[j].y
        
        var intersect = ((yi > point.y) != (yj > point.y)) and \
                        (point.x < (xj - xi) * (point.y - yi) / (yj - yi) + xi)
        if intersect:
            inside = not inside
    return inside
```

---

## Öffnungs-Struktur

### Öffnungs-Klasse (GDScript)

```gdscript
class_name Opening

# Typ der Öffnung
var type: String  # "Treppe", "Tür", "Furt", "Pass"

# Position (Start-Kachel der Öffnung)
var position: Vector2

# Breite in Kacheln
var width: int

# Interaktiv? (z.B. für Türen)
var is_interactive: bool = false

# Hilfsfunktionen
func contains_point(point: Vector2) -> bool:
    # Prüfe, ob der Punkt innerhalb der Öffnung liegt
    var end_position = Vector2(position.x + width - 1, position.y)
    return (point.x >= position.x and point.x <= end_position.x and \
            point.y == position.y)

func open() -> void:
    if is_interactive:
        is_interactive = false
        # Kollisionslayer ändern (z.B. von "Barrier" zu "Passable")
        print("Öffnung geöffnet!")
```

---

## Generierungs-Ablauf

### 1. Level generieren

```gdscript
func generate_level(seed: int, width: int = 64, height: int = 64) -> Level:
    var level = Level.new(width, height, 32, 32, seed)
    
    # Seed für Determinismus setzen
    seed_random(seed)
    
    # 1. Biom-Karte generieren
    var biome_map = generate_biome_map(seed, width, height)
    
    # 2. Chunks generieren
    for x in range(width):
        for y in range(height):
            var chunk = generate_chunk(seed, x, y, biome_map[x][y])
            level.chunks[x][y] = chunk
    
    # 3. Chunk-Übergänge glätten (optional)
    smooth_chunk_transitions(level)
    
    return level
```

### 2. Chunk generieren

```gdscript
func generate_chunk(seed: int, x: int, y: int, biome: String) -> Chunk:
    var chunk = Chunk.new(x, y)
    chunk.biome = biome
    
    # 1. Biom-spezifische Parameter abrufen
    var biome_params = get_biome_params(biome)
    
    # 2. Barrieren generieren
    var num_barriers = biome_params["barrier_count"]
    for i in range(num_barriers):
        var barrier = generate_barrier(seed, x, y, biome)
        chunk.barriers.append(barrier)
    
    # 3. Kacheln aus Barrieren und Biom erstellen
    chunk.tiles = generate_tiles_from_barriers(chunk)
    
    return chunk
```

### 3. Kacheln aus Barrieren erstellen

```gdscript
func generate_tiles_from_barriers(chunk: Chunk) -> Array:
    var tiles = []
    for x in range(32):
        tiles.append([])
        for y in range(32):
            # Standard-Kachel basierend auf Biom
            var tile_type = get_base_tile_for_biome(chunk.biome)
            
            # Prüfe, ob die Kachel in einer Barriere liegt
            var is_barrier = false
            for barrier in chunk.barriers:
                if barrier.contains_point(Vector2(x, y)):
                    is_barrier = true
                    tile_type = get_barrier_tile_for_biome(chunk.biome)
                    break
            
            # Prüfe, ob die Kachel eine Öffnung ist
            if is_barrier:
                for barrier in chunk.barriers:
                    if barrier.is_opening_at(Vector2(x, y)):
                        tile_type = get_opening_tile_for_type(barrier.get_opening_at(Vector2(x, y)).type)
                        break
            
            tiles[x].append(tile_type)
    
    return tiles

func get_base_tile_for_biome(biome: String) -> String:
    match biome:
        "Grasland": return "Gras"
        "Wald": return "Gras"  # Wald hat Gras als Basis
        "Fels": return "Fels"
        "Wasser": return "Wasser"
        "Sand": return "Sand"
        _: return "Gras"

func get_barrier_tile_for_biome(biome: String) -> String:
    match biome:
        "Grasland": return "Fels-Barriere"
        "Wald": return "Baum-Barriere"
        "Fels": return "Fels-Barriere"
        "Wasser": return "Fels-Barriere"  # Inseln
        "Sand": return "Sand-Barriere"
        _: return "Fels-Barriere"

func get_opening_tile_for_type(opening_type: String) -> String:
    match opening_type:
        "Treppe": return "Treppe"
        "Tür": return "Tür"
        "Furt": return "Furt"
        "Pass": return "Pass"
        _: return "Pass"
```

---

## Chunk-Übergänge glätten

### Problem
- Barrieren an **Chunk-Grenzen** können unnatürlich aussehen, wenn sie abrupt enden.

### Lösung
1. **Barrieren nicht am Chunk-Rand platzieren:**
   - Barrieren nur im **inneren Bereich** (z.B. 2–28 Kacheln) generieren.
2. **Chunk-übergreifende Barrieren:**
   - Große Barrieren (z.B. Felsketten) können **mehrere Chunks überspannen**.
3. **Biom-Übergänge:**
   - Biome an Chunk-Grenzen **glätten** (z.B. mit Noise).

```gdscript
func smooth_chunk_transitions(level: Level) -> void:
    for x in range(level.width):
        for y in range(level.height):
            var chunk = level.chunks[x][y]
            
            # Prüfe Nachbar-Chunks
            for dx in [-1, 0, 1]:
                for dy in [-1, 0, 1]:
                    if dx == 0 and dy == 0:
                        continue
                    var nx = x + dx
                    var ny = y + dy
                    if nx >= 0 and nx < level.width and ny >= 0 and ny < level.height:
                        var neighbor = level.chunks[nx][ny]
                        # Glätte Biom-Übergänge
                        smooth_biome_transition(chunk, neighbor)
```

---

## Godot-Integration

### TileMap-Konfiguration

1. **TileSet erstellen:**
   - Alle Kachel-Typen (Gras, Fels, Wasser, etc.) als **Tiles** im TileSet definieren.
   - **Kollisionsformen** für Barrieren-Kacheln hinzufügen.

2. **TileMap in der Szene:**
   - Eine **TileMap** für die gesamte Level-Darstellung.
   - **Kollisionslayer:**
     - Barrieren-Kacheln: Layer `1` (Barrier)
     - Öffnungen: Kein Layer (durchgängig)
     - Wasser: Layer `2` (Wasser)

3. **Level in TileMap laden:**

```gdscript
func load_level_into_tilemap(level: Level, tile_map: TileMap) -> void:
    tile_map.clear()
    
    for x in range(level.width):
        for y in range(level.height):
            var chunk = level.chunks[x][y]
            for tile_x in range(32):
                for tile_y in range(32):
                    var global_x = x * 32 + tile_x
                    var global_y = y * 32 + tile_y
                    var tile_type = chunk.tiles[tile_x][tile_y]
                    
                    # Tile in TileMap platzieren
                    tile_map.set_cell(0, Vector2i(global_x, global_y), get_tile_id(tile_type))
```

### Spieler-Kollisionsabfrage

```gdscript
func _physics_process(delta):
    var velocity = Vector2.ZERO
    if Input.is_action_pressed("move_right"):
        velocity.x += 1
    if Input.is_action_pressed("move_left"):
        velocity.x -= 1
    if Input.is_action_pressed("move_down"):
        velocity.y += 1
    if Input.is_action_pressed("move_up"):
        velocity.y -= 1
    
    if velocity.length() > 0:
        velocity = velocity.normalized() * speed
    
    # Kollisionsabfrage
    var collision = move_and_collide(velocity * delta)
    if collision:
        if collision.collider.is_in_group("Barrier"):
            # Spieler kann nicht durch Barrieren
            velocity = Vector2.ZERO
        elif collision.collider.is_in_group("Interactive"):
            # Interaktive Öffnung (z.B. Tür)
            if Input.is_action_just_pressed("interact"):
                collision.collider.open()
```

---

## Beispiele

### Beispiel 1: Einfaches Level generieren

```gdscript
func _ready():
    var level = generate_level(12345, 64, 64)
    load_level_into_tilemap(level, $TileMap)
```

### Beispiel 2: Chunk manuell abrufen

```gdscript
func get_chunk_at_position(world_x: int, world_y: int) -> Chunk:
    var chunk_x = floor(world_x / 32)
    var chunk_y = floor(world_y / 32)
    return level.get_chunk(chunk_x, chunk_y)
```

### Beispiel 3: Barriere an Position prüfen

```gdscript
func is_position_blocked(world_x: int, world_y: int) -> bool:
    var chunk = get_chunk_at_position(world_x, world_y)
    var local_x = world_x % 32
    var local_y = world_y % 32
    return chunk.is_barrier(local_x, local_y)
```

---

## Erweiterungen

### 1. Dynamisches Laden
- **Lazy Loading:** Chunks nur generieren, wenn sie **im Sichtbereich der Kamera** sind.
- **Caching:** Generierte Chunks zwischenspeichern, um Performance zu verbessern.

### 2. Level-Themen
- **Spezielle Level:**
  - **Tempel-Level:** Viele Türen und Rätsel.
  - **Höhlen-Level:** Geschlossene Barrieren mit wenigen Öffnungen.
  - **Insel-Level:** Wasser mit vielen Inseln.

### 3. Höhensystem
- **2.5D-Effekte:**
  - Kacheln mit **Höhenwerten** (z.B. für Berge).
  - **Treppen** als Übergänge zwischen Höhen.

---

## Links

- [Godot TileMap Dokumentation](https://docs.godotengine.org/en/stable/tutorials/2d/procedural_geometry/tilemap.html)
- [Godot Kollisionslayer](https://docs.godotengine.org/en/stable/tutorials/physics/physics_intro.html)
- [Godot Klassen und Vererbung](https://docs.godotengine.org/en/stable/getting_started/scripting/gdscript/gdscript_basics.html)
