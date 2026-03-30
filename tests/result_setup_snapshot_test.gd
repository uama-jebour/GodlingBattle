extends SceneTree

const RESULT_SCENE := preload("res://scenes/result/result_screen.tscn")

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var session_state := root.get_node_or_null("SessionState")
	if session_state == null:
		_failures.append("missing SessionState")
		_finish()
		return

	session_state.battle_setup = {
		"hero_id": "hero_angel",
		"ally_ids": ["ally_hound_remnant", "ally_hound_remnant", "ally_hound_remnant"],
		"strategy_ids": ["strat_void_echo", "strat_nuclear_strike"],
		"battle_id": "battle_void_gate_beta",
		"seed": 20260330
	}
	session_state.last_battle_result = {
		"victory": true,
		"survivors": ["hero_angel"],
		"casualties": [],
		"triggered_events": [],
		"triggered_strategies": []
	}

	var screen: Control = RESULT_SCENE.instantiate()
	root.add_child(screen)
	await process_frame

	var snapshot_label := screen.get_node_or_null("Layout/SetupSnapshotLabel") as Label
	if snapshot_label == null:
		_failures.append("missing SetupSnapshotLabel")
		screen.queue_free()
		await process_frame
		_finish()
		return

	var text := String(snapshot_label.text)
	if text.find("hero_angel") == -1:
		_failures.append("expected hero_id in setup snapshot")
	if text.find("ally_hound_remnant") == -1:
		_failures.append("expected ally_ids in setup snapshot")
	if text.find("strat_nuclear_strike") == -1:
		_failures.append("expected strategy_ids in setup snapshot")
	if text.find("battle_void_gate_beta") == -1:
		_failures.append("expected battle_id in setup snapshot")
	if text.find("20260330") == -1:
		_failures.append("expected seed in setup snapshot")

	screen.queue_free()
	await process_frame
	_finish()


func _finish() -> void:
	if _failures.is_empty():
		quit(0)
		return
	for message in _failures:
		printerr(message)
	quit(1)
