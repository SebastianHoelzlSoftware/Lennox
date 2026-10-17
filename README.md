# Lennox

> *Un juego 2D movil que ensena a los ninos a leer en ingles y espanol. El enfoque esta en la diversion y una educacion profesional.*

---

## 📖 Descripcion

**Lennox** es un juego educativo 2D desarrollado con **Godot Engine 4.x**, disenado para ayudar a los ninos a aprender a leer en **ingles y espanol** de manera interactiva y divertida. El proyecto combina mecanicas de juego atractivas con contenido pedagogico de alta calidad, priorizando siempre la experiencia del usuario y el aprendizaje efectivo.

---

## 🎮 Estado del Proyecto & Jira Roadmap

Die Entwicklung von **Lennox** wird strukturiert über **Atlassian Jira** organisiert und nachverfolgt. Die Präfixe und Nummern (z. B. `LEN-3`, `LEN-5`) entsprechen den offiziellen Tickets / Aufgaben im Jira-Projekt:

- **Jira Workspace:** [devhoelzlsebastian.atlassian.net](https://devhoelzlsebastian.atlassian.net)
- **Projekt-Key:** `LEN` (Lennox)

### 📊 Aktueller Ticket- & Entwicklungsstand

| Ticket | Titel / Meilenstein | Status | Details |
| :--- | :--- | :---: | :--- |
| **LEN-3** | Level- und Chunk-Struktur definieren | ✅ Erledigt | Prozedurale Chunks, deterministischer Seed, Koordinatenzugriff `(x, y)` |
| **LEN-5** | Barrieren-Generierungsalgorithmus umsetzen | ✅ Erledigt | Convex Hull + Perturbation, blockierende Kacheln, Aperturas |
| **LEN-17** | [LEN-5] 100% Testabdeckung für Barrieren-Integration | ✅ Erledigt | 38 Tests (33 Unit + 5 Integration), 14.710 Asserts, 0 Fehler |
| **LEN-4** | Biom-System implementieren (Voronoi + Perlin Noise) | 📋 Zu erledigen *(Nächster Schritt)* | Natürliche Biom-Übergänge, Dichte- und Typ-Parameter (`biomes.md`) |
| **LEN-6** | Öffnungen in Barrieren platzieren | 📋 Zu erledigen | Erweiterte Platzierungsregeln für Durchgänge |
| **LEN-7** | Godot-Integration & Prototyp-Level | 📋 Zu erledigen | TileMap-Visualisierung in Godot-Szene, Spieler-Kollisionen |

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
  │       ├── barrier.gd      # Barreras (LEN-5)
  │       ├── opening.gd      # Aperturas (LEN-5)
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
