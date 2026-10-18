# Estructura de Niveles y Chunks para Lennox

## Descripcion General

Este documento describe las **estructuras de datos y la organizacion** de los niveles y chunks en Lennox. El mapa se genera **proceduralmente** y consiste en **chunks**, cada uno de los cuales contiene **biomas, barreras y aperturas**.

---

## Estructura del Nivel

### Parametros Basicos

| Parametro | Valor | Descripcion |
|-----------|-------|-------------|
| **Tamano del Nivel** | 64x64 chunks | Tamano total de un nivel |
| **Tamano del Chunk** | 32x32 baldosas | Numero de baldosas por chunk |
| **Tamano de Baldosa** | 32x32 pixeles | Tamano de una baldosa en pixeles |
| **Tamano Total** | 2048x2048 pixeles | 64 x 32 x 32 = 2048 pixeles por eje |

### Clase Level (GDScript)

```gdscript
class_name Level

# Parametros base
var width: int          # Numero de chunks en direccion x (64)
var height: int         # Numero de chunks en direccion y (64)
var chunk_size: int     # Baldosas por chunk (32)
var tile_size: int      # Pixeles por baldosa (32)
var seed: int           # Semilla base para determinismo

# Chunks
var chunks: Array = []  # Array 2D de chunks (chunks[x][y])

# Funciones de ayuda
func _init(p_width: int = 64, p_height: int = 64, p_chunk_size: int = 32, p_tile_size: int = 32, p_seed: int = 0):
				# Inizializar parametros
    width = p_width
    height = p_height
    chunk_size = p_chunk_size
    tile_size = p_tile_size
    seed = p_seed
				# Initializar almacen para los chunks
    chunks = []
    for x in range(width):
        chunks.append([])
        for y in range(height):
            chunks[x].append(null)

# Obtener o generar chunk
func get_chunk(x: int, y: int) -> Chunk:
    if chunks[x][y] == null:
        chunks[x][y] = generate_chunk(x, y)
    return chunks[x][y]

# Generar nivel
func generate() -> void:
    for x in range(width):
        for y in range(height):
            chunks[x][y] = generate_chunk(x, y)

# Generar chunk (se implementa en subclases)
func generate_chunk(x: int, y: int) -> Chunk:
    pass
```

---

## Estructura del Chunk

### Parametros Basicos

| Parametro | Valor | Descripcion |
|-----------|-------|-------------|
| **x, y** | int | Coordenadas del chunk en el nivel |
| **biome** | BiomeType.Type | Tipo de bioma (ej. `BiomeType.GRASSLAND`) |
| **tiles** | Array[Array] | Array 2D de tipos de baldosas (`TileType`, 32x32) |
| **barriers** | Array[Barrier] | Lista de barreras en el chunk |

### Clase Chunk (GDScript)

```gdscript
class_name Chunk

# Posicion
var x: int
var y: int

# Bioma (usa clase global BiomeType)
var biome: BiomeType.Type

# Baldosas (Array 2D: tiles[x][y] = tipo de baldosa TileType)
var tiles: Array = []

# Barreras
var barriers: Array = []

# Funciones de ayuda
func _init(p_x: int, p_y: int):
    x = p_x
    y = p_y
    biome = BiomeType.GRASSLAND
    tiles = []
    for i in range(32):  # chunk_size = 32
        tiles.append([])
        for j in range(32):
            tiles[i].append(TileType.GRASS)  # Baldosa por defecto

# Obtener tipo de baldosa
func get_tile(p_x: int, p_y: int) -> int:
    if p_x >= 0 and p_x < 32 and p_y >= 0 and p_y < 32:
        return tiles[p_x][p_y]
    return TileType.GRASS

# Verificar si hay barrera en la posicion
func is_barrier(p_x: int, p_y: int) -> bool:
    for barrier in barriers:
        if barrier.contains_point(Vector2(p_x, p_y)):
            return true
    return false
```

---

## Tipos de Baldosas

### Definicion Tecnica: Clase Global `TileType` (`src/core/tile_type.gd`)

Los tipos de baldosas estan definidos en la clase global `TileType`:

```gdscript
# src/core/tile_type.gd
class_name TileType

enum Type {
	GRASS,
	ROCK,
	TREE,
	SAND,
	WATER
}

const GRASS: Type = Type.GRASS
const ROCK: Type = Type.ROCK
const TREE: Type = Type.TREE
const SAND: Type = Type.SAND
const WATER: Type = Type.WATER
```

### Baldosas Base

| Tipo de Baldosa | Constante / Enum | Descripcion | Comportamiento de Colision | Textura |
|-----------------|------------------|-------------|----------------------------|---------|
| Grass | `TileType.GRASS` | Baldosa por defecto para Grassland. | Sin colision | grass.png |
| Sand | `TileType.SAND` | Baldosa por defecto para bioma Sand. | Sin colision | sand.png |
| Water | `TileType.WATER` | Baldosa por defecto para bioma Water. | Colision (agua) | water.png |
| Rock | `TileType.ROCK` | Baldosa por defecto para bioma Rocks. | Colision | rock.png |
| Tree | `TileType.TREE` | Baldosa con arbol (para bioma Wood). | Colision | tree.png |

### Baldosas de Barrera

| Tipo de Baldosa | Descripcion | Comportamiento de Colision | Textura |
|-----------------|-------------|----------------------------|---------|
| Rock-Barrier | Baldosa dentro de una barrera de Rocks. | Colision | rock_barrier.png |
| Tree-Barrier | Baldosa dentro de un grupo de arboles. | Colision | tree_barrier.png |
| Sand-Barrier | Baldosa dentro de una duna. | Colision | sand_barrier.png |

### Baldosas de Apertura

| Tipo de Baldosa | Descripcion | Comportamiento de Colision | Textura |
|-----------------|-------------|----------------------------|---------|
| Steps | Baldosa para aperturas tipo Steps. | Sin colision | steps.png |
| Door | Baldosa para aperturas tipo Door. | Colision (interactiva) | door.png |
| Ford | Baldosa para aperturas tipo Ford. | Sin colision | water_shallow.png |
| Pass | Baldosa para aperturas tipo Pass. | Sin colision | pass.png |

---

## Estructura de Barreras

### Clase Barrier (GDScript)

```gdscript
class_name Barrier

# Poligono (lista de puntos en coordenadas de baldosas)
var polygon: Array = []

# Tipo de bioma de la barrera (usa clase global BiomeType)
var biome: BiomeType.Type = BiomeType.GRASSLAND

# Aperturas en esta barrera
var openings: Array = []

# Funciones de ayuda
func contains_point(point: Vector2) -> bool:
    return is_point_in_polygon(point, polygon)

func is_opening_at(point: Vector2) -> bool:
    for opening in openings:
        if opening.contains_point(point):
            return true
    return false

func is_point_in_polygon(point: Vector2, polygon: Array[Vector2]) -> bool:
    # Algoritmo Ray-Casting
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

## Estructura de Aperturas

### Clase Opening (GDScript)

```gdscript
class_name Opening

# Tipo de apertura
enum OpeningType { STEPS, DOOR, FORD, PASS }

var type: OpeningType  # STEPS, DOOR, FORD, PASS

# Posicion (baldosa inicial de la apertura)
var position: Vector2

# Ancho en baldosas
var width: int

# ¿Es interactiva? (ej. para puertas)
var is_interactive: bool = false

# Bioma de la apertura
var biome: BiomeType.Type

# Funciones de ayuda
func contains_point(point: Vector2) -> bool:
    # Verifica si el punto esta dentro de la apertura
    var end_position = Vector2(position.x + width - 1, position.y)
    return (point.x >= position.x and point.x <= end_position.x and \
            point.y == position.y)

func open() -> void:
    if is_interactive:
        # Cambiar capa de colision (ej. de "Barrier" a "Passable")
        print("Apertura abierta!")
```

---

## Flujo de Generacion

### 1. Generar Nivel

```gdscript
func generate_level(seed: int, width: int = 64, height: int = 64) -> Level:
    var level = Level.new()
    level.seed = seed
    level.width = width
    level.height = height
    
    # 1. Generar mapa de biomas
    var biome_map = generate_biome_map(seed, width, height)
    
    # 2. Generar chunks
    for x in range(width):
        for y in range(height):
            var chunk = generate_chunk(seed, x, y, biome_map[x][y])
            level.chunks[x][y] = chunk
    
    # 3. Suavizar transiciones entre chunks (opcional)
    smooth_chunk_transitions(level)
    
    return level
```

### 2. Generar Chunk

```gdscript
func generate_chunk(seed: int, x: int, y: int, biome: String) -> Chunk:
    var chunk = Chunk.new()
    chunk.x = x
    chunk.y = y
    chunk.biome = biome
    
    # 1. Obtener parametros especificos del bioma
    var biome_params = get_biome_params(biome)
    
    # 2. Generar barreras
    var num_barriers = biome_params["barrier_count"]
    for i in range(num_barriers):
        var barrier = generate_barrier(seed, x, y, biome)
        chunk.barriers.append(barrier)
    
    # 3. Crear baldosas a partir de barreras y bioma
    chunk.tiles = generate_tiles_from_barriers(chunk)
    
    return chunk
```

### 3. Crear Baldosas a partir de Barreras

```gdscript
func generate_tiles_from_barriers(chunk: Chunk) -> Array:
    var tiles = []
    for x in range(32):
        tiles.append([])
        for y in range(32):
            # Baldosa base segun bioma
            var tile_type = get_base_tile_for_biome(chunk.biome)
            
            # Verificar si la baldosa esta en una barrera
            var is_barrier = false
            for barrier in chunk.barriers:
                if barrier.contains_point(Vector2(x, y)):
                    is_barrier = true
                    tile_type = get_barrier_tile_for_biome(chunk.biome)
                    break
            
            # Verificar si la baldosa es una apertura
            if is_barrier:
                for barrier in chunk.barriers:
                    if barrier.is_opening_at(Vector2(x, y)):
                        tile_type = get_opening_tile_for_type(barrier.get_opening_at(Vector2(x, y)).type)
                        break
            
            tiles[x].append(tile_type)
    
    return tiles

func get_base_tile_for_biome(biome: String) -> String:
    match biome:
        "Grassland": return "Grass"
        "Wood": return "Grass"  # Wood tiene Grass como base
        "Rocks": return "Rock"
        "Water": return "Water"
        "Sand": return "Sand"
        _: return "Grass"

func get_barrier_tile_for_biome(biome: String) -> String:
    match biome:
        "Grassland": return "Rock-Barrier"
        "Wood": return "Tree-Barrier"
        "Rocks": return "Rock-Barrier"
        "Water": return "Rock-Barrier"  # Islas
        "Sand": return "Sand-Barrier"
        _: return "Rock-Barrier"

func get_opening_tile_for_type(opening_type: int) -> String:
    match opening_type:
        Opening.OpeningType.STEPS: return "Steps"
        Opening.OpeningType.DOOR: return "Door"
        Opening.OpeningType.FORD: return "Ford"
        Opening.OpeningType.PASS: return "Pass"
        _: return "Pass"
```

---

## Suavizar Transiciones entre Chunks

### Problema
- Las barreras en los **limites de los chunks** pueden verse antinaturales si terminan abruptamente.

### Solucion
1. **No colocar barreras en el borde del chunk:**
   - Generar barreras solo en el **area interna** (ej. 2-28 baldosas).
2. **Barreras que abarcan multiples chunks:**
   - Barreras grandes (ej. cadenas montañosas) pueden **abarcar varios chunks**.
3. **Transiciones suaves de biomas:**
   - Suavizar biomas en los limites de chunks (ej. con Noise).

```gdscript
func smooth_chunk_transitions(level: Level) -> void:
    for x in range(level.width):
        for y in range(level.height):
            var chunk = level.chunks[x][y]
            
            # Verificar chunks vecinos
            for dx in [-1, 0, 1]:
                for dy in [-1, 0, 1]:
                    if dx == 0 and dy == 0:
                        continue
                    var nx = x + dx
                    var ny = y + dy
                    if nx >= 0 and nx < level.width and ny >= 0 and ny < level.height:
                        var neighbor = level.chunks[nx][ny]
                        # Suavizar transiciones de bioma
                        smooth_biome_transition(chunk, neighbor)
```

---

## Integracion con Godot

### Configuracion de TileMap

1. **Crear TileSet:**
   - Definir todos los tipos de baldosas (Grass, Rock, Water, etc.) como **Tiles** en el TileSet.
   - Anadir **formas de colision** para las baldosas de barreras.

2. **TileMap en la escena:**
   - Un **TileMap** para toda la representacion del nivel.
   - **Capas de colision:**
     - Baldosas de barreras: Capa `1` (Barrier)
     - Aperturas: Sin capa (transitable)
     - Water: Capa `2` (Water)

3. **Cargar nivel en TileMap:**

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
                    
                    # Colocar tile en el TileMap
                    tile_map.set_cell(0, Vector2i(global_x, global_y), get_tile_id(tile_type))
```

### Consulta de Colision del Jugador

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
    
    # Consulta de colision
    var collision = move_and_collide(velocity * delta)
    if collision:
        if collision.collider.is_in_group("Barrier"):
            # El jugador no puede pasar a traves de barreras
            velocity = Vector2.ZERO
        elif collision.collider.is_in_group("Interactive"):
            # Apertura interactiva (ej. puerta)
            if Input.is_action_just_pressed("interact"):
                collision.collider.open()
```

---

## Ejemplos

### Ejemplo 1: Generar un Nivel Simple

```gdscript
func _ready():
    var level = generate_level(12345, 64, 64)
    load_level_into_tilemap(level, $TileMap)
```

### Ejemplo 2: Obtener Chunk Manual

```gdscript
func get_chunk_at_position(world_x: int, world_y: int) -> Chunk:
    var chunk_x = floor(world_x / 32)
    var chunk_y = floor(world_y / 32)
    return level.get_chunk(chunk_x, chunk_y)
```

### Ejemplo 3: Verificar si una Posicion esta Bloqueada

```gdscript
func is_position_blocked(world_x: int, world_y: int) -> bool:
    var chunk = get_chunk_at_position(world_x, world_y)
    var local_x = world_x % 32
    var local_y = world_y % 32
    return chunk.is_barrier(local_x, local_y)
```

---

## Extensiones

### 1. Carga Dinamica
- **Carga perezosa:** Generar chunks solo cuando esten en el **area visible de la camara**.
- **Cache:** Almacenar chunks generados para mejorar el rendimiento.

### 2. Temas de Nivel
- **Niveles especiales:**
  - **Nivel Templo:** Muchas puertas y rompecabezas.
  - **Nivel Cueva:** Barreras cerradas con pocas aperturas.
  - **Nivel Islas:** Water con muchas islas.

### 3. Sistema de Alturas
- **Efectos 2.5D:**
  - Baldosas con **valores de altura** (ej. para montanas).
  - **Steps** como transiciones entre alturas.

---

## Enlaces

- [Documentacion de TileMap en Godot](https://docs.godotengine.org/en/stable/tutorials/2d/procedural_geometry/tilemap.html)
- [Capas de Colision en Godot](https://docs.godotengine.org/en/stable/tutorials/physics/physics_intro.html)
- [Godot Clases y Herencia](https://docs.godotengine.org/en/stable/getting_started/scripting/gdscript/gdscript_basics.html)
