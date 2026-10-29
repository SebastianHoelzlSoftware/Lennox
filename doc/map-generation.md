# Generación Procedural de Mapas: La Arquitectura del Mundo de Cuentos de Hadas

## Descripción General

Este documento describe la arquitectura y los algoritmos del **generador de mundos de cuento de hadas ("Märchenwelt-Generator")** para **Lennox**.
El sistema reemplaza las antiguas aproximaciones rígidas (como combinaciones fragmentadas de Convex Hull, perturbación de vértices y expansión de rectángulos) por un modelo estratificado, armónico y ecológico que genera paisajes naturales, amplias mesetas transitables y biomas densamente poblados de vida y magia.

---

## Estratificación del Generador (Pipeline en 4 Capas)

```
┌─────────────────────────────────────────────────────────────┐
│ 1. Capa Macro: Continentes y Biomas                         │
│    Voronoi orgánico deformado con ruido Simplex (FBM)       │
├─────────────────────────────────────────────────────────────┤
│ 2. Capa Meso: Formaciones Naturales y Grandes Mesetas        │
│    Deformación armónica radial con pasos y cañones          │
├─────────────────────────────────────────────────────────────┤
│ 3. Capa Micro: Población Ecológica Densa (4 Reglas)         │
│    Hitos/Ruinas, arboledas agrupadas, maleza y flora viva   │
├─────────────────────────────────────────────────────────────┤
│ 4. Capa de Renderizado y Presentación                       │
│    TileMapLayers + WorldObjects Y-Sorted en Godot           │
└─────────────────────────────────────────────────────────────┘
```

---

## 1. Capa Macro: Los 8 Biomas del Mundo

El mundo se divide en 8 biomas canónicos generados de forma determinista mediante `BiomeGenerator`:
1. 🌾 **GRASSLAND (Praderas y Alamedas de Cuento)**: Llanuras abiertas de hierba esmeralda, pozos de los deseos, vallas rústicas, flores silvestres.
2. 🌲 **FOREST (Bosque Encantado)**: Arboledas centenarias de robles y sauces, círculos de hadas, setas gigantes y santuarios de madera.
3. 🪨 **ROCKS (Montañas de Dragón)**: Majestuosas mesetas de piedra con amplias cimas transitables, columnas de cuarzo y ruinas monolíticas.
4. 🌊 **ROCKS AND WATER (Costa Acantilada y Fiordos)**: Arrecifes costeros, restos de navíos, faros de piedra y pozas de marea.
5. 🏜️ **DESERT (Dunas Doradas y Oasis)**: Palmerales rodeando manantiales, obeliscos de arenisca y reliquias sepultadas.
6. 🍄 **SWAMP (Ciénaga Misteriosa)**: Bosques sumergidos de sauces, hongos luminiscentes, senderos de madera y calderos de bruja.
7. 🪸 **SEABED (Bahía de Coral)**: Arrecifes turquesa, estrellas de mar, conchas perleras gigantes y anémonas.
8. 💎 **CAVE (Gruta Brillante / Inframundo)**: Cavernas basálticas oscuras, estalagmitas, gemas brillantes y vetas de mineral.

---

## 2. Capa Meso: Formaciones Naturales y Mesas Majestuosas

En lugar de crear pequeños bloques aislados de 2x2 que fragmentaban las caras de los acantilados:
- **Escala adecuada**: Las mesetas y barreras se generan con dimensiones generosas (al menos 8–16 baldosas de ancho), lo que garantiza una cumbre plana y espaciosa sobre la que el jugador puede caminar y descubrir secretos.
- **Deformación Armónica Radial**: El contorno de las formaciones se genera calculando radios en torno a un centro con armónicos trigonométricos:
  $$r(\theta) = R_{\text{base}} + A_1 \sin(k_1 \theta + \phi_1) + \text{jitter}$$
- **Pasos Naturales y Cañones**: Cada formación incorpora pasos de montaña o aperturas transitables de ancho natural (3 a 6 baldosas), garantizando que el mapa sea explorable y nunca frustre el movimiento del jugador.

---

## 3. Capa Micro: Población Ecológica Densa (4 Reglas de Cuento de Hadas)

Para lograr un mundo vibrante ("schön voll mit Zeug"), los objetos se sitúan mediante 4 reglas ecológicas:

### Regla 1: Anclaje de Hitos Narrativos (Landmarks / POIs)
Cada zona importante y un 50% de los chunks albergan un hito principal (un monumento de piedra, pozo sagrado, estatua antigua o altar arcano) que atrae la curiosidad del jugador y sirve como punto de orientación.

### Regla 2: Agrupación Biológica (Clustering de Biotopos)
Los elementos naturales nunca se esparcen de forma aleatoria como ruido estático:
- **Arboledas**: Los árboles crecen en grupos naturales de 3 a 7 unidades.
- **Maleza circundante**: Los arbustos y helechos bordean las arboledas y el pie de los acantilados.
- **Campos florales y minerales**: Las flores silvestres en praderas o los cristales en cuevas aparecen en constelaciones agrupadas.

### Regla 3: Garantía de Transitabilidad (Clearance Corridors)
Los caminos principales y los centros de las mesetas mantienen pasillos despejados de al menos 2 baldosas de ancho, evitando que el jugador quede atrapado por colisiones de objetos.

### Regla 4: Profundidad Perspectiva (Y-Sorting)
Todos los objetos y personajes se renderizan con `y_sort_enabled = true`. Los árboles y ruinas proyectan su presencia hacia el fondo o primer plano de forma correcta en función de la coordenada Y de la base.

---

## 4. Estado Técnico y Pruebas

- **Clases Principales**:
  - `Level` (`src/core/level.gd`): Orquestación de chunks, mapas de bioma, formaciones y objetos.
  - `Chunk` (`src/core/chunk.gd`): Baldoas, barreras y colección de `placed_objects`.
  - `ObjectCatalog` (`src/core/object_catalog.gd`): Catálogo dinámico de cientos de activos para los 8 biomas y categorías comunes.
  - `LevelTileMap` (`scenes/level.gd`): Renderizado de baldosas y contenedores de objetos con ordenación en Y.
- **Cobertura de Pruebas**: Suite de pruebas unitarias e integración en GUT ejecutadas al 100% en verde (72 tests pasando).
