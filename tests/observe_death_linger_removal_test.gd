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
		{
			"tick": 0,
			"entities": [
				{
					"entity_id": "hero_angel_0",
					"display_name": "英雄：天使",
					"side": "hero",
					"alive": true,
					"hp": 100.0,
					"max_hp": 100.0,
					"position": Vector2(140, 180)
				}
			]
		},
		{
			"tick": 1,
			"entities": [
				{
					"entity_id": "hero_angel_0",
					"display_name": "英雄：天使",
					"side": "hero",
					"alive": false,
					"hp": 0.0,
					"max_hp": 100.0,
					"position": Vector2(140, 180)
				}
			]
		},
		{
			"tick": 20,
			"entities": [
				{
					"entity_id": "hero_angel_0",
					"display_name": "英雄：天使",
					"side": "hero",
					"alive": false,
					"hp": 0.0,
					"max_hp": 100.0,
					"position": Vector2(140, 180)
				}
			]
		}
	]
	session_state.last_battle_result = {
		"log_entries": [
			{"tick": 1, "type": "hero_down", "entity_id": "hero_angel_0"}
		]
	}

	var screen: Control = OBSERVE_SCENE.instantiate()
	root.add_child(screen)
	await process_frame

	screen.call("_seek_to_frame", 1)
	var linger_token: Variant = screen.call("get_token_view", "hero_angel_0")
	if linger_token == null:
		_failures.append("token should exist during linger at frame 1")

	screen.call("_seek_to_frame", 2)
	var removed_token: Variant = screen.call("get_token_view", "hero_angel_0")
	if removed_token != null:
		_failures.append("token should be removed after linger expiry at frame 2")

	screen.call("_seek_to_frame", 1)
	var rewind_token: Variant = screen.call("get_token_view", "hero_angel_0")
	if rewind_token == null:
		_failures.append("token should reappear when rewinding back into linger window")

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
