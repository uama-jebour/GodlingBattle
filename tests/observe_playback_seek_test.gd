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
		{"tick": 1, "entities": []},
		{"tick": 2, "entities": []},
		{"tick": 3, "entities": []},
		{"tick": 4, "entities": []}
	]
	session_state.last_battle_result = {"log_entries": []}

	var screen: Control = OBSERVE_SCENE.instantiate()
	root.add_child(screen)
	await process_frame

	var step_forward_button := screen.get_node_or_null("PlaybackPanel/StepForwardButton") as Button
	assert(step_forward_button != null)
	var step_back_button := screen.get_node_or_null("PlaybackPanel/StepBackButton") as Button
	assert(step_back_button != null)
	var progress_slider := screen.get_node_or_null("PlaybackPanel/ProgressSlider") as HSlider
	assert(progress_slider != null)

	step_forward_button.emit_signal("pressed")
	assert(int(screen._current_tick) == 4)

	step_back_button.emit_signal("pressed")
	assert(int(screen._current_tick) == 0)

	progress_slider.value = 3
	progress_slider.emit_signal("value_changed", 3.0)
	assert(int(screen._current_tick) == 3)

	screen.queue_free()
	await process_frame
	quit(0)
