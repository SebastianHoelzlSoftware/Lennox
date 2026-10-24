# Sistema de Biomas para Lennox

## Descripcion General

Los biomas definen la **estructura basica y la apariencia** del mundo del juego. Cada bioma tiene **caracteristicas especificas** como densidad de barreras, obstaculos tipicos y frecuencias de aperturas que afectan el flujo del juego.

## Estado actual de la implementacion

- `BiomeGenerator.generate_biome_map()` asigna un tipo de `BiomeType` a cada chunk usando puntos de Voronoi colocados en una cuadrícula cada 4 chunks.
- Las asignaciones de bioma y las fronteras deformadas son deterministas para una misma semilla. `Level.generate()` usa este mapa para asignar el bioma a cada chunk.
- Cada chunk se rellena con la baldosa base de su bioma antes de aplicar barreras; por eso las regiones de roca, agua y arena también se distinguen visualmente del terreno verde.
- Las fronteras se deforman mediante **domain warping con FastNoiseLite Simplex FBM**. La configuración común a todos los biomas usa 4 octavas, una frecuencia de `0.05` (`1.0 / 20.0`) y una ganancia fractal de `0.5`. Dos muestras de ruido desplazan cada eje de la posición consultada hasta `2.5` chunks. Esto produce fronteras irregulares, pero **no mezcla biomas ni crea zonas de transición**. El ruido tampoco controla altura o densidad de vegetación.
- No hay parámetros de ruido específicos por bioma en la implementación actual. Los perfiles de altura Perlin que aparecían en las descripciones siguientes eran propuestas de diseño y se omiten porque todavía no existe generación de altura.
- `BiomeGenerator.get_biome_params()` proporciona parámetros por bioma. La generación de barreras usa la cantidad, el tamaño y los tipos/cantidad de aperturas configurados para recortar huecos en el polígono. Esos huecos todavía no se representan como objetos `Opening` adjuntos a las barreras; la integración de aperturas interactivas corresponde a LEN-15.
- Los parámetros aleatorios usan un `RandomNumberGenerator` local cuando se proporciona; la generación de un mapa no cambia el estado aleatorio global.

---

## Referencias visuales

Los archivos `assets/*_overview.jpeg` son referencias visuales de los conjuntos gráficos previstos para cada entorno; ilustran la dirección artística y no necesariamente una captura del mapa generado actualmente.

<table>
  <tr><th>Cueva</th><th>Desierto</th></tr>
  <tr>
    <td><img src="../assets/cave_overview.jpeg" alt="Referencia visual de cueva" width="100%"></td>
    <td><img src="../assets/desert_overview.jpeg" alt="Referencia visual de desierto" width="100%"></td>
  </tr>
  <tr><th>Bosque</th><th>Pradera</th></tr>
  <tr>
    <td><img src="../assets/forest_overview.jpeg" alt="Referencia visual de bosque" width="100%"></td>
    <td><img src="../assets/grasland_overview.jpeg" alt="Referencia visual de pradera" width="100%"></td>
  </tr>
  <tr><th>Rocas</th><th>Rocas y agua</th></tr>
  <tr>
    <td><img src="../assets/rocks_overview.jpeg" alt="Referencia visual de rocas" width="100%"></td>
    <td><img src="../assets/rocks_water_overview.jpeg" alt="Referencia visual de rocas y agua" width="100%"></td>
  </tr>
  <tr><th>Pantano</th><th>Agua</th></tr>
  <tr>
    <td><img src="../assets/swamp_overview.jpeg" alt="Referencia visual de pantano" width="100%"></td>
    <td><img src="../assets/water_overview.jpeg" alt="Referencia visual de agua" width="100%"></td>
  </tr>
</table>

La vista animada de la cueva se encuentra en [`assets/cave_overview_animated.mp4`](../assets/cave_overview_animated.mp4).

La captura más reciente del juego está en [`doc/video/daily_screencap.mp4`](video/daily_screencap.mp4) y se muestra en el README. La actualización es manual: reemplaza ese archivo cada día manteniendo el mismo nombre y ruta.

---

## Biomas Base

| Bioma | Descripcion | Color (Hex) | Densidad de Barreras | Barreras Tipicas | Frecuencia de Aperturas |
|-------|-------------|------------|---------------------|-------------------|------------------------|
| Grassland | Areas abiertas y verdes con arboles o rocas aisladas. | `#7CF06B` | Alta (4-6) | Rocks, Tree groups | Media (1-2) |
| Wood | Vegetacion densa con muchos obstaculos naturales. | `#3A7D44` | Muy alta (7-10) | Tree groups, Rocks | Media (1-2) |
| Rocks | Regiones montañosas y rocosas con acantilados pronunciados. | `#8B8B8B` | Extrema (8-12) | Rock formations, Cliffs | Baja (0-1) |
| Water | Lagos, rios o mares. Puede contener islas. | `#4169E1` | Muy baja (0-1) | Islands | Media (1-2) |
| Sand | Desiertos o regiones costeras con dunas y rocas aisladas. | `#F4A460` | Alta (4-6) | Dunes, Rocks | Media (1-2) |

---

## Definicion Tecnica: Clase Global `BiomeType` (`src/core/biome_type.gd`)

Los biomas estan modelados como una **clase global con enum** en GDScript (`class_name BiomeType`). Esto permite acceder directamente a los valores y tipos en cualquier parte del codigo sin prefijos (ej. `BiomeType.GRASSLAND`):

```gdscript
# src/core/biome_type.gd
class_name BiomeType

enum Type {
	GRASSLAND,
	WOOD,
	ROCKS,
	WATER,
	SAND
}

const GRASSLAND: Type = Type.GRASSLAND
const WOOD: Type = Type.WOOD
const ROCKS: Type = Type.ROCKS
const WATER: Type = Type.WATER
const SAND: Type = Type.SAND
```

### Correspondencia de Valores:
| Enum / Constante | Indice Numerico | Nombre |
|------------------|-----------------|--------|
| `BiomeType.GRASSLAND` | `0` | Grassland |
| `BiomeType.WOOD` | `1` | Wood |
| `BiomeType.ROCKS` | `2` | Rocks |
| `BiomeType.WATER` | `3` | Water |
| `BiomeType.SAND` | `4` | Sand |

> [!NOTE]
> `BiomeType` fue desacoplado de `Level` a su propio archivo global (`src/core/biome_type.gd`). Clases como `Chunk`, `Barrier`, `Opening` y los tests unitarios pueden referenciarlo directamente como `BiomeType.GRASSLAND` o como tipo estatico `BiomeType.Type`.

---

## Parametros por Bioma

### Grassland
- **Vegetacion:** Hierba, arboles aislados, flores.
- **Barreras:**
  - **Rocks:** Grupos pequeños y aislados de rocas.
  - **Tree groups:** 3-5 arboles en grupo.
- **Aperturas:**
  - **Ford:** Frecuente (si hay agua cerca).
  - **Pass:** Media.
  - **Steps:** Poco frecuente.

### Wood
- **Vegetacion:** Arboles densos, arbustos, musgo.
- **Barreras:**
  - **Tree groups:** 5-10 arboles en grupo (10-15 tiles de diametro).
  - **Rocks:** Pequeñas protuberancias rocosas.
- **Aperturas:**
  - **Pass:** Frecuente (entre grupos de arboles).
  - **Ford:** Media (si hay agua cerca).
  - **Door:** Poco frecuente (ej. para cuevas o areas especiales).

### Rocks
- **Vegetacion:** Casi ninguna, líquenes aislados.
- **Barreras:**
  - **Rock formations:** 10-20 tiles de diametro, a menudo poligonos cerrados.
  - **Cliffs:** Paredes verticales (no transitables).
- **Aperturas:**
  - **Pass:** Poco frecuente (cañones estrechos).
  - **Steps:** Media (para diferencias de altura).
  - **Door:** Muy poco frecuente (ej. entradas a cuevas).

### Water
- **Vegetacion:** Ninguna (excepto en islas).
- **Barreras:**
  - **Islands:** 15-30 tiles de diametro (Rocks o Sand).
- **Aperturas:**
  - **Ford:** Siempre (si la isla limite con tierra).

### Sand
- **Vegetacion:** Casi ninguna, cactus aislados (para desiertos).
- **Barreras:**
  - **Dunes:** 6-12 tiles de diametro (colinas de arena).
  - **Rocks:** Pequeñas formaciones rocosas.
- **Aperturas:**
  - **Pass:** Frecuente (entre dunas).
  - **Ford:** Poco frecuente (solo en oasis).

---

## Fronteras entre Biomas (implementacion actual)

Cada chunk recibe un único bioma: no hay mezcla ni zona de amortiguación. Los centros de Voronoi están separados 4 chunks; Simplex FBM desplaza la posición usada para buscar el punto más cercano. La amplitud actual del desplazamiento es 2.5 chunks.

Las zonas mezcladas, la altura y la densidad de vegetación son ideas de diseño futuro, no comportamiento implementado.

---

## Parametros Especificos de Barreras por Bioma

Los valores siguientes son rangos iniciales de balance para chunks de 32 × 32 tiles. Se centralizan en `src/core/biome_config.gd` para poder ajustarlos sin modificar la lógica de generación. `barrier_size` limita la dispersión de los puntos que forman el polígono; no es un diámetro garantizado. La cantidad de puntos controla el detalle de la forma.

### Grassland
| Parametro | Valor |
|-----------|-------|
| Barreras por Chunk | 4-6 |
| Rango de dispersión de la barrera | 8-14 tiles |
| Puntos por barrera | 5-8 |
| Aperturas intentadas por barrera | 1-2 |
| Tipos de Apertura | Ford, Pass, Steps (probabilidad igual) |

### Wood
| Parametro | Valor |
|-----------|-------|
| Barreras por Chunk | 7-10 |
| Rango de dispersión de la barrera | 10-16 tiles |
| Puntos por barrera | 8-12 |
| Aperturas por Barrera | 1-2 |
| Tipos de Apertura | Pass, Ford, Door (probabilidad igual) |

### Rocks
| Parametro | Valor |
|-----------|-------|
| Barreras por Chunk | 8-12 |
| Rango de dispersión de la barrera | 12-18 tiles |
| Puntos por barrera | 10-15 |
| Aperturas por Barrera | 0-1 |
| Tipos de Apertura | Pass, Steps (probabilidad igual) |

### Water
| Parametro | Valor |
|-----------|-------|
| Barreras por Chunk | 0-1 (islas) |
| Rango de dispersión de la barrera | 8-14 tiles |
| Puntos por barrera | 5-10 |
| Aperturas por Barrera | 1-2 (Fords) |
| Tipos de Apertura | Ford |

### Sand
| Parametro | Valor |
|-----------|-------|
| Barreras por Chunk | 4-6 |
| Rango de dispersión de la barrera | 8-14 tiles |
| Puntos por barrera | 5-8 |
| Aperturas por Barrera | 1-2 |
| Tipos de Apertura | Pass, Ford (probabilidad igual) |

---

## Implementacion y parametros

La implementación fuente está en `src/core/biome_generator.gd`. `generate_biome_map(seed, width, height)` devuelve una matriz indexada como `[x][y]` con valores `BiomeType.Type`. `get_biome_params()` define los rangos de barreras y los tipos de apertura disponibles; cuando se llama con un RNG local, los valores aleatorios también son reproducibles.

Los rangos de cantidad y tamaño indicados en las tablas anteriores describen los parámetros usados por la generación. El tamaño limita la dispersión de los puntos; la forma final también depende del hull, la perturbación y los límites del chunk.

---

## Extensiones

### Agregar Nuevos Biomas
1. **Definir nuevo bioma:**
   - Nombre, descripcion, color.
   - Densidad de barreras, barreras tipicas, frecuencia de aperturas.
2. **Ajustar parametros del bioma:**
   - Extender `get_biome_params()`.
3. **Agregar texturas:**
   - Importar nuevos tiles para el bioma en Godot.

### Objetos Especificos por Bioma
- **Grassland:** Flores, hongos.
- **Wood:** Arboles, arbustos, troncos caidos.
- **Rocks:** Piedras, cristales.
- **Water:** Algas, lirios de agua.
- **Sand:** Cactus, dunas.

---

## Enlaces

- [Godot FastNoiseLite](https://docs.godotengine.org/en/stable/classes/class_fastnoiselite.html)
- [Diagrama de Voronoi](https://en.wikipedia.org/wiki/Voronoi_diagram)
