class_name Player
extends CharacterBody2D

@export var speed: float = 60.0
@export var clamp_left: float = 8.0
@export var clamp_right: float = 472.0

enum Form { ADULT, CHILD }

var _locked: bool = false
var _nearby: Array[Interactable] = []

func _ready() -> void:
	add_to_group("player")

func _physics_process(_delta: float) -> void:
	if _locked:
		return
	var dir: float = Input.get_axis("move_left", "move_right")
	velocity.x = dir * speed
	move_and_slide()
	position.x = clampf(position.x, clamp_left, clamp_right)

func _unhandled_input(event: InputEvent) -> void:
	if _locked:
		return
	if event.is_action_pressed("interact"):
		_trigger_nearest()

func _trigger_nearest() -> void:
	if _nearby.is_empty():
		return
	var nearest: Interactable = _nearby[0]
	var min_dist: float = global_position.distance_squared_to(nearest.global_position)
	for i in range(1, _nearby.size()):
		var d: float = global_position.distance_squared_to(_nearby[i].global_position)
		if d < min_dist:
			min_dist = d
			nearest = _nearby[i]
	nearest.trigger()

func add_nearby_interactable(i: Interactable) -> void:
	if i not in _nearby:
		_nearby.append(i)

func remove_nearby_interactable(i: Interactable) -> void:
	_nearby.erase(i)

func lock_control() -> void:
	_locked = true
	velocity = Vector2.ZERO

func unlock_control() -> void:
	_locked = false

func set_form(form: Form) -> void:
	var body: Node = get_node_or_null("Body")
	if body is ColorRect:
		(body as ColorRect).color = Color(0.2, 0.4, 0.8) if form == Form.ADULT else Color(0.8, 0.4, 0.2)
