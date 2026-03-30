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
		"strategy_ids": ["strat_chill_wave", "strat_nuclear_strike"],
		"battle_id": "battle_void_gate_alpha",
		"seed": 1
	}
	session_state.last_timeline = [{
		"tick": 0,
		"entities": [
			{"entity_id": "hero_angel_0", "display_name": "英雄：天使", "side": "hero", "alive": true, "hp": 80.0, "max_hp": 100.0, "position": Vector2(200, 200)},
			{"entity_id": "enemy_hunter_fiend_4", "display_name": "追猎魔", "side": "enemy", "alive": true, "hp": 30.0, "max_hp": 30.0, "position": Vector2(600, 240)}
		]
	}]
	session_state.last_battle_result = {
		"log_entries": [
			{"tick": 0, "type": "event_warning", "event_id": "evt_hunter_fiend_arrival"},
			{"tick": 0, "type": "strategy_cast", "strategy_id": "strat_chill_wave"},
			{"tick": 0, "type": "enemy_down", "entity_id": "enemy_hunter_fiend_4"}
		]
	}

	var screen: Control = OBSERVE_SCENE.instantiate()
	root.add_child(screen)
	await process_frame

	if not screen.has_method("get_alive_roster_text"):
		_failures.append("missing get_alive_roster_text")
	else:
		var roster_text := String(screen.call("get_alive_roster_text"))
		if roster_text.find("英雄：天使") == -1:
			_failures.append("roster should contain ally unit name")
		if roster_text.find("追猎魔") == -1:
			_failures.append("roster should contain enemy unit name")

	if not screen.has_method("get_battle_log_text"):
		_failures.append("missing get_battle_log_text")
	else:
		var log_text := String(screen.call("get_battle_log_text"))
		if log_text.find("5秒后") == -1:
			_failures.append("log should include warning countdown text")
		if log_text.find("施放") == -1:
			_failures.append("log should include strategy cast text")
		if log_text.find("倒下") == -1:
			_failures.append("log should include death text")

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
