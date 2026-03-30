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
		{"tick": 0, "entities": [{"entity_id": "hero_angel_0", "unit_id": "hero_angel", "side": "hero", "alive": true, "hp": 100.0, "max_hp": 100.0}]},
		{"tick": 1, "entities": [{"entity_id": "hero_angel_0", "unit_id": "hero_angel", "side": "hero", "alive": true, "hp": 96.0, "max_hp": 100.0}]}
	]
	session_state.last_battle_result = {
		"victory": true,
		"survivors": ["hero_angel_0"],
		"casualties": ["ally_hound_remnant_1"],
		"triggered_events": [{"event_id": "evt_hunter_fiend_arrival"}],
		"triggered_strategies": [{"strategy_id": "strat_chill_wave"}],
		"log_entries": [
			{"tick": 0, "type": "event_warning", "event_id": "evt_hunter_fiend_arrival"},
			{"tick": 1, "type": "strategy_cast", "strategy_id": "strat_chill_wave"}
		]
	}

	var screen: Control = OBSERVE_SCENE.instantiate()
	root.add_child(screen)
	await process_frame

	if not screen.has_method("get_battle_overview_text"):
		_failures.append("missing get_battle_overview_text")
	if not screen.has_method("get_tick_summary_text"):
		_failures.append("missing get_tick_summary_text")
	if not _failures.is_empty():
		screen.queue_free()
		await process_frame
		_finish()
		return

	var overview_text := String(screen.call("get_battle_overview_text"))
	if overview_text.find("战况总览") == -1:
		_failures.append("battle overview should include title")
	if overview_text.find("胜负：胜利") == -1:
		_failures.append("battle overview should include localized victory")
	if overview_text.find("触发事件：") == -1:
		_failures.append("battle overview should include event count")
	if overview_text.find("战技施放：") == -1:
		_failures.append("battle overview should include strategy cast count")

	screen.call("update_hud_for_tick", 1, session_state.last_battle_result.get("log_entries", []))
	var tick_summary_text := String(screen.call("get_tick_summary_text"))
	if tick_summary_text.find("本帧动态") == -1:
		_failures.append("tick summary should include localized title")
	if tick_summary_text.find("寒潮冲击") == -1:
		_failures.append("tick summary should include localized strategy name")

	screen.queue_free()
	await process_frame
	_finish()


func _finish() -> void:
	if _failures.is_empty():
		quit(0)
		return
	for failure in _failures:
		printerr(failure)
	quit(1)
