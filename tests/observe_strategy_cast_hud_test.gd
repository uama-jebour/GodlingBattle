extends SceneTree

const OBSERVE_SCENE := preload("res://scenes/observe/observe_screen.tscn")

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
		"strategy_ids": ["strat_chill_wave"],
		"battle_id": "battle_void_gate_alpha",
		"seed": 1
	}
	session_state.last_timeline = [
		{"tick": 0, "entities": []}
	]
	session_state.last_battle_result = {
		"log_entries": [
			{"tick": 5, "type": "strategy_cast", "strategy_id": "strat_void_echo", "cast_mode": "passive"},
			{"tick": 5, "type": "strategy_cast", "strategy_id": "strat_chill_wave"},
			{"tick": 5, "type": "strategy_cast", "strategy_id": "strat_nuclear_strike"},
			{"tick": 6, "type": "event_warning", "event_id": "evt_any"}
		]
	}

	var screen: Control = OBSERVE_SCENE.instantiate()
	root.add_child(screen)
	await process_frame

	if not screen.has_method("get_strategy_cast_text"):
		_failures.append("missing get_strategy_cast_text")
		screen.queue_free()
		await process_frame
		_finish()
		return

	screen.update_hud_for_tick(5, session_state.last_battle_result.get("log_entries", []))
	var cast_text := String(screen.call("get_strategy_cast_text"))
	if cast_text.find("虚无回响") == -1:
		_failures.append("expected void echo in cast hud text")
	if cast_text.find("寒潮冲击") == -1:
		_failures.append("expected chill wave in cast hud text")
	if cast_text.find("核击协议") == -1:
		_failures.append("expected nuclear strike in cast hud text")
	if cast_text.find("被动生效") == -1:
		_failures.append("expected passive cast marker in cast hud text")
	if cast_text.find("strat_") != -1:
		_failures.append("cast hud should not expose strategy ids")

	screen.update_hud_for_tick(6, session_state.last_battle_result.get("log_entries", []))
	if String(screen.call("get_strategy_cast_text")) != "":
		_failures.append("expected empty cast hud text when no strategy_cast at tick")

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
