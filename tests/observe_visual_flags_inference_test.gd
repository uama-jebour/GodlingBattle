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
					"entity_id": "hero_1",
					"display_name": "英雄",
					"side": "hero",
					"alive": true,
					"hp": 100.0,
					"max_hp": 100.0,
					"position": Vector2(120, 220)
				},
				{
					"entity_id": "enemy_1",
					"display_name": "敌方",
					"side": "enemy",
					"alive": true,
					"hp": 100.0,
					"max_hp": 100.0,
					"position": Vector2(520, 220)
				}
			]
		},
		{
			"tick": 1,
			"entities": [
				{
					"entity_id": "hero_1",
					"display_name": "英雄",
					"side": "hero",
					"alive": true,
					"hp": 100.0,
					"max_hp": 100.0,
					"position": Vector2(120, 220)
				},
				{
					"entity_id": "enemy_1",
					"display_name": "敌方",
					"side": "enemy",
					"alive": true,
					"hp": 70.0,
					"max_hp": 100.0,
					"position": Vector2(520, 220)
				}
			]
		},
		{
			"tick": 2,
			"entities": [
				{
					"entity_id": "hero_1",
					"display_name": "英雄",
					"side": "hero",
					"alive": true,
					"hp": 100.0,
					"max_hp": 100.0,
					"position": Vector2(120, 220)
				},
				{
					"entity_id": "enemy_1",
					"display_name": "敌方",
					"side": "enemy",
					"alive": false,
					"hp": 0.0,
					"max_hp": 100.0,
					"position": Vector2(520, 220)
				}
			]
		}
	]
	session_state.last_battle_result = {
		"log_entries": [
			{"tick": 2, "type": "event_warning", "event_id": "evt_hunter_fiend_arrival"},
			{"tick": 2, "type": "enemy_down", "entity_id": "enemy_1"}
		]
	}

	var screen: Control = OBSERVE_SCENE.instantiate()
	root.add_child(screen)
	await process_frame
	screen.set_process(false)

	screen.call("_seek_to_frame", 1)
	var hero_token: Node = screen.call("get_token_view", "hero_1")
	var enemy_token: Node = screen.call("get_token_view", "enemy_1")
	if hero_token == null or enemy_token == null:
		_failures.append("expected tokens for hero_1 and enemy_1 at frame 1")
	else:
		if bool(hero_token.get("is_hit")):
			_failures.append("hero_1 should not be marked hit when hp is unchanged")
		if hero_token.get("damage_value") != 0:
			_failures.append("hero_1 damage_value should be 0 when hp is unchanged")
		if not bool(enemy_token.get("is_hit")):
			_failures.append("enemy_1 should be marked hit when hp drops")
		if enemy_token.get("damage_value") != 30:
			_failures.append("enemy_1 damage_value should match hp delta (30)")

	screen.call("_seek_to_frame", 2)
	hero_token = screen.call("get_token_view", "hero_1")
	enemy_token = screen.call("get_token_view", "enemy_1")
	if hero_token == null or enemy_token == null:
		_failures.append("expected tokens for hero_1 and enemy_1 at frame 2")
	else:
		if bool(hero_token.get("is_affected")):
			_failures.append("hero_1 should not be affected by untargeted rows at tick 2")
		if not bool(enemy_token.get("is_affected")):
			_failures.append("enemy_1 should be affected by its targeted down row")
		if not bool(enemy_token.get("is_dead")):
			_failures.append("enemy_1 should be marked dead on its down frame")
		if not enemy_token.has_method("is_death_marker_visible"):
			_failures.append("enemy_1 token missing death marker visibility API")
		elif not bool(enemy_token.call("is_death_marker_visible", int(screen._current_tick))):
			_failures.append("death marker should be visible on the death tick")

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
