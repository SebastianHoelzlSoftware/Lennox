# Sistema de Barreras para Lennox

## 📌 Estado: Generacion y consultas de barreras implementadas

Las barreras son polígonos dependientes del bioma que se aplican a las baldosas del chunk y pueden consultarse mediante pruebas de punto. La integración con colisión física del jugador todavía no está implementada.

`Level` obtiene la cantidad, el tamaño y las opciones de apertura de `BiomeGenerator.get_biome_params()` y genera las barreras de forma determinista mediante RNG locales. La generación crea huecos pasables al modificar el polígono, pero todavía no crea ni adjunta objetos `Opening` a las barreras generadas para controlar su estado interactivo. Esa integración está asignada a LEN-15.

Los ejemplos de algoritmo y fragmentos de código de este documento son material de diseño; para el comportamiento actual, consulta `src/core/level.gd`, `src/core/chunk.gd`, `src/core/barrier.gd` y `src/core/opening.gd`.

**Implementacion:**
- `src/core/barrier.gd` - Clase de barreras con poligono y aperturas
- `src/core/opening.gd` - Clase de aperturas (Tipos: Steps, Door, Ford, Pass)
- `src/core/biome_type.gd` - Enum global para biomas (`BiomeType`)
- `src/core/tile_type.gd` - Enum global para tipos de baldosas (`TileType`)
- `src/core/level.gd` - Generacion de barreras por Chunk
- `src/core/chunk.gd` - Integracion de barreras en las baldosas
- `test/unit/test_barrier.gd` - Tests unitarios para barreras

---

## Tipos de Barreras

| Tipo | Descripcion | Textura de Baldosa | Comportamiento de Colision | Area Interna |
|------|-------------|-------------------|----------------------------|--------------|
| Rocks | Formaciones rocosas naturales (ej. montanas, acantilados). | Rock-Texture | Bloqueante | Rocks |
| Tree groups | Grupo de arboles que forman una barrera. | Tree-Texture | Bloqueante | Wood |
| Dunes | Colinas de arena en biomas de desierto o playa. | Sand-Texture | Bloqueante | Sand |
| Islands | Masa de tierra en biomas de agua (logica inversa). | Grass/Rock-Texture | Bloqueante (agua) | Grass/Rocks |
| Walls | Barrera artificial (ej. para edificios o cuevas). | Stone-Texture | Bloqueante | Interior |

---

## Algoritmo: Generacion de Barreras

### 1. Convex Hull + Perturbation

#### Paso 1: Generar puntos aleatorios
- Por Chunk: **5-15 puntos aleatorios** en el **area interna** (no en el borde).
- **Distancia minima:** Al menos 2 baldosas entre puntos para evitar barreras demasiado pequenas.
- **Cantidad dependiente del bioma:**
  - Grassland: 5-8 puntos
  - Wood: 8-12 puntos
  - Rocks: 10-15 puntos

```gdscript
func generate_random_points(chunk_x: int, chunk_y: int, biome: String, chunk_size: int = 32) -> Array[Vector2]:
    var points = []
    var num_points = 0
    
    # Cantidad de puntos dependiente del bioma
    match biome:
        "Grassland": num_points = randi_range(5, 8)
        "Wood": num_points = randi_range(8, 12)
        "Rocks": num_points = randi_range(10, 15)
        "Water": num_points = randi_range(5, 10)
        "Sand": num_points = randi_range(5, 8)
        _: num_points = 8
    
    # Generar puntos en el area interna (no en el borde)
    var margin = 2
    for i in range(num_points):
        var x = randi_range(margin, chunk_size - margin - 1)
        var y = randi_range(margin, chunk_size - margin - 1)
        
        # Verificar distancia minima a otros puntos
        var valid = true
        for point in points:
            if point.distance_to(Vector2(x, y)) < 2:
                valid = false
                break
        
        if valid:
            points.append(Vector2(x, y))
    
    return points
```

#### Paso 2: Calcular Convex Hull
- **Objetivo:** Poligono convexo mas pequeño que engloba todos los puntos.
- **Algoritmo:** Graham-Scan (sencillo de implementar).

```gdscript
func compute_convex_hull(points: Array[Vector2]) -> Array[Vector2]:
    if points.size() <= 2:
        return points.duplicate()
    
    # 1. Encuentra el punto con la coordenada y mas baja
    var p0 = points[0]
    for point in points:
        if point.y < p0.y or (point.y == p0.y and point.x < p0.x):
            p0 = point
    
    # 2. Ordena puntos por angulo polar respecto a p0
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
            
            # Calcula el angulo entre next_to_top -> top -> p
            var cross = (top.x - next_to_top.x) * (p.y - top.y) - (top.y - next_to_top.y) * (p.x - top.x)
            if cross > 0:
                break
            else:
                hull.pop_back()
        hull.append(p)
    
    return hull
```

#### Paso 3: Aplicar Perturbation para formas organicas
- **Objetivo:** Formas mas naturales y menos geometricas.
- **Metodo:** Mover cada punto del Convex Hull ligeramente.

```gdscript
func perturb_hull(hull: Array[Vector2], perturbation: int = 1) -> Array[Vector2]:
    var perturbed_hull = []
    for point in hull:
        var x_offset = randi_range(-perturbation, perturbation)
        var y_offset = randi_range(-perturbation, perturbation)
        perturbed_hull.append(Vector2(point.x + x_offset, point.y + y_offset))
    return perturbed_hull
```

### 2. Convertir Barreras a Baldosas
- **Todas las baldosas dentro del poligono** se convierten en **baldosas de barrera**.
- **Metodo:** Prueba Point-in-Polygon para cada baldosa en el Chunk.

```gdscript
func generate_barrier_tiles(hull: Array[Vector2], chunk_size: int = 32) -> Array:
    var barrier_tiles = []
    for x in range(chunk_size):
        barrier_tiles.append([])
        for y in range(chunk_size):
            # Prueba Point-in-Polygon
            if is_point_in_polygon(Vector2(x, y), hull):
                barrier_tiles[x].append(true)
            else:
                barrier_tiles[x].append(false)
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
        
        # Algoritmo Ray-Casting
        var intersect = ((yi > point.y) != (yj > point.y)) and \
                        (point.x < (xj - xi) * (point.y - yi) / (yj - yi) + xi)
        if intersect:
            inside = not inside
    return inside
```

---

## Aperturas en Barreras

### Tipos de Aperturas

| Tipo | Ancho (baldosas) | Descripcion | Transitable | Interactiva | Textura |
|------|-----------------|-------------|-------------|-------------|---------|
| Steps | 2-3 | Baldosas inclinadas para diferencias de altura | Si | No | steps.png |
| Door | 1 | Espacio simple con objeto de puerta | Si | **Si** | door.png |
| Ford | 2-4 | Baldosas de agua en la barrera | Si | No | water_shallow.png |
| Pass | 3-5 | Paso estrecho con baldosas de rocas | Si | No | pass.png |

### Colocar Aperturas

#### Paso 1: Encontrar candidatos para aperturas
- Identificar **bordes del poligono**.
- **Bordes validos:** Bordes que **no estan en un limite de Chunk**.

```gdscript
func find_valid_edges(hull: Array[Vector2], chunk_size: int = 32) -> Array[Array]:
    var valid_edges = []
    var n = hull.size()
    for i in range(n):
        var j = (i + 1) % n
        var edge = [hull[i], hull[j]]
        
        # Verifica si el borde esta en un limite de Chunk
        var is_at_border = false
        for point in edge:
            if point.x == 0 or point.x == chunk_size - 1 or point.y == 0 or point.y == chunk_size - 1:
                is_at_border = true
                break
        
        if not is_at_border:
            valid_edges.append(edge)
    
    return valid_edges
```

#### Paso 2: Colocar apertura en borde
- Seleccionar borde **aleatorio**.
- Calcular **punto medio del borde**.
- Crear **espacio en la barrera** (ancho = ancho de la apertura).

```gdscript
func place_opening(hull: Array[Vector2], opening_type: String, opening_width: int) -> Array[Vector2]:
    var valid_edges = find_valid_edges(hull)
    if valid_edges.size() == 0:
        return hull
    
    # Seleccionar borde aleatorio
    var edge_idx = randi() % valid_edges.size()
    var edge = valid_edges[edge_idx]
    var p1 = edge[0]
    var p2 = edge[1]
    
    # Punto medio del borde
    var midpoint = Vector2((p1.x + p2.x) / 2, (p1.y + p2.y) / 2)
    
    # Direccion del borde (perpendicular al borde)
    var dx = p2.x - p1.x
    var dy = p2.y - p1.y
    var length = sqrt(dx * dx + dy * dy)
    var nx = -dy / length
    var ny = dx / length
    
    # Generar puntos de apertura (espacio en la barrera)
    var opening_points = []
    for i in range(opening_width):
        var offset = i - (opening_width - 1) / 2.0
        var x = midpoint.x + nx * offset
        var y = midpoint.y + ny * offset
        opening_points.append(Vector2(round(x), round(y)))
    
    # Eliminar puntos de apertura del hull (crear espacio)
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

#### Paso 3: Seleccionar tipo de apertura aleatoriamente
- Probabilidades **dependientes del bioma** (ver documentacion de [biomas](biomes.md)).

```gdscript
func get_random_opening_type(biome: String) -> String:
    var opening_types = []
    match biome:
        "Grassland":
            opening_types = ["Ford", "Ford", "Pass", "Pass", "Steps"]
        "Wood":
            opening_types = ["Pass", "Pass", "Pass", "Ford", "Door"]
        "Rocks":
            opening_types = ["Pass", "Pass", "Pass", "Steps", "Steps"]
        "Water":
            opening_types = ["Ford"]
        "Sand":
            opening_types = ["Pass", "Pass", "Pass", "Pass", "Ford"]
        _:
            opening_types = ["Pass"]
    
    return opening_types[randi() % opening_types.size()]
```

---

## Generar Barreras con Aperturas

### Algoritmo Completo por Chunk

```gdscript
func generate_barriers_for_chunk(chunk_x: int, chunk_y: int, biome: String, seed: int) -> Array[Barrier]:
    var barriers = []
    var num_barriers = get_biome_params(biome)["barrier_count"]
    
    for i in range(num_barriers):
        # 1. Generar puntos aleatorios
        var points = generate_random_points(chunk_x, chunk_y, biome)
        
        # 2. Calcular Convex Hull
        var hull = compute_convex_hull(points)
        
        # 3. Aplicar perturbation
        hull = perturb_hull(hull)
        
        # 4. Colocar aperturas
        var num_openings = get_biome_params(biome)["opening_count"]
        var opening_types = get_biome_params(biome)["opening_types"]
        
        for j in range(num_openings):
            var opening_type = opening_types[randi() % opening_types.size()]
            var opening_width = 0
            match opening_type:
                "Steps": opening_width = randi_range(2, 3)
                "Door": opening_width = 1
                "Ford": opening_width = randi_range(2, 4)
                "Pass": opening_width = randi_range(3, 5)
            
            hull = place_opening(hull, opening_type, opening_width)
        
        # 5. Crear objeto de barrera
        var barrier = Barrier.new()
        barrier.polygon = hull
        barrier.biome = biome
        barrier.openings = []
        barriers.append(barrier)
    
    return barriers
```

---

## 6. Detalles de Implementacion (LEN-5)

### Estructura de Clases

#### Barrier (`src/core/barrier.gd`)
```gdscript
class_name Barrier
var polygon: Array           # Puntos del poligono
var biome: BiomeType.Type    # Tipo de bioma de la barrera (BiomeType.GRASSLAND, etc.)
var openings: Array          # Lista de aperturas
```

#### Opening (`src/core/opening.gd`)
```gdscript
class_name Opening
enum OpeningType { STEPS, DOOR, FORD, PASS }
var type: OpeningType
var position: Vector2
var width: int
var is_interactive: bool
var biome: BiomeType.Type    # Tipo de bioma de la apertura
```

### Implementacion del Algoritmo

La generacion de barreras en `level.gd` sigue este flujo:

1. **Generar puntos aleatorios** (`_generate_random_points`)
   - Cantidad dependiente del bioma (Grassland: 5-8, Wood: 8-12, Rocks: 10-15)
   - Distancia minima: 2 baldosas
   - Solo en el area interna (margen: 2 baldosas)

2. **Calcular Convex Hull** (`_compute_convex_hull`)
   - Algoritmo Graham-Scan
   - Crea el poligono convexo mas pequeño alrededor de todos los puntos

3. **Aplicar perturbation** (`_perturb_hull`)
   - Mueve puntos +/- 1 baldosa
   - Crea formas mas organicas y menos geometricas

4. **Colocar aperturas** (`_place_opening_in_hull`)
   - Cantidad y tipos dependientes del bioma
   - Solo en bordes validos (no en limites de Chunk)
   - Aperturas interactivas (puertas) para rompecabezas

### Integracion en Chunks

La clase `Chunk` aplica barreras a las baldosas:
- `apply_barriers_to_tiles()` - Establece baldosas dentro de poligonos de barreras
- `is_barrier(x, y)` - Verifica si una baldosa es una barrera

---

## Consulta de Colisiones en Godot

### Configuracion de TileMap
- **Baldosas de barreras:**
  - **Capa de colision:** `Barrier`
  - **Mascara de colision:** `Player`
- **Aperturas:**
  - **Sin capa de colision** (transitable).
- **Aperturas interactivas (puertas):**
  - **Capa de colision:** `Barrier` (bloqueado por defecto).
  - **Al interactuar:** Cambiar capa de colision a `Passable`.

### Ejemplo: TileMap en Godot
```gdscript
# En la funcion _ready() del TileMap:
func _ready():
    # Establecer capa de colision para baldosas de barreras
    set_collision_layer(1)
    set_collision_mask(1)
    
    # Las baldosas de barreras tienen forma de colision (ej. RectangleShape2D)
    # Las aperturas no tienen forma de colision
```

### Consulta de Colision del Jugador
```gdscript
func _physics_process(delta):
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

### Ejemplo 1: Barrera de Rocks con Pass
- **Bioma:** Rocks
- **Poligono de barrera:** 12 puntos (Convex Hull + Perturbation).
- **Apertura:** 1 Pass (4 baldosas de ancho).
- **Baldosas:**
  - Dentro del poligono: Textura de Rocks.
  - En la apertura: Baldosas vacias (transitables).

### Ejemplo 2: Barrera de Wood con Door
- **Bioma:** Wood
- **Poligono de barrera:** 10 puntos (grupo de arboles).
- **Apertura:** 1 Door (1 baldosa de ancho, interactiva).
- **Baldosas:**
  - Dentro del poligono: Textura de Tree.
  - En la puerta: Textura de puerta (bloqueante, hasta abrir).

### Ejemplo 3: Barrera de Rocks cerrada
- **Bioma:** Rocks
- **Poligono de barrera:** 15 puntos.
- **Aperturas:** 0 (barrera cerrada).
- **Baldosas:**
  - Dentro del poligono: Textura de Rocks.
  - Sin huecos (no transitable).

---

## Extensiones

### 1. Formas de Barreras mas Complejas
- **Poligonos no convexos:** Algoritmos como **Alpha Shapes** o **Concave Hull** para formas mas organicas.
- **Agujeros en barreras:** Multiples poligonos por barrera (ej. formacion rocosa con cueva).

### 2. Barreras Dinamicas
- **Barreras moviles:** Ej. rocas rodantes o ramas oscilantes.
- **Barreras rompibles:** Barreras que pueden ser destruidas por acciones del jugador.

### 3. Texturas de Barreras Especificas por Bioma
- **Rocks:** Diferentes texturas de rocas (claras, oscuras, escarpadas).
- **Wood:** Diferentes tipos de arboles (roble, pino, etc.).

---

## Enlaces

- [Algoritmos de Convex Hull](https://en.wikipedia.org/wiki/Convex_hull_algorithms)
- [Algoritmo Point-in-Polygon](https://en.wikipedia.org/wiki/Point_in_polygon)
- [Tutorial de TileMap en Godot](https://docs.godotengine.org/en/stable/tutorials/2d/procedural_geometry/tilemap.html)
- [Capas de Colision en Godot](https://docs.godotengine.org/en/stable/tutorials/physics/physics_intro.html)
