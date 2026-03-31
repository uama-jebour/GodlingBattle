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
		"victory": false,
		"survivors": ["hero_angel_0"],
		"casualties": [
			"ally_hound_remnant_1",
			"ally_hound_remnant_2",
			"enemy_wandering_demon_4",
			"enemy_animated_machine_5"
		],
		"triggered_events": [{"event_id": "evt_hunter_fiend_arrival"}],
		"triggered_strategies": [{"strategy_id": "strat_void_echo"}],
		"log_entries": [
			{"tick": 5, "type": "strategy_cast", "strategy_id": "strat_void_echo"},
			{"tick": 10, "type": "strategy_cast", "strategy_id": "strat_nuclear_strike"}
		]
	}

	var result_screen: Control = RESULT_SCENE.instantiate()
	root.add_child(result_screen)
	await process_frame

	var text_blocks: Array[String] = []
	for path in [
		"Layout/SurvivorLabel",
		"Layout/CasualtyLabel",
		"Layout/EventLabel",
		"Layout/StrategyLabel",
		"Layout/StrategyCastSummaryLabel",
		"Layout/SetupSnapshotLabel"
	]:
		var label := result_screen.get_node_or_null(path) as Label
		if label == null:
			_failures.append("missing label: %s" % path)
			continue
		text_blocks.append(String(label.text))

	var joined := "\n".join(text_blocks)
	if (
		joined.find("hero_") != -1
		or joined.find("ally_") != -1
		or joined.find("enemy_") != -1
		or joined.find("strat_") != -1
		or joined.find("battle_") != -1
	):
		_failures.append("result screen should not expose english ids")
	if joined.find("英雄：天使") == -1:
		_failures.append("expected localized hero name in result screen")
	if joined.find("野犬残形") == -1:
		_failures.append("expected localized ally name in result screen")
	if joined.find("游荡魔") == -1 or joined.find("活化机械") == -1:
		_failures.append("expected enemy entity ids to resolve through localized enemy names")
	if joined.find("核击协议") == -1:
		_failures.append("expected localized strategy name in result screen")

	result_screen.queue_free()
	await process_frame
	_finish()


func _finish() -> void:
	if _failures.is_empty():
		quit(0)
		return
	for failure in _failures:
		printerr(failure)
	quit(1)
