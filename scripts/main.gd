class_name MainScene
extends Node


func _ready() -> void:
	get_tree().change_scene_to_file.call_deferred("res://scene/title.tscn")
