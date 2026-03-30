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
	session_state.last_battle_result = {
		"victory": true,
		"survivors": ["hero_angel"],
		"casualties": [],
		"triggered_events": [],
		"triggered_strategies": [{"strategy_id": "strat_chill_wave"}],
		"log_entries": [
			{"tick": 5, "type": "strategy_cast", "strategy_id": "strat_chill_wave"},
			{"tick": 12, "type": "strategy_cast", "strategy_id": "strat_chill_wave"},
			{"tick": 18, "type": "strategy_cast", "strategy_id": "strat_nuclear_strike"}
		]
	}

	var screen: Control = RESULT_SCENE.instantiate()
	root.add_child(screen)
	await process_frame

	var cast_label := screen.get_node_or_null("Layout/StrategyCastSummaryLabel") as Label
	if cast_label == null:
		_failures.append("missing StrategyCastSummaryLabel")
		screen.queue_free()
		await process_frame
		_finish()
		return

	var text := String(cast_label.text)
	if text.find("strat_chill_wave x2") == -1:
		_failures.append("expected chill wave summary count")
	if text.find("strat_nuclear_strike x1") == -1:
		_failures.append("expected nuclear strike summary count")

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
