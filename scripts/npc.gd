extends "res://scripts/interactable.gd"

@export var npc_id: String = ""
@export var dialogue_keys: Array[String] = []
@export var required: bool = false

var _spoken: bool = false
var _dm: Node

func _ready() -> void:
	super()
	_dm = get_node("/root/DialogueManager")
	interacted.connect(_on_interacted)
	if required:
		GameState.register_required_npc(get_tree().current_scene.name, npc_id)
	_update_indicator()

func _on_interacted() -> void:
	if _spoken:
		return
	_dm.start(dialogue_keys)
	_dm.dialogue_finished.connect(_on_dialogue_finished, CONNECT_ONE_SHOT)

func _on_dialogue_finished() -> void:
	_spoken = true
	_update_indicator()
	GameState.mark_npc_talked(npc_id, get_tree().current_scene.name, required)

func _update_indicator() -> void:
	var indicator: Node = get_node_or_null("Indicator")
	if indicator:
		indicator.visible = not _spoken
