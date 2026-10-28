class_name DialogueBox
extends CanvasLayer

signal page_done

@export var font_size_speaker: int = 8
@export var font_size_text: int = 10

@onready var _text_label: Label = $Panel/Margins/Layout/TextLabel
@onready var _hint_label: Label = $Panel/HintLabel
@onready var _speaker_label: Label = $Panel/Margins/Layout/SpeakerLabel

const CHAR_DELAY: float = 0.04

var _full_text: String = ""
var _shown_chars: int = 0
var _typing: bool = false
var _char_timer: float = 0.0

func _ready() -> void:
	_speaker_label.add_theme_font_size_override("font_size", font_size_speaker)
	_text_label.add_theme_font_size_override("font_size", font_size_text)

func show_text(text: String, speaker: String = "") -> void:
	_full_text = text
	_shown_chars = 0
	_typing = true
	_char_timer = 0.0
	_text_label.text = ""
	_hint_label.visible = false
	_speaker_label.text = speaker
	_speaker_label.visible = speaker != ""

func _process(delta: float) -> void:
	if not visible or not _typing:
		return
	_char_timer += delta
	while _char_timer >= CHAR_DELAY and _shown_chars < _full_text.length():
		_char_timer -= CHAR_DELAY
		_shown_chars += 1
	_text_label.text = _full_text.substr(0, _shown_chars)
	if _shown_chars >= _full_text.length():
		_typing = false
		_hint_label.visible = true

func _input(event: InputEvent) -> void:
	if not visible:
		return
	if not event.is_action_pressed("interact"):
		return
	get_viewport().set_input_as_handled()
	if _typing:
		_shown_chars = _full_text.length()
		_text_label.text = _full_text
		_typing = false
		_hint_label.visible = true
	else:
		page_done.emit()
