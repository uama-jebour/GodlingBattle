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
		"strategy_ids": ["strat_nuclear_strike"],
		"battle_id": "battle_void_gate_alpha",
		"seed": 1
	}
	session_state.last_timeline = [
		{
			"tick": 0,
			"entities": [
				{"entity_id": "hero_1", "display_name": "英雄", "side": "hero", "alive": true, "hp": 100.0, "max_hp": 100.0, "position": Vector2(240, 260)},
				{"entity_id": "enemy_1", "display_name": "敌方", "side": "enemy", "alive": true, "hp": 100.0, "max_hp": 100.0, "position": Vector2(680, 260)}
			]
		},
		{
			"tick": 1,
			"entities": [
				{"entity_id": "hero_1", "display_name": "英雄", "side": "hero", "alive": true, "hp": 100.0, "max_hp": 100.0, "position": Vector2(250, 262)},
				{"entity_id": "enemy_1", "display_name": "敌方", "side": "enemy", "alive": true, "hp": 76.0, "max_hp": 100.0, "position": Vector2(670, 260)}
			]
		}
	]
	session_state.last_battle_result = {
		"log_entries": [
			{"tick": 1, "type": "strategy_cast", "strategy_id": "strat_nuclear_strike"}
		]
	}

	var screen: Control = OBSERVE_SCENE.instantiate()
	root.add_child(screen)
	await process_frame
	screen.set_process(false)
	screen.call("_seek_to_frame", 1)

	if not screen.has_method("get_strategy_card_highlight_count"):
		_failures.append("missing get_strategy_card_highlight_count")
	elif int(screen.call("get_strategy_card_highlight_count")) <= 0:
		_failures.append("expected strategy card highlight when strategy_cast occurs")

	if not screen.has_method("get_strategy_target_highlight_count"):
		_failures.append("missing get_strategy_target_highlight_count")
	elif int(screen.call("get_strategy_target_highlight_count")) <= 0:
		_failures.append("expected strategy target highlight when strategy_cast occurs")

	if not screen.has_method("get_strategy_origin_pulse_count"):
		_failures.append("missing get_strategy_origin_pulse_count")
	elif screen.has_method("get_strategy_line_count"):
		var strategy_line_count := int(screen.call("get_strategy_line_count"))
		var pulse_count := int(screen.call("get_strategy_origin_pulse_count"))
		if strategy_line_count > 0 and pulse_count <= 0:
			_failures.append("expected strategy origin pulse when strategy lines are present")

	if not screen.has_method("get_strategy_name_popup_alpha"):
		_failures.append("missing get_strategy_name_popup_alpha")
	elif float(screen.call("get_strategy_name_popup_alpha")) <= 0.001:
		_failures.append("expected strategy name popup alpha when strategy_cast occurs")

	if not screen.has_method("get_strategy_screen_flash_alpha"):
		_failures.append("missing get_strategy_screen_flash_alpha")
	elif float(screen.call("get_strategy_screen_flash_alpha")) <= 0.001:
		_failures.append("expected strategy screen flash alpha when strategy_cast occurs")

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
