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
		{"tick": 0, "entities": []},
		{"tick": 1, "entities": []}
	]
	session_state.last_battle_result = {
		"log_entries": [
			{"tick": 1, "type": "strategy_cast", "strategy_id": "strat_chill_wave"}
		]
	}

	var screen: Control = OBSERVE_SCENE.instantiate()
	root.add_child(screen)
	await process_frame

	var hud_root := screen.get_node_or_null("HudRoot") as Control
	if hud_root == null:
		_failures.append("missing HudRoot")
	else:
		if hud_root.mouse_filter != Control.MOUSE_FILTER_IGNORE:
			_failures.append("HudRoot should ignore mouse input to avoid blocking right panel buttons")
		var tick_label := hud_root.get_node_or_null("TickLabel") as Label
		if tick_label != null and tick_label.mouse_filter != Control.MOUSE_FILTER_IGNORE:
			_failures.append("TickLabel should ignore mouse input")
		var event_label := hud_root.get_node_or_null("EventLabel") as Label
		if event_label != null and event_label.mouse_filter != Control.MOUSE_FILTER_IGNORE:
			_failures.append("EventLabel should ignore mouse input")
		var strategy_label := hud_root.get_node_or_null("StrategyCastLabel") as Label
		if strategy_label != null and strategy_label.mouse_filter != Control.MOUSE_FILTER_IGNORE:
			_failures.append("StrategyCastLabel should ignore mouse input")

	if screen.get_node_or_null("EventPanel/DetailSectionTitleBar") == null:
		_failures.append("missing DetailSectionTitleBar")
	if screen.get_node_or_null("EventPanel/TimelineSectionTitleBar") == null:
		_failures.append("missing TimelineSectionTitleBar")

	var token_host := screen.get_node_or_null("TokenHost") as Control
	if token_host == null:
		_failures.append("missing TokenHost")
	else:
		if token_host.mouse_filter != Control.MOUSE_FILTER_IGNORE:
			_failures.append("TokenHost should ignore mouse input to avoid blocking right panel")
	var ally_layer := screen.get_node_or_null("TokenHost/AllyLayer") as Control
	if ally_layer == null:
		_failures.append("missing AllyLayer")
	elif ally_layer.mouse_filter != Control.MOUSE_FILTER_IGNORE:
		_failures.append("AllyLayer should ignore mouse input")
	var enemy_layer := screen.get_node_or_null("TokenHost/EnemyLayer") as Control
	if enemy_layer == null:
		_failures.append("missing EnemyLayer")
	elif enemy_layer.mouse_filter != Control.MOUSE_FILTER_IGNORE:
		_failures.append("EnemyLayer should ignore mouse input")

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
