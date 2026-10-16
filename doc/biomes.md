# Sistema de Biomas para Lennox

## Descripcion General

Los biomas definen la **estructura basica y la apariencia** del mundo del juego. Cada bioma tiene **caracteristicas especificas** como densidad de barreras, obstaculos tipicos y frecuencias de aperturas que afectan el flujo del juego.

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

## Transiciones entre Biomas

### Reglas para transiciones suaves
1. **Voronoi + Perlin Noise:**
   - **Voronoi** define las regiones gruesas.
   - **Perlin Noise** suaviza las transiciones entre regiones.

2. **Zonas de amortiguacion:**
   - En los limites entre biomas hay una **zona de amortiguacion de 2-4 tiles** donde se mezclan las propiedades de ambos biomas.
   - **Ejemplo:** Grassland → Wood: La zona de amortiguacion contiene hierba y arboles aislados.

3. **Dominancia de Bioma:**
   - El **bioma dominante** en una celda esta determinado por el **punto Voronoi mas cercano**.
   - El **valor de Noise** determina la **altura y densidad** dentro del bioma.

### Ejemplo: Grassland → Wood
| Distancia al limite del bosque | Mezcla de Biomas | Vegetacion |
|--------------------------------|-----------------|------------|
| 0-2 tiles | 70% Grassland, 30% Wood | Hierba + arboles aislados |
| 2-4 tiles | 30% Grassland, 70% Wood | Hierba densa + muchos arboles |
| >4 tiles | 100% Wood | Solo arboles y arbustos |

---

## Parametros Especificos de Barreras por Bioma

### Grassland
| Parametro | Valor |
|-----------|-------|
| Barreras por Chunk | 1-2 |
| Tamano de Barreras | 5-10 tiles de diametro |
| Aperturas por Barrera | 1-3 |
| Tipos de Apertura tipicos | Ford (50%), Pass (30%), Steps (20%) |

### Wood
| Parametro | Valor |
|-----------|-------|
| Barreras por Chunk | 3-5 |
| Tamano de Barreras | 8-15 tiles de diametro |
| Aperturas por Barrera | 1-2 |
| Tipos de Apertura tipicos | Pass (60%), Ford (20%), Door (20%) |

### Rocks
| Parametro | Valor |
|-----------|-------|
| Barreras por Chunk | 5-8 |
| Tamano de Barreras | 10-20 tiles de diametro |
| Aperturas por Barrera | 0-1 |
| Tipos de Apertura tipicos | Pass (70%), Steps (30%) |

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

## Implementacion en GDScript

### Generar Mapa de Biomas
```gdscript
func generate_biome_map(seed: int, width: int, height: int) -> Array:
    var biome_map = []
    var noise = OpenSimplexNoise.new()
    noise.seed = seed
    noise.octaves = 4
    noise.period = 20.0
    noise.persistence = 0.5
    
    # Generar puntos Voronoi (1 punto cada 5x5 chunks)
    var voronoi_points = []
    var step = 5
    for x in range(0, width, step):
        for y in range(0, height, step):
            voronoi_points.append(Vector2(x, y))
    
    # Asignar tipos de bioma a puntos Voronoi
    var biome_types = ["Grassland", "Wood", "Rocks", "Water", "Sand"]
    var biome_assignments = []
    for point in voronoi_points:
        var biome_idx = randi() % biome_types.size()
        biome_assignments.append(biome_types[biome_idx])
    
    # Crear mapa de biomas
    for x in range(width):
        biome_map.append([])
        for y in range(height):
            # Encontrar el punto Voronoi mas cercano
            var min_dist = INF
            var closest_idx = -1
            for i in range(voronoi_points.size()):
                var dist = voronoi_points[i].distance_to(Vector2(x, y))
                if dist < min_dist:
                    min_dist = dist
                    closest_idx = i
            
            # Valor Noise para suavizar
            var noise_val = noise.get_noise_2d(x * 0.1, y * 0.1)
            
            # Asignar bioma (con suavizacion por Noise)
            var biome = biome_assignments[closest_idx]
            biome_map[x].append(biome)
    
    return biome_map
```

### Obtener Parametros Especificos del Bioma
```gdscript
func get_biome_params(biome: BiomeType.Type) -> Dictionary:
    match biome:
        BiomeType.GRASSLAND:
            return {
                "barrier_count": randi_range(1, 2),
                "barrier_size": randi_range(5, 10),
                "opening_count": randi_range(1, 3),
                "opening_types": ["Ford", "Pass", "Steps"]
            }
        BiomeType.WOOD:
            return {
                "barrier_count": randi_range(3, 5),
                "barrier_size": randi_range(8, 15),
                "opening_count": randi_range(1, 2),
                "opening_types": ["Pass", "Ford", "Door"]
            }
        BiomeType.ROCKS:
            return {
                "barrier_count": randi_range(5, 8),
                "barrier_size": randi_range(10, 20),
                "opening_count": randi_range(0, 1),
                "opening_types": ["Pass", "Steps"]
            }
        BiomeType.WATER:
            return {
                "barrier_count": randi_range(0, 1),
                "barrier_size": randi_range(15, 30),
                "opening_count": randi_range(1, 2),
                "opening_types": ["Ford"]
            }
        BiomeType.SAND:
            return {
                "barrier_count": randi_range(1, 2),
                "barrier_size": randi_range(6, 12),
                "opening_count": randi_range(1, 3),
                "opening_types": ["Pass", "Ford"]
            }
        _:
            return {
                "barrier_count": 1,
                "barrier_size": 8,
                "opening_count": 1,
                "opening_types": ["Pass"]
            }
```

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

- [Godot OpenSimplexNoise](https://docs.godotengine.org/en/stable/classes/class_opensimplexnoise.html)
- [Diagrama de Voronoi](https://en.wikipedia.org/wiki/Voronoi_diagram)
- [Explicacion de Perlin Noise](https://adrianb.io/2014/08/09/perlinnoise.html)
