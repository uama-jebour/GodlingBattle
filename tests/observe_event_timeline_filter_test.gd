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
			{"tick": 0, "type": "event_warning", "event_id": "evt_a"},
			{"tick": 1, "type": "event_resolve", "event_id": "evt_a"},
			{"tick": 1, "type": "strategy_cast", "strategy_id": "strat_chill_wave"}
		]
	}

	var screen: Control = OBSERVE_SCENE.instantiate()
	root.add_child(screen)
	await process_frame

	var filter_select := screen.get_node_or_null("EventPanel/EventFilterSelect") as OptionButton
	var timeline_label := screen.get_node_or_null("EventPanel/EventTimelineLabel") as Label
	if filter_select == null:
		_failures.append("missing EventFilterSelect")
	if timeline_label == null:
		_failures.append("missing EventTimelineLabel")
	if not _failures.is_empty():
		screen.queue_free()
		await process_frame
		_finish()
		return

	var all_text := String(timeline_label.text)
	if all_text.find("event_warning") == -1:
		_failures.append("all filter should include event_warning")
	if all_text.find("event_resolve") == -1:
		_failures.append("all filter should include event_resolve")
	if all_text.find("strategy_cast") == -1:
		_failures.append("all filter should include strategy_cast")

	filter_select.select(1)
	filter_select.emit_signal("item_selected", 1)
	await process_frame
	var warning_text := String(timeline_label.text)
	if warning_text.find("event_warning") == -1:
		_failures.append("warning filter should include event_warning")
	if warning_text.find("event_resolve") != -1:
		_failures.append("warning filter should exclude event_resolve")
	if warning_text.find("strategy_cast") != -1:
		_failures.append("warning filter should exclude strategy_cast")

	screen.update_hud_for_tick(1, session_state.last_battle_result.get("log_entries", []))
	if String(screen.get_event_text()) != "":
		_failures.append("warning filter should hide tick=1 non-warning events")

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
