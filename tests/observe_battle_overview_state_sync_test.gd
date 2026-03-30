extends SceneTree

const OBSERVE_SCENE := preload("res://scenes/observe/observe_screen.tscn")

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	await _verify_progress_sync()
	await _verify_empty_state_text()
	_finish()


func _verify_progress_sync() -> void:
	var session_state := root.get_node_or_null("SessionState")
	if session_state == null:
		_failures.append("missing SessionState")
		return
	session_state.battle_setup = {
		"hero_id": "hero_angel",
		"ally_ids": ["ally_hound_remnant", "ally_hound_remnant", "ally_hound_remnant"],
		"strategy_ids": ["strat_chill_wave"],
		"battle_id": "battle_void_gate_alpha",
		"seed": 1
	}
	session_state.last_timeline = [
		{"tick": 0, "entities": []},
		{"tick": 1, "entities": []},
		{"tick": 2, "entities": []}
	]
	session_state.last_battle_result = {
		"victory": true,
		"survivors": ["hero_angel_0"],
		"casualties": [],
		"triggered_events": [],
		"log_entries": []
	}

	var screen: Control = OBSERVE_SCENE.instantiate()
	root.add_child(screen)
	await process_frame
	screen.set_process(false)

	screen.call("_seek_to_frame", 1)
	var overview_frame_1 := String(screen.call("get_battle_overview_text"))
	if overview_frame_1.find("进度：1/3帧") == -1:
		_failures.append("overview progress should sync to frame 1 immediately")

	screen.call("_seek_to_frame", 2)
	var overview_frame_2 := String(screen.call("get_battle_overview_text"))
	if overview_frame_2.find("进度：2/3帧") == -1:
		_failures.append("overview progress should sync to frame 2 immediately")

	screen.queue_free()
	await process_frame


func _verify_empty_state_text() -> void:
	var session_state := root.get_node_or_null("SessionState")
	if session_state == null:
		_failures.append("missing SessionState")
		return
	session_state.battle_setup = {}
	session_state.last_timeline = []
	session_state.last_battle_result = {}

	var screen: Control = OBSERVE_SCENE.instantiate()
	root.add_child(screen)
	await process_frame

	var overview_text := String(screen.call("get_battle_overview_text"))
	if overview_text.find("战况总览：数据准备中") == -1:
		_failures.append("empty state should show data preparing text")

	screen.queue_free()
	await process_frame


func _finish() -> void:
	if _failures.is_empty():
		quit(0)
		return
	for failure in _failures:
		printerr(failure)
	quit(1)
