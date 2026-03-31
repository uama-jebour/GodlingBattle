extends SceneTree

const OBSERVE_SCENE := preload("res://scenes/observe/observe_screen.tscn")

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var runner: RefCounted = load("res://scripts/battle_runtime/battle_runner.gd").new()
	var payload: Dictionary = runner.run({
		"hero_id": "hero_angel",
		"ally_ids": ["ally_hound_remnant", "ally_hound_remnant"],
		"strategy_ids": ["strat_nuclear_strike"],
		"battle_id": "battle_void_gate_alpha",
		"seed": 26033188
	})
	var result: Dictionary = payload.get("result", {})
	var cast_tick := _first_strategy_cast_tick(result.get("log_entries", []), "strat_nuclear_strike")
	if cast_tick < 0:
		_failures.append("expected runtime strategy_cast log for strat_nuclear_strike")
		_finish()
		return

	var session_state := root.get_node_or_null("SessionState")
	if session_state == null:
		_failures.append("missing SessionState")
		_finish()
		return
	session_state.battle_setup = {
		"hero_id": "hero_angel",
		"ally_ids": ["ally_hound_remnant", "ally_hound_remnant"],
		"strategy_ids": ["strat_nuclear_strike"],
		"battle_id": "battle_void_gate_alpha",
		"seed": 26033188
	}
	session_state.last_timeline = payload.get("timeline", [])
	session_state.last_battle_result = result

	var screen: Control = OBSERVE_SCENE.instantiate()
	root.add_child(screen)
	await process_frame
	screen.set_process(false)
	screen.call("_seek_to_frame", cast_tick)

	if not screen.has_method("get_strategy_card_highlight_count"):
		_failures.append("missing get_strategy_card_highlight_count")
	elif int(screen.call("get_strategy_card_highlight_count")) <= 0:
		_failures.append("expected strategy card highlight on live strategy_cast frame")

	if not screen.has_method("get_strategy_target_highlight_count"):
		_failures.append("missing get_strategy_target_highlight_count")
	elif int(screen.call("get_strategy_target_highlight_count")) <= 0:
		_failures.append("expected strategy target highlight on live strategy_cast frame")

	if not screen.has_method("get_strategy_name_popup_alpha"):
		_failures.append("missing get_strategy_name_popup_alpha")
	elif float(screen.call("get_strategy_name_popup_alpha")) <= 0.001:
		_failures.append("expected strategy popup alpha on live strategy_cast frame")

	if not screen.has_method("get_strategy_screen_flash_alpha"):
		_failures.append("missing get_strategy_screen_flash_alpha")
	elif float(screen.call("get_strategy_screen_flash_alpha")) <= 0.001:
		_failures.append("expected strategy screen flash alpha on live strategy_cast frame")

	screen.queue_free()
	await process_frame
	_finish()


func _first_strategy_cast_tick(log_entries: Array, strategy_id: String) -> int:
	for row_raw in log_entries:
		var row := row_raw as Dictionary
		if str(row.get("type", "")) != "strategy_cast":
			continue
		if str(row.get("strategy_id", "")) != strategy_id:
			continue
		return int(row.get("tick", -1))
	return -1


func _finish() -> void:
	if _failures.is_empty():
		quit(0)
		return
	for message in _failures:
		printerr(message)
	quit(1)
