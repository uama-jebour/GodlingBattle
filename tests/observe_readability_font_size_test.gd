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
		"LayoutRoot/LeftColumn/StrategyPanel/StrategyTitle": 15,
		"LayoutRoot/RightColumn/AliveRosterPanel/RosterTitle": 15,
		"LayoutRoot/RightColumn/BattleLogPanel/BattleLogTitle": 15
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
