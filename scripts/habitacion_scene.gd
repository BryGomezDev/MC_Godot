class_name HabitacionScene
extends Node2D

enum State { EXPLORING, FLASHBACK, ESCAPE, ESPERA, MUSICA, MIRA_ARRIBA, SCROLL, MENSAJE }

@export var tint_alpha: float = 0.25
@export var escape_speed: float = 140.0
@export var prompt_delay_seconds: float = 1.0
@export var look_up_seconds: float = 1.5
@export var scroll_distance: float = 540.0
@export var scroll_seconds: float = 12.0
@export var message_fade_seconds: float = 2.0
@export var message_gap_seconds: float = 1.5
@export var music_stream: AudioStream = null

const _BEAM_LEFT_X: float = 240.0
const _ESCAPE_MARGIN: float = 20.0

var _state: State = State.EXPLORING
var _box_taken: bool = false
var _prompt_consumed: bool = false
var _tint_tween: Tween
var _escape_tween: Tween
var _scroll_tween: Tween

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


func _unhandled_input(event: InputEvent) -> void:
	if _state != State.ESPERA:
		return
	if _prompt_consumed:
		return
	if not event.is_action_pressed("interact"):
		return
	_prompt_consumed = true
	var prompt := get_node_or_null("PromptLayer/PromptLabel") as Label
	if prompt:
		prompt.visible = false
	_player.lock_control()
	if _music_player.stream:
		var ogg := _music_player.stream as AudioStreamOggVorbis
		if ogg:
			ogg.loop = true
		else:
			push_warning("HabitacionScene: stream is not AudioStreamOggVorbis, loop not set")
	else:
		push_warning("HabitacionScene: music_player has no stream")
	_music_player.play()
	_state = State.MUSICA
	await get_tree().create_timer(look_up_seconds).timeout
	if is_inside_tree():
		_enter_mira_arriba()


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
			_enter_espera()


func _on_caja_interacted() -> void:
	if _state != State.FLASHBACK:
		return
	if _box_taken:
		return
	_box_taken = true
	_caja.visible = false
	var box_in_hand := _player.get_node_or_null("BoxInHand") as CanvasItem
	if box_in_hand:
		box_in_hand.visible = true
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
		_enter_espera()


func _enter_espera() -> void:
	if _state != State.ESCAPE:
		return
	_state = State.ESPERA
	_player.set_form(Player.Form.ADULT)
	_fade_tint(0.0)
	await get_tree().create_timer(prompt_delay_seconds).timeout
	if not is_inside_tree():
		return
	var prompt := get_node_or_null("PromptLayer/PromptLabel") as Label
	if prompt:
		prompt.visible = true
	_player.unlock_control()


func _enter_mira_arriba() -> void:
	# ponytail: no hay animación de pose aún; placeholder directo a scroll
	_state = State.MIRA_ARRIBA
	_enter_scroll()


func _enter_scroll() -> void:
	_state = State.SCROLL
	var cam := get_node_or_null("Camera2D") as Camera2D
	if not cam:
		push_warning("HabitacionScene: Camera2D not found, skipping scroll")
		_enter_mensaje()
		return
	if _scroll_tween:
		_scroll_tween.kill()
	_scroll_tween = create_tween()
	_scroll_tween.tween_property(cam, "position:y", 135.0 - scroll_distance, scroll_seconds)
	await _scroll_tween.finished
	if is_inside_tree():
		_enter_mensaje()


func _enter_mensaje() -> void:
	_state = State.MENSAJE
	_show_final_messages()


func _show_final_messages() -> void:
	var container := get_node_or_null("FinalMessages") as CanvasLayer
	if not container:
		push_warning("HabitacionScene: FinalMessages not found")
		return
	for label_name: String in ["Label1", "Label2", "Label3"]:
		var label := container.get_node_or_null(label_name) as CanvasItem
		if not label:
			push_warning("HabitacionScene: FinalMessages/" + label_name + " not found")
			continue
		var tw: Tween = create_tween()
		tw.tween_property(label, "modulate:a", 1.0, message_fade_seconds)
		await tw.finished
		if not is_inside_tree():
			return
		await get_tree().create_timer(message_gap_seconds).timeout
		if not is_inside_tree():
			return


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
	if _scroll_tween:
		_scroll_tween.kill()
