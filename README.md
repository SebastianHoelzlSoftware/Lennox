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
| **LEN-13** | Implementar el sistema de biomas | ✅ Completado | 8 biomas canónicos, mapa determinista con Voronoi y FastNoiseLite domain warping |
| **LEN-14** | Generador de mundo orgánico de cuento de hadas | ✅ Completado | Formaciones naturales armónicas, grandes mesetas y pasos transitables |
| **LEN-15** | Colocar aperturas en las barreras | ✅ Completado | Aperturas generadas e interactivas (puertas, desfiladeros, vados) |
| **LEN-34** | Población ecológica y catálogo de objetos | ✅ Completado | Catálogo dinámico `ObjectCatalog` y 4 reglas de población para los 8 biomas |
| **LEN-17** | Pruebas de integración de barreras y chunks | ✅ Completado | Pruebas unitarias y de integración para la generación y aplicación de formaciones |
| **LEN-16** | Integrar Godot y crear nivel de demostración | ✅ Completado | Escena de exploración con cámara suave, zoom y ordenación en Y |
| **LEN-20** | Añadir características de mundo entre chunks | 📋 Por hacer | Soporte para ríos continuos entre límites de chunks |


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
  │       ├── level.gd                 # Generacion de niveles y mundo organico
  │       ├── chunk.gd                 # Sistema de chunks y objetos poblados
  │       ├── terrain_painter.gd       # Motor de autotiling: suelos, acantilados 3/4 y derrames
  │       ├── terrain_styles.gd        # Estilos de suelo y acantilado por bioma (datos)
  │       ├── cliff_autotiler.gd       # Clasificador 9-slice basado en patrones (herramientas)
  │       ├── object_catalog.gd        # Catalogo dinamico de activos para los 8 biomas
  │       ├── biome_config.gd          # Perfiles y configuracion de biomas
  │       ├── biome_generator.gd       # Generador de biomas Voronoi + Domain Warping
  │       ├── barrier.gd               # Barreras naturales y consulta de aperturas
  │       ├── opening.gd               # Aperturas generadas e interactivas
  │       ├── biome_type.gd            # Enum global de los 8 biomas (BiomeType)
  │       └── tile_type.gd             # Enum global de baldosas (TileType)
  ├── test/
  │   ├── unit/                        # Tests unitarios (GUT)
  │   └── integration/                 # Tests de integracion (GUT)
  ├── assets/
  │   ├── biomes/                      # Activos organizados en 8 biomas (tiles y objects)
  │   ├── common/                      # Activos compartidos (trees, bushes, ruins, etc.)
  │   └── tiles/rocks/rocks_16x16.tres # TileSet combinado
  ├── scenes/
  │   ├── main.tscn                    # Escena del mundo generado
  │   ├── level.gd                     # Renderizado del terreno (TerrainPainter) y objetos
  │   ├── terrain_lab.tscn             # Laboratorio visual de estilos de terreno por bioma
  │   ├── test_autotiling_level.tscn   # Escena de exploracion de los 8 biomas
  │   └── player.gd                    # Controlador del personaje y animaciones
  ├── doc/
  │   ├── map-generation.md            # Arquitectura del mundo de cuentos de hadas
  │   ├── biomes.md                    # Catalogo y guia visual de los 8 biomas
  │   ├── barriers.md                  # Formaciones naturales y pasos
  │   └── images/                      # Capturas y diagramas
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

El proyecto incluye pruebas unitarias y de integracion con **GUT** (Godot Unit Test). La suite actual contiene 77 pruebas unitarias y 6 de integracion (83 en total), con una tasa de exito del 100%.

| Suite | Cantidad | Cobertura |
|-------|---------:|-----------|
| [`test_barrier.gd`](test/unit/test_barrier.gd) | 15 | Poligonos, consultas de puntos, aperturas pasables y estados de puertas |
| [`test_biome.gd`](test/unit/test_biome.gd) | 11 | Generacion de biomas, determinismo, parametros y perfiles |
| [`test_chunk.gd`](test/unit/test_chunk.gd) | 11 | Inicializacion de chunks, barreras y aplicacion de baldosas |
| [`test_cliff_autotiler.gd`](test/unit/test_cliff_autotiler.gd) | 7 | Clasificacion 9-slice, esquinas, bordes y dibujado de mesetas |
| [`test_level.gd`](test/unit/test_level.gd) | 15 | Generacion de niveles, reglas de forma, estilos y poblacion de objetos |
| [`test_object_catalog.gd`](test/unit/test_object_catalog.gd) | 5 | Catalogo de activos para los 8 biomas y categorias comunes |
| [`test_terrain_painter.gd`](test/unit/test_terrain_painter.gd) | 6 | Autotiling 3x3 + esquinas concavas, caras 3/4, derrames y estilos |
| [`test_tilemapper.gd`](test/unit/test_tilemapper.gd) | 3 | Dibujado de patrones en TileMapLayer |
| [`test_tilepattern.gd`](test/unit/test_tilepattern.gd) | 1 | Creacion y validacion de patrones de baldosas |
| [`test_tilepattern_registry.gd`](test/unit/test_tilepattern_registry.gd) | 3 | Registro e integridad de indices de patrones |
| [`test_barrier_chunk_integration.gd`](test/integration/test_barrier_chunk_integration.gd) | 6 | Integracion de barreras y aperturas generadas con chunks y baldosas |


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
