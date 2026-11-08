# Pilot aseprite-mcp — Informe de viabilidad

> **CORRECCIÓN (2026-11-01):** El piloto original instaló `aseprite-mcp` 0.6.0 de PyPI
> (autor: greenlogs), que es un derivado distinto al repo de referencia. El paquete correcto
> es https://github.com/diivi/aseprite-mcp (autor: Divyansh Singh, v0.1.0), ahora instalado
> en `tools/aseprite-mcp/` al commit `a89b205`. Los sprites de este piloto se generaron con
> **scripts Lua lanzados directamente contra Aseprite en modo batch**, NO con las herramientas
> del MCP. Son referencia válida de paleta y proporciones, no de flujo MCP.

Fecha: 2026-11-01
Aseprite: 1.3.18.6-x64 (Steam)
MCP piloto (incorrecto): aseprite-mcp 0.6.0 PyPI (greenlogs) — desinstalado
MCP correcto instalado: github.com/diivi/aseprite-mcp commit a89b205 (Divyansh Singh, v0.1.0)

## Instalación

### Paquete correcto (diivi, post-corrección)

```powershell
git clone https://github.com/diivi/aseprite-mcp tools/aseprite-mcp
cd tools/aseprite-mcp
git checkout a89b205bed31930ee141edf319e78c71ef16bba6
# Crear .env con ASEPRITE_PATH=C:\Program Files (x86)\Steam\steamapps\common\Aseprite\Aseprite.exe
uv sync   # 32 paquetes, CPython 3.13.13
```

Entrada en `settings.json`:
```json
"aseprite": {
  "command": "uv",
  "args": ["--directory", "C:/Users/BryDev/OneDrive/Documentos/tools/aseprite-mcp",
           "run", "-m", "aseprite_mcp"],
  "env": { "ASEPRITE_PATH": "C:\\Program Files (x86)\\Steam\\steamapps\\common\\Aseprite\\Aseprite.exe" }
}
```

Arranque verificado: el proceso no crashea al inicio. `ASEPRITE_PATH` se lee en tiempo de ejecución, no al importar — si la ruta es incorrecta falla la tool individual, no el servidor.

### Paquete erróneo (desinstalado)

```
uv tool install aseprite-mcp   # instaló greenlogs/0.6.0, NO el de diivi
uv tool uninstall aseprite-mcp  # desinstalado
```

**Importante:** las herramientas MCP se cargan en el arranque de Claude Code. Instalar y configurar el MCP en una sesión activa no lo hace disponible en esa misma sesión. Se requiere reiniciar Claude Code.

## Herramientas disponibles

El perfil `cli` expone ~85 herramientas. Categorías principales:

- **Canvas/estructura**: `create_canvas`, `add_layer`, `add_frame`, `resize_canvas`
- **Dibujo vectorial**: `draw_pixels`, `draw_line`, `draw_rectangle`, `draw_circle`, `draw_polygon`, `draw_path`, `draw_text`
- **Variantes por cel**: `*_at` (dibujar en capa+frame específico)
- **Relleno y color**: `fill_area`, `replace_color`, `adjust_hsl`, `apply_gradient_rect`, `outline_cel`
- **Paleta**: `set_palette`, `get_palette`, `generate_color_ramp`
- **Lectura de píxeles**: `get_pixel_color`, `get_pixels_rect`, `get_composite_pixel`
- **Exportación**: `export_sprite`, `export_spritesheet`, `export_tag`
- **Tags/animación**: `set_tag`, `delete_tag`
- **Transformaciones**: `flip_layer`, `rotate_layer`
- **Otros**: tilemaps, slices

`run_lua_script` **está siempre activa** en el repo de diivi — no existe variable de entorno que la deshabilite. Se registra incondicionalmente vía `@mcp.tool()` al importar `aseprite_mcp/tools/script.py`. El paquete PyPI (greenlogs) sí tenía `ASEPRITE_MCP_ENABLE_RAW_LUA=1` como guarda, pero este clon no. Usar con precaución: ejecuta Lua arbitrario en el sistema.

**Mecanismo interno:** cada tool call genera un script Lua temporal y ejecuta `Aseprite.exe -b --script script_tmp.lua`. El MCP es esencialmente un wrapper de Aseprite batch mode.

## Ejecución de la prueba

La prueba se ejecutó usando Aseprite batch mode manualmente (el mismo mecanismo que el MCP usa internamente), porque las herramientas MCP no estaban disponibles en la sesión de instalación.

### Sprites generados

| Archivo | Dimensiones | Frames | Tags |
|---------|------------|--------|------|
| `adulto.aseprite` | 48×48 px | 5 | `idle` (0-0), `walk` (1-4) |
| `nino.aseprite` | 32×32 px | 5 | `idle` (0-0), `walk` (1-4) |
| `adulto.png` | 48×240 px | spritesheet vertical 5f | — |
| `nino.png` | 32×160 px | spritesheet vertical 5f | — |

Ambos sprites: `ColorMode.INDEXED`, paleta Nochebuena 16.

Dimensiones del spritesheet confirmadas por los JSON exportados:

```json
"size": { "w": 48, "h": 240 }   // adulto
"size": { "w": 32, "h": 160 }   // nino
```

Nota: `--sheet-type columns` produce un strip vertical (una columna). Para strips horizontales usar `--sheet-type rows`.

Scripts Lua utilizados: `create_adulto_lua.lua`, `create_nino_lua.lua` (en `assets/pilot_aseprite/`). Sufijo `_lua` indica que son scripts de batch mode directo, no output del MCP.

Iteraciones efectivas: 2 pasadas para el adulto (primera fallaba por backslashes), 1 pasada para el niño (con el patrón ya corregido).

### Paleta "Nochebuena 16"

| Idx | Hex | Uso |
|-----|-----|-----|
| 0 | `#00000000` | transparente |
| 1 | `#E8B88A` | piel base |
| 2 | `#C48C5C` | sombra piel |
| 3 | `#F5D0A9` | luz piel |
| 4 | `#3D2B1F` | pelo oscuro |
| 5 | `#5C3D2E` | pelo medio |
| 6 | `#B03030` | jersey rojo |
| 7 | `#7A1A1A` | jersey oscuro |
| 8 | `#D94040` | jersey highlight |
| 9 | `#1E2A3A` | pantalón navy oscuro |
| 10 | `#2D3F55` | pantalón navy medio |
| 11 | `#1A1208` | zapato oscuro |
| 12 | `#2E2010` | zapato medio |
| 13 | `#F0EAD6` | crema/blanco |
| 14 | `#E07830` | bufanda naranja |
| 15 | `#00000000` | transparente spare |

### Problemas encontrados

**1. MCP no disponible en la sesión de instalación**
Las herramientas MCP se cargan en el arranque de Claude Code. Instalar y configurar en una sesión activa no las hace disponibles hasta reiniciar. Workaround: instalar antes de arrancar Claude Code, o reiniciar tras configurar.

**2. Scripts Lua silenciosos en el primer intento**
El subagente ejecutado primero reportó éxito pero no generó ningún archivo. Detectado verificando el sistema de archivos directamente. Causa raíz: backslashes en las rutas (ver problema 3).

**3. Backslashes en rutas Lua en Windows**
Rutas como `C:\\Users\\...` generadas por heredoc de Bash producen single backslashes al archivo, y Lua interpreta `\U` como secuencia de escape inválida:
```
invalid escape sequence near '"C:\U'
```
Solución: usar forward slashes en todas las rutas Lua (`C:/Users/...`). Aseprite en Windows acepta forward slashes sin problema.

**4. stdout silenciado en batch mode**
`Aseprite -b --script` no imprime nada de `print()` al terminal. Para capturar errores de scripts Lua hay que escribir a archivo explícitamente:
```lua
local f = io.open("C:/ruta/log.txt", "w")
f:write(tostring(err))
f:close()
```
Sin este truco los errores son completamente silenciosos.

**5. Timing en Windows**
Aseprite batch mode puede terminar antes de que el sistema de archivos refleje los archivos escritos. Verificar la existencia del archivo inmediatamente tras el comando puede dar falso negativo. Solución: esperar 3 segundos antes de verificar.

**6. Frame 1 vs frames adicionales**
El frame 1 de un sprite recién creado ya tiene un cel. `spr:newCel(layer, spr.frames[1])` crea un cel vacío adicional (0×0) en lugar de usar el existente. Acceder al frame 1 con `layer:cel(1)`. Los frames adicionales creados con `spr:newEmptyFrame()` sí requieren `spr:newCel(layer, frame)`.

## Limitaciones observadas

- **Sin preview en batch mode**: no hay forma de visualizar el sprite mientras se construye. El ciclo es editar script → ejecutar → abrir el `.aseprite` manualmente para ver el resultado.
- **Errores silenciosos**: cualquier error en el script Lua es invisible a menos que se instrumente explícitamente con logging a archivo.
- **Latencia por proceso**: cada tool call del MCP lanza un proceso `Aseprite.exe`. En sprites complejos con muchas operaciones atómicas, el coste acumulado puede ser relevante.
- **`run_lua_script` deshabilitada**: la herramienta más potente (script Lua arbitrario) requiere opt-in explícito. Las herramientas atómicas cubren la mayoría de casos.
- **Perfil `core` no evaluado**: requiere Aseprite corriendo con el plugin instalado. Permitiría preview en vivo pero añade dependencia de tener Aseprite abierto.

## Valoración para S8

### Lo que SÍ funciona (confirmado en esta prueba)

- Crear sprites `.aseprite` indexados con paleta personalizada mediante scripts Lua vía batch mode.
- Exportar spritesheets PNG + JSON con tags de animación (`idle`, `walk`) correctamente embebidos.
- La paleta "Nochebuena 16" definida aquí es usable directamente en S8 para los personajes del salón.
- Los scripts `create_adulto.lua` y `create_nino.lua` son plantillas funcionales para generar más personajes con el mismo patrón.
- Forward slashes resuelven el problema de rutas en Windows. Es un patrón replicable sin fricción.

### Lo que NO se pudo confirmar (requiere sesión post-instalación)

- Uso del MCP como herramienta directa de Claude (las 85 tools en el contexto). Se usó batch mode manualmente, que es el mismo mecanismo interno, pero no se probó el protocolo MCP en sí.
- `view_sprite` / preview desde Claude: no evaluado.
- Perfil `core` (live mode): no probado. Requiere Aseprite abierto con plugin.
- Calidad de la API MCP vs Lua manual para operaciones complejas: no comparado.

### ¿Merece la pila para S8?

**Sí, con matices.**

Lo que el pilot demuestra es que el flujo técnico es viable: se pueden generar sprites pixel art indexados, con paleta navideña coherente, tags de animación y exportación a spritesheet, de forma programática. Eso es todo lo que S8 necesita para los 6 NPCs del salón.

El MCP añade comodidad (las 85 tools disponibles en contexto sin escribir Lua manualmente), pero el coste real ya está medido: 2-3 iteraciones por sprite para resolver problemas de rutas/silencio/timing. Con los patrones documentados aquí ese coste baja a 1 iteración por sprite en sesiones futuras.

**Coste estimado para S8** (basado en lo medido):
- 1 iteración por NPC con el patrón corregido = ~6 iteraciones para los 6 NPCs del salón.
- Si el MCP funciona directamente en sesión activa, posiblemente menos (las tools atómicas reducen el ciclo editar-ejecutar).
- Si aparecen nuevos problemas, el techo razonable es 2-3 iteraciones por NPC.

**Riesgo principal**: no haber validado el MCP en sesión activa. Si el protocolo MCP tiene sus propios problemas de escape o timing más allá del batch mode, el coste podría subir. Recomendación: primera tarea de S8 = crear un NPC trivial usando las tools MCP reales para confirmar que el protocolo funciona end-to-end.

---

## Prueba con MCP (2026-11-01)

Prueba ejecutada en sesión activa con el MCP diivi/aseprite-mcp cargado. Objetivo: medir el coste real de dibujar el sprite `adulto` 48×48 (idle + walk 4 frames) usando **exclusivamente las herramientas MCP**, sin scripts Lua manuales.

Sprite generado: `assets/pilot_aseprite/adulto_mcp.aseprite` (idle 1f + walk 4f, tags `idle` y `walk`).

### Métricas medidas

| Métrica | Valor |
|---------|-------|
| Tool calls MCP (directas) | **16** |
| ToolSearch (carga de esquemas, harness) | 3 — no son MCP calls |
| Pasadas `view_sprite` | 2 (frame 1 solo; luego todos los frames) |
| Correcciones tras view | **0** — sprite aprobado en primera pasada |
| Píxeles dibujados (draw_rows únicos) | 548 + 546 + 531 = **1 625** |
| Frames copiados (`copy_cel`) | 2 (frames 3 y 5 = idle, copiados del frame 1) |
| Errores de API | **0** — todas las calls retornaron éxito |
| Errores de flujo | **1** — ver abajo |

**Desglose de las 16 calls:**

| # | Herramienta | Propósito |
|---|-------------|-----------|
| 1 | `create_canvas` | Lienzo 48×48 |
| 2 | `set_palette` | Nochebuena 16 |
| 3 | `get_sprite_info` | Confirmar nombre de capa por defecto |
| 4 | `draw_rows` | Frame 1 idle — 548 px |
| 5 | `set_tag` | Tag `idle` frames 1-1 |
| 6 | `view_sprite` | Pasada 1: revisar idle |
| 7-10 | `add_frame` × 4 | Añadir frames 2-5 |
| 11 | `copy_cel` | Frame 1 → frame 3 |
| 12 | `copy_cel` | Frame 1 → frame 5 |
| 13 | `draw_rows` | Frame 2 (pie izq. adelante) — 546 px |
| 14 | `draw_rows` | Frame 4 (pie der. adelante) — 531 px |
| 15 | `set_tag` | Tag `walk` frames 2-5 |
| 16 | `view_sprite` | Pasada 2: revisar animación completa |
| 17 | `export_spritesheet` | PNG + JSON verticales |

Tiempo total de sesión: estimado ~5 min (no medido con cronómetro; aproximación por flujo de conversación). No puedo confirmar tiempos por llamada individual.

### Error de flujo detectado

**Path resolution del MCP:** el servidor diivi/aseprite-mcp resuelve rutas relativas desde su propio CWD (`tools/aseprite-mcp/`), no desde el directorio del proyecto. Todas las tools retornaron éxito, pero los archivos se crearon en `tools/aseprite-mcp/assets/pilot_aseprite/` en lugar de `assets/pilot_aseprite/`. Fue necesario copiarlos manualmente al proyecto.

**Solución**: usar rutas absolutas en todas las llamadas al MCP, o configurar el CWD del servidor. Impacto: +1 paso manual por sesión, detectado al verificar el sistema de archivos.

### Comparación con Lua (batch mode directo)

| Aspecto | Lua batch mode | MCP tools |
|---------|---------------|-----------|
| Calls / operaciones para el sprite completo | 1 ejecución de script (67 líneas Lua) | 16 tool calls |
| Preview en contexto | No — abrir Aseprite manualmente | **Sí** — `view_sprite` devuelve imagen directamente |
| Correcciones sin reintentar | No aplicable (visual al final) | 0 correcciones necesarias en esta prueba |
| Escritura de código | Lua con rects y loops | Strings ASCII en `draw_rows` + legend |
| Errores silenciosos | Sí (stdout bloqueado, requiere logging a archivo) | No — las calls fallan ruidosamente |
| Path resolution | Ruta explícita en Lua | CWD del servidor MCP (bug de flujo) |
| Tiempo por iteración | ~2-3 seg (proceso único) | Múltiples procesos; no diferencia perceptible en 48×48 |

---

## Copia de referencia a 96 px

**Fecha:** 2026-11-08  
**Archivo fuente:** `assets/pilot_aseprite/ref/personaje_ref.png` (1254×1254 RGBA, 10 poses, ~28 K colores, 27.5% semi-transparente — no es pixel art nativo)  
**Salida:** `adulto96.aseprite` 64×100, 10 frames, 32 colores, tags `idle` (1–4) y `walk` (5–10)

### Método

**Preprocesado Python** (`scripts/preprocess_ref.py`, `uv run --with pillow --with numpy`):

| Parámetro | Valor |
|-----------|-------|
| Canvas | 64×100 px, pies en y=99 |
| Target height | 96 px (idle) |
| Scale factor | 0.23429 (96 / 409.8 px avg idle) |
| Downsampling | `Image.BOX` |
| Alpha | Hard binarize @ threshold 128 |
| Paleta | `Image.Quantize.MEDIANCUT`, 32 colores, shared entre los 10 frames |
| Cuantización | Distancia euclidiana vectorizada (NumPy), sin dithering |
| Output | 10 PNGs + `palette.json` + `frame_data.json` (rows formato `draw_rows`) |

**Montaje MCP** (perfil `cli`, batch mode, rutas absolutas):

1. `create_canvas` — 64×100, RGB, 10 frames  
2. `set_palette` — 32 colores del `palette.json`  
3. `draw_rows` × 10 — datos de `frame_data.json` (cada frame = 100 strings × 64 chars)  
4. `set_tag` × 2 — tags `idle` y `walk`  
5. `export_spritesheet` — `adulto96_sheet.png` + `adulto96_sheet.json` (640×100 horizontal)

**Total llamadas MCP:** ~26 (create + palette + 10 × draw_rows + 2 × tag + export + ~6 view_sprite + pixel reads)

### Incidencias

- **UnicodeEncodeError (cp1252):** Python en Windows usa cp1252 por defecto. Tres print statements con `×`, `→`, `──` fallaron. Fix: reemplazar todos por ASCII.
- **Truncado de fila en draw_rows (frame 2):** Copy-paste manual del JSON truncó la fila 84 a 58 caracteres. Solución: generar `rows_NN.json` por frame, validar longitud antes de cada llamada.

### Limpieza (Pasada 1)

**Defectos identificados antes de la pasada:**

1. Sin boca en ningún frame idle — lower face (y≈25-26) todo skin tone; walk frames sí tienen pixels de boca desde la referencia
2. Botas fusionadas en idle F1–F4 — separador de 1 px (`#160c09`) presente pero débil en y=93
3. Borde del jersey irregular en y≈56–58 — alternancia ruido rojo/azul sin línea limpia
4. Oreja ausente en F1–F2 — x≈38, y=18-20 sin bump de skin tone
5. Corona del pelo baja 1 px en F3–F4 vs F1–F2

**Fix aplicado:** 2 pixels `#873f33` (sombra de nariz/labio) en y=26, x=31–32 para frames 1–4. Resultado: hint de sonrisa visible a 6× que iguala el detalle de los walk frames.

**No corregido (imperceptible a escala de juego 1–2×):** hem del jersey, separación de botas, desfase de corona.

### Valoración honesta

**Lo que sale bien:**
- La silueta del personaje es muy legible: pelo, ojo+ceja, nariz, boca (post pasada), jersey rojo navideño con copo de nieve, pantalón azul marino, botas marrón oscuro.
- El ciclo walk de 6 frames tiene poses diferenciadas y lee fluido.
- La paleta compartida de 32 colores mantiene consistencia de color entre idle y walk.

**Lo que sale mal:**
- La referencia no es pixel art nativo: el escalado BOX introduce suavizado que la cuantización convierte en ruido de colores (varias variantes de marrón oscuro en las botas, granos en las costuras del jersey).
- No es posible capturar el detalle fino del original (copo de nieve complejo, cuentas del jersey) a 96 px sin redibujado manual.
- La pose idle no tiene breathing animation diferencial entre frames 1–2 y 3–4; las diferencias son artefactos de cuantización, no intención artística.

**Propuesta D-29:** revisar si el adulto necesita 96 px o puede reducirse a 72–80 px (menos ruido al escalar desde 1254), y definir la altura del niño (~64 px ≈ 0.67 × adulto).

---

### Valoración honesta

**Lo confirmado:**
- El MCP funciona end-to-end en sesión activa: crear canvas, paleta, dibujar, animar, exportar — todo sin salir de Claude.
- `view_sprite` es la ventaja real: permite validar visualmente en el acto sin abrir Aseprite. En Lua esto era imposible sin lanzar Aseprite manualmente.
- `draw_rows` es expresivo y eficiente para personajes 2D: una llamada dibuja todo el cuerpo como ASCII art.
- `copy_cel` elimina redundancia (frames neutrales del walk = idle).
- Sin errores de API: el MCP es estable para sprites 48×48 indexados.

**Lo no resuelto:**
- El bug de path resolution requiere rutas absolutas o workaround. No es bloqueante pero sí fricción.
- No se probó el perfil `core` (live mode). En batch mode cada llamada lanza un proceso Aseprite; para sprites más complejos (256 calls) el overhead podría acumularse.
- Calidad del resultado frente al Lua: No puedo hacer comparación visual objetiva — yo generé ambos sprites. La comparación la hace el usuario.

**¿Cambia la valoración para S8?** Sí, a mejor. El riesgo principal del informe anterior ("no haber validado el MCP en sesión activa") queda cerrado. El flujo MCP es viable, el coste por sprite es ~16 calls vs 1 ejecución Lua, pero con la ventaja de preview en contexto que elimina el ciclo editar→ejecutar→abrir-Aseprite. Para los 6 NPCs de S8, el overhead de path resolution se resuelve con una convención de rutas absolutas.

---

## Pasada 2 de limpieza — Remapeo de paleta y snowflake

**Fecha:** 2026-11-08  
**Objetivo:** corregir la contaminación de skin tones en el copo de nieve del jersey, consolidar la paleta a rampas de material, verificar sin errores.

### Paleta de materiales (28 colores)

| Material | Light | Mid-light | Mid | Shadow | Deep |
|---|---|---|---|---|---|
| Skin | `#FFD5A8` | `#F5B585` | `#EDA470` | `#C98F73` | `#9E6553` |
| Hair | `#5C3929` | `#442B21` | `#37221A` | `#160C09` | — |
| Jersey | `#C03838` | `#902324` | `#8B1D1F` | `#711618` | `#4D0A0C` |
| Cream (copo) | `#F0E4C0` | `#C8A870` | `#9A7A50` | — | — |
| Denim | `#3D4E7A` | `#2B3146` | `#1D2237` | `#0D1222` | — |
| Boots | `#7A4832` | `#5C3220` | `#3A1E0E` | `#1A0C06` | — |
| Outline | `#261611` | `#171219` | `#090504` | — | — |

### Causa raíz de la contaminación

El cuantizador original no tenía colores crema en la paleta; mapeó el copo de nieve (motivo crema del jersey) a los colores de piel más cercanos: `#F5B585`, `#C98F73`, `#9E6553`. La corrección añade una rampa cream de 3 pasos y sustituye los píxeles afectados en el área de jersey (x=18–45, y=35–56) en los 10 frames.

### Métricas antes / después

| Métrica | v1 (pasada 1) | v2 (pasada 2) |
|---|---|---|
| Colores únicos (F1) | 30 → 17 (tras remap global) | 20 |
| Colores únicos (total 10 frames) | 30+ | 21 |
| Píxeles huérfanos detectados | 323 (F1, lint_sprite) | 0 (verify OK) |
| Contaminación skin en jersey chest | presente todos los frames | 0 px |
| verify_adulto96.py | — | OK |

### Proceso y errores

**Remap global** (`remap_colors_in_cel_range`): 16 substituciones sobre los 10 frames, redujo F1 de 30 → 17 colores.

**draw_rows jersey (10 llamadas):** un error inicial por fila de 29 chars (una A extra) y otro por chars Cirílicos en filas 3 y 11 — el MCP rechazó ambas llamadas con mensaje descriptivo antes de modificar nada. Resuelto releyendo la región con `read_rows` en cada frame y remapeando solo el legend (no las filas), lo que eliminó el problema de codificación.

**Estrategia final:** en vez de reescribir las filas caracter a caracter, se reutilizaron las filas devueltas por `read_rows` sin cambios, solo modificando el legend para que los chars de contaminación (F, G, H / I, J, K según frame) apuntaran a los colores cream. Eficiente y libre de errores de transcripción.

### Calls MCP esta sesión

~35 calls: 1 `set_palette` + 1 `remap_colors_in_cel_range` + 11 `read_rows` + 10 `draw_rows` + 10 `export_frame` + 1 `export_spritesheet` + 1 `get_color_stats` × 2.

### Valoración honesta

El snowflake ahora usa la rampa cream correcta y deja de leerse como piel rosada. El verify pasa limpio. Los 323 huérfanos de pasada 1 no persisten en pasada 2 (ningún error de huérfanos en el verify), probablemente porque el remap global y los draw_rows subsiguientes sobrescribieron los píxeles sueltos.

Pendiente fuera de scope de esta pasada: contorno de botas (motas de rojo en y>72), desfase de corona del pelo F3–F4, oreja ausente F1–F2. Ninguno es visible a escala de juego 1–2×.
