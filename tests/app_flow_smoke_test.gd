extends SceneTree

const APP_ROOT_SCENE := preload("res://scenes/app_root.tscn")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var session_state := root.get_node_or_null("SessionState")
	assert(session_state != null)
	session_state.battle_setup = {}
	session_state.clear_runtime()

	var app_root: Control = APP_ROOT_SCENE.instantiate()
	root.add_child(app_root)
	await process_frame

	var screen_host := app_root.get_node("ScreenHost") as Control
	assert(screen_host != null)

	var prep_screen := _current_screen(screen_host)
	assert(prep_screen != null)
	assert(prep_screen.name == "PreparationScreen")
	assert(prep_screen.get_node_or_null("ScrollContainer/Layout/StartBattleButton") != null)

	prep_screen.start_battle({
		"hero_id": "hero_angel",
		"ally_ids": ["ally_hound_remnant", "ally_hound_remnant", "ally_hound_remnant"],
		"strategy_ids": ["strat_void_echo"],
		"battle_id": "battle_void_gate_alpha",
		"seed": 20260330
	})
	await process_frame

	var observe_screen := _current_screen(screen_host)
	assert(observe_screen != null)
	assert(observe_screen.has_method("play_battle"))

	var guard := 0
	while guard < 800:
		var current := _current_screen(screen_host)
		if current != null and current.name == "ResultScreen":
			break
		observe_screen._process(0.10)
		await process_frame
		guard += 1

	var result_screen := _current_screen(screen_host)
	assert(result_screen != null)
	assert(result_screen.name == "ResultScreen")
	assert(result_screen.get_node_or_null("Layout/ReplayButton") != null)
	assert(result_screen.get_node_or_null("Layout/ReturnButton") != null)

	result_screen.replay_battle()
	await process_frame

	var observe_replay := _current_screen(screen_host)
	assert(observe_replay != null)
	assert(observe_replay.name == "ObserveScreen")

	guard = 0
	while guard < 800:
		var replay_current := _current_screen(screen_host)
		if replay_current != null and replay_current.name == "ResultScreen":
			break
		observe_replay._process(0.10)
		await process_frame
		guard += 1

	var replay_result := _current_screen(screen_host)
	assert(replay_result != null)
	assert(replay_result.name == "ResultScreen")
	assert(replay_result.get_node_or_null("Layout/ReturnButton") != null)

	replay_result.return_to_preparation()
	await process_frame

	var prep_again := _current_screen(screen_host)
	assert(prep_again != null)
	assert(prep_again.name == "PreparationScreen")
	assert(prep_again.get_node_or_null("ScrollContainer/Layout/StartBattleButton") != null)
	assert(session_state.last_timeline.is_empty())
	assert(session_state.last_battle_result.is_empty())

	app_root.queue_free()
	await process_frame
	quit(0)


func _current_screen(host: Control) -> Node:
	for child in host.get_children():
		if child is Node and not child.is_queued_for_deletion():
			return child
	return null
