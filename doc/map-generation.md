# Generacion Procedural de Mapas 2D

## Descripcion General

Este documento describe el algoritmo y la implementacion de la **generacion procedural de mapas 2D** para Lennox. El objetivo es crear un mundo de juego dinamico y variado con biomas naturales, barreras cerradas y aperturas estrategicamente colocadas.

## Estado actual del proyecto

- `Level.generate()` crea el mapa de biomas con la semilla del mundo y genera cada chunk usando el bioma correspondiente.
- `BiomeGenerator` usa puntos de Voronoi con asignaciones deterministas y FastNoiseLite Simplex FBM para hacer domain warping de las fronteras. No hay mezcla de biomas, zonas de amortiguación, alturas ni transiciones por Perlin Noise.
- `Level` genera barreras por bioma, aplica los tipos de baldosa al chunk y usa RNG locales con semillas derivadas para mantener la generación determinista.
- Los parámetros de cantidad, tamaño y aperturas se obtienen de `BiomeGenerator.get_biome_params()`. Cada apertura generada se guarda como `Opening` en la barrera correspondiente. Las puertas son interactivas y empiezan cerradas; las demás aperturas son pasables. La generación de aperturas y su integración con las consultas de barrera están implementadas (LEN-15).
- La integración con un TileMap de Godot y la colisión física del jugador no forman parte del código actual. Las comprobaciones disponibles son de punto y baldosa.

Las secciones de diseño y pseudocódigo que siguen describen objetivos o alternativas; cuando difieran, el código en `src/core/` representa el comportamiento implementado.

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

1. **Generacion de Biomas** (Voronoi + Simplex Domain Warping)
2. **Generacion de Barreras** (Convex Hull + Perturbation)
3. **Colocar Aperturas** (0-n por barrera)
4. **Aplicar barreras a las baldosas del chunk**

Las aperturas generadas conservan tipo, posición, ancho y bioma en `Barrier.openings`. `Barrier.contains_point()` permite el paso por aperturas pasables y bloquea las puertas cerradas. La física del jugador y su colisión en una escena de Godot siguen fuera del alcance implementado y corresponden a la integración posterior.

---

## 1. Generacion de Biomas

### Biomas Base

| Bioma | Densidad de Barreras | Tipos de Barreras Tipicos | Frecuencia de Aperturas | Descripcion |
|-------|---------------------|---------------------------|------------------------|-------------|
| Grassland | Baja (1-2) | Rocks, Tree groups | Alta (1-3) | Areas abiertas con obstaculos aislados |
| Wood | Alta (3-5) | Tree groups, Rocks | Media (1-2) | Vegetacion densa con barreras naturales |
| Rocks | Muy Alta (5-8) | Rock formations, Cliffs | Baja (0-1) | Regiones montañosas, dificilmente transitables |
| Water | Muy baja (0-1) | Islands | - | Lagos, rios, mares |
| Sand | Baja (1-2) | Dunes, Rocks | Alta (1-3) | Desiertos o regiones costeras |

### Proceso de Generacion (implementacion actual)

1. **Puntos de Voronoi:**
   - Se coloca un punto cada 4 chunks en los ejes X e Y.
   - Cada punto recibe uno de los cinco valores de `BiomeType`, usando un RNG local con la semilla del mundo.

2. **Domain warping:**
   - FastNoiseLite Simplex FBM desplaza cada coordenada de consulta hasta 2.5 chunks antes de buscar el punto más cercano.
   - Las fronteras resultan irregulares, pero los chunks mantienen un único bioma; no se mezclan propiedades.

3. **Asignación al nivel:**
   - `Level.generate()` conserva el mapa en `biome_map` y asigna cada valor al chunk correspondiente.

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

4. **Aplicar barrera a baldosas:**
   - Todas las baldosas **dentro del poligono** se convierten en **baldosas de barrera** (ej. texturas de Rocks o Tree).
   - `Chunk.is_barrier()` y `Barrier.contains_point()` permiten consultar puntos; la integración con la física del jugador todavía no está implementada.

### Parametros Dependientes del Bioma

| Bioma | Barreras por Chunk | Tamano Tipico de Barreras | Superficie Interna |
|-------|---------------------|--------------------------|-------------------|
| Grassland | 4-6 | 8-14 baldosas de dispersion | Grass |
| Wood | 7-10 | 10-16 baldosas de dispersion | Wood |
| Rocks | 8-12 | 12-18 baldosas de dispersion | Rocks |
| Water | 0-1 (Islands) | 15-30 baldosas de diametro | Water (Island) |
| Sand | 4-6 | 8-14 baldosas de dispersion | Sand |

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
   - Guarda el tipo, punto medio, ancho y bioma en un `Opening` asociado a la barrera.

3. **Aperturas interactivas:**
   - Las **puertas** se generan interactivas y **cerradas por defecto**; abrirlas las hace pasables.
   - Los tipos no interactivos, como **Ford**, **Pass** y **Steps**, son pasables por defecto.
   - La representación visual y las colisiones físicas de las puertas requieren la integración posterior con la escena de Godot.

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
    # o uso de FastNoiseLite de Godot.
	# hahaha @ai/todo:"check if perlin noise is necessary or whats that noise thing"
    pass
```

---

## Enlaces

- [Documentacion de TileMap en Godot](https://docs.godotengine.org/en/stable/tutorials/2d/procedural_geometry/tilemap.html)
- [FastNoiseLite en Godot](https://docs.godotengine.org/en/stable/classes/class_fastnoiselite.html)
- [Algoritmos de Convex Hull](https://en.wikipedia.org/wiki/Convex_hull_algorithms)
