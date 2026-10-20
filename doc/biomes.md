# Sistema de Biomas para Lennox

## Descripcion General

Los biomas definen la **estructura basica y la apariencia** del mundo del juego. Cada bioma tiene **caracteristicas especificas** como densidad de barreras, obstaculos tipicos y frecuencias de aperturas que afectan el flujo del juego.

## Estado actual de la implementacion

- `BiomeGenerator.generate_biome_map()` asigna un tipo de `BiomeType` a cada chunk usando puntos de Voronoi colocados en una cuadrícula cada 5 chunks.
- Las asignaciones de bioma y las fronteras deformadas son deterministas para una misma semilla. `Level.generate()` usa este mapa para asignar el bioma a cada chunk.
- Las fronteras se deforman mediante **domain warping con FastNoiseLite Simplex FBM**: dos muestras de ruido desplazan cada coordenada consultada hasta 2.5 chunks. Esto produce fronteras irregulares, pero **no mezcla biomas ni crea zonas de transición**. El ruido tampoco controla altura o densidad de vegetación.
- `BiomeGenerator.get_biome_params()` proporciona parámetros por bioma. La generación de barreras usa la cantidad, el tamaño y los tipos/cantidad de aperturas configurados para recortar huecos en el polígono. Esos huecos todavía no se representan como objetos `Opening` adjuntos a las barreras; la integración de aperturas interactivas corresponde a LEN-15.
- Los parámetros aleatorios usan un `RandomNumberGenerator` local cuando se proporciona; la generación de un mapa no cambia el estado aleatorio global.

---

## Biomas Base

| Bioma | Descripcion | Color (Hex) | Densidad de Barreras | Barreras Tipicas | Frecuencia de Aperturas |
|-------|-------------|------------|---------------------|-------------------|------------------------|
| Grassland | Areas abiertas y verdes con arboles o rocas aisladas. | `#7CF06B` | Baja (1-2) | Rocks, Tree groups | Alta (1-3) |
| Wood | Vegetacion densa con muchos obstaculos naturales. | `#3A7D44` | Alta (3-5) | Tree groups, Rocks | Media (1-2) |
| Rocks | Regiones montañosas y rocosas con acantilados pronunciados. | `#8B8B8B` | Muy alta (5-8) | Rock formations, Cliffs | Baja (0-1) |
| Water | Lagos, rios o mares. Sin barreras, excepto islas. | `#4169E1` | Ninguna | Islands (logica inversa) | - |
| Sand | Desiertos o regiones costeras con dunas y rocas aisladas. | `#F4A460` | Baja (1-2) | Dunes, Rocks | Alta (1-3) |

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
- **Perfil de Altura:** Plano o ligeramente ondulado (Perlin Noise: 0.3-0.6).
- **Vegetacion:** Hierba, arboles aislados, flores.
- **Barreras:**
  - **Rocks:** Pequeños grupos de rocas (5-8 tiles de diametro).
  - **Tree groups:** 3-5 arboles en grupo.
- **Aperturas:**
  - **Ford:** Frecuente (si hay agua cerca).
  - **Pass:** Media.
  - **Steps:** Poco frecuente.

### Wood
- **Perfil de Altura:** Ligeramente ondulado (Perlin Noise: 0.4-0.7).
- **Vegetacion:** Arboles densos, arbustos, musgo.
- **Barreras:**
  - **Tree groups:** 5-10 arboles en grupo (10-15 tiles de diametro).
  - **Rocks:** Pequeñas protuberancias rocosas.
- **Aperturas:**
  - **Pass:** Frecuente (entre grupos de arboles).
  - **Ford:** Media (si hay agua cerca).
  - **Door:** Poco frecuente (ej. para cuevas o areas especiales).

### Rocks
- **Perfil de Altura:** Muy ondulado a montañoso (Perlin Noise: 0.7-1.0).
- **Vegetacion:** Casi ninguna, líquenes aislados.
- **Barreras:**
  - **Rock formations:** 10-20 tiles de diametro, a menudo poligonos cerrados.
  - **Cliffs:** Paredes verticales (no transitables).
- **Aperturas:**
  - **Pass:** Poco frecuente (cañones estrechos).
  - **Steps:** Media (para diferencias de altura).
  - **Door:** Muy poco frecuente (ej. entradas a cuevas).

### Water
- **Perfil de Altura:** Plano (Perlin Noise: 0.0-0.2).
- **Vegetacion:** Ninguna (excepto en islas).
- **Barreras:**
  - **Islands:** 15-30 tiles de diametro (Rocks o Sand).
- **Aperturas:**
  - **Ford:** Siempre (si la isla limite con tierra).

### Sand
- **Perfil de Altura:** Plano o ligeramente ondulado (Perlin Noise: 0.2-0.5).
- **Vegetacion:** Casi ninguna, cactus aislados (para desiertos).
- **Barreras:**
  - **Dunes:** 6-12 tiles de diametro (colinas de arena).
  - **Rocks:** Pequeñas formaciones rocosas.
- **Aperturas:**
  - **Pass:** Frecuente (entre dunas).
  - **Ford:** Poco frecuente (solo en oasis).

---

## Fronteras entre Biomas (implementacion actual)

Cada chunk recibe un único bioma: no hay mezcla ni zona de amortiguación. Voronoi define la región y Simplex FBM desplaza la posición usada para buscar el punto más cercano. La amplitud actual del desplazamiento es 2.5 chunks.

Las zonas mezcladas, la altura y la densidad de vegetación son ideas de diseño futuro, no comportamiento implementado.

---

## Parametros Especificos de Barreras por Bioma

### Grassland
| Parametro | Valor |
|-----------|-------|
| Barreras por Chunk | 1-2 |
| Tamano de Barreras | 5-10 tiles de diametro |
| Aperturas por Barrera | 1-3 |
| Tipos de Apertura tipicos | Ford (33%), Pass (33%), Steps (33%) |

### Wood
| Parametro | Valor |
|-----------|-------|
| Barreras por Chunk | 3-5 |
| Tamano de Barreras | 8-15 tiles de diametro |
| Aperturas por Barrera | 1-2 |
| Tipos de Apertura tipicos | Pass (33%), Ford (33%), Door (33%) |

### Rocks
| Parametro | Valor |
|-----------|-------|
| Barreras por Chunk | 5-8 |
| Tamano de Barreras | 10-20 tiles de diametro |
| Aperturas por Barrera | 0-1 |
| Tipos de Apertura tipicos | Pass (50%), Steps (50%) |

### Water
| Parametro | Valor |
|-----------|-------|
| Barreras por Chunk | 0-1 (Islands) |
| Tamano de Barreras | 15-30 tiles de diametro |
| Aperturas por Barrera | 1-2 (Fords) |
| Tipos de Apertura tipicos | Ford (100%) |

### Sand
| Parametro | Valor |
|-----------|-------|
| Barreras por Chunk | 1-2 |
| Tamano de Barreras | 6-12 tiles de diametro |
| Aperturas por Barrera | 1-3 |
| Tipos de Apertura tipicos | Pass (80%), Ford (20%) |

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
- [Explicacion de Perlin Noise](https://adrianb.io/2014/08/09/perlinnoise.html)
