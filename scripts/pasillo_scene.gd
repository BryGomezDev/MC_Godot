extends Node2D

var _exit_unlocked: bool = false

func _ready() -> void:
	$SceneLabel.text = tr("SCENE_PASILLO")
	GameState.all_required_done.connect(_on_all_required_done)
	if GameState.is_scene_done(name):
		_exit_unlocked = true
		$LightBeam.modulate.a = 1.0
	$ExitZone.body_entered.connect(_on_exit_zone_body_entered)

func _on_all_required_done() -> void:
	_exit_unlocked = true
	var tw: Tween = create_tween()
	tw.tween_property($LightBeam, "modulate:a", 1.0, 0.6)
	for body in $ExitZone.get_overlapping_bodies():
		if body.is_in_group("player"):
			SceneManager.change_scene("res://scene/habitacion.tscn")
			return

func _on_exit_zone_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and _exit_unlocked:
		SceneManager.change_scene("res://scene/habitacion.tscn")
