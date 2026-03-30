extends SceneTree

const APP_ROOT_SCENE := preload("res://scenes/app_root.tscn")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var session_state := root.get_node_or_null("SessionState")
	assert(session_state != null)
	session_state.clear_runtime()
	session_state.battle_setup = {
		"hero_id": "hero_angel",
		"ally_ids": ["ally_hound_remnant", "ally_hound_remnant", "ally_hound_remnant"],
		"strategy_ids": ["strat_void_echo"],
		"battle_id": "battle_void_gate_alpha",
		"seed": 20260330
	}
	session_state.last_timeline = [
		{"tick": 0, "entities": []},
		{"tick": 1, "entities": []}
	]
	session_state.last_battle_result = {
		"victory": true,
		"survivors": ["hero_angel"],
		"casualties": [],
		"triggered_events": [],
		"triggered_strategies": []
	}

	var app_root: Control = APP_ROOT_SCENE.instantiate()
	root.add_child(app_root)
	await process_frame

	var app_router := root.get_node_or_null("AppRouter")
	assert(app_router != null)
	app_router.call("goto_result")
	await process_frame

	var screen_host := app_root.get_node("ScreenHost") as Control
	assert(screen_host != null)
	var result_screen := _current_screen(screen_host)
	assert(result_screen != null)
	assert(result_screen.name == "ResultScreen")
	assert(result_screen.get_node_or_null("Layout/ReplayButton") != null)

	result_screen.call("replay_battle")
	await process_frame

	var observe_screen := _current_screen(screen_host)
	assert(observe_screen != null)
	assert(observe_screen.name == "ObserveScreen")
	assert(session_state.battle_setup.get("battle_id", "") == "battle_void_gate_alpha")

	app_root.queue_free()
	await process_frame
	quit(0)


func _current_screen(host: Control) -> Node:
	for child in host.get_children():
		if child is Node and not child.is_queued_for_deletion():
			return child
	return null
