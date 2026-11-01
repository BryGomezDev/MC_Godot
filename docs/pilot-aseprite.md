# Pilot aseprite-mcp — Informe de viabilidad

Fecha: 2026-11-01
Aseprite: 1.3.18.6-x64 (Steam)
MCP: aseprite-mcp 0.6.0 (perfil cli)

## Instalación

```
uv tool install aseprite-mcp   # 58 dependencias
```

- Ejecutable resultante: `C:\Users\BryDev\AppData\Roaming\uv\tools\aseprite-mcp\Scripts\aseprite-mcp.exe`
- Configurado en `C:\Users\BryDev\.claude\settings.json` bajo `mcpServers.aseprite`
- Variables de entorno activas:
  - `ASEPRITE_PATH`: ruta al ejecutable de Steam
  - `ASEPRITE_MCP_TOOL_PROFILE=cli` (modo disco, sin instancia de Aseprite corriendo)
- Python 3.14.4, uv 0.13.5

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

`run_lua_script` está deshabilitada por defecto; requiere `ASEPRITE_MCP_ENABLE_RAW_LUA=1`.

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

Scripts Lua utilizados: `create_adulto.lua`, `create_nino.lua` (en `assets/pilot_aseprite/`).

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
