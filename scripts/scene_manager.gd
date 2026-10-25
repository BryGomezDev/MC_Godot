extends Node

var _canvas_layer: CanvasLayer
var _overlay: ColorRect
var _tween: Tween


func _ready() -> void:
	_canvas_layer = CanvasLayer.new()
	_canvas_layer.layer = 100
	add_child(_canvas_layer)

	_overlay = ColorRect.new()
	_overlay.color = Color.BLACK
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.modulate.a = 0.0
	_canvas_layer.add_child(_overlay)


func change_scene(path: String) -> void:
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_tween.tween_property(_overlay, "modulate:a", 1.0, 0.4)
	_tween.tween_callback(func() -> void: get_tree().change_scene_to_file(path))
	_tween.tween_property(_overlay, "modulate:a", 0.0, 0.4)
	_tween.tween_callback(func() -> void: _overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE)
