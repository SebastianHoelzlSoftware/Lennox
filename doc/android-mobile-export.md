# 📱 Exportacion, Pruebas Moviles y Distribucion en Android

Este documento describe como funciona el sistema de controles tactiles de **Lennox**, como compilar y desplegar el juego directamente en un telefono Android (como el **Google Pixel 6**) desde Godot 4.6 y las distintas opciones para compartir versiones de prueba (`.apk`) con otras personas.

---

## 🎮 1. Controles Tactiles (`scenes/mobile_controls.gd`)

La capa `MobileControls` (`CanvasLayer` en [`scenes/main.tscn`](../scenes/main.tscn)) proporciona una interfaz tactil disenada con la paleta visual de la **Vision de Lennox** (`#58506B` morado pizarra, `#F29B38` naranja calido y destellos dorados/cian):

| Control / Gesto | Ubicacion | Funcionamiento |
| :--- | :--- | :--- |
| **Joystick Virtual** | Abajo a la izquierda | Semitransparente y discreto. Arrastra suavemente para **caminar** (`walk`). Si empujas el mando hasta el anillo exterior (`>= 85 %`), el personaje **corre automaticamente** (`run`) a una velocidad fluida (`145 px/s`). Tambien acepta toque flotante en toda la esquina inferior izquierda. |
| **Boton `E` (Corazon ❤️)** | Abajo a la derecha | Interactua con el companero NPC mas cercano (`interact_with_nearest_npc()`). Cuando la arquera (`NpcFriend`) esta dentro del radio de interaccion, el boton muestra un **aura dorada pulsante**. |
| **Toque directo sobre el NPC** | En el mundo | Tocar directamente a la arquera en la pantalla abre o cierra su burbuja de dialogo (`AMOR`), pensado para que sea muy intuitivo para ninos en pantallas tactiles. |
| **Lupas de Zoom y Pellizco** | Arriba a la derecha / 2 dedos | Dos botones semitransparentes con una **lupa pequena (`-`)** y una **lupa mas grande (`+`)** en la esquina superior derecha, o gesto de pellizco con dos dedos (*pinch-to-zoom*) para acercar o alejar la camara (`0.3x` a `3.5x`). |

> **Prueba en PC:** En [`project.godot`](../project.godot) esta activo `pointing/emulate_touch_from_mouse=true`, por lo que puedes probar el joystick y todos los botones tactiles directamente con el raton en el ordenador.

---

## 🛠️ 2. Requisitos Previos en el Ordenador (Configuracion Unica)

Para compilar o desplegar en Android con **Godot 4.6.3**, se requieren los siguientes ajustes:

0. **Compresion de texturas moviles (ETC2 / ASTC) en `project.godot`**:
   - En la seccion `[rendering]` de [`project.godot`](../project.godot) debe estar activo:
     `textures/vram_compression/import_etc2_astc=true`
     *(Sin esta opcion, Godot 4 rechaza el export de Android con un error de configuracion).*

1. **Plantillas de Exportacion (*Export Templates*) de Godot 4.6.3**:
   - En el menu superior de Godot, abre **Editor → Manage Export Templates…**.
   - Haz clic en **Download and Install** para descargar e instalar las plantillas oficiales de la version actual (`%APPDATA%\Godot\export_templates\4.6.3.stable\`).
2. **JDK 17 o superior (p. ej. JDK 21)**:
   - Ruta configurada en `export/android/java_sdk_path`:
     `C:/Program Files/Android/Android Studio/jbr` (JetBrains Runtime JDK 21 incluido con Android Studio) o cualquier instalacion de OpenJDK 17/21.
3. **Android SDK y Debug Keystore**:
   - Ruta del SDK en `export/android/android_sdk_path`:
     `C:/Users/sebas/AppData/Local/Android/Sdk`
   - Clave de depuracion (`export/android/debug_keystore`):
     `C:/Users/sebas/AppData/Roaming/Godot/keystores/debug.keystore` (usuario `androiddebugkey`, contrasena `android`).

---

## 🚀 3. Despliegue Directo por USB (*One-Click Deploy* en Pixel 6)

Para probar cambios al instante en tu propio telefono sin copiar archivos manualmente:

1. **En tu telefono Android (Pixel 6)**:
   - Ve a **Ajustes → Acerca del telefono** y toca 7 veces sobre **Numero de compilacion** (*Build number*) hasta activar las **Opciones para desarrolladores**.
   - Entra en **Ajustes → Sistema → Opciones para desarrolladores** y activa **Depuracion por USB** (*USB debugging*).
2. **Conecta el telefono al PC por cable USB**:
   - En la ventana emergente del telefono (*"¿Permitir depuracion por USB?"*), marca **Permitir siempre desde este ordenador** y pulsa **Permitir**.
3. **Lanza el juego desde Godot**:
   - En la esquina superior derecha del editor de Godot (al lado de los botones de reproduccion habituales) aparecera el icono de **Remote Deploy** (un pequeno icono de telefono movil).
   - Haz clic en el icono y selecciona tu **Google Pixel 6**.
   - Godot empaquetara el APK, lo instalara por `adb` y abrira **Lennox** automaticamente en pantalla completa horizontal.

---

## 📦 4. Compilar el Archivo `lennox.apk` para Compartir

El proyecto ya incluye el perfil preconfigurado **`Android`** en [`export_presets.cfg`](../export_presets.cfg) con:
- **Nombre del paquete:** `com.sebastianhoelzl.lennox`
- **Arquitecturas activas:** `arm64-v8a` (todos los moviles modernos de 64 bits, incluido Pixel 6) + `armeabi-v7a` (compatibilidad con moviles Android mas antiguos de 32 bits), para que funcione en **cualquier telefono Android** sin importar el modelo.
- **Modo inmersivo y pantalla:** Horizontal (*Sensor Landscape*), escalado `canvas_items` + `expand`.
- **Exclusion automatica de archivos de prueba:** `addons/gut/*`, `test/*`, `bin/*`.

### Opción A: Desde el Editor de Godot (Interfaz Grafica)
1. Abre **Project → Export…** en el menu superior.
2. Selecciona el preset **Android (Runnable)**.
3. Haz clic en **Export Project…** en la parte inferior.
4. Elige la ruta (por defecto `build/android/lennox.apk`), deja marcada la casilla **Export With Debug** para versiones de prueba y pulsa **Save**.

### Opción B: Desde la Terminal (Headless CLI)
Una vez instaladas las plantillas de exportacion, tambien puedes generar el `.apk` con un solo comando desde la raiz del proyecto:

```powershell
New-Item -ItemType Directory -Force -Path "build\android" | Out-Null
& '.\bin\Godot_v4.6.3-stable_win64_console.exe' --headless --path '.' --export-debug "Android" "build/android/lennox.apk"
```

---

## 💌 5. Como Enviar y Probar el Juego en Otro Movil Android (p. ej. para tu pareja o amigos)

A diferencia de iOS (donde Apple obliga a usar *TestFlight* y una cuenta de desarrollador de pago), en **Android** puedes compartir e instalar un archivo `.apk` directamente o usar canales de prueba. Aqui tienes las **3 mejores opciones** ordenadas de mas sencilla a mas avanzada:

### 🥇 Opcion 1: Envio directo del `.apk` por canal privado (Signal, WhatsApp, Telegram o Google Drive) — *La mas rapida*
Ideal para pasarle una version rapida a tu pareja:
1. Exporta `build/android/lennox.apk` y enviale el archivo por **Signal, Telegram, WhatsApp** (como documento) o **Google Drive**.
2. Ella descarga el archivo en su Android y lo toca para abrirlo.
3. Si es la primera vez que instala una app desde fuera de Google Play, Android mostrara un aviso:
   - *"Por motivos de seguridad, tu telefono no puede instalar aplicaciones desconocidas de esta fuente"* → tocar **Ajustes** y activar **Permitir desde esta fuente**.
   - Si aparece el aviso de **Google Play Protect** (*"App no reconocida"* porque aun no esta en la Play Store), tocar **Mas detalles → Instalar de todas formas** (*Trotzdem installieren*).
4. ¡Listo! El icono de **Lennox** aparecera en su pantalla de inicio. Para actualizar a una nueva version, basta con enviarle el nuevo `.apk` y abrirlo (Android actualiza la app conservando los datos siempre que uses la misma clave de firma).

### 🥈 Opcion 2: GitHub Releases (Enlace de descarga limpio desde el navegador)
Si prefieres mandarle un enlace web limpio para que siempre descargue la ultima version:
1. En el repositorio de GitHub (`SebastianHoelzlSoftware/Lennox`), entra en la seccion **Releases → Draft a new release**.
2. Crea una etiqueta (por ejemplo `v0.1.0-alpha`), ponle un titulo (p. ej. *"Lennox Mobile Preview - AMOR"*) y arrastra el archivo `lennox.apk` a la zona de **Attach binaries**.
3. Publica el *Release* (o marcalo como *Pre-release*).
4. Pasale el enlace de la pagina de *Releases*: ella solo tiene que pulsar sobre `lennox.apk` desde Chrome en su movil para descargarlo e instalarlo.

### 🥉 Opcion 3: El equivalente a "TestFlight" en Android
Si mas adelante quieres actualizaciones automaticas con notificacion sin enviar archivos manualmente:
- **Firebase App Distribution (Gratis, de Google)**:
  - Es el equivalente mas cercano y sencillo a TestFlight para pequenos grupos. Subes el `.apk`, anades el correo de tu pareja y ella recibe una invitacion para instalar *Firebase App Tester*. Cada vez que subas una version nueva, le llega una notificacion para actualizar con un toque, **sin** necesidad de pagar cuenta de Google Play.
- **Google Play Console — Prueba Interna (*Internal Testing*)**:
  - Permite hasta 100 testers por correo electronico que instalan y actualizan directamente desde la app oficial de **Google Play Store** (igual que TestFlight en iPhone). Requiere una cuenta de desarrollador de Google Play (pago unico de 25 USD).

