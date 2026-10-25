extends Area2D

signal interacted

func _ready() -> void:
	add_to_group("interactable")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	body.call("add_nearby_interactable", self)
	var hint: Node = get_node_or_null("HintLabel")
	if hint:
		hint.visible = true

func _on_body_exited(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	body.call("remove_nearby_interactable", self)
	var hint: Node = get_node_or_null("HintLabel")
	if hint:
		hint.visible = false

func trigger() -> void:
	interacted.emit()
