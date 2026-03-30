extends SceneTree

const OBSERVE_SCENE := preload("res://scenes/observe/observe_screen.tscn")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var session_state := root.get_node_or_null("SessionState")
	assert(session_state != null)
	session_state.battle_setup = {
		"hero_id": "hero_angel",
		"ally_ids": ["ally_hound_remnant", "ally_hound_remnant", "ally_hound_remnant"],
		"strategy_ids": ["strat_void_echo"],
		"battle_id": "battle_void_gate_alpha",
		"seed": 1
	}
	session_state.last_timeline = [
		{"tick": 0, "entities": []},
		{"tick": 1, "entities": []}
	]
	session_state.last_battle_result = {"log_entries": []}

	var screen: Control = OBSERVE_SCENE.instantiate()
	root.add_child(screen)
	await process_frame

	var pause_button := screen.get_node_or_null("PlaybackPanel/PauseButton") as Button
	assert(pause_button != null)
	var speed_select := screen.get_node_or_null("PlaybackPanel/SpeedSelect") as OptionButton
	assert(speed_select != null)
	var progress_slider := screen.get_node_or_null("PlaybackPanel/ProgressSlider") as HSlider
	assert(progress_slider != null)
	var step_back_button := screen.get_node_or_null("PlaybackPanel/StepBackButton") as Button
	assert(step_back_button != null)
	var step_forward_button := screen.get_node_or_null("PlaybackPanel/StepForwardButton") as Button
	assert(step_forward_button != null)
	var event_filter_select := screen.get_node_or_null("EventPanel/EventFilterSelect") as OptionButton
	assert(event_filter_select != null)
	var event_timeline_zoom_select := screen.get_node_or_null("EventPanel/EventTimelineZoomSelect") as OptionButton
	assert(event_timeline_zoom_select != null)
	var event_timeline_density_select := screen.get_node_or_null("EventPanel/EventTimelineDensitySelect") as OptionButton
	assert(event_timeline_density_select != null)
	var event_timeline_label := screen.get_node_or_null("EventPanel/EventTimelineLabel") as Label
	assert(event_timeline_label != null)
	var event_marker_list := screen.get_node_or_null("EventPanel/EventMarkerList") as ItemList
	assert(event_marker_list != null)

	pause_button.emit_signal("pressed")
	var frame_before_pause := int(screen._frame_index)
	screen._process(1.0)
	assert(int(screen._frame_index) == frame_before_pause)

	speed_select.select(1)
	speed_select.emit_signal("item_selected", 1)
	pause_button.emit_signal("pressed")
	var frame_before_resume := int(screen._frame_index)
	screen._process(0.03)
	assert(int(screen._frame_index) > frame_before_resume)

	screen.queue_free()
	await process_frame
	quit(0)
