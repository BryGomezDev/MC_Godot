# Dev Notes — S3/S4 Player, NPC & Dialogue System

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
- `set_form(Form)` — switches Body ColorRect color (ADULT = blue, CHILD = orange) — ready for story use

### `scripts/interactable.gd` — Area2D base
- No `class_name` (omitted to avoid GDScript reload error code 43 in MCP reload cycles)
- NPC inherits via path: `extends "res://scripts/interactable.gd"`
- On `body_entered` by a "player" group member: calls `add_nearby_interactable`, shows `HintLabel`
- On `body_exited`: calls `remove_nearby_interactable`, hides `HintLabel`
- `trigger()` emits `interacted` signal

### `scripts/npc.gd` — extends Interactable
- `@export var npc_id: String = ""`
- `@export var dialogue_keys: Array[String] = []`
- `@export var required: bool = false`
- `@export var speaker_key: String = ""` — translation key for the speaker name shown in the dialogue box
- `@export var body_color: Color = Color(0.6, 0.2, 0.2, 1)` — placeholder body colour
- `@export var body_height: int = 20` — body height in px (20 = standing, 14 = seated)
- `_dm` reference obtained at runtime via `get_node("/root/DialogueManager")`
- In `_ready()`: applies `body_color` and `body_height` to the child ColorRect `Body`
- On interact: starts dialogue via `_dm.start(dialogue_keys, speaker_key)` if not yet spoken
- After dialogue: hides Indicator, notifies GameState

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

### `scripts/game_state.gd` — Node autoload
- `register_required_npc(scene, id)` — called from NPC._ready when required=true
- `mark_npc_talked(id, scene, required)` — called from NPC after dialogue_finished
- `_check_complete(scene)` — fires `all_required_done` when every required NPC in the scene is spoken
- `is_scene_done(scene)` — used on re-entry to pre-unlock exit if scene was already completed

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

Eliminadas: `TEST_NPC_A_*`, `TEST_NPC_B_*` (NPCs de prueba ya no existen)

---

## Known Gotchas

- **`input_key("E")` vs `input_action("interact")`**: `input_key` dispatches through the event system (needed for `_unhandled_input` / `_input`). `input_action` only updates the `Input` singleton (needed for `Input.get_axis()` in `_physics_process`). Use the right one for the right handler.
- **Spawning inside an Area2D**: `body_entered` does not fire if a body spawns already overlapping the zone. Start slightly outside for reliable detection.
- **`class_name Interactable`**: Omitted from `interactable.gd` — caused GDScript error code 43 during hot-reload cycles in the MCP environment.
- **DialogueManager in npc.gd**: accessed via `get_node("/root/DialogueManager")` at runtime rather than by class identifier, because the MCP plugin's parser cache doesn't see dynamically-added autoloads.
- **tr("") returns ""**: Passing empty speaker_key through tr() is safe — the SpeakerLabel is hidden when speaker == "".

---

## Dialogue Choice System (Design-Ready, Not Implemented)

The architecture supports branching dialogue. To add choices:
1. `dialogue_box.tscn` would gain an OptionContainer with buttons
2. `DialogueManager.start()` would accept a tree structure instead of a flat `Array[String]`
3. `page_done` would carry the chosen branch index

No code written — implement when the story requires it.
