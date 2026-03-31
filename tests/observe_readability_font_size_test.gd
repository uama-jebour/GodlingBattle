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
	session_state.last_timeline = [{"tick": 0, "entities": []}]
	session_state.last_battle_result = {"log_entries": []}

	var screen: Control = OBSERVE_SCENE.instantiate()
	root.add_child(screen)
	await process_frame

	var targets := {
		"LayoutRoot/LeftColumn/BattlefieldPanel/BattlefieldTitle": 26,
		"LayoutRoot/LeftColumn/StrategyPanel/StrategyTitle": 26,
		"LayoutRoot/RightColumn/AliveRosterPanel/RosterTitle": 26,
		"LayoutRoot/RightColumn/BattleLogPanel/BattleLogTitle": 26
	}
	for path in targets.keys():
		var label := screen.get_node_or_null(path) as Label
		if label == null:
			_failures.append("missing label: %s" % path)
			continue
		var minimum_size := int(targets[path])
		var font_size := int(label.get_theme_font_size("font_size"))
		if font_size < minimum_size:
			_failures.append("%s font too small: %d" % [path, font_size])

	var hud_targets := {
		"LayoutRoot/LeftColumn/BattlefieldPanel/BattlefieldRuntime/HudRoot/TickLabel": 48,
		"LayoutRoot/LeftColumn/BattlefieldPanel/BattlefieldRuntime/HudRoot/EventLabel": 34,
		"LayoutRoot/LeftColumn/BattlefieldPanel/BattlefieldRuntime/HudRoot/StrategyCastLabel": 34
	}
	for path in hud_targets.keys():
		var hud_label := screen.get_node_or_null(path) as Label
		if hud_label == null:
			_failures.append("missing hud label: %s" % path)
			continue
		var minimum_size := int(hud_targets[path])
		var font_size := int(hud_label.get_theme_font_size("font_size"))
		if font_size < minimum_size:
			_failures.append("%s font too small: %d" % [path, font_size])

	var roster_columns := screen.get_node_or_null("LayoutRoot/RightColumn/AliveRosterPanel/AliveRosterColumns")
	if roster_columns == null:
		_failures.append("missing roster columns")
	else:
		var body_font_sizes: Array[int] = []
		var stack: Array[Node] = [roster_columns]
		while not stack.is_empty():
			var node: Node = stack.pop_back()
			for child in node.get_children():
				stack.append(child as Node)
			var label := node as Label
			if label == null:
				continue
			if String(label.text) in ["我方", "敌方", "存活名册"]:
				continue
			body_font_sizes.append(int(label.get_theme_font_size("font_size")))
		if body_font_sizes.is_empty():
			_failures.append("missing roster body label font size sample")
		else:
			for font_size in body_font_sizes:
				if font_size < 24:
					_failures.append("roster body font too small: %d" % font_size)
					break

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
