# Dev Notes — S3 Player & NPC System

## Architecture

### Autoloads
| Singleton | Script | Role |
|-----------|--------|------|
| GameState | `scripts/game_state.gd` | Tracks which NPCs have been spoken to; emits `all_required_done` when a scene's required set is complete |
| SceneManager | `scripts/scene_manager.gd` | Fade-to-black transition between scenes via Tween |
| DialogueManager | `scripts/dialogue_manager.gd` | Owns the dialogue box UI; `start(keys)` locks player and plays through localized strings one page at a time |

### Key Signals
```
NPC.interacted           → npc._on_interacted() → DialogueManager.start()
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
- `@export npc_id`, `dialogue_keys`, `required`
- `_dm` reference obtained at runtime via `get_node("/root/DialogueManager")` (not via class name, to avoid MCP parser issues with dynamically-added autoloads)
- On interact: starts dialogue if not yet spoken (`_spoken` flag)
- After dialogue: hides Indicator node, notifies GameState
- Registers itself as required on `_ready` when `required = true`

### `scripts/dialogue_manager.gd` — Node autoload
- Instantiates `ui/dialogue_box.tscn` as a child at startup via `load()` (not `preload()`)
- `start(keys)`: locks player, shows box, displays first key
- Advances pages via `page_done` signal from box
- On last page: hides box, unlocks player, emits `dialogue_finished`

### `scripts/dialogue_box.gd` — CanvasLayer (layer 50)
- Typewriter effect: `_process(delta)` increments `_shown_chars` every `CHAR_DELAY` (0.04s)
- Uses `_input` (not `_unhandled_input`) so dialogue intercepts E before the player does
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
| `scene/actors/npc.tscn` | Area2D | CollisionShape2D (24×30), ColorRect Body, HintLabel ("E"), Indicator (yellow ColorRect) |
| `ui/dialogue_box.tscn` | CanvasLayer (layer=50) | Panel (lower 70px), TextLabel (autowrap), HintLabel ("[ E ]") |
| `scene/salon.tscn` | Node2D | Test scene: Player at (50,190), NPC_A at (150,190) required, NPC_B at (350,190) required, ExitZone at (460,135) |

---

## Known Gotchas

- **`input_key("E")` vs `input_action("interact")`**: `input_key` dispatches through the event system (needed for `_unhandled_input` / `_input`). `input_action` only updates the `Input` singleton (needed for `Input.get_axis()` in `_physics_process`). Use the right one for the right handler.
- **Spawning inside an Area2D**: `body_entered` does not fire if a body spawns already overlapping the zone. Start slightly outside for reliable detection.
- **`class_name Interactable`**: Omitted from `interactable.gd` — caused GDScript error code 43 during hot-reload cycles in the MCP environment.
- **DialogueManager in npc.gd**: accessed via `get_node("/root/DialogueManager")` at runtime rather than by class identifier, because the MCP plugin's parser cache doesn't see dynamically-added autoloads.

---

## Dialogue Choice System (Design-Ready, Not Implemented)

The architecture supports branching dialogue. To add choices:
1. `dialogue_box.tscn` would gain an OptionContainer with buttons
2. `DialogueManager.start()` would accept a tree structure instead of a flat `Array[String]`
3. `page_done` would carry the chosen branch index

No code written — implement when the story requires it.
