class_name Npc
extends Interactable

@export var npc_id: String = ""
@export var dialogue_keys: Array[String] = []
@export var required: bool = false
@export var speaker_key: String = ""
@export var body_color: Color = Color(0.6, 0.2, 0.2, 1)
@export var body_height: int = 20
@export var show_body: bool = true

var _spoken: bool = false

func _ready() -> void:
	super()
	interacted.connect(_on_interacted)
	if required:
		GameState.register_required_npc(get_tree().current_scene.name, npc_id)
	var body: Node = get_node_or_null("Body")
	if body is ColorRect:
		if show_body:
			(body as ColorRect).color = body_color
			(body as ColorRect).offset_top = float(-body_height)
		else:
			(body as ColorRect).visible = false
	_update_indicator()

func _on_interacted() -> void:
	if _spoken:
		return
	DialogueManager.start(dialogue_keys, speaker_key)
	DialogueManager.dialogue_finished.connect(_on_dialogue_finished, CONNECT_ONE_SHOT)

func _on_dialogue_finished() -> void:
	_spoken = true
	_update_indicator()
	GameState.mark_npc_talked(npc_id, get_tree().current_scene.name, required)

func _update_indicator() -> void:
	var indicator: Node = get_node_or_null("Indicator")
	if indicator:
		indicator.visible = not _spoken
