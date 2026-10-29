# Catálogo y Sistema de los 8 Biomas de Lennox

## Descripción General

El mundo de **Lennox** está compuesto por **8 biomas temáticos** distintivos, cada uno diseñado con su propio conjunto visual de baldosas, elementos decorativos, hitos narrativos y paleta de colores. El generador asigna biomas usando regiones de Voronoi deformadas con ruido fractal Simplex (FastNoiseLite FBM), logrando transiciones orgánicas y variadas.

---

## Los 8 Biomas Canónicos

| Bioma | Nombre Temático | Tipo de Suelo Base | Densidad de Vegetación / Rocas | Hitos y Objetos Característicos |
|---|---|---|---|---|
| **GRASSLAND** | *Praderas y Alamedas* | `TileType.GRASS` | Media | Pozos de los deseos, vallas de madera, margaritas, arbustos en flor. |
| **FOREST** | *El Bosque Encantado* | `TileType.GRASS` | Muy Alta | Robles centenarios, setas gigantes, altares de madera, tocones musgosos. |
| **ROCKS** | *Montañas de Dragón* | `TileType.ROCK` | Alta (Rocosa) | Grandes mesetas de piedra, columnas de cuarzo, estatuas de dragón, grava. |
| **ROCKS_AND_WATER** | *Costa y Fiordos* | `TileType.WATER` | Media | Pozas de marea, faros antiguos, tablas de barco encalladas, arrecifes. |
| **DESERT** | *Dunas Doradas* | `TileType.SAND` | Baja / Focal | Palmeras de oasis, obeliscos de arenisca, vasijas milenarias, fósiles. |
| **SWAMP** | *Ciénaga Misteriosa* | `TileType.WATER` | Alta | Sauces llorones sumergidos, hongos venenosos luminosos, calderos de bruja. |
| **SEABED** | *Bahía de Coral* | `TileType.WATER` | Muy Alta | Corales multicolores, estrellas de mar, conchas gigantes, anémonas. |
| **CAVE** | *Glimmergrotte / Caverna* | `TileType.ROCK` | Media (Mineral) | Estalagmitas, cristales resplandecientes, vagonetas mineras, vetas de amatista. |

---

## 🌿 Referencias Visuales Oficiales

Las imágenes de referencia artística de cada bioma se encuentran en `assets/*_overview.jpeg`:

<table>
  <tr><th>Cueva (Cave)</th><th>Desierto (Desert)</th></tr>
  <tr>
    <td><img src="../assets/cave_overview.jpeg" alt="Referencia visual de cueva" width="100%"></td>
    <td><img src="../assets/desert_overview.jpeg" alt="Referencia visual de desierto" width="100%"></td>
  </tr>
  <tr><th>Bosque (Forest)</th><th>Pradera (Grassland)</th></tr>
  <tr>
    <td><img src="../assets/forest_overview.jpeg" alt="Referencia visual de bosque" width="100%"></td>
    <td><img src="../assets/grasland_overview.jpeg" alt="Referencia visual de pradera" width="100%"></td>
  </tr>
  <tr><th>Rocas (Rocks)</th><th>Rocas y Agua (Rocks and Water)</th></tr>
  <tr>
    <td><img src="../assets/rocks_overview.jpeg" alt="Referencia visual de rocas" width="100%"></td>
    <td><img src="../assets/rocks_water_overview.jpeg" alt="Referencia visual de rocas y agua" width="100%"></td>
  </tr>
  <tr><th>Pantano (Swamp)</th><th>Lecho Marino (Seabed)</th></tr>
  <tr>
    <td><img src="../assets/swamp_overview.jpeg" alt="Referencia visual de pantano" width="100%"></td>
    <td><img src="../assets/water_overview.jpeg" alt="Referencia visual de lecho marino / agua" width="100%"></td>
  </tr>
</table>

---

## 📦 Estructura de Activos en el Proyecto

Todos los activos se organizan de forma estricta y limpia bajo:
- `assets/biomes/<nombre_bioma>/tiles/`: Hojas de baldosas y texturas de suelo.
- `assets/biomes/<nombre_bioma>/objects/`: Sprites individuales de vegetación, rocas y detalles del bioma.
- `assets/common/`: Categorías compartidas (`trees`, `bushes`, `ruins`, `roads`, `icons`, `characters`, `cursed_land`).

El módulo `ObjectCatalog` (`src/core/object_catalog.gd`) ofrece funciones con caché y determinismo para consultar y cargar estas texturas dinámicamente en tiempo de ejecución.
