extends Node

const PREP_SCENE := preload("res://scenes/prep/preparation_screen.tscn")
const OBSERVE_SCENE := preload("res://scenes/observe/observe_screen.tscn")
const RESULT_SCENE := preload("res://scenes/result/result_screen.tscn")
const MISSION_EDITOR_SCENE := preload("res://scenes/mission_editor/mission_editor.tscn")

var _host: Control


func bind_host(host: Control) -> void:
	_host = host


func goto_preparation() -> void:
	_switch_to(PREP_SCENE)


func goto_observe() -> void:
	_switch_to(OBSERVE_SCENE)


func goto_result() -> void:
	_switch_to(RESULT_SCENE)


func goto_mission_editor(mission_id: String = "") -> void:
	_switch_to(MISSION_EDITOR_SCENE)
	if mission_id != "":
		await get_tree().process_frame
		var node := _host.get_node_or_null("MissionEditor")
		if node and node.has_method("load_mission"):
			node.load_mission(mission_id)


func _switch_to(scene_res: PackedScene) -> void:
	if _host == null:
		return
	for child in _host.get_children():
		child.queue_free()
	var instance := scene_res.instantiate()
	_host.add_child(instance)
