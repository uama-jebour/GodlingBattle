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
	session_state.last_timeline = [{"tick": 0, "entities": []}]
	session_state.last_battle_result = {"log_entries": []}

	var screen: Control = OBSERVE_SCENE.instantiate()
	root.add_child(screen)
	await process_frame

	for path in [
		"LayoutRoot",
		"LayoutRoot/LeftColumn/BattlefieldPanel",
		"LayoutRoot/LeftColumn/StrategyPanel",
		"LayoutRoot/RightColumn/AliveRosterPanel",
		"LayoutRoot/RightColumn/BattleLogPanel"
	]:
		if screen.get_node_or_null(path) == null:
			_failures.append("missing node: %s" % path)

	if not screen.has_method("get_layout_ratio_snapshot"):
		_failures.append("missing get_layout_ratio_snapshot")
	else:
		var ratio: Dictionary = screen.call("get_layout_ratio_snapshot")
		if absf(float(ratio.get("left", 0.0)) - 0.68) > 0.02:
			_failures.append("left ratio should be ~0.68")
		if absf(float(ratio.get("right_top", 0.0)) - 0.25) > 0.03:
			_failures.append("right top ratio should be ~0.25")

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
