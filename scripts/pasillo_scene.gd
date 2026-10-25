extends Node2D


func _ready() -> void:
	$SceneLabel.text = tr("SCENE_PASILLO")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		SceneManager.change_scene("res://scene/habitacion.tscn")
