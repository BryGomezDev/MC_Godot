class_name TitleScene
extends Node2D


func _ready() -> void:
	$SceneLabel.text = tr("SCENE_TITLE")
	$LangButtons/BtnES.pressed.connect(_on_btn_es_pressed)
	$LangButtons/BtnEN.pressed.connect(_on_btn_en_pressed)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		SceneManager.change_scene("res://scene/salon.tscn")


func _on_btn_es_pressed() -> void:
	TranslationServer.set_locale("es")
	$SceneLabel.text = tr("SCENE_TITLE")


func _on_btn_en_pressed() -> void:
	TranslationServer.set_locale("en")
	$SceneLabel.text = tr("SCENE_TITLE")
