# Generación Procedural de Mapas: La Arquitectura del Mundo de Cuentos de Hadas

## Descripción General

Este documento describe la arquitectura y los algoritmos del **generador de mundos de cuento de hadas ("Märchenwelt-Generator")** para **Lennox**.
El mundo es un campo continuo que atraviesa los chunks: mesetas, cañones y fronteras de bioma fluyen sin costuras, y un motor de autotiling a nivel de baldosa dibuja suelos y acantilados con las piezas originales de CraftPix.

---

## Estratificación del Generador (Pipeline en 4 Capas)

```
┌─────────────────────────────────────────────────────────────┐
│ 1. Capa Macro: Biomas                                       │
│    Voronoi + Simplex (por chunk) y fronteras deformadas     │
│    por macro-celda, suavizadas para evitar islotes sueltos  │
├─────────────────────────────────────────────────────────────┤
│ 2. Capa Meso: Campo continuo de mesetas                     │
│    Elevación FBM + tallado de cañones + reglas de forma     │
├─────────────────────────────────────────────────────────────┤
│ 3. Capa Micro: Población ecológica                          │
│    Recetas por bioma, huellas sin solapes, arboledas        │
├─────────────────────────────────────────────────────────────┤
│ 4. Renderizado: TerrainPainter                              │
│    Suelo + manchas autotile + decals + acantilados 3/4      │
└─────────────────────────────────────────────────────────────┘
```

---

## 1. Capa Macro: Los 8 Biomas del Mundo

`BiomeGenerator` asigna un bioma a cada chunk (Voronoi deformado). `Level.get_biome_at_macro()` refina
la frontera a nivel de macro-celda (2×2 baldosas) con un ruido de deformación de baja frecuencia y un fleco
de alta frecuencia; después un filtro de mayoría elimina celdas aisladas. Así las fronteras serpentean
en lugar de seguir la rejilla de chunks.

1. 🌾 **GRASSLAND**: hierba sobre tierra con senderos serpenteantes, flores y matas.
2. 🌲 **FOREST**: hierba densa, arboledas agrupadas, setas y helechos.
3. 🪨 **ROCKS**: suelo de piedra clara y macizos grises con agujas oscuras.
4. 🏝️ **ROCKS AND WATER**: islas flotantes sobre un mar de nubes.
5. 🏜️ **DESERT**: arena, oasis de hierba y mesas de tierra anaranjada.
6. 🍄 **SWAMP**: barro y hierba húmeda, flora extraña y calderos.
7. 🪸 **SEABED**: lecho marino oscuro con montículos de arena azulada.
8. 💎 **CAVE**: losas de mazmorra, cristales, huesos y ruinas oscuras.

---

## 2. Capa Meso: Campo Continuo de Mesetas

- **Elevación**: ruido FBM simplex muestreado en coordenadas globales de macro-celda; el umbral depende del bioma.
- **Cañones**: donde `|canyon| < 0.085` se talla una garganta transitable.
- **Pase de jugabilidad**: chunks casi cubiertos abren un claro central; chunks sin relieve reciben una meseta escénica.
- **Reglas de forma** (garantizan piezas de autotiling válidas):
  1. Sin conexiones solo diagonales.
  2. Ningún hueco vertical de 1 macro-celda bajo un borde sur: la cara de roca nunca tapa otra meseta.
  3. Sin celdas sueltas de 1×1.
- **Estilo por meseta**: cada meseta conexa recibe un único estilo de acantilado (votación del bioma dominante), así una cordillera no cambia de material a mitad de camino.

---

## 3. Capa Micro: Población Ecológica

`Level._populate_chunk_objects()` sigue recetas por bioma (`POPULATION_RECIPES`):

- **Clases de baldosa**: valle (suelo libre, sin cara de roca ni al pie de ella) o interior de meseta (a 1 baldosa del borde). El techo de la cueva no se puebla.
- **Huellas**: cada sprite reserva una huella proporcional a su tamaño → sin solapes.
- **Orden**: landmarks enormes → grandes → medianos → detalles.
- **Arboledas**: árboles y arbustos aceptan posiciones según un ruido de bosquecillos, dejando claros.
- **Temática**: las categorías comunes se filtran por bioma (`COMMON_FILTERS`): palmeras y cactus en el desierto, árboles musgosos en el pantano, sin árboles nevados en la pradera…
- **Frontera orgánica**: el sprite se elige con el bioma real de la baldosa donde cae.

---

## 4. Renderizado: `TerrainPainter`

`src/core/terrain_painter.gd` dibuja el mundo a nivel de baldosa en capas `TileMapLayer` propias
(`Ground`, `GroundOverlay`, `GroundDecor`, `CliffFace`, `CliffTop`, `TopDecor`, `CliffSpillV`, `CliffSpillH`),
con un `TileSet` creado en tiempo de ejecución a partir de las hojas PNG.

- **Clasificación 3×3 + esquinas cóncavas** con los 8 vecinos. Las máscaras usan macro-celdas de 2×2, por lo que todas las formas tienen ≥2 baldosas de grosor y la clasificación es inequívoca.
- **Vista 3/4**: la cara de roca (1–3 filas según el estilo) se dibuja *debajo* de cada borde sur.
- **Esquinas cóncavas sur**: la cara continúa por debajo del flanco vecino; el borde transparente de la hierba cuelga sobre la roca sin dejar huecos.
- **Derrame**: los estilos con agujas (rocas) emiten piezas que sobresalen de la huella hacia las celdas vacías.
- **Suelos**: suelo base + manchas autotile (hierba sobre tierra, oasis…) + senderos + decals sueltos.

Los estilos se definen como datos en `src/core/terrain_styles.gd` (coordenadas de atlas verificadas con
`scenes/terrain_lab.tscn`, que dibuja una forma de prueba con todos los casos para cada bioma).

| Estilo | Hoja | Uso |
| :--- | :--- | :--- |
| `grass` | `grassland/tiles/ground_grasss.png` | Pradera, bosque, pantano |
| `dirt` | `grassland/tiles/ground_grasss.png` | Desierto |
| `rock` | `tiles/rocks/Ground_rocks.png` | Rocas, cueva |
| `cave` | `cave/tiles/ground_source.png` | Paredes de cueva (opcional) |
| `flying` | `rocks_and_water/tiles/Ground_grass_flying.png` | Islas flotantes |
| `seabed` | `seabed/tiles/Ground_sand.png` | Lecho marino |

---

## 5. Estado Técnico y Pruebas

- **Clases principales**:
  - `Level` (`src/core/level.gd`): biomas, campo de mesetas, reglas de forma, estilos y población.
  - `TerrainPainter` / `TerrainStyles` (`src/core/`): motor de autotiling y datos de estilo.
  - `Chunk` (`src/core/chunk.gd`): baldosas lógicas, barreras y `placed_objects`.
  - `ObjectCatalog` (`src/core/object_catalog.gd`): catálogo de activos de los 8 biomas.
  - `LevelTileMap` (`scenes/level.gd`): construye las rejillas y lanza el renderizado y los sprites.
- **Pruebas**: 83 tests GUT en verde (77 unitarios + 6 de integración), incluidos los del motor de terreno y las reglas de forma.
