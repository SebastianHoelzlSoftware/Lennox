# Formaciones Naturales, Barreras y Pasos en Lennox

## 📌 Evolución de la Arquitectura

> [!NOTE]
> **Actualización Arquitectónica:**
> Las fases tempranas del prototipo experimentaron con una combinación de *Convex Hull*, *perturbación de vértices* y *expansión de rectángulos*. Dicha mezcla generaba geometrías fragmentadas y bloques artificiales poco naturales.
> El sistema actual ha sido refactorizado hacia un **generador de formaciones naturales armónicas** y **grandes mesetas orgánicas**, manteniendo la clase `Barrier` y `Opening` para consultas espaciales y pasos transitables.

---

## 1. Arquitectura de Formaciones Naturales

Las formaciones en el mundo representan obstáculos o hitos geográficos acordes al bioma:
- **Montañas de Dragón (`ROCKS`)**: Grandes crestas de piedra y macizos rocosos.
- **Bosque Encantado (`FOREST`)**: Arboledas densas impenetrables que enmarcan senderos.
- **Costa y Fiordos (`ROCKS_AND_WATER`)**: Arrecifes y acantilados marinos.
- **Ciénaga (`SWAMP`)**: Aguas pantanosas y raíces retorcidas.

### Generación Armónica Radial
Las formaciones se generan calculando polígonos alrededor de un centro dentro del chunk, aplicando funciones armónicas sinusoidales:
$$r(\theta) = R_{\text{base}} + A_1 \sin(k_1 \theta + \phi_1) + \text{jitter}$$
Esto produce contornos suaves, naturales y coherentes que encajan con el pixel art de fantasía del juego.

---

## 2. El Sistema de Pasos y Puertas (`Opening`)

Cada formación natural o barrera puede contener pasos naturales o interactivos para permitir el tránsito del jugador:

| Tipo | Naturaleza | Estado Inicial | Comportamiento |
|---|---|---|---|
| `Opening.OpeningType.PASS` | Paso de montaña / Desfiladero | Abierto | Siempre transitable |
| `Opening.OpeningType.STEPS` | Escalones de piedra o sendero | Abierto | Transitable |
| `Opening.OpeningType.FORD` | Vado de río / Rocas de paso | Abierto | Transitable |
| `Opening.OpeningType.DOOR` | Puerta antigua / Reja de ruina | Cerrada | Bloquea el paso hasta que el jugador interactúa (`open()`) |

### Consultas Espaciales
- `barrier.contains_point(Vector2(x, y))`: Devuelve si una coordenada pertenece a la formación. Si el punto cae dentro de una apertura activa (`is_passable() == true`), el punto **no** bloquea al jugador y permanece transitable.
- `barrier.get_passable_points(chunk_size)`: Devuelve el conjunto de coordenadas de paso del chunk.
