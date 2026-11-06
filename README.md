# Lennox

> *Un juego 2D movil que ensena a los ninos a leer en ingles y espanol. El enfoque esta en la diversion y una educacion profesional.*

---


<p align="center">
  <img src="assets/title_art/title_art_03.jpg" alt="Vision del juego educativo Lennox con biomas, exploracion y aprendizaje de lectura" width="100%">
</p>


## 📖 Descripcion

**Lennox** es un juego educativo 2D desarrollado con **Godot Engine 4.x**, disenado para ayudar a los ninos a aprender a leer en **ingles y espanol** de manera interactiva y divertida. El proyecto combina mecanicas de juego atractivas con contenido pedagogico de alta calidad, priorizando siempre la experiencia del usuario y el aprendizaje efectivo.

## 🌟 Vision de Lennox

<p align="center">
  <img src="doc/images/lennox_project_vision.jpg" alt="Vision del juego educativo Lennox con biomas, exploracion y aprendizaje de lectura" width="100%">
</p>

### 💬 Companera NPC y Burbuja Educativa de Palabras (`AMOR`)

Siguiendo el diseno visual de la vision de **Lennox**, el jugador viaja acompanado por una **arquera companera (`NpcFriend`)** que sigue sus pasos de forma natural por el mundo. Al acercarse a ella y pulsar la tecla **`E`** (`interact`), se despliega una **burbuja de dialogo interactiva (`NpcDialogBubble`)** que combina:

- **Asociacion visual simbolo + palabra**: Muestra un icono ilustrativo (como el corazon ❤️) junto a la palabra representada en **bloques de letras de colores (`A` `M` `O` `R`)**, facilitando que los ninos conecten la imagen con cada letra de forma intuitiva en espanol e ingles.
- **Totalmente configurable desde el Inspector de Godot**: Tanto el icono (`dialog_icon`) como la palabra (`dialog_word = "AMOR"`) se pueden ajustar directamente en cada NPC o dinamicamente por codigo para crear nuevos encuentros y vocabulario.

<p align="center">
  <img src="doc/images/npc_dialog_amor_vision.png" alt="Companera arquera mostrando el icono de corazon y la palabra AMOR en bloques de letras al pulsar E" width="68%">
</p>

---

## 🎬 Daily Screencap

<p align="center"><strong>La captura más reciente del juego</strong></p>




https://github.com/user-attachments/assets/242e53a6-bf94-48ca-92d3-e11ae9e5d1c4



---

## 🗺️ Generacion procedural del mapa

<p align="center">
  <img src="doc/images/procedual_map_generation.jpg" alt="Diagrama de generacion procedural del mapa, biomas, barreras y aperturas" width="100%">
</p>

### 🌍 Vista panoramica del mundo generado por semilla (*Seed*)

Todo el mundo de **Lennox** se genera de forma 100 % procedural y determinista a partir de una única **semilla numérica (*seed*)**:

- **Reproducibilidad exacta**: La misma semilla produce siempre el mismo mapa (regiones de biomas, mesetas continuas entre *chunks*, pasos transitables y distribución ecológica de objetos). Cambiar la semilla crea un mundo completamente nuevo.
- **Transiciones y relieve continuo**: Mediante diagramas de Voronoi con *domain warping* (`FastNoiseLite`) y campos de elevación macro, los **8 biomas** se integran de forma orgánica con acantilados en perspectiva 3/4 y vegetación propia de cada entorno.

<p align="center">
  <img src="doc/images/mapa.png" alt="Vista panoramica del mapa completo generado proceduralmente a partir de una semilla" width="100%">
</p>

---

## 🌿 Referencias visuales de los biomas

Estas imágenes muestran los estilos y conjuntos visuales previstos para los distintos entornos. 

!!! All credits go to @craftpix.net and their great top down tileset artwork <3 !!!

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
| **LEN-16** | Integrar Godot y crear nivel de demostración | ✅ Completado | Escena principal con mapa horneado (seed `691`), cámara suave, compañera NPC y diálogo `AMOR` |
| **LEN-43** | Compañera NPC, burbuja mágica (`AMOR`) y controles táctiles Android | ✅ Completado | Ventana de diálogo con letras brillantes, joystick virtual, lupas de zoom y `lennox.apk` |
| **LEN-46** | [Roadmap Paso 1] Poblar biomas con NPCs y vocabulario desde el Editor | 📋 Por hacer | Colocar compañeros/encuentros con distintos iconos (`dialog_icon`) y palabras (`dialog_word`) |
| **LEN-47** | [Roadmap Paso 2] Minijuego de formar la palabra (tocar/recoger letras) | 📋 Por hacer | Completar letras ocultas o desordenadas en la burbuja al estilo de la Visión de Lennox |
| **LEN-48** | [Roadmap Paso 3] Sonidos mágicos y pronunciación de palabras | 📋 Por hacer | `AudioStreamPlayer2D` con efecto al abrir la burbuja y voz en español/inglés (`dialog_audio`) |
| **LEN-49** | [Roadmap Paso 4] Conectar puertas/barreras con palabras aprendidas | 📋 Por hacer | Desbloquear aperturas interactivas (`Opening.open()`) al resolver la palabra de un guardián |
| **LEN-20** | Añadir características de mundo entre chunks | 📋 Por hacer | Soporte para ríos continuos entre límites de chunks |

---

## 🛠 Tecnologias

- **Motor**: [Godot Engine 4.x](https://godotengine.org/) (GDScript)
- **Testing**: [GUT](https://github.com/bitwes/Gut) (Godot Unit Test)
- **Estructura del proyecto**:
  ```
  lennox/
  ├── src/
  │   └── core/
  │       ├── level.gd                 # Generacion de niveles, mesetas entre chunks y mundo organico
  │       ├── chunk.gd                 # Sistema de chunks, grilla de baldosas y objetos poblados
  │       ├── terrain_painter.gd       # Motor de autotiling: suelos, acantilados 3/4 y derrames
  │       ├── terrain_styles.gd        # Estilos de suelo y acantilado para los 8 biomas (datos)
  │       ├── cliff_autotiler.gd       # Clasificador 9-slice basado en patrones de TileSet
  │       ├── tile_mapper.gd           # Dibujado de TilePattern sobre TileMapLayer
  │       ├── tile_pattern.gd          # Modelo de datos para patrones de baldosas (TilePattern)
  │       ├── tile_pattern_registry.gd # Registro y consulta indexada de patrones
  │       ├── corner_type.gd           # Enum de esquinas de patrones (CornerType)
  │       ├── hull_curvature.gd        # Enum de curvatura de bordes (HullCurvature)
  │       ├── object_catalog.gd        # Catalogo dinamico de activos para los 8 biomas y comunes
  │       ├── biome_config.gd          # Perfiles y parametros de configuracion de biomas
  │       ├── biome_generator.gd       # Generador determinista de biomas (Voronoi + Domain Warping)
  │       ├── barrier.gd               # Poligonos de barreras naturales y consulta de aperturas
  │       ├── opening.gd               # Aperturas generadas e interactivas (puertas, vados, pasos)
  │       ├── biome_type.gd            # Enum global de los 8 biomas (BiomeType)
  │       └── tile_type.gd             # Enum global de tipos de baldosa (TileType)
  ├── test/
  │   ├── unit/                        # Tests unitarios con GUT (11 suites, 85 tests)
  │   │   ├── test_barrier.gd
  │   │   ├── test_biome.gd
  │   │   ├── test_chunk.gd
  │   │   ├── test_cliff_autotiler.gd
  │   │   ├── test_level.gd
  │   │   ├── test_npc_friend.gd
  │   │   ├── test_object_catalog.gd
  │   │   ├── test_terrain_painter.gd
  │   │   ├── test_tilemapper.gd
  │   │   ├── test_tilepattern.gd
  │   │   └── test_tilepattern_registry.gd
  │   └── integration/                 # Tests de integracion con GUT (1 suite, 6 tests)
  │       └── test_barrier_chunk_integration.gd
  ├── assets/
  │   ├── biomes/                      # Activos de los 8 biomas (tiles, objects y <bioma>_16x16.tres)
  │   ├── common/                      # Activos compartidos (characters, trees, bushes, ruins, crystals)
  │   ├── player_sprites/              # Spritesheets animados del personaje (walk, idle, run)
  │   ├── tiles/                       # TileSet maestro de terreno (terrain_master_16x16.tres) y rocas
  │   └── title_art/                   # Arte conceptual y portada del proyecto
  ├── scenes/
  │   ├── main.tscn                    # Escena principal (mundo horneado seed 691 + jugador y companera)
  │   ├── main.gd                      # Controlador de escena, camara suave, zoom y capturas
  │   ├── level.gd                     # Renderizado multicapa del terreno (TerrainPainter) y objetos
  │   ├── player.gd                    # Controlador del jugador, movimiento, animaciones e interaccion (E)
  │   ├── npc_friend.gd                # Companero NPC con seguimiento por migas de pan e interaccion
  │   ├── npc_dialog_bubble.gd         # Burbuja de dialogo estilo Vision de Lennox (icono + bloques AMOR)
  │   ├── mobile_controls.gd           # Controles tactiles para Android / movil (joystick, boton E, RUN y zoom)
  │   ├── terrain_lab.tscn             # Escena del laboratorio visual de estilos por bioma
  │   ├── terrain_lab.gd               # Generador de galeria de pruebas para los 8 biomas
  │   ├── test_autotiling_level.tscn   # Escena de prueba de autotiling para los 8 biomas
  │   ├── test_autotiling_level.gd     # Script de escena de prueba de autotiling
  │   └── grassland_test_pattern.tscn  # Escena de referencia manual de patrones en pradera
  ├── doc/
  │   ├── android-mobile-export.md     # Guia de controles tactiles, exportacion APK y despliegue en Android
  │   ├── map-generation.md            # Arquitectura del generador de mundo y autotiling 3/4
  │   ├── biomes.md                    # Catalogo y guia visual de los 8 biomas
  │   ├── barriers.md                  # Formaciones naturales, mesetas y aperturas
  │   ├── level-structure.md           # Estructura de niveles y coordenadas de chunks
  │   ├── snap-in-mechanism.md         # Mecanismo de encaje de piezas y patrones
  │   ├── images/                      # Capturas de pantalla y diagramas de arquitectura
  │   └── video/                       # Videos de demostracion (daily_screencap.mp4)
  ├── export_presets.cfg               # Perfil de exportacion Android (arm64-v8a + armeabi-v7a)
  └── README.md
  ```

---

## 🚀 Instalacion y Ejecucion

### 📱 Probar directamente en Android (Descarga APK)

Si quieres probar la ultima version de **Lennox** directamente en tu movil o tablet Android sin instalar el motor de desarrollo:

<p align="center">
  <a href="https://github.com/SebastianHoelzlSoftware/Lennox/raw/main/build/android/lennox.apk">
    <strong>⬇️ Descargar la ultima version de prueba para Android (<code>lennox.apk</code>)</strong>
  </a>
</p>

> **💡 Cómo instalar `lennox.apk` en tu móvil Android:**
>
> Como es una versión de prueba en desarrollo y todavía no está publicada en la Google Play Store, Android te pedirá un par de confirmaciones de seguridad al abrir el archivo:
>
> 1. **Toca el archivo `lennox.apk`** cuando termine de descargarse.
> 2. Si te sale un aviso de *"Instalar aplicaciones desconocidas"*, toca en **Ajustes** (*Configuración*) y activa **Permitir desde esta fuente** (*Confiar en esta fuente*).
> 3. Si te aparece una ventana de **Google Play Protect** diciendo *"Se bloqueó la app"* o *"App no reconocida"*, toca en **Más detalles** (abajo) y luego en **Instalar de todas formas** (*Instalar sin analizar*).
> 4. ¡Y listo! Ya puedes darle a **Abrir** y probar el juego (con el joystick táctil a la izquierda y el botón ❤️ **`E`** o tocando a la arquera para ver la burbuja mágica de **`AMOR`**).

#### ANOTACIÓN: En mi Pixel 6 hice "Scan App" por Google Play Protect y dijo que era seguro.
#### ANOTACIÓN: Parece necesario en mi Pixel 6 hacer "Scan App" y que pase esa prueba para poder instalarlo.
---

### 💻 Ejecutar desde el Editor de Godot (PC y Desarrollo)

#### Requisitos
- [Godot Engine 4.x](https://godotengine.org/download) (recomendado: 4.6+)

#### Pasos
1. Clona el repositorio:
   ```bash
   git clone https://github.com/SebastianHoelzlSoftware/Lennox.git
   cd Lennox
   ```
2. Abre el proyecto en Godot:
   - Ejecuta `project.godot` con Godot Engine
   - O arrastra la carpeta del proyecto al editor

3. **Iniciar el juego en PC**:
   - Pulsa **F5** (**Run Project**) o abre `scenes/main.tscn` y pulsa **F6** (**Run Current Scene**).
   - Puedes moverte con `W/A/S/D` o flechas, mantener `Shift` para correr, pulsar `E` para hablar con la arquera o usar directamente el joystick y los botones tactiles en pantalla con el raton.

4. **Compilar o desplegar en Android por USB**:
   - Consulta la guia completa en [`doc/android-mobile-export.md`](doc/android-mobile-export.md) para desplegar por USB con un clic (*One-Click Deploy* en Google Pixel 6 y otros dispositivos) o volver a exportar [`build/android/lennox.apk`](build/android/lennox.apk).

5. **Ejecutar pruebas** (opcional):
   - Abre el panel **GUT** en el editor de Godot
   - Ejecuta los tests utilizando la interfaz grafica de GUT

---

## 🧪 Pruebas

El proyecto incluye pruebas unitarias y de integracion con **GUT** (Godot Unit Test). La suite actual contiene 85 pruebas unitarias y 6 de integracion (91 en total), con una tasa de exito del 100%.

| Suite | Cantidad | Cobertura |
|-------|---------:|-----------|
| [`test_barrier.gd`](test/unit/test_barrier.gd) | 15 | Poligonos, consultas de puntos, aperturas pasables y estados de puertas |
| [`test_biome.gd`](test/unit/test_biome.gd) | 11 | Generacion de biomas, determinismo, parametros y perfiles |
| [`test_chunk.gd`](test/unit/test_chunk.gd) | 11 | Inicializacion de chunks, barreras y aplicacion de baldosas |
| [`test_cliff_autotiler.gd`](test/unit/test_cliff_autotiler.gd) | 7 | Clasificacion 9-slice, esquinas, bordes y dibujado de mesetas |
| [`test_level.gd`](test/unit/test_level.gd) | 15 | Generacion de niveles, reglas de forma, estilos y poblacion de objetos |
| [`test_npc_friend.gd`](test/unit/test_npc_friend.gd) | 8 | Companeros NPC, animaciones 4 direcciones, seguimiento, burbuja y controles tactiles |
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
