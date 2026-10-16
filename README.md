# Lennox

> *Un juego 2D movil que ensena a los ninos a leer en ingles y espanol. El enfoque esta en la diversion y una educacion profesional.*

---

## 📖 Descripcion

**Lennox** es un juego educativo 2D desarrollado con **Godot Engine 4.x**, disenado para ayudar a los ninos a aprender a leer en **ingles y espanol** de manera interactiva y divertida. El proyecto combina mecanicas de juego atractivas con contenido pedagogico de alta calidad, priorizando siempre la experiencia del usuario y el aprendizaje efectivo.

---

## 🎮 Estado Actual del Proyecto

✅ **LEN-3: Generacion de Niveles** – Finalizado
- Sistema de generacion procedural de niveles con semilla (*seed*) deterministica
- Division en *chunks* para manejo eficiente de mundos grandes
- Generacion de biomas variados (Grassland, Wood, Rocks, Water, Sand)
- Acceso a chunks mediante coordenadas `(x, y)`

✅ **LEN-5: Sistema de barreras y obstaculos** – **¡NUEVO! Implementado**
- Generacion procedural de barreras por chunk (Convex Hull + Perturbation)
- Tipos de barreras: Rocks, Tree groups, Dunes, Islands, Walls
- Aperturas: Steps, Door (interactiva), Ford, Pass
- Integracion con el sistema de chunks y biomas
- Tests unitarios en `test/unit/test_barrier.gd`

📋 **LEN-4: Mecanismo Snap-In con modo de silabas** – **Documentacion lista**
- Mecanismo de arrastrar y soltar (Drag & Drop)
- Modo de letras: Puzzles con letras individuales
- Modo de silabas: Puzzles con silabas (ej. "Ma" + "ma" = "Mama")
- Soporte de audio para retroalimentacion fonetica
- Documentacion en `doc/snap-in-mechanism.md`

📌 **Proximos pasos** (Roadmap):
- [ ] LEN-4: Implementar mecanismo Snap-In (prioridad alta)
- [ ] LEN-6: Sistema de progresion y recompensas
- [ ] LEN-7: Integracion de contenido educativo (vocabulario, frases)
- [ ] LEN-8: Interfaz de usuario adaptada a ninos
- [ ] LEN-9: Personaje jugador + colisiones con barreras

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
  │   └── unit/               # Tests unitarios (GUT)
  ├── doc/
  │   ├── map-generation.md   # Documentacion LEN-3
  │   ├── barriers.md         # Documentacion LEN-5
  │   ├── biomes.md           # Documentacion de biomas
  │   ├── level-structure.md  # Estructura de chunks y niveles
  │   └── snap-in-mechanism.md # Documentacion LEN-4
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
