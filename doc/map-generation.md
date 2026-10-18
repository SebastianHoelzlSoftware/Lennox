# Generacion Procedural de Mapas 2D

## Descripcion General

Este documento describe el algoritmo y la implementacion de la **generacion procedural de mapas 2D** para Lennox. El objetivo es crear un mundo de juego dinamico y variado con biomas naturales, barreras cerradas y aperturas estrategicamente colocadas.

---

## Condiciones Tecnicas

| Parametro | Valor | Justificacion |
|-----------|-------|---------------|
| **Tamano del Nivel** | 64x64 chunks | Suficientemente grande para prototipos |
| **Tamano del Chunk** | 32x32 baldosas | Balance entre detalle y rendimiento |
| **Tamano de Baldosa** | 32x32 pixeles | Optimo para rendimiento en movil |
| **Tamano Total** | 2048x2048 pixeles | 64 Chunks x 32 Baldosas x 32 Pixeles |
| **Implementacion** | GDScript | Facil integracion en Godot |
| **Determinismo** | Por Chunk | Misma semilla = mismo chunk |

---

## Resumen del Algoritmo

El proceso de generacion de mapas sigue un **proceso de 4 etapas**:

1. **Generacion de Biomas** (Voronoi + Perlin Noise)
2. **Generacion de Barreras** (Convex Hull + Perturbation)
3. **Colocar Aperturas** (0-n por barrera)
4. **Crear Baldosas** (TileMap en Godot)

---

## 1. Generacion de Biomas

### Biomas Base

| Bioma | Densidad de Barreras | Tipos de Barreras Tipicos | Frecuencia de Aperturas | Descripcion |
|-------|---------------------|---------------------------|------------------------|-------------|
| Grassland | Baja (1-2) | Rocks, Tree groups | Alta (1-3) | Areas abiertas con obstaculos aislados |
| Wood | Alta (3-5) | Tree groups, Rocks | Media (1-2) | Vegetacion densa con barreras naturales |
| Rocks | Muy Alta (5-8) | Rock formations, Cliffs | Baja (0-1) | Regiones montañosas, dificilmente transitables |
| Water | Ninguna | Islands | - | Lagos, rios, mares |
| Sand | Baja (1-2) | Dunes, Rocks | Alta (1-3) | Desiertos o regiones costeras |

### Proceso de Generacion

1. **Diagrama de Voronoi:**
   - Divide el nivel en **3-5 celdas de Voronoi** por grupo de chunks.
   - Cada celda se asigna a un **tipo de bioma**.
   - **Objetivo:** Crear regiones naturales y organicas.

2. **Perlin Noise para transiciones:**
   - Aplica **Perlin Noise** a los limites de Voronoi para crear **transiciones suaves** entre biomas.
   - **Parametros:**
     - Escalado: 0.05-0.1
     - Octavas: 2-4
     - Persistencia: 0.5

3. **Ajustes Especificos por Bioma:**
   - **Water:** Solo en hundimientos (valores de Noise < 0.2).
   - **Rocks:** En colinas (valores de Noise > 0.7).
   - **Wood:** En altitudes medias (valores de Noise 0.4-0.7).

---

## 2. Generacion de Barreras

### Algoritmo: Convex Hull + Perturbation

1. **Generar puntos aleatorios:**
   - Por Chunk: **5-15 puntos aleatorios** en el area interna (no en el borde).
   - **Distancia minima:** Al menos 2 baldosas entre puntos.

2. **Calcular Convex Hull:**
   - Encuentra el **poligono convexo mas pequeño** que engloba todos los puntos.
   - **Metodo:** Algoritmo Graham-Scan o QuickHull.

3. **Aplicar Perturbation para formas organicas:**
   - Mueve cada punto del Convex Hull **aleatoriamente +/- 1-2 baldosas** hacia adentro o afuera.
   - **Objetivo:** Formas mas naturales y menos geometricas.

4. **Convertir barrera a baldosas:**
   - Todas las baldosas **dentro del poligono** se convierten en **baldosas de barrera** (ej. texturas de Rocks o Tree).
   - **Consulta de colision:** Estas baldosas bloquean al jugador.

### Parametros Dependientes del Bioma

| Bioma | Barreras por Chunk | Tamano Tipico de Barreras | Superficie Interna |
|-------|---------------------|--------------------------|-------------------|
| Grassland | 1-2 | 5-10 baldosas de diametro | Grass |
| Wood | 3-5 | 8-15 baldosas de diametro | Wood |
| Rocks | 5-8 | 10-20 baldosas de diametro | Rocks |
| Water | 0-1 (Islands) | 15-30 baldosas de diametro | Water (Island) |
| Sand | 1-2 | 6-12 baldosas de diametro | Sand |

---

## 3. Aperturas en Barreras

### Tipos de Aperturas

| Tipo | Ancho (baldosas) | Descripcion | Transitable | Interactiva |
|------|-----------------|-------------|-------------|-------------|
| Steps | 2-3 | Baldosas inclinadas para diferencias de altura | Si | No |
| Door | 1 | Espacio simple con objeto de puerta | Si | **Si** |
| Ford | 2-4 | Baldosas de agua en la barrera | Si | No |
| Pass | 3-5 | Paso estrecho con baldosas de rocas | Si | No |

### Reglas de Colocacion

1. **Cantidad por barrera:**
   - **Grassland:** 80% de probabilidad de 1-3 aperturas.
   - **Wood:** 60% de probabilidad de 1-2 aperturas.
   - **Rocks:** 20% de probabilidad de 0-1 apertura.

2. **Posicionamiento:**
   - Selecciona **un borde aleatorio** del poligono de la barrera.
   - Reemplaza el borde con un **espacio** (ancho = ancho de la apertura).
   - **Restriccion:** La apertura no debe estar en un **limite de Chunk**.

3. **Aperturas interactivas:**
   - Las **puertas** estan **bloqueadas por defecto** y deben abrirse resolviendo rompecabezas.
   - **Marcador:** Baldosa especial (ej. textura de puerta) para aperturas interactivas.

---

## 4. Integracion con Godot

### Estructuras de Datos

#### Level
```gdscript
class_name Level
var width: int      # Numero de chunks (x)
var height: int     # Numero de chunks (y)
var chunk_size: int # Baldosas por chunk (32)
var tile_size: int  # Pixeles por baldosa (32)
var seed: int       # Semilla base para determinismo
var chunks: Array[Chunk] # Array 2D de chunks
```

#### Clases Globales de Enums
- `BiomeType` (`src/core/biome_type.gd`): `GRASSLAND`, `WOOD`, `ROCKS`, `WATER`, `SAND`
- `TileType` (`src/core/tile_type.gd`): `GRASS`, `ROCK`, `TREE`, `SAND`, `WATER`

#### Chunk
```gdscript
class_name Chunk
var x: int                  # Coordenada del chunk (x)
var y: int                  # Coordenada del chunk (y)
var biome: BiomeType.Type   # Tipo de bioma (ej. BiomeType.GRASSLAND)
var tiles: Array            # Array 2D de tipos de baldosas (TileType)
var barriers: Array         # Lista de barreras en el chunk
```

#### Barrier
```gdscript
class_name Barrier
var polygon: Array          # Lista de puntos (coordenadas de baldosas)
var biome: BiomeType.Type   # Tipo de bioma de la barrera
var openings: Array         # Lista de aperturas
```

#### Opening
```gdscript
class_name Opening
enum OpeningType { STEPS, DOOR, FORD, PASS }
var type: OpeningType
var position: Vector2       # Baldosa inicial de la apertura
var width: int              # Ancho en baldosas
var is_interactive: bool    # Para puertas: true
var biome: BiomeType.Type   # Tipo de bioma de la apertura
```

### Flujo de Generacion en GDScript

```gdscript
func generate_level(seed: int, width: int, height: int) -> Level:
    var level = Level.new()
    level.seed = seed
    level.width = width
    level.height = height
    
    # 1. Generar mapa de biomas
    level.biomes = generate_biome_map(seed, width, height)
    
    # 2. Generar barreras por chunk
    for x in range(width):
        for y in range(height):
            var chunk = generate_chunk(seed, x, y, level.biomes[x][y])
            level.chunks[x][y] = chunk
    
    # 3. Suavizar transiciones entre chunks (opcional)
    smooth_chunk_transitions(level)
    
    return level

func generate_chunk(seed: int, x: int, y: int, biome: String) -> Chunk:
    var chunk = Chunk.new()
    chunk.x = x
    chunk.y = y
    chunk.biome = biome
    
    # Generar barreras especificas del bioma
    var num_barriers = get_barrier_count_for_biome(biome)
    for i in range(num_barriers):
        var barrier = generate_barrier(seed, x, y, biome)
        chunk.barriers.append(barrier)
    
    # Crear baldosas a partir de barreras y bioma
    chunk.tiles = generate_tiles_from_barriers(chunk)
    
    return chunk
```

---

## 5. Consulta de Colisiones

- **Baldosas de barreras:** Bloquean al jugador (Capa de colision: `Barrier`).
- **Aperturas:** Sin consulta de colision (Capa de colision: `Passable`).
- **Aperturas interactivas (puertas):**
  - Bloquean por defecto.
  - Al interactuar (ej. resolver rompecabezas): Cambiar capa de colision a `Passable`.

---

## 6. Optimizaciones de Rendimiento

1. **Cache de Chunks:**
   - Almacenar chunks generados (ej. en un Dictionary: `{x, y: Chunk}`).

2. **Carga Perezosa:**
   - Solo generar chunks que esten en el **area visible de la camara**.
   - **Buffer:** Precargar 2-3 chunks alrededor del area visible.

3. **Optimizacion de Baldosas:**
   - Usar **TileMap** en Godot (mas eficiente que objetos de baldosas individuales).
   - **Colision:** `CollisionPolygon2D` para barreras complejas o `CollisionShape2D` para formas simples.

---

## 7. Ejemplos

### Ejemplo 1: Chunk de Grassland
- **Bioma:** Grassland
- **Barreras:** 1 grupo de Rocks (8x8 baldosas) con 2 aperturas (1 Ford, 1 Pass).
- **Superficie interna:** Grass.

### Ejemplo 2: Chunk de Rocks
- **Bioma:** Rocks
- **Barreras:** 3 cadenas de rocas (10-15 baldosas de diametro) con 0-1 apertura por barrera.
- **Superficie interna:** Rocks.

### Ejemplo 3: Chunk de Wood
- **Bioma:** Wood
- **Barreras:** 4 grupos de arboles (6-12 baldosas de diametro) con 1-2 aperturas por barrera.
- **Superficie interna:** Wood.

---

## 8. Extensiones (Futuro)

1. **Mas Biomas:** Cueva, Volcan, Nieve, etc.
2. **Barreras Dinamicas:** Barreras que se mueven o desaparecen (ej. por rompecabezas).
3. **Mapa de Alturas:** Efectos 2.5D con diferencias de altura.
4. **Objetos Procedurales:** Colocar arboles, piedras, etc. en las baldosas.
5. **Temas de Nivel:** Niveles especiales con barreras unicas (ej. "Nivel Templo" con muchas puertas).

---

## Apendice: Pseudocodigo de Algoritmos

### Convex Hull (Graham-Scan)
```
1. Encuentra el punto con la coordenada y mas baja (P0).
2. Ordena todos los puntos segun el angulo polar respecto a P0.
3. Inicializa una pila con P0, P1, P2.
4. Para cada punto P:
   a. Mientras el angulo entre los ultimos 2 puntos en la pila y P > 180:
      - Elimina el ultimo punto de la pila.
   b. Anade P a la pila.
5. La pila contiene el Convex Hull.
```

### Perturbation
```
Para cada punto en el Convex Hull:
   - Mueve el punto +/- 1-2 baldosas en direccion x e y.
   - Asegurate de que el poligono permanezca cerrado.
```

### Perlin Noise
```
func perlin_noise(x: float, y: float, seed: int) -> float:
    # Implementacion de un algoritmo de Perlin Noise sencillo
    # o uso de OpenSimplexNoise de Godot.
	# hahaha @gemini/todo:"check if perlin noise is necessary or whats that OpenSimplexNoise thing"
    pass
```

---

## Enlaces

- [Documentacion de TileMap en Godot](https://docs.godotengine.org/en/stable/tutorials/2d/procedural_geometry/tilemap.html)
- [OpenSimplexNoise en Godot](https://docs.godotengine.org/en/stable/classes/class_opensimplexnoise.html)
- [Algoritmos de Convex Hull](https://en.wikipedia.org/wiki/Convex_hull_algorithms)
