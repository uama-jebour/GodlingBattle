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
		{"tick": 1, "entities": []},
		{"tick": 2, "entities": []},
		{"tick": 3, "entities": []},
		{"tick": 4, "entities": []},
		{"tick": 5, "entities": []}
	]
	session_state.last_battle_result = {
		"log_entries": [
			{"tick": 2, "type": "event_warning", "event_id": "evt_a"},
			{"tick": 4, "type": "event_resolve", "event_id": "evt_a"}
		]
	}

	var screen: Control = OBSERVE_SCENE.instantiate()
	root.add_child(screen)
	await process_frame

	var marker_list := screen.get_node_or_null("EventPanel/EventMarkerList") as ItemList
	var pause_button := screen.get_node_or_null("PlaybackPanel/PauseButton") as Button
	if marker_list == null:
		_failures.append("missing EventMarkerList")
		screen.queue_free()
		await process_frame
		_finish()
		return
	if pause_button == null:
		_failures.append("missing PauseButton")
		screen.queue_free()
		await process_frame
		_finish()
		return
	if marker_list.item_count < 2:
		_failures.append("expected at least 2 event markers")
		screen.queue_free()
		await process_frame
		_finish()
		return

	pause_button.emit_signal("pressed")
	marker_list.emit_signal("item_selected", 1)
	await process_frame
	if int(screen._current_tick) != 4:
		_failures.append("expected marker jump to tick 4")

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
