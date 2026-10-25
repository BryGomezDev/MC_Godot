extends Node2D

var _exit_unlocked: bool = false

func _ready() -> void:
	$SceneLabel.text = tr("SCENE_SALON")
	GameState.all_required_done.connect(_on_all_required_done)
	if GameState.is_scene_done(name):
		_exit_unlocked = true
	$ExitZone.body_entered.connect(_on_exit_zone_body_entered)

func _on_all_required_done() -> void:
	_exit_unlocked = true
	for body in $ExitZone.get_overlapping_bodies():
		if body.is_in_group("player"):
			SceneManager.change_scene("res://scene/pasillo.tscn")
			return

func _on_exit_zone_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and _exit_unlocked:
		SceneManager.change_scene("res://scene/pasillo.tscn")
