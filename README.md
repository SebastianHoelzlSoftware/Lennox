# Lennox

> *Un juego 2D móvil que enseña a los niños a leer en inglés y español. El enfoque está en la diversión y una educación profesional.*

---

## 📖 Descripción

**Lennox** es un juego educativo 2D desarrollado con **Godot Engine 4.x**, diseñado para ayudar a los niños a aprender a leer en **inglés y español** de manera interactiva y divertida. El proyecto combina mecánicas de juego atractivas con contenido pedagógico de alta calidad, priorizando siempre la experiencia del usuario y el aprendizaje efectivo.

---

## 🎮 Estado Actual del Proyecto

✅ **LEN-3: Generación de Niveles** – Finalizado
- Sistema de generación procedural de niveles con semilla (*seed*) determinística
- Division en *chunks* para manejo eficiente de mundos grandes
- Generación de biomas variados (Grasland, Wald, Fels, Wasser, Sand)
- Acceso a chunks mediante coordenadas `(x, y)`

🔜 **Próximos pasos** (Roadmap):
- [ ] LEN-5: Sistema de barreras y obstáculos
- [ ] Sistema de progresión y recompensas
- [ ] Integración de contenido educativo (vocabulario, frases)
- [ ] Interfaz de usuario adaptada a niños

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
  │       └── chunk.gd      # Sistema de chunks
  ├── test/
  │   └── unit/             # Tests unitarios (GUT)
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
   - Abre la escena `test/unit/test_runner.tscn` en Godot
   - Ejecuta la escena para correr todos los tests con GUT

---

## 🧪 Pruebas

El proyecto incluye pruebas unitarias para garantizar la estabilidad del código. Usamos **GUT** (Godot Unit Test):

| Test | Descripción |
|------|-------------|
| `test_level_initialization` | Verifica la inicialización correcta de parámetros del nivel |
| `test_level_generates_chunks` | Confirma que los chunks se generan correctamente |
| `test_chunk_generation_is_deterministic` | **Determinismo**: Same seed → mismos biomas |
| `test_get_chunk_returns_correct_chunk` | Acceso correcto a chunks por coordenadas |

**Ejecutar pruebas:**
Abre `test/unit/test_runner.tscn` en Godot y corre la escena.

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

## 📬 Contacto

Para preguntas o sugerencias:
- **Autor**: Sebastian Hoelzl
- **Repositorio**: [SebastianHoelzlSoftware/Lennox](https://github.com/SebastianHoelzlSoftware/Lennox)

---

> *"La educación es el arma más poderosa para cambiar el mundo."* — Nelson Mandela
