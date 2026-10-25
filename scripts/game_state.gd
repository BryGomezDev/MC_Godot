extends Node

signal all_required_done

var salon_interactions: int = 0
var padre_hablado: bool = false
var flashback_visto: bool = false

var _talked: Dictionary = {}
var _required: Dictionary = {}
var _scene_done: Dictionary = {}

func register_required_npc(scene_name: String, npc_id: String) -> void:
	if scene_name not in _required:
		_required[scene_name] = []
	if npc_id not in _required[scene_name]:
		_required[scene_name].append(npc_id)

func mark_npc_talked(npc_id: String, scene_name: String, required: bool) -> void:
	_talked[npc_id] = true
	if required:
		_check_complete(scene_name)

func _check_complete(scene_name: String) -> void:
	if _scene_done.get(scene_name, false):
		return
	var req: Array = _required.get(scene_name, [])
	if req.is_empty():
		return
	for id in req:
		if not _talked.get(id, false):
			return
	_scene_done[scene_name] = true
	all_required_done.emit()

func is_scene_done(scene_name: String) -> bool:
	return _scene_done.get(scene_name, false)
