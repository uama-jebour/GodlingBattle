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
		"strategy_ids": ["strat_counter_demon_summon"],
		"battle_id": "battle_void_gate_alpha",
		"seed": 1
	}
	session_state.last_timeline = [
		{"tick": 0, "entities": []}
	]
	session_state.last_battle_result = {"log_entries": []}

	var screen: Control = OBSERVE_SCENE.instantiate()
	root.add_child(screen)
	await process_frame
	screen.set_process(false)

	var legend := screen.get_node_or_null("LayoutRoot/RightColumn/BattleLogPanel/BattleLogLegend") as RichTextLabel
	if legend == null:
		_failures.append("missing BattleLogLegend")
	else:
		var legend_text := legend.get_parsed_text()
		if legend_text.find("绿色封印=已拦截") == -1:
			_failures.append("legend should describe intercepted seal")
		if legend_text.find("红色后果=未响应入场") == -1:
			_failures.append("legend should describe unresolved entry")

	if not screen.has_method("get_battle_log_legend_text"):
		_failures.append("missing get_battle_log_legend_text")

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
