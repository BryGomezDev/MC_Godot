class_name HabitacionScene
extends Node2D

enum State { EXPLORING, FLASHBACK, ESCAPE, PAUSE, MUSIC, DONE }

@export var tint_alpha: float = 0.25
@export var escape_speed: float = 140.0
@export var connect_pause_seconds: float = 1.5
@export var music_hold_seconds: float = 4.0
@export var music_stream: AudioStream = null

const _BEAM_LEFT_X: float = 240.0
const _ESCAPE_MARGIN: float = 20.0

var _state: State = State.EXPLORING
var _box_taken: bool = false
var _tint_tween: Tween
var _escape_tween: Tween

@onready var _player: Player = $Player
@onready var _beam_zone: Area2D = $BeamZone
@onready var _tint_rect: ColorRect = $FlashbackTint/TintRect
@onready var _music_player: AudioStreamPlayer = $MusicPlayer
@onready var _caja: Interactable = $CajaDMusica


func _ready() -> void:
	$SceneLabel.text = tr("SCENE_HABITACION")
	_beam_zone.body_entered.connect(_on_beam_entered)
	_beam_zone.body_exited.connect(_on_beam_exited)
	_caja.interacted.connect(_on_caja_interacted)


func _on_beam_entered(body: Node2D) -> void:
	if not body is Player:
		return
	if _state != State.EXPLORING:
		return
	_state = State.FLASHBACK
	GameState.flashback_visto = true
	_player.set_form(Player.Form.CHILD)
	_fade_tint(tint_alpha)


func _on_beam_exited(body: Node2D) -> void:
	if not body is Player:
		return
	match _state:
		State.FLASHBACK:
			_state = State.EXPLORING
			_player.set_form(Player.Form.ADULT)
			_fade_tint(0.0)
		State.ESCAPE:
			_enter_pause()


func _on_caja_interacted() -> void:
	if _state != State.FLASHBACK:
		return
	if _box_taken:
		return
	_box_taken = true
	_caja.visible = false
	_player.lock_control()
	DialogueManager.start(["FLASHBACK_MAMA_1", "FLASHBACK_MAMA_2"], "SPEAKER_MAMA")
	await DialogueManager.dialogue_finished
	if not is_inside_tree():
		return
	_player.lock_control()
	_state = State.ESCAPE
	var dest_x: float = _BEAM_LEFT_X - _ESCAPE_MARGIN
	var distance: float = abs(_player.position.x - dest_x)
	var duration: float = distance / escape_speed
	if _escape_tween:
		_escape_tween.kill()
	_escape_tween = create_tween()
	_escape_tween.tween_property(_player, "position:x", dest_x, duration)
	_escape_tween.tween_callback(_on_escape_tween_done)


func _on_escape_tween_done() -> void:
	if _state == State.ESCAPE:
		_enter_pause()


func _enter_pause() -> void:
	if _state != State.ESCAPE:
		return
	_state = State.PAUSE
	_player.set_form(Player.Form.ADULT)
	_fade_tint(0.0)
	await get_tree().create_timer(connect_pause_seconds).timeout
	if is_inside_tree():
		_enter_music()


func _enter_music() -> void:
	_state = State.MUSIC
	if music_stream:
		_music_player.stream = music_stream
		_music_player.play()
	else:
		push_warning("HabitacionScene: music_stream is null, skipping playback")
	await get_tree().create_timer(music_hold_seconds).timeout
	if is_inside_tree():
		_enter_done()


func _enter_done() -> void:
	if _state == State.DONE:
		return
	_state = State.DONE
	SceneManager.change_scene("res://scene/final.tscn")


func _fade_tint(target: float) -> void:
	if _tint_tween:
		_tint_tween.kill()
	_tint_tween = create_tween()
	_tint_tween.tween_property(_tint_rect, "modulate:a", target, 0.5)


func _exit_tree() -> void:
	if _tint_tween:
		_tint_tween.kill()
	if _escape_tween:
		_escape_tween.kill()
