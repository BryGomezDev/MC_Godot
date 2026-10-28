# Dev Notes — S3/S4/S5/S6 Player, NPC, Dialogue, Pasillo & Habitación

## Architecture

### Autoloads
| Singleton | Script | Role |
|-----------|--------|------|
| GameState | `scripts/game_state.gd` | Tracks which NPCs have been spoken to; emits `all_required_done` when a scene's required set is complete |
| SceneManager | `scripts/scene_manager.gd` | Fade-to-black transition between scenes via Tween |
| DialogueManager | `scripts/dialogue_manager.gd` | Owns the dialogue box UI; `start(keys, speaker)` locks player and plays through localized strings one page at a time, showing the speaker name |

### Key Signals
```
NPC.interacted           → npc._on_interacted() → DialogueManager.start(keys, speaker_key)
DialogueManager.dialogue_finished → npc._on_dialogue_finished() → GameState.mark_npc_talked()
GameState.all_required_done → salon_scene._on_all_required_done() → unlock exit
DialogueBox.page_done    → DialogueManager._on_page_done() → next page or finish
```

---

## Scripts

### `scripts/player.gd` — CharacterBody2D
- Horizontal movement via `Input.get_axis("move_left", "move_right")` in `_physics_process`
- Position clamped to `[clamp_left, clamp_right]` (default 8–472)
- `lock_control()` / `unlock_control()` — called by DialogueManager during dialogue
- `add_nearby_interactable(area)` / `remove_nearby_interactable(area)` — called by Interactable on body enter/exit
- `_unhandled_input`: on `interact` press, calls `trigger()` on the nearest Area2D in `_nearby`
- `set_form(Form)` — cambia color Y tamaño del Body ColorRect. ADULT: 12×20 (offset -6,-10,6,10). CHILD: 10×14 pies en y=10 (offset -5,-4,5,10). CollisionShape2D no se toca.

### `scripts/interactable.gd` — Area2D base (`class_name Interactable`)
- Uses `body is Player` check (typed, replaces group-based check)
- Calls `(body as Player).add_nearby_interactable(self)` / `remove_nearby_interactable(self)` directly
- `trigger()` emits `interacted` signal

### `scripts/npc.gd` — extends Interactable
- `@export var npc_id: String = ""`
- `@export var dialogue_keys: Array[String] = []`
- `@export var required: bool = false`
- `@export var speaker_key: String = ""` — translation key for the speaker name shown in the dialogue box
- `@export var body_color: Color = Color(0.6, 0.2, 0.2, 1)` — placeholder body colour
- `@export var body_height: int = 20` — body height in px (20 = standing, 14 = seated)
- `@export var show_body: bool = true` — si false, oculta el Body ColorRect (útil para NPCs detrás de una puerta)
- `extends Interactable` (tipado, ya no usa ruta de texto)
- `DialogueManager.start(dialogue_keys, speaker_key)` directo (sin `_dm` ni get_node)
- In `_ready()`: aplica body_color/body_height si show_body=true; oculta Body si show_body=false
- On interact: inicia diálogo si no hablado aún; conecta dialogue_finished CONNECT_ONE_SHOT
- After dialogue: oculta Indicator, notifica GameState
- **S6 fix**: `_update_indicator()` usa `required and not _spoken` — el rombo amarillo solo aparece en NPCs requeridos no hablados
- **S6 fix**: override `_on_body_entered` — oculta HintLabel "E" si ya se habló con el NPC (`super(body)` + hide if `_spoken`)

### `scripts/dialogue_manager.gd` — Node autoload
- Instantiates `ui/dialogue_box.tscn` as a child at startup via `load()` (not `preload()`)
- `start(keys: Array[String], speaker: String = "")`: locks player, stores speaker, shows box, displays first key
- `_speaker: String` stored between pages so the name persists through the whole dialogue
- `_show_current()`: calls `box.show_text(tr(key), tr(speaker))` — tr("") safely returns ""
- On last page: hides box, unlocks player, emits `dialogue_finished`

### `scripts/dialogue_box.gd` — CanvasLayer (layer 50)
- Typewriter effect: `_process(delta)` increments `_shown_chars` every `CHAR_DELAY` (0.04s)
- Uses `_input` (not `_unhandled_input`) so dialogue intercepts E before the player does
- `show_text(text: String, speaker: String = "")`: sets SpeakerLabel text/visibility and starts typewriter
- First E press while typing: fast-forwards to full text
- E press when fully shown: emits `page_done`
- `@export var font_size_speaker: int = 8` / `@export var font_size_text: int = 10` — aplicados en `_ready()` vía `add_theme_font_size_override`
- Estructura UI: `Panel/Margins(MarginContainer)/Layout(VBoxContainer)/SpeakerLabel` y `TextLabel`; `HintLabel` es hijo directo de Panel. Panel sube a y=205.

### `scripts/game_state.gd` — Node autoload
- `register_required_npc(scene, id)` — called from NPC._ready when required=true
- `mark_npc_talked(id, scene, required)` — called from NPC after dialogue_finished
- `_check_complete(scene)` — fires `all_required_done` when every required NPC in the scene is spoken
- `is_scene_done(scene)` — used on re-entry to pre-unlock exit if scene was already completed

### `scripts/habitacion_scene.gd` — Node2D (`class_name HabitacionScene`)

State machine con enum `State { EXPLORING, FLASHBACK, ESCAPE, PAUSE, MUSIC, DONE }`.

**Transiciones:**
- `EXPLORING → FLASHBACK`: Player entra en BeamZone. Pone `GameState.flashback_visto = true`, llama `player.set_form(CHILD)`, sube tinte. Solo la primera vez lanza `DialogueManager.start(["FLASHBACK_MAMA_1","FLASHBACK_MAMA_2"], "SPEAKER_MAMA")`.
- `FLASHBACK → EXPLORING`: Player sale de BeamZone sin coger la caja. Vuelve a ADULT, apaga tinte.
- `FLASHBACK → ESCAPE`: Player interactúa con CajaDMusica. Oculta caja, bloquea Player, mueve con Tween hacia `x = 240 - 20 = 220` a velocidad `escape_speed`. Respaldo: si el Tween termina y sigue en ESCAPE, fuerza PAUSE.
- `ESCAPE → PAUSE`: `body_exited` de BeamZone **o** tween completado. Vuelve a ADULT, apaga tinte, espera `connect_pause_seconds`.
- `PAUSE → MUSIC`: reproduce `MusicPlayer` (si `music_stream` es null → `push_warning` y continúa). Espera `music_hold_seconds`.
- `MUSIC → DONE`: `SceneManager.change_scene("res://scene/final.tscn")`.
- Desde ESCAPE en adelante el Player queda bloqueado. `_exit_tree()` mata ambos Tweens.

**@export (HabitacionScene):**
| Variable | Tipo | Default |
|----------|------|---------|
| `tint_alpha` | float | 0.25 |
| `escape_speed` | float | 140.0 |
| `connect_pause_seconds` | float | 1.5 |
| `music_hold_seconds` | float | 4.0 |
| `music_stream` | AudioStream | null |

### `scripts/salon_scene.gd` — Node2D
- Connects `GameState.all_required_done` and `ExitZone.body_entered`
- Exit is blocked (`_exit_unlocked = false`) until all required NPCs are spoken
- On `all_required_done`: sets flag, immediately checks if player is already in zone

---

## Scene Files

| File | Root type | Notes |
|------|-----------|-------|
| `scene/actors/player.tscn` | CharacterBody2D | CollisionShape2D (12×20), ColorRect Body |
| `scene/actors/npc.tscn` | Area2D | CollisionShape2D (24×30), ColorRect Body (colour/height set at runtime via @export), HintLabel ("E"), Indicator (yellow) |
| `ui/dialogue_box.tscn` | CanvasLayer (layer=50) | Panel (y=195–270, 75px), SpeakerLabel (11px, hidden when no speaker), TextLabel (autowrap), HintLabel ("[ E ]") |
| `scene/salon.tscn` | Node2D | 480×270. Placeholders: Floor, Mesa, Sofá, ArbolTronco, ArbolCopa, Puerta. 6 NPC (Mamá, Hermano, Cuñada, Esposa, Hija, Sobrino), todos required=true. ExitZone en x=470 |
| `scene/pasillo.tscn` | Node2D | 480×270. Placeholders: DoorPadre (x=138-180), DoorOtra (x=278-320), DoorHabitacion (x=442-475), LightBeam (apagado al inicio). NPC_Papa (required=true, show_body=false), NPC_DoorOther (required=false, show_body=false). ExitZone en x=470 |
| `scene/habitacion.tscn` | Node2D | 480×270. Placeholders: Floor, PuertaIzq (x=5-25), Ventana (x=400-470, y=30-90), Mesa (x=345-395, y=175-200). LunaBeam ColorRect (x=240-480, alpha baked in color 0.12). BeamZone Area2D en (360,135) shape 240×270. CajaDMusica Interactable en (370,185). FlashbackTint CanvasLayer layer=10 con TintRect (modulate.a=0). MusicPlayer. Player en x=20,y=200. |

### Salon layout (480×270)
| Elemento | Posición placeholder | Color |
|----------|---------------------|-------|
| Background | 0,0 → 480,270 | Color(0.22, 0.1, 0.04, 1) |
| Floor | 0,200 → 480,270 | Color(0.55, 0.38, 0.2, 1) |
| Mesa | 100,170 → 240,200 | Color(0.45, 0.25, 0.1, 1) |
| Sofá | 275,183 → 400,200 | Color(0.35, 0.08, 0.08, 1) |
| Árbol (tronco) | 424,178 → 434,200 | Color(0.35, 0.2, 0.05, 1) |
| Árbol (copa) | 409,138 → 449,180 | Color(0.1, 0.45, 0.15, 1) |
| Puerta | 454,145 → 475,200 | Color(0.3, 0.12, 0.04, 1) |

### NPC positions & @export values
| NPC | x,y | body_color | body_height | npc_id |
|-----|-----|-----------|-------------|--------|
| Mamá (de pie, junto a mesa) | 88, 190 | Color(0.85, 0.35, 0.35, 1) | 20 | MAMA |
| Hermano (sentado, mesa) | 148, 200 | Color(0.3, 0.4, 0.8, 1) | 14 | HERMANO |
| Cuñada (sentada, mesa) | 198, 200 | Color(0.2, 0.65, 0.6, 1) | 14 | CUNADA |
| Esposa (de pie, junto sofá) | 260, 190 | Color(0.65, 0.3, 0.75, 1) | 20 | ESPOSA |
| Hija (sentada, sofá) | 308, 200 | Color(0.9, 0.65, 0.2, 1) | 14 | HIJA |
| Sobrino (sentado, sofá) | 355, 200 | Color(0.3, 0.7, 0.35, 1) | 14 | SOBRINO |

Player: x=20, y=190 (izquierda, fuera de zona de cualquier NPC)
ExitZone: Area2D en x=470, y=135 — RectangleShape2D 20×270

---

## Translations (translations/game_text.csv)

Claves activas:
- `SCENE_*` — nombres de escenas
- `TITLE_START`, `LANG_ES`, `LANG_EN` — título
- `SPEAKER_MAMA/HERMANO/CUNADA/ESPOSA/HIJA/SOBRINO/PAPA` — nombres de hablantes
- `NPC_MAMA_1/2`, `NPC_HERMANO_1/2`, `NPC_CUNADA_1/2`, `NPC_ESPOSA_1/2`, `NPC_HIJA_1/2`, `NPC_SOBRINO_1/2` — diálogos [TEMP]
- `NPC_PAPA_1/2` — diálogos del padre (pasillo) [TEMP]
- `DOOR_OTHER_1` — texto de descarte de la puerta cerrada [TEMP]

Eliminadas: `TEST_NPC_A_*`, `TEST_NPC_B_*` (NPCs de prueba ya no existen)
- `FLASHBACK_MAMA_1/2` — diálogos flashback habitación (voz de la madre): la madre avisa de que han llegado los abuelos. [TEMP]
- `SPEAKER_MAMA` — ya existía

---

---

## Tabla completa de @export (todos los scripts)

| Script | Variable | Tipo | Default |
|--------|----------|------|---------|
| `player.gd` | `speed` | float | 60.0 |
| `player.gd` | `clamp_left` | float | 8.0 |
| `player.gd` | `clamp_right` | float | 472.0 |
| `npc.gd` | `npc_id` | String | "" |
| `npc.gd` | `dialogue_keys` | Array[String] | [] |
| `npc.gd` | `required` | bool | false |
| `npc.gd` | `speaker_key` | String | "" |
| `npc.gd` | `body_color` | Color | Color(0.6,0.2,0.2,1) |
| `npc.gd` | `body_height` | int | 20 |
| `npc.gd` | `show_body` | bool | true |
| `dialogue_box.gd` | `font_size_speaker` | int | 8 |
| `dialogue_box.gd` | `font_size_text` | int | 10 |
| `habitacion_scene.gd` | `tint_alpha` | float | 0.25 |
| `habitacion_scene.gd` | `escape_speed` | float | 140.0 |
| `habitacion_scene.gd` | `connect_pause_seconds` | float | 1.5 |
| `habitacion_scene.gd` | `music_hold_seconds` | float | 4.0 |
| `habitacion_scene.gd` | `music_stream` | AudioStream | null |

---

## Known Gotchas

- **`input_key("E")` vs `input_action("interact")`**: `input_key` dispatches through the event system (needed for `_unhandled_input` / `_input`). `input_action` only updates the `Input` singleton (needed for `Input.get_axis()` in `_physics_process`). Use the right one for the right handler.
- **Spawning inside an Area2D**: `body_entered` does not fire if a body spawns already overlapping the zone. Start slightly outside for reliable detection.
- **`class_name` en hot-reload (MCP)**: Al añadir class_name puede aparecer el error código 43 durante la recarga en caliente del plugin MCP. Solución: recargar el plugin (`editor_reload_plugin`) y volver a comprobar los logs. No revierte la class_name — el error es del hot-reload, no del código.
- **DialogueManager en npc.gd**: acceso directo por nombre global (`DialogueManager.start(...)`) — los autoloads son globales en Godot 4 y no necesitan get_node ni ruta de texto.
- **tr("") returns ""**: Passing empty speaker_key through tr() is safe — the SpeakerLabel is hidden when speaker == "".

---

## Dialogue Choice System (Design-Ready, Not Implemented)

The architecture supports branching dialogue. To add choices:
1. `dialogue_box.tscn` would gain an OptionContainer with buttons
2. `DialogueManager.start()` would accept a tree structure instead of a flat `Array[String]`
3. `page_done` would carry the chosen branch index

No code written — implement when the story requires it.
