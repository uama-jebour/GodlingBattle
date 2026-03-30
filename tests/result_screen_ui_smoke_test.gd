extends SceneTree

const RESULT_SCENE := preload("res://scenes/result/result_screen.tscn")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var session_state := root.get_node_or_null("SessionState")
	assert(session_state != null)
	session_state.last_battle_result = {
		"victory": true,
		"survivors": ["hero_angel"],
		"casualties": ["ally_hound_remnant"],
		"triggered_events": [{"event_id": "evt_hunter_fiend_arrival"}],
		"triggered_strategies": [{"strategy_id": "strat_void_echo"}]
	}

	var screen: Control = RESULT_SCENE.instantiate()
	root.add_child(screen)
	await process_frame

	assert(screen.get_node_or_null("Layout/HeadlineLabel") != null)
	assert(screen.get_node_or_null("Layout/ReturnButton") != null)
	assert(not (screen.get_node("Layout/HeadlineLabel") as Label).text.is_empty())

	screen.queue_free()
	await process_frame
	quit(0)
