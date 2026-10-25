extends Node

signal dialogue_finished

var _box: CanvasLayer
var _keys: Array[String] = []
var _index: int = 0
var _player: Node
var _speaker: String = ""

func _ready() -> void:
	_box = load("res://ui/dialogue_box.tscn").instantiate()
	add_child(_box)
	_box.visible = false
	_box.page_done.connect(_on_page_done)

func start(keys: Array[String], speaker: String = "") -> void:
	_keys = keys
	_speaker = speaker
	_index = 0
	_player = get_tree().get_first_node_in_group("player")
	if _player:
		_player.call("lock_control")
	_box.visible = true
	_show_current()

func _show_current() -> void:
	_box.call("show_text", tr(_keys[_index]), tr(_speaker))

func _on_page_done() -> void:
	_index += 1
	if _index >= _keys.size():
		_box.visible = false
		if _player:
			_player.call("unlock_control")
			_player = null
		dialogue_finished.emit()
	else:
		_show_current()
