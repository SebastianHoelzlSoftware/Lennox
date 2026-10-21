# Lennox

> *Un juego 2D movil que ensena a los ninos a leer en ingles y espanol. El enfoque esta en la diversion y una educacion profesional.*

---

## 📖 Descripcion

**Lennox** es un juego educativo 2D desarrollado con **Godot Engine 4.x**, disenado para ayudar a los ninos a aprender a leer en **ingles y espanol** de manera interactiva y divertida. El proyecto combina mecanicas de juego atractivas con contenido pedagogico de alta calidad, priorizando siempre la experiencia del usuario y el aprendizaje efectivo.

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
| **LEN-17** | Pruebas de integración de barreras (LEN-5) | ✅ Completado | Pruebas unitarias y de integración para la generación y aplicación de barreras |
| **LEN-16** | Integrar Godot y crear un nivel prototipo | 📋 Por hacer | Integración del mapa y prototipo dentro del motor |
| **LEN-20** | Añadir características de mundo entre chunks | 📋 Por hacer | Soporte para elementos que atraviesan los límites entre chunks |

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
  │       ├── barrier.gd      # Barreras y consulta de aperturas (LEN-5 / LEN-15)
  │       ├── opening.gd      # Aperturas generadas e interactivas (LEN-15)
  │       ├── biome_type.gd   # Enum global de biomas (BiomeType)
  │       └── tile_type.gd    # Enum global de baldosas (TileType)
  ├── test/
  │   ├── unit/               # Tests unitarios (GUT)
  │   └── integration/        # Tests de integracion (GUT)
  ├── doc/
  │   ├── map-generation.md   # Documentacion LEN-3
  │   ├── barriers.md         # Documentacion LEN-5
  │   ├── biomes.md           # Documentacion de biomas (LEN-4)
  │   ├── level-structure.md  # Estructura de chunks y niveles
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

3. **Ejecutar pruebas** (opcional):
   - Abre el panel **GUT** en el editor de Godot
   - Ejecuta los tests utilizando la interfaz grafica de GUT

---

## 🧪 Pruebas

El proyecto incluye pruebas unitarias para garantizar la estabilidad del codigo. Usamos **GUT** (Godot Unit Test):

| Test | Descripcion |
|------|-------------|
| `test_level_initialization` | Verifica la inicializacion correcta de parametros del nivel |
| `test_level_generates_chunks` | Confirma que los chunks se generan correctamente |
| `test_chunk_generation_is_deterministic` | **Determinismo**: Same seed → mismos biomas |
| `test_barrier_with_polygon` | Prueba de barreras con poligonos |
| `test_point_in_polygon_ray_casting` | Prueba de algoritmo Ray-Casting |
| `test_barrier_with_opening` | Prueba de barreras con aperturas |
| `test_generated_barriers_store_openings_deterministically` | Comprueba datos, bioma y determinismo de aperturas generadas |
| `test_generated_passable_openings_update_chunk_passability_and_tiles` | Comprueba la transitabilidad de aperturas generadas en el chunk |
| `test_generated_door_open_and_close_updates_chunk_tiles` | Comprueba bloqueo y actualización de baldosas para puertas generadas |

**Ejecutar pruebas:**
Busca el panel **GUT** en el editor y ejecuta los tests con la interfaz grafica.

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
