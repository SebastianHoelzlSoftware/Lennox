# Lennox

> *Un juego 2D móvil que enseña a los niños a leer en inglés y español. El enfoque está en la diversión y una educación profesional.*

---

## 📖 Descripción

**Lennox** es un juego educativo 2D desarrollado con **Godot Engine 4.x**, diseñado para ayudar a los niños a aprender a leer en **inglés y español** de manera interactiva y divertida. El proyecto combina mecánicas de juego atractivas con contenido pedagógico de alta calidad, priorizando siempre la experiencia del usuario y el aprendizaje efectivo.

---

## 🎮 Estado Actual del Proyecto

✅ **LEN-3: Generación de Niveles** – Finalizado
- Sistema de generación procedural de niveles con semilla (*seed*) determinística
- División en *chunks* para manejo eficiente de mundos grandes
- Generación de biomas variados (Grasland, Wald, Fels, Wasser, Sand)
- Acceso a chunks mediante coordenadas `(x, y)`

✅ **LEN-5: Sistema de barreras y obstáculos** – **¡NUEVO! Implementado**
- Generación procedural de barreras por chunk (Convex Hull + Perturbation)
- Tipos de barreras: Fels, Baumgruppe, Düne, Insel, Wand
- Aberturas: Treppe, Tür (interactiva), Furt, Pass
- Integración con el sistema de chunks y biomas
- Tests unitarios en `test/unit/test_barrier.gd`

📋 **LEN-4: Mecanismo Snap-In con modo de sílabas** – **Documentación lista**
- Mecanismo de arrastrar y soltar (Drag & Drop)
- Modo de letras: Puzzles con letras individuales
- Modo de sílabas: Puzzles con sílabas (ej. "Ma" + "ma" = "Mama")
- Soporte de audio para retroalimentación fonética
- Documentación en `doc/snap-in-mechanism.md`

📌 **Próximos pasos** (Roadmap):
- [ ] LEN-4: Implementar mecanismo Snap-In (prioridad alta)
- [ ] LEN-6: Sistema de progresión y recompensas
- [ ] LEN-7: Integración de contenido educativo (vocabulario, frases)
- [ ] LEN-8: Interfaz de usuario adaptada a niños
- [ ] LEN-9: Personaje jugador + colisiones con barreras

---

## 🛠 Tecnologías

- **Motor**: [Godot Engine 4.x](https://godotengine.org/) (GDScript)
- **Testing**: [GUT](https://github.com/bitwes/Gut) (Godot Unit Test)
- **Estructura del proyecto**:
  ```
  lennox/
  ├── src/
  │   └── core/
  │       ├── level.gd      # Generación de niveles
  │       ├── chunk.gd      # Sistema de chunks
  │       ├── barrier.gd     # Barrieren (LEN-5)
  │       └── opening.gd     # Öffnungen (LEN-5)
  ├── test/
  │   └── unit/             # Tests unitarios (GUT)
  ├── doc/
  │   ├── map-generation.md # Dokumentation LEN-3
  │   ├── barriers.md       # Dokumentation LEN-5
  │   └── snap-in-mechanism.md # Dokumentation LEN-4
  └── README.md
  ```

---

## 🚀 Instalación y Ejecución

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
   - Abre la escena `gut_main.tscn` en Godot
   - Ejecuta la escena para correr todos los tests con GUT

---

## 🧪 Pruebas

El proyecto incluye pruebas unitarias para garantizar la estabilidad del código. Usamos **GUT** (Godot Unit Test):

| Test | Descripción |
|------|-------------|
| `test_level_initialization` | Verifica la inicialización correcta de parámetros del nivel |
| `test_level_generates_chunks` | Confirma que los chunks se generan correctamente |
| `test_chunk_generation_is_deterministic` | **Determinismo**: Same seed → mismos biomas |
| `test_barrier_with_polygon` | Prueba de barreras con polígonos |
| `test_point_in_polygon_ray_casting` | Prueba de algoritmo Ray-Casting |
| `test_barrier_with_opening` | Prueba de barreras con aberturas |

**Ejecutar pruebas:**
Abre `gut_main.tscn` en Godot y corre la escena.

---

## 🤝 Contribución

¡Las contribuciones son bienvenidas! Si deseas colaborar:

1. Haz un *fork* del repositorio
2. Crea una rama con tu característica (*feature*):
   ```bash
   git checkout -b feature/nueva-funcionalidad
   ```
3. Realiza tus cambios y añade pruebas si es relevante
4. Envía un *Pull Request* con una descripción clara

**Normas:**
- Usa **GDScript** con tipado estático (`: int`, `: String`, etc.)
- Sigue el estilo de código existente (nombres descriptivos, comentarios en docstrings)
- Asegúrate de que todos los tests pasen antes de enviar un PR

---

## 📜 Licencia

Este proyecto está bajo la licencia **MIT**. Consulta el archivo [LICENSE](LICENSE) para más detalles.

---

## 📧 Contacto

Para preguntas o sugerencias:
- **Autor**: Sebastian Hoelzl
- **Repositorio**: [SebastianHoelzlSoftware/Lennox](https://github.com/SebastianHoelzlSoftware/Lennox)

---

> *"La educación es el arma más poderosa para cambiar el mundo."* — Nelson Mandela
