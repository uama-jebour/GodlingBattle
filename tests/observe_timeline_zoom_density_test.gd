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
		{"tick": 5, "entities": []},
		{"tick": 6, "entities": []},
		{"tick": 7, "entities": []},
		{"tick": 8, "entities": []},
		{"tick": 9, "entities": []}
	]
	var log_entries: Array = []
	for tick in range(10):
		log_entries.append({
			"tick": tick,
			"type": "event_warning",
			"event_id": "evt_%d" % tick
		})
	session_state.last_battle_result = {
		"log_entries": log_entries
	}

	var screen: Control = OBSERVE_SCENE.instantiate()
	root.add_child(screen)
	await process_frame

	var zoom_select := screen.get_node_or_null("EventPanel/EventTimelineZoomSelect") as OptionButton
	var density_select := screen.get_node_or_null("EventPanel/EventTimelineDensitySelect") as OptionButton
	var timeline_label := screen.get_node_or_null("EventPanel/EventTimelineLabel") as Label
	if zoom_select == null:
		_failures.append("missing EventTimelineZoomSelect")
	if density_select == null:
		_failures.append("missing EventTimelineDensitySelect")
	if timeline_label == null:
		_failures.append("missing EventTimelineLabel")
	if not _failures.is_empty():
		screen.queue_free()
		await process_frame
		_finish()
		return

	var default_text := String(timeline_label.text)
	if default_text.find("第0帧 事件预警") == -1:
		_failures.append("default timeline should include unscaled tick marker")

	zoom_select.select(2)
	zoom_select.emit_signal("item_selected", 2)
	await process_frame

	var zoomed_text := String(timeline_label.text)
	if zoomed_text.find("第0~4帧 事件预警 x5") == -1:
		_failures.append("zoomed timeline should aggregate first bucket")
	if zoomed_text.find("第5~9帧 事件预警 x5") == -1:
		_failures.append("zoomed timeline should aggregate second bucket")

	density_select.select(2)
	density_select.emit_signal("item_selected", 2)
	await process_frame
	if not screen.has_method("get_event_timeline_marker_count"):
		_failures.append("missing get_event_timeline_marker_count")
	elif int(screen.call("get_event_timeline_marker_count")) != 1:
		_failures.append("low density should limit marker count to 1")

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
