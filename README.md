# Lennox

> *Un juego 2D movil que ensena a los ninos a leer en ingles y espanol. El enfoque esta en la diversion y una educacion profesional.*

---

## 📖 Descripcion

**Lennox** es un juego educativo 2D desarrollado con **Godot Engine 4.x**, disenado para ayudar a los ninos a aprender a leer en **ingles y espanol** de manera interactiva y divertida. El proyecto combina mecanicas de juego atractivas con contenido pedagogico de alta calidad, priorizando siempre la experiencia del usuario y el aprendizaje efectivo.

## 🌟 Vision de Lennox

<p align="center">
  <img src="doc/images/lennox_project_vision.jpg" alt="Vision del juego educativo Lennox con biomas, exploracion y aprendizaje de lectura" width="100%">
</p>

---

## 🎬 Daily Screencap

<p align="center"><strong>La captura más reciente del juego</strong></p>

<p align="center">
  <img src="doc/images/screenshot_of_the_day.png" alt="Captura de pantalla del dia" width="100%">
</p>

<p align="center"><a href="doc/video/daily_screencap.mp4">▶ Abrir o descargar el video del día</a></p>

---

## 🎮 Estado del Proyecto y Hoja de Ruta de Jira

El desarrollo de **Lennox** se organiza y supervisa de forma estructurada a traves de **Atlassian Jira**. Los prefijos y numeros (por ejemplo, `LEN-3`, `LEN-5`) corresponden a los tickets y tareas oficiales dentro del proyecto de Jira:

- **Espacio de trabajo de Jira:** [devhoelzlsebastian.atlassian.net](https://devhoelzlsebastian.atlassian.net/jira/software/projects/LEN/boards/35?filter=&groupBy=none)
- **Clave del proyecto:** `LEN` (Lennox)

### 📊 Estado Actual de Tareas e Hitos

| Ticket | Titulo / Hito | Estado | Detalles |
| :--- | :--- | :---: | :--- |
| **LEN-3** | Definir la estructura de niveles y chunks | ✅ Completado | Estructura del nivel y acceso a chunks por coordenadas |
| **LEN-10** | Configurar el entorno de pruebas TDD | ✅ Completado | Godot, VS Code y GUT |
| **LEN-11** | Implementar las clases Level y Chunk con TDD | ✅ Completado | Clases principales de nivel y chunks |
| **LEN-13** | Implementar el sistema de biomas | ✅ Completado | Mapa de biomas determinista, Voronoi con domain warping y parámetros por bioma |
| **LEN-14** | Implementar el algoritmo de generación de barreras | ✅ Completado | Barreras por bioma, convex hull, perturbación y aplicación a las baldosas |
| **LEN-15** | Colocar aperturas en las barreras | ✅ Completado | Aperturas generadas asociadas a barreras; puertas cerradas bloquean y otras aperturas son transitables |
| **LEN-34** | Implementar colocación de objetos con ocupación de baldosas | 📋 Por hacer | La decoración actual de hierba es una demostración temporal; falta el algoritmo de ocupación |
| **LEN-17** | Pruebas de integración de barreras (LEN-5) | ✅ Completado | Pruebas unitarias y de integración para la generación y aplicación de barreras |
| **LEN-16** | Integrar Godot y crear un nivel prototipo | 📋 Por hacer | Integración del mapa y prototipo dentro del motor |
| **LEN-20** | Añadir características de mundo entre chunks | 📋 Por hacer | Soporte para elementos que atraviesan los límites entre chunks |

---

## 🗺️ Generacion procedural del mapa

<p align="center">
  <img src="doc/images/procedual_map_generation.jpg" alt="Diagrama de generacion procedural del mapa, biomas, barreras y aperturas" width="100%">
</p>

---

## 🌿 Referencias visuales de los biomas

Estas imágenes muestran los estilos y conjuntos visuales previstos para los distintos entornos. All credits go to @craftpix

<table>
 <tr><th>Cueva</th><th>Desierto</th></tr>
 <tr>
   <td><img src="assets/cave_overview.jpeg" alt="Referencia visual del bioma de cueva" width="100%"></td>
   <td><img src="assets/desert_overview.jpeg" alt="Referencia visual del bioma de desierto" width="100%"></td>
 </tr>
 <tr><th>Bosque</th><th>Pradera</th></tr>
 <tr>
   <td><img src="assets/forest_overview.jpeg" alt="Referencia visual del bioma de bosque" width="100%"></td>
   <td><img src="assets/grasland_overview.jpeg" alt="Referencia visual del bioma de pradera" width="100%"></td>
 </tr>
 <tr><th>Rocas</th><th>Rocas y agua</th></tr>
 <tr>
   <td><img src="assets/rocks_overview.jpeg" alt="Referencia visual del bioma rocoso" width="100%"></td>
   <td><img src="assets/rocks_water_overview.jpeg" alt="Referencia visual del entorno de rocas y agua" width="100%"></td>
 </tr>
 <tr><th>Pantano</th><th>Agua</th></tr>
 <tr>
   <td><img src="assets/swamp_overview.jpeg" alt="Referencia visual del bioma de pantano" width="100%"></td>
   <td><img src="assets/water_overview.jpeg" alt="Referencia visual del bioma acuático" width="100%"></td>
 </tr>
</table>

La animación de la cueva también está disponible en [`assets/cave_overview_animated.mp4`](assets/cave_overview_animated.mp4).

---

## 🛠 Tecnologias

- **Motor**: [Godot Engine 4.x](https://godotengine.org/) (GDScript)
- **Testing**: [GUT](https://github.com/bitwes/Gut) (Godot Unit Test)
- **Estructura del proyecto**:
  ```
  lennox/
  ├── src/
  │   └── core/
  │       ├── level.gd        # Generacion de niveles
  │       ├── chunk.gd        # Sistema de chunks
  │       ├── tile_object_cell.gd    # Celda visual de un objeto de TileSet
  │       ├── tile_object_pattern.gd # Huella y validacion de colocacion
  │       ├── tile_object_library.gd # Biblioteca de objetos con nombre
  │       ├── barrier.gd      # Barreras y consulta de aperturas (LEN-5 / LEN-15)
  │       ├── opening.gd      # Aperturas generadas e interactivas (LEN-15)
  │       ├── biome_type.gd   # Enum global de biomas (BiomeType)
  │       └── tile_type.gd    # Enum global de baldosas (TileType)
  ├── test/
  │   ├── unit/               # Tests unitarios (GUT)
  │   └── integration/        # Tests de integracion (GUT)
  ├── assets/tiles/rocks/
  │   ├── rocks_16x16.tres             # TileSet combinado que usa la escena
  │   └── tile_object_library.tres     # Patrones y grupos de atlas
  ├── assets/*_overview.jpeg           # Referencias visuales de biomas
  ├── scenes/
  │   ├── main.tscn                    # Escena de demostracion del mundo
  │   └── level.gd                     # Renderizado de chunks en TileMapLayer
  ├── doc/
  │   ├── map-generation.md   # Generacion, objetos y decoracion temporal
  │   ├── barriers.md         # Documentacion LEN-5
  │   ├── biomes.md           # Documentacion de biomas (LEN-4)
  │   ├── level-structure.md  # Estructura de chunks y niveles
  │   ├── images/             # Diagramas y vision del proyecto
  │   ├── video/
  │   │   └── daily_screencap.mp4 # Captura diaria destacada en este README
  │   └── snap-in-mechanism.md # Documentacion de mecanismo educativo
  └── README.md
  ```

---

## 🚀 Instalacion y Ejecucion

### Requisitos
- [Godot Engine 4.x](https://godotengine.org/download) (recomendado: 4.2+)

### Pasos
1. Clona el repositorio:
   ```bash
   git clone https://github.com/SebastianHoelzlSoftware/Lennox.git
   cd Lennox
   ```
2. Abre el proyecto en Godot:
   - Ejecuta `project.godot` con Godot Engine
   - O arrastra la carpeta del proyecto al editor

3. **Iniciar el juego**:
   - En el panel **FileSystem**, selecciona y abre `scenes/main.tscn`.
   - Pulsa **F6** (**Run Current Scene**) para ejecutar la escena principal.
   - No uses **F5** para iniciar el juego: el proyecto tiene GUT configurado como escena de inicio.

4. **Ejecutar pruebas** (opcional):
   - Abre el panel **GUT** en el editor de Godot
   - Ejecuta los tests utilizando la interfaz grafica de GUT

---

## 🧪 Pruebas

El proyecto incluye pruebas unitarias y de integracion con **GUT** (Godot Unit Test). La suite actual contiene 60 pruebas unitarias y 8 de integracion (68 en total).

| Suite | Cantidad | Cobertura |
|-------|---------:|-----------|
| [`test_barrier.gd`](test/unit/test_barrier.gd) | 15 | Poligonos, consultas de puntos, aperturas pasables y estados de puertas |
| [`test_biome.gd`](test/unit/test_biome.gd) | 11 | Generacion de biomas, determinismo, parametros y perfiles |
| [`test_chunk.gd`](test/unit/test_chunk.gd) | 11 | Inicializacion de chunks, barreras y aplicacion de baldosas |
| [`test_level.gd`](test/unit/test_level.gd) | 13 | Generacion de niveles, biomas, barreras y determinismo |
| [`test_level_tilemap.gd`](test/unit/test_level_tilemap.gd) | 3 | Renderizado de tilesets y limpieza al cargar un nivel nuevo |
| [`test_main_object_layer.gd`](test/unit/test_main_object_layer.gd) | 1 | Inicio en bioma de hierba y decoracion restringida al terreno |
| [`test_tile_object_library.gd`](test/unit/test_tile_object_library.gd) | 6 | Patrones, huellas, atlas y restricciones de terreno |
| [`test_barrier_chunk_integration.gd`](test/integration/test_barrier_chunk_integration.gd) | 8 | Integracion de barreras y aperturas generadas con chunks, puertas y baldosas |

### Ejecutar pruebas:
Desde la raíz del proyecto, también se puede ejecutar toda la suite en modo *headless* si Godot está disponible en `PATH`:

```sh
godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://test -ginclude_subdirs -gprefix=test_ -gexit
```

O busca el panel **GUT** en el editor y ejecuta los tests con la interfaz gráfica:


<p align="center">
  <img src="doc/images/screenshot_GUT.png" alt="GUT Interfaz" width="100%">
</p>

---

## 🤝 Contribucion

¡Las contribuciones son bienvenidas! Si deseas colaborar:

1. Haz un *fork* del repositorio
2. Crea una rama con tu caracteristica (*feature*):
   ```bash
   git checkout -b feature/nueva-funcionalidad
   ```
3. Realiza tus cambios y anade pruebas si es relevante
4. Envia un *Pull Request* con una descripcion clara

**Normas:**
- Usa **GDScript** con tipado estatico (`: int`, `: String`, etc.)
- Sigue el estilo de codigo existente (nombres descriptivos, comentarios en docstrings)
- Asegurate de que todos los tests pasen antes de enviar un PR

---

## 📜 Licencia

Este proyecto esta bajo la licencia **MIT**. Consulta el archivo [LICENSE](LICENSE) para mas detalles.

---

## 📧 Contacto

Para preguntas o sugerencias:
- **Autor**: Sebastian Hoelzl
- **Repositorio**: [SebastianHoelzlSoftware/Lennox](https://github.com/SebastianHoelzlSoftware/Lennox)

---

> *"La educacion es el arma mas poderosa para cambiar el mundo."* — Nelson Mandela
